module suipass::user {
    use std::string::{Self, String};

    use sui::vec_map::{Self, VecMap};
    use sui::linked_table::{Self, LinkedTable};
    use suipass::approval::{Self, Approval};

    //======================================================================
    // Module Structs
    //======================================================================

    public struct User has key {
        id: UID,
        info: String,
        approvals: LinkedTable<ID, Approval>,
    }

    //======================================================================
    // Event Structs
    //======================================================================

    // struct UserRegistered has copy, drop {
    //     user_id: ID,
    // }

    //======================================================================
    // Functions
    //======================================================================

    public fun new(info: vector<u8>, ctx: &mut TxContext) {
        let user = User {
            id: object::new(ctx),
            info: string::utf8(info),
            approvals: linked_table::new(ctx),
        };
        transfer::transfer(user, tx_context::sender(ctx))
    }

    public fun update_info(
        user: &mut User, 
        info: vector<u8>,
    ) {
        user.info = string::utf8(info)
    }

    public fun merge(user: &mut User, approval: Approval) {
        linked_table::push_back(&mut user.approvals, approval::provider_id(&approval), approval)
    }

    //======================================================================
    // Accessors
    //======================================================================

    public fun levels(user: &User): VecMap<ID, u16> {
        let mut current_key_opt = user.approvals.front();
        let mut result: VecMap<ID, u16> = vec_map::empty();
        while (!current_key_opt.is_none()){
            let current = *option::borrow<ID>(current_key_opt);
            let approval = linked_table::borrow(&user.approvals, current);
            let _ = approval::level(approval);
            current_key_opt = linked_table::next(&user.approvals, current);
            vec_map::insert(&mut result, current, approval::level(approval));
        };

        result
    }

    //======================================================================
    // Tests
    //======================================================================

    #[test_only]
    public fun get_user_info(user: &User): String {
        user.info
    }
}
