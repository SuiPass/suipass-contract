module suipass::provider {
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::coin;
    use sui::address;
    use sui::vec_map::{Self, VecMap};
    use sui::hash;

    use suipass::approval;

    friend suipass::suipass;

    // Errors
    const ENotProviderOwner: u64 = 0;
    const EInsufficientPayment: u64 = 1;
    const ERequestRejected: u64 = 2;
    const EInvalidRequest: u64 = 3;
    const EInvalidScoreDistribution: u64 = 4;

    //======================================================================
    // Module Structs
    //======================================================================

    struct ProviderCap has key, store {
        id: UID,
        provider: ID
    }

    struct Provider has store, key {
        id: UID,
        name: String,
        metadata: String,

        submit_fee: u64, // Fee for creating submission
        update_fee: u64,
        balance: Balance<SUI>,

        max_level: u16,
        level_score_distribution: VecMap<u16, u16>,
        max_score: u16,
        disable: bool,

        requests: VecMap<address, Request>,
        records: VecMap<address, Record>,
    }

    struct Request has store, drop {
        requester: address,
        proof: String,
    }

    struct Record has store, drop {
        requester: address,
        level: u16,
        evidence: String,
        issued_date: u64
    }

    //======================================================================
    // Functions
    //======================================================================

    public fun withdraw(provider_cap: &ProviderCap, provider: &mut Provider, ctx: &mut TxContext): coin::Coin<SUI> {
        assert!(provider_cap.provider == object::uid_to_inner(&provider.id), ENotProviderOwner);

        let amount = balance::value(&provider.balance);
        let coin = coin::take(&mut provider.balance, amount, ctx);
        coin
    }

    public fun add_balance(provider: &mut Provider, coin: coin::Coin<SUI>) {
        coin::put(&mut provider.balance, coin)
    }

    public fun check_level_score_distribution(distribution: VecMap<u16, u16>, max_level: u16){
        let total_percent: u16 = 0;
        let count = 1;
        let pre_level_percent = 0;
        while (count <= max_level) {
            //TODO check if the distribution lengh is out of max_level
            assert!(vec_map::contains(&distribution, &count), EInvalidScoreDistribution);
            let percent = *vec_map::get(&distribution, &count);
            assert!(percent > pre_level_percent, EInvalidScoreDistribution);
            total_percent = total_percent + percent;
            count = count + 1;
        };

        assert!(total_percent == 100, EInvalidScoreDistribution);
    }

    //======================================================================
    // Accessors
    //======================================================================

    public fun id(provider: &Provider): ID {
        object::uid_to_inner(&provider.id)
    }

    public fun cap_id(cap: &ProviderCap): ID {
        object::uid_to_inner(&cap.id)
    }

    public fun id_from_cap(cap: &ProviderCap): ID {
        cap.provider
    }

    public fun name(provider: &Provider): String {
        provider.name
    }

    public fun max_score(provider: &Provider): u16 {
        provider.max_score
    }

    public fun max_level(provider: &Provider): u16 { 
        provider.max_level
    }

    public fun level_score_distribution(provider: &Provider): VecMap<u16, u16> {
        provider.level_score_distribution
    }

    public fun submit_fee(provider: &Provider): u64 {
        provider.submit_fee
    }

    public fun requester(request: &Request): address {
        request.requester
    }

    //======================================================================
    // Friend required functions
    //======================================================================

    public(friend) fun create_provider(
        name: vector<u8>,
        metadata: vector<u8>,
        submit_fee: u64,
        update_fee: u64,
        max_level: u16,
        level_score_distribution: VecMap<u16, u16>,
        max_score: u16,
        ctx: &mut TxContext
    ): (ProviderCap, Provider) {
        check_level_score_distribution(level_score_distribution, max_level);
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        let cap = ProviderCap {
            id: object::new(ctx),
            provider: id
        };
        let provider = Provider {
            id: uid,
            name: string::utf8(name),
            metadata: string::utf8(metadata),
            submit_fee,
            update_fee,
            balance: balance::zero(),
            max_level,
            level_score_distribution,
            max_score,
            disable: false,
            requests: vec_map::empty(),
            records: vec_map::empty(),
        };
        (cap, provider)
    }

    public(friend) fun update_max_score(
        provider: &mut Provider,
        score: u16,
    ) {
        provider.max_score = score
    }

    public(friend) fun update_score_distribution(
        provider: &mut Provider,
        distribution: VecMap<u16, u16>,
    ){
        check_level_score_distribution(distribution, provider.max_level);
        provider.level_score_distribution = distribution;
    }

    public(friend) fun update_info(
        provider: &mut Provider,
        metadata: Option<vector<u8>>,
        submit_fee: Option<u64>,
        update_fee: Option<u64>,
        max_level: Option<u16>,
    ) {
        if (option::is_some(&metadata)) {
            provider.metadata = string::utf8(option::extract(&mut metadata));
        };
        if (option::is_some(&submit_fee)) {
            provider.submit_fee = option::extract(&mut submit_fee);
        };
        if (option::is_some(&update_fee)) {
            provider.update_fee = option::extract(&mut update_fee);
        };
        if (option::is_some(&max_level)) {
            provider.max_level = option::extract(&mut max_level);
        };
    }

    public(friend) fun submit_request(
        provider: &mut Provider,
        requester: address,
        proof: vector<u8>,
        coin: &mut coin::Coin<SUI>,
        ctx: &mut TxContext
    ): address {
        let balance = coin::balance_mut(coin);

        if (balance::value(balance) < provider.submit_fee) {
            abort(EInsufficientPayment)
        };

        let coin = coin::take(balance, provider.submit_fee, ctx);
        coin::put(&mut provider.balance, coin);

        // TODO: Concat with other thing to change the constraint of an request
        let key = address::from_bytes(hash::blake2b256(&address::to_bytes(requester)));
        let req = Request {
            requester,
            proof: string::utf8(proof)
        };

        vec_map::insert(&mut provider.requests, key, req);

        key
    }

    public(friend) fun resolve_request(
        provider_cap: &ProviderCap,
        provider: &mut Provider,
        requester: &address, // HACK: request_id
        evidence: vector<u8>,
        level: u16,
        ctx: &mut TxContext
    ): Request {
        // HACK: Trick the request id
        //Từ id của người request lấy ra key
        let request_id = &address::from_bytes(hash::blake2b256(&address::to_bytes(*requester)));

        //Kiểm tra xem người gọi hàm có phải là chủ sở hữu của provider không
        assert!(provider_cap.provider == object::uid_to_inner(&provider.id), ENotProviderOwner);
        assert!(vec_map::contains(&provider.requests, request_id), EInvalidRequest);
        assert!(vector::length(&evidence) > 0, ERequestRejected);
        //xoá request khỏi provider
        let (_, request) = vec_map::remove(&mut provider.requests, request_id);
        //Lấy thời gian hiện tại
        let issued_date = tx_context::epoch_timestamp_ms(ctx);
        //Tạo một record lưu thông tin được resolve
        let record = Record { requester: *requester, level, evidence: string::utf8(evidence), issued_date };
        //Nếu requester đã có record thì cập nhật record cũ, ngược lại thì thêm record mới
        if (vec_map::contains(&provider.records, &request.requester)) {
            let cur = vec_map::get_mut(&mut provider.records, &request.requester);
            *cur = record;
        } else {
            vec_map::insert(&mut provider.records, request.requester, record);
        };

        //Call đến hàm new của package approval để tạo một approval mới
        let approval = approval::new(id(provider), level, evidence, issued_date, ctx);
        //Chuyển approval đến cho requester
        transfer::public_transfer(approval, request.requester);
        request
    }

    public(friend) fun reject_request(
        provider_cap: &ProviderCap,
        provider: &mut Provider,
        requester: &address, // HACK: request_id
    ): Request {
        // HACK: Trick the request id
        let request_id = &address::from_bytes(hash::blake2b256(&address::to_bytes(*requester)));

        assert!(provider_cap.provider == object::uid_to_inner(&provider.id), ENotProviderOwner);
        assert!(vec_map::contains(&provider.requests, request_id), EInvalidRequest);

        let (_, request) = vec_map::remove(&mut provider.requests, request_id);

        request
    }
}
