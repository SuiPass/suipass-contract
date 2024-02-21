module suipass::admin {
  use sui::object::{Self, UID};
  use std::string::{Self, String};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use std::vector;

  struct Rule has key {
      name: String,
      description: String,
      hash: String,
    }

  struct CreditRules has key,  store {
      id: UID,
      name: String,
      description: String, 
      connectMessage: String,
      rules: vector<Rule>
    }

  struct AdminCapability has key {id: UID}

  fun init(ctx: &mut TxContext) {
      transfer::transfer(AdminCapability {
          id: object::new(ctx),
        }, tx_context::sender(ctx))
    }

    public entry fun newCredit(
          _: &AdminCapability,
          name: vector<u8>,
          description: vector<u8>, 
          connectMessage: vector<u8>,
          ctx: &mut TxContext,
    ) {
      let creditRules = CreditRules{
          id: object::new(ctx),
          name: string::utf8(name), 
          description: string::utf8(description),
          connectMessage: string::utf8(connectMessage),
          rules: vector::empty()
        };
        transfer::transfer(creditRules, tx_context::sender(ctx));
      }

    public entry fun addRule(
          _: &AdminCapability,
          credit: &mut CreditRules,
          name: vector<u8>,
          description: vector<u8>,
          hash: vector<u8>,
          ctx: &mut TxContext,
    ) {
      let rule = Rule {
        name: string::utf8(name),
        description:string::utf8(description),
        hash: string::utf8(hash),
      };
      vector::push_back(&credit.rules, rule);
      }
 }


