module suipass::suipass {
    use std::vector;
    use std::option::{Option};

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin;
    use sui::event;
    use sui::vec_map::{Self, VecMap};

    use suipass::provider::{Self, Provider, ProviderCap};
    use suipass::user::{Self, User};

    friend suipass::enterprise;

    // This module sumarizes all supported credits,
    // allows users to mint their passport NFT (Need to check if NFT can be updated, OR users will hold a lot of passports since their credit can be expire)
    const DEFAULT_THRESHOLD: u16 = 30; // 30/100
    const DEFAULT_EXPIRATION_PERIOD: u64 = 3 * 30 * 24 * 60 * 60 * 1000 ; // 3 months in miliseconds

    // Errors
    const EProviderNotExist: u64 = 0;
    const EProviderAlreadyExist: u64 = 1;
    const EUsernotQualified: u64 = 2;

    //======================================================================
    // Module Structs
    //======================================================================

    // This struct store supported providers and others config
    struct SuiPass has key, store {
        id: UID,
        providers: VecMap<ID, Provider>,
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

    //======================================================================
    // Event Structs
    //======================================================================

    /*
        Event to be emitted when a provider is added.
        @param provider_id - The id of the provider object.
        @param provider_cap_id - The id of the provider capability object.
    */
    struct ProviderAdded has copy, drop {
        provider_id: ID,
        provider_cap_id: ID,
    }

    struct RequestSubmitted has copy, drop {
        provider_id: ID,
        requester: address,
        request_id: address
    }

    struct RequestResolved has copy, drop {
        provider_id: ID,
        requester: address,
        request_id: address
    }

    //======================================================================
    // Functions
    //======================================================================

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));

        transfer::share_object(SuiPass {
            id: object::new(ctx),
            providers: vec_map::empty(),
            threshold: DEFAULT_THRESHOLD,
            expiration_period: DEFAULT_EXPIRATION_PERIOD
        });
    }

    public fun add_provider(
        _: &AdminCap,
        suipass: &mut SuiPass, 
        owner: address,
        name: vector<u8>,
        metadata: vector<u8>,
        submit_fee: u64,
        update_fee: u64,
        total_levels: u16,
        score: u16,
        ctx: &mut TxContext
    ) {
        let (provider_cap, provider) = provider::create_provider(name, metadata, submit_fee, update_fee, total_levels, score, ctx);

        let provider_id = provider::id(&provider);
        let event = ProviderAdded {
           provider_id,
           provider_cap_id: provider::cap_id(&provider_cap)
        };

        assert!(!vec_map::contains(&suipass.providers, &provider_id), EProviderAlreadyExist);
        vec_map::insert(&mut suipass.providers, provider_id, provider);
        transfer::public_transfer(provider_cap, owner);
        event::emit(event);
    }

    public fun update_provider(
        provider_cap: &ProviderCap,
        suipass: &mut SuiPass, 
        metadata: Option<vector<u8>>,
        submit_fee: Option<u64>,
        update_fee: Option<u64>,
        total_levels: Option<u16>,
    ) {
        assert_provider_exist(suipass, provider::id_from_cap(provider_cap));
        let provider = vec_map::get_mut(&mut suipass.providers, &provider::id_from_cap(provider_cap)); 
        provider::update_info(provider, metadata, submit_fee, update_fee, total_levels);
    }

    // public fun remove_provider(_: &AdminCap, suipass: &mut SuiPass, provider: &Provider, _: &mut TxContext) {
    //     let id = provider::id(provider);
    //     assert_provider_exist(suipass, id);
    //
    //     vec_map::get_mut(&mut suipass.providers, &id);
    //     // table::remove(&mut suipass.providers_data, provider);
    // }

    public fun update_provider_score(
        _: &AdminCap,
        suipass: &mut SuiPass,
        provider_id: ID,
        score: u16,
        _: &mut TxContext
    ) {
        assert_provider_exist(suipass, provider_id);

        let provider = vec_map::get_mut(&mut suipass.providers, &provider_id);
        provider::update_max_score(provider, score);
    }

    public fun submit_request(
        suipass: &mut SuiPass,
        provider_id: ID,
        proof: vector<u8>,
        coin: &mut coin::Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert_provider_exist(suipass, provider_id);
        let provider = vec_map::get_mut(&mut suipass.providers, &provider_id);
        let requester = tx_context::sender(ctx);
        let request_id = provider::submit_request(provider, requester, proof, coin, ctx);
        event::emit(RequestSubmitted {
            provider_id,
            requester,
            request_id
        });
    }

    public fun resolve_request(
        provider_cap: &ProviderCap,
        suipass: &mut SuiPass,
        request_id: address,
        evidence: vector<u8>,
        level: u16,
        ctx: &mut TxContext
    ) {
        let provider = vec_map::get_mut(&mut suipass.providers, &provider::id_from_cap(provider_cap));
        let request = provider::resolve_request(provider_cap, provider, &request_id, evidence, level, ctx);
        event::emit(RequestResolved {
            provider_id: provider::id(provider),
            requester: provider::requester(&request),
            request_id
        });
    }

    public fun reject_request(
        provider_cap: &ProviderCap,
        suipass: &mut SuiPass,
        request_id: address,
    ) {
        let provider = vec_map::get_mut(&mut suipass.providers, &provider::id_from_cap(provider_cap));
        let request = provider::reject_request(provider_cap, provider, &request_id);
        event::emit(RequestResolved {
            provider_id: provider::id(provider),
            requester: provider::requester(&request),
            request_id
        });
    }

    public fun get_provider_score(suipass: &SuiPass, provider: &Provider, _: &mut TxContext): u16 {
        let id = provider::id(provider);
        assert_provider_exist(suipass, id);
        provider::max_score(vec_map::get(&suipass.providers, &id))
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
            let max_score = provider::max_score(provider);
            let total_levels = provider::max_level(provider);

            let increase = (level / total_levels * max_score);

            result = result + increase;
        };

        result
    }

    public fun is_human(suiPass: &SuiPass, user: &User, ctx: &mut TxContext): bool {
        let score = calculate_user_score(suiPass, user, ctx);
        score >= suiPass.threshold
    }

    public fun mint_passport(suipass: &SuiPass, user: &mut User, ctx: &mut TxContext): NFTPassportMetadata {
        let score = calculate_user_score(suipass, user, ctx);

        assert!(score >= suipass.threshold, EUsernotQualified);

        let issued_date = tx_context::epoch_timestamp_ms(ctx);

        NFTPassportMetadata {
            id: object::new(ctx),
            issued_date,
            expiration_date: issued_date + suipass.expiration_period, 
            score,
            threshold: suipass.threshold
        }
    }

    //======================================================================
    // Validation functions - Add your validation functions here (if any)
    //======================================================================
    public fun assert_provider_exist(suipass: &SuiPass, provider_id: ID) {
        assert!(vec_map::contains(&suipass.providers, &provider_id), EProviderNotExist);
    }

    //======================================================================
    // Tests
    //======================================================================
}
