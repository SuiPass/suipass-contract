module suipass::provider {
    use std::string::{Self, String};
    use sui::table::{Self, Table};

    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::coin;
    use sui::address;
    use sui::vec_map::{Self, VecMap};
    use sui::hash;

    use suipass::approval;
    // Errors
    const ENotProviderOwner: u64 = 0;
    const EInsufficientPayment: u64 = 1;
    const ERequestRejected: u64 = 2;
    const EInvalidRequest: u64 = 3;
    const EInvalidScoreDistribution: u64 = 4;

    //======================================================================
    // Module Structs
    //======================================================================

    public struct ProviderCap has key, store {
        id: UID,
        provider: ID
    }

    public struct Provider has store, key {
        id: UID,
        name: String,
        metadata: String,

        submit_fee: u64, // Fee for creating submission
        update_fee: u64,
        balance: Balance<SUI>,

        max_level: u16,
        level_score_distribution: Table<u16, u16>,
        max_score: u16,
        disable: bool,

        requests: Table<address, Request>,
        records: Table<address, Record>,
    }

    public struct Request has store, drop, copy {
        requester: address,
        proof: String,
    }

    public struct Record has store, drop {
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

    fun set_level_score_distribution(distribution_vec: vector<u16>, max_level: u16, result: &mut Table<u16, u16>): &mut Table<u16, u16> {
        let mut total_percent: u16 = 0;
        let mut count = 0;
        let pre_level_percent = 0;
        assert!((vector::length(&distribution_vec) as u16) == max_level, EInvalidScoreDistribution);
        while (count < max_level) {
            let percent = *vector::borrow(&distribution_vec, (count as u64));
            assert!(percent > pre_level_percent, EInvalidScoreDistribution);
            total_percent = total_percent + percent;
            table::add(result, count + 1, percent);
            count = count + 1;
        };

        assert!(total_percent == 100, EInvalidScoreDistribution);

        result
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
        let length = table::length(&provider.level_score_distribution);
        let mut i = 1;
        let mut result = vec_map::empty();    
        while (i <= length) {
            let key = i as u16;
            let value = table::borrow(&provider.level_score_distribution, i as u16);
            result.insert(key, *value);
            i = i + 1;
        };
        result
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

    public(package) fun create_provider(
        name: vector<u8>,
        metadata: vector<u8>,
        submit_fee: u64,
        update_fee: u64,
        max_level: u16,
        level_score_distribution: vector<u16>,
        max_score: u16,
        ctx: &mut TxContext
    ): (ProviderCap, Provider) {
        let mut distribution = table::new(ctx);
        let _ = set_level_score_distribution(level_score_distribution, max_level, &mut distribution);
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
            level_score_distribution: distribution,
            max_score,
            disable: false,
            requests: table::new(ctx),
            records: table::new(ctx),
        };
        (cap, provider)
    }

    public(package) fun update_max_score(
        provider: &mut Provider,
        score: u16,
    ) {
        provider.max_score = score
    }

    public(package) fun update_score_distribution(
        provider: &mut Provider,
        distribution: vector<u16>,
    ){
        let _ = set_level_score_distribution(distribution, provider.max_level, &mut provider.level_score_distribution);
    }

    public(package) fun update_info(
        provider: &mut Provider,
        metadata: &mut Option<vector<u8>>,
        submit_fee: &mut Option<u64>,
        update_fee: &mut Option<u64>,
        max_level: &mut Option<u16>,
    ) {
        if (option::is_some(metadata)) {
            provider.metadata = string::utf8(option::extract(metadata));
        };
        if (option::is_some(submit_fee)) {
            provider.submit_fee = option::extract(submit_fee);
        };
        if (option::is_some(update_fee)) {
            provider.update_fee = option::extract(update_fee);
        };
        if (option::is_some(max_level)) {
            provider.max_level = option::extract(max_level);
        };
    }

    public(package) fun submit_request(
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

        table::add(&mut provider.requests, key, req);

        key
    }

    public(package) fun resolve_request(
        provider_cap: &ProviderCap,
        provider: &mut Provider,
        requester: &address, // HACK: request_id
        evidence: vector<u8>,
        level: u16,
        ctx: &mut TxContext
    ): Request {
        // HACK: Trick the request id
        let request_id = &address::from_bytes(hash::blake2b256(&address::to_bytes(*requester)));

        assert!(provider_cap.provider == object::uid_to_inner(&provider.id), ENotProviderOwner);
        assert!(table::contains(&provider.requests, *request_id), EInvalidRequest);
        assert!(vector::length(&evidence) > 0, ERequestRejected);
        let request = table::remove(&mut provider.requests, *request_id);
        let issued_date = tx_context::epoch_timestamp_ms(ctx);
        let record = Record { requester: *requester, level, evidence: string::utf8(evidence), issued_date };
        if (table::contains(&provider.records, request.requester)) {
            let cur = table::borrow_mut(&mut provider.records, request.requester);
            *cur = record;
        } else {
            table::add(&mut provider.records, request.requester, record);
        };

        let approval = approval::new(id(provider), level, evidence, issued_date, ctx);
        transfer::public_transfer(approval, request.requester);
        request
    }

    public(package) fun reject_request(
        provider_cap: &ProviderCap,
        provider: &mut Provider,
        requester: &address, // HACK: request_id
    ): Request {
        // HACK: Trick the request id
        let request_id = &address::from_bytes(hash::blake2b256(&address::to_bytes(*requester)));

        assert!(provider_cap.provider == object::uid_to_inner(&provider.id), ENotProviderOwner);
        assert!(table::contains(&provider.requests, *request_id), EInvalidRequest);

        let request = table::remove(&mut provider.requests, *request_id);

        request
    }
}
