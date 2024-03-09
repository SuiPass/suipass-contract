module suipass::suipass {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use std::vector;

    use sui::table::{Self, Table};
    use sui::vec_set::{Self, VecSet};

    use sui::vec_map::{Self, VecMap};

    use suipass::provider::{Self, Provider, ProviderCap};
    use suipass::user::{Self, User};

    #[test_only]
    use sui::test_scenario;
    #[test_only]
    use sui::test_utils::assert_eq;

    // This module sumarizes all supported credits,
    // allows users to mint their passport NFT (Need to check if NFT can be updated, OR users will hold a lot of passports since their credit can be expire)
    const DEFAULT_THRESHOLD: u16 = 30; // 30/100
    const DEFAULT_EXPIRATION_PERIOD: u64 = 3 * 30 * 24 * 60 * 60 * 1000 ; // 3 months in miliseconds

    // Errors
    const EProviderNotExist: u64 = 0;
    const EProviderAlreadyExist: u64 = 1;
    const EUsernotQualified: u64 = 2;
    const ENotAdmin: u64 = 3;

    // This struct store supported providers and their score
    struct SuiPass has key, store {
        id: UID,
        providers: VecMap<ID, Provider>,
        // providers: VecSet<address>,
        // providers_data: Table<address, Provider>,
        threshold: u16,
        expiration_period: u64
    }

    // We need to pass more data into this object, basically suipass's owner can set score for each 3rd party

    // We assume that the threshold will be changed in the future, but it doesn't matter. 
    // The NFT is still legal since it doesn't expire
    struct NFTPassportMetadata has key, store {
        id: UID,
        // name: string::String,
        // description: string::String,
        // url: Url,
        issued_date: u64,
        expiration_date: u64,
        score: u16,
        threshold: u16
    }

    struct AdminCap has key {
        id: UID,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));

        transfer::share_object(SuiPass {
            id: object::new(ctx),
            providers: vec_map::empty(),
            // providers_data: table::new<address, Provider>(ctx),
            threshold: DEFAULT_THRESHOLD,
            expiration_period: DEFAULT_EXPIRATION_PERIOD
        });
    }

    public fun add_provider(
        _: &AdminCap,
        suipass: &mut SuiPass, 
        owner: address,
        name: vector<u8>,
        submit_fee: u64,
        update_fee: u64,
        total_levels: u16,
        score: u16,
        ctx: &mut TxContext
    ) {
        let (id, provider_cap, provider) = provider::create_provider(name, submit_fee, update_fee, total_levels, score, ctx);

        assert!(!vec_map::contains(&suipass.providers, &id), EProviderAlreadyExist);
        vec_map::insert(&mut suipass.providers, id, provider);
        transfer::public_transfer(provider_cap, owner)
    }

    // public fun remove_provider(_: &AdminCap, suipass: &mut SuiPass, provider: &Provider, _: &mut TxContext) {
    //     let id = provider::id(provider);
    //     assert_provider_exist(suipass, id);
    //
    //     vec_map::get_mut(&mut suipass.providers, &id);
    //     // table::remove(&mut suipass.providers_data, provider);
    // }

    public fun update_provider_score(_: &AdminCap, suipass: &mut SuiPass, provider: &Provider, score: u16, _: &mut TxContext) {
        let id = provider::id(provider);
        assert_provider_exist(suipass, id);

        let provider = vec_map::get_mut(&mut suipass.providers, &id);
        provider::update_score(provider, score);
    }

    /* WARN: deprecated */
    public fun submit_request(
        _user: &mut User,
        suipass: &mut SuiPass,
        provider_id: ID,
        _request_by: address,
        proof: vector<u8>,
        coin: &mut coin::Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert_provider_exist(suipass, provider_id);
        let provider = vec_map::get_mut(&mut suipass.providers, &provider_id);
        provider::submit_request(provider, tx_context::sender(ctx), proof, coin, ctx);
    }

    public fun submit_request_v1(
        suipass: &mut SuiPass,
        provider_id: ID,
        proof: vector<u8>,
        coin: &mut coin::Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert_provider_exist(suipass, provider_id);
        let provider = vec_map::get_mut(&mut suipass.providers, &provider_id);
        provider::submit_request(provider, tx_context::sender(ctx), proof, coin, ctx);
    }

    public fun resolve_request(
        provider_cap: &ProviderCap,
        suipass: &mut SuiPass,
        request: address,
        evidence: vector<u8>,
        level: u16,
        ctx: &mut TxContext
    ) {
        let provider = vec_map::get_mut(&mut suipass.providers, &provider::id_from_cap(provider_cap));
        provider::resolve_request_internal(provider_cap, provider, request, evidence, level, ctx);
    }

    public fun get_provider_score(suipass: &SuiPass, provider: &Provider, _: &mut TxContext): u16 {
        let id = provider::id(provider);
        assert_provider_exist(suipass, id);
        provider::score(vec_map::get(&suipass.providers, &id))
    }

    public fun calculate_user_score(suiPass: &SuiPass, user: &User, _: &mut TxContext): u16 {
        let levels = user::levels(user);
        let ids = vec_map::keys(&levels);
        let len = vector::length(&ids);

        let result: u16 = 0;
        loop {
            if (len == 0) break;
            len = len - 1;

            let id = vector::borrow(&ids, len);

            let level = *vec_map::get(&levels, id);

            let provider = vec_map::get(&suiPass.providers, id);
            let max_score = provider::score(provider);
            let total_levels = provider::total_levels(provider);

            let increase = (level / total_levels * max_score);

            result = result + increase;
        };

        result
    }

    public fun mint_passport(suipass: &SuiPass, user: &mut User, ctx: &mut TxContext) {
        let score = calculate_user_score(suipass, user, ctx);

        assert!(score >= suipass.threshold, EUsernotQualified);

        let issued_date = tx_context::epoch_timestamp_ms(ctx);

        transfer::public_transfer(NFTPassportMetadata {
            id: object::new(ctx),
            issued_date,
            expiration_date: issued_date + suipass.expiration_period, 
            score,
            threshold: suipass.threshold
        }, tx_context::sender(ctx));
    }

    //==============================================================================================
    // Validation functions - Add your validation functions here (if any)
    //==============================================================================================
    fun assert_provider_exist(suipass: &SuiPass, provider_id: ID) {
        assert!(vec_map::contains(&suipass.providers, &provider_id), EProviderNotExist);
    }

    //==============================================================================================
    // Tests - DO NOT MODIFY
    //==============================================================================================
}
