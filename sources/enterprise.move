module suipass::enterprise {
    use std::vector;
    use std::option::{Option};
    use std::string::{Self, String};

    use sui::coin;
    use sui::event;
    use sui::transfer;
    use sui::sui::SUI;
    use sui::object::{Self, UID, ID};
    use sui::vec_map::{Self, VecMap};
    use sui::tx_context::{Self, TxContext};

    use suipass::provider::{Self, Provider, ProviderCap};
    use suipass::user::{Self, User};
    use suipass::suipass::{Self, AdminCap, SuiPass};

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

    struct EnterpriseCap has key {
        id: UID,
        enterprise: ID
    }
    // This struct store supported providers and others config
    struct Enterprise has key, store {
        id: UID,
        name: String,
        metadata: String,
        providers: VecMap<ID, ProviderConfig>,
        threshold: u16,
    }

    struct ProviderConfig has store { }

    //======================================================================
    // Event Structs
    //======================================================================

    struct CreatedEnterprise has copy, drop {
        enterprise_id: ID,
        enterprise_cap_id: ID,
    }

    //======================================================================
    // Functions
    //======================================================================

    public fun create_enterprise(
        suipass: &mut SuiPass,
        owner: address,
        name: vector<u8>,
        metadata: vector<u8>,
        provider_ids: vector<ID>,
        threshold: u16, // TODO: Handle check if it valid
        ctx: &mut TxContext
    ) {
        let providers = vec_map::empty();
        let i = 0;
        while (i < vector::length(&provider_ids)) {
            let id = *vector::borrow(&provider_ids, i);
            suipass::assert_provider_exist(suipass, id);
            vec_map::insert(&mut providers, id, ProviderConfig {});
            i = i + 1;
        };

        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        let cap = EnterpriseCap {
            id: object::new(ctx),
            enterprise: id
        };

        let event = CreatedEnterprise {
           enterprise_id: id,
           enterprise_cap_id: object::uid_to_inner(&cap.id)
        };

        transfer::share_object(Enterprise {
            id: uid,
            name: string::utf8(name),
            metadata: string::utf8(metadata),
            providers,
            threshold,
        });

        transfer::transfer(cap, tx_context::sender(ctx));
        event::emit(event);
    }

    //======================================================================
    // Accessors
    //======================================================================

    public fun calculate_user_score(ent: &Enterprise, suipass: &SuiPass, user: &User, _: &mut TxContext): u16 {
        let levels = user::levels(user);
        let ids = vec_map::keys(&levels);
        let len = vector::length(&ids);

        let result: u16 = 0;
        loop {
            if (len == 0) break;
            len = len - 1;

            let id = vector::borrow(&ids, len);

            let level = *vec_map::get(&levels, id);

            let increase = suipass::get_score(suipass, id, level);

            result = result + increase;
        };

        result
    }

    public fun is_human(ent: &Enterprise, suipass: &SuiPass, user: &User, ctx: &mut TxContext): bool {
        let score = calculate_user_score(ent, suipass, user, ctx);
        score >= ent.threshold
    }

    //======================================================================
    // Validation functions
    //======================================================================

    //======================================================================
    // Tests
    //======================================================================
}
