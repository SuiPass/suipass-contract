module suipass::x {
    use sui::object::{Self, UID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};

    use std::vector;

    // Errors
    const EInsufficientBalance: u64 = 0;
    const ESameScore: u64 = 1;
    const ERequestRejected: u64 = 2;
    const EInvalidRequest: u64 = 3;

    struct Provider has store, key {
        id: UID,
        name: String,
        submit_fee: u64, // A provider can add a fee for every created credit
        update_fee: u64,
        balance: Balance<SUI>,  
        total_levels: u16,
        requests: Table<address ,Request>,
        records: Table<address , Record>
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

    struct ProviderCap has key {id: UID}

    fun init(ctx: &mut TxContext) {
        transfer::transfer(ProviderCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));
    }

    // only suipass owner can create a provider
    fun create_provider(
        _: &ProviderCap,
        name: vector<u8>, // Name of the provider
        submit_fee: u64, // A provider can add a fee for every created credit
        update_fee: u64,
        total_levels: u16,
        ctx: &mut TxContext) {

        transfer::share_object(Provider {
            id: object::new(ctx),
            name: string::utf8(name),
            submit_fee,
            update_fee,
            balance: balance::zero(),
            total_levels,
            requests: table::new<address, Request>(ctx),
            records: table::new<address, Record>(ctx)
        });
    }

    fun submit_request(
        provider: &mut Provider,
        request_by: address,
        proof: vector<u8>) {
        let req = Request {
            request_by,
            proof: string::utf8(proof)
        };
        table::add(&mut provider.requests, request_by, req);
    }

    fun resolve_request(
        _: &ProviderCap,
        provider: &mut Provider,
        request_id: address,
        evidence: vector<u8>,
        score: u16) {
        assert!(table::contains(&provider.requests, request_id), EInvalidRequest);
        table::remove(&mut provider.requests, request_id);
        assert!(vector::length(&evidence) > 0, ERequestRejected);

        let record = Record {
            evidence: string::utf8(evidence),
            score
        };
        table::add(&mut provider.records, request_id, record);
    }

    // TODO: We will handle update later 

    public fun total_levels(provider: &mut Provider): u16 { 
        provider.total_levels
    }

    public fun withdraw(_: &ProviderCap, provider: &mut Provider, ctx: &mut TxContext): Coin<SUI> {
        let amount = balance::value(&provider.balance);
        coin::take(&mut provider.balance, amount, ctx)
    }
}


