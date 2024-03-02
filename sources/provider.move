module suipass::provider {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};

    use std::vector;

    use suipass::user::{User};
    use suipass::approval;

    friend suipass::suipass;

    // Errors
    const EInsufficientBalance: u64 = 0;
    const ESameScore: u64 = 1;
    const ERequestRejected: u64 = 2;
    const EInvalidRequest: u64 = 3;
    const ENotProviderOwner: u64 = 4;
    const EInsufficientPayment: u64 = 5;

    struct Provider has store, key {
        id: UID,
        name: String,
        submit_fee: u64, // A provider can add a fee for every created credit
        update_fee: u64,
        balance: Balance<SUI>,  
        total_levels: u16,
        requests: Table<address ,Request>,
        records: Table<address , Record>,

        score: u16,
    }

    struct Request has store, drop {
        request_by: address,
        proof: String,
    }

    // User will store their record in their wallet - Maybe we need to change later, I'm not sure =))
    struct Record has store, drop {
        score: u16,
        evidence: String
    }

    // Assumption: 
    // We have 3 levels
    // Level 1: cur_ts - joined_date < a year
    // Level 2: cur_ts - joined_date < 3 years
    // Level 3: cur_ts - joined_date >= 3 years
    // Hopefully we are able to update the contract to change these conditions

    struct ProviderCap has key, store {id: UID, provider: ID}

    // TODO: require coin to call this method
    public fun submit_request(
        _user: &mut User,
        provider: &mut Provider,
        request_by: address,
        proof: vector<u8>,
        coin: &mut coin::Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let balance = coin::balance_mut(coin);

        if (balance::value(balance) < provider.submit_fee) {
            abort(EInsufficientPayment)
        };

        let coin = coin::take(balance, provider.submit_fee, ctx);
        coin::put(&mut provider.balance, coin);

        let req = Request {
            request_by,
            proof: string::utf8(proof)
        };

        table::add(&mut provider.requests, request_by, req);
    }

    public fun resolve_request(
        provider_cap: &ProviderCap,
        provider: &mut Provider,
        request_id: address,
        evidence: vector<u8>,
        level: u16,
        ctx: &mut TxContext
    ) {
        assert!(provider_cap.provider == object::uid_to_inner(&provider.id), ENotProviderOwner);
        assert!(table::contains(&provider.requests, request_id), EInvalidRequest);
        table::remove(&mut provider.requests, request_id);
        assert!(vector::length(&evidence) > 0, ERequestRejected);

        let issued_date = tx_context::epoch_timestamp_ms(ctx);

        let approval = approval::new(id(provider), level, evidence, issued_date, ctx);
        transfer::public_transfer(approval, request_id)
    }

    public fun withdraw(provider_cap: &ProviderCap, provider: &mut Provider, ctx: &mut TxContext) {
        assert!(provider_cap.provider == object::uid_to_inner(&provider.id), ENotProviderOwner);

        let amount = balance::value(&provider.balance);
        let coin = coin::take(&mut provider.balance, amount, ctx);
        transfer::public_transfer(coin, tx_context::sender(ctx));
    }

    // TODO: We will handle update later 

    public fun id(provider: &Provider): ID {
        object::uid_to_inner(&provider.id)
    }

    public fun score(provider: &Provider): u16 {
        provider.score
    }

    public fun total_levels(provider: &Provider): u16 { 
        provider.total_levels
    }

    public(friend) fun create_provider(
        name: vector<u8>,
        submit_fee: u64,
        update_fee: u64,
        total_levels: u16,
        score: u16,
        ctx: &mut TxContext
    ): (ID, ProviderCap, Provider) {
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        let cap = ProviderCap {
            id: object::new(ctx),
            provider: id
        };
        let provider = Provider {
            id: uid,
            name: string::utf8(name),
            submit_fee,
            update_fee,
            balance: balance::zero(),
            total_levels,
            requests: table::new<address, Request>(ctx),
            records: table::new<address, Record>(ctx),
            score,
        };
        (id, cap, provider)
    }

    public(friend) fun update_score(
        provider: &mut Provider, 
        score: u16,
    ) {
        provider.score = score
    }
}


