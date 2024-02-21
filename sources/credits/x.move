module suipass::x {
  use sui::object::{Self, UID};
  use std::string::{Self, String};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::sui::SUI;
  use sui::clock::{Self, Clock};
  use sui::balance::{Self, Balance};
  use sui::coin::{Self, Coin};

  const YEAR: u64 = 31556952000;

  // Errors
  const EInsufficientBalance: u64 = 0;
  const ESameScore: u64 = 1;

  struct X has key {
      id: UID,
      name: String,
      submit_fee: u64, // A provider can add a fee for every created credit
      update_fee: u64,
      balance: Balance<SUI>,  
      total_levels: u16
    }

  // User will store their record in their wallet - Maybe we need to change later, I'm not sure =))
  struct Record has key {
      id: UID,
      score: u16,
      last_score_timestamp: u64,
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

      transfer::share_object(X {
          id: object::new(ctx),
          name: string::utf8(b"X"),
          submit_fee: 0,
          update_fee: 0,
          balance: balance::zero(),
          total_levels: 3
      })
    }


    public fun total_levels(provider: &mut X): u16 { 
        provider.total_levels
    }

    // Call this function to get the level you may have
    public fun simulate(
        clock: &Clock, // address 0x6
        joined_date: u64, // in ms
    ): u16 {
        let cur = clock::timestamp_ms(clock);
        let time = cur - joined_date;

        let score = if (time < YEAR) {
            1
        } else if (time < 3*YEAR) {
            2
        } else {
            3
        };
        score 
    }

    public entry fun submit(
          _: &ProviderCap,
          provider: &mut X,
          clock: &Clock, // address 0x6
          joined_date: u64, // in ms
          evidence: vector<u8>, // Backend needs to generate this evidence
          payment: &mut Coin<SUI>,
          ctx: &mut TxContext,
        ) {
        assert!(coin::value(payment) >= provider.submit_fee, EInsufficientBalance);

        let sent_balance = coin::balance_mut(payment);
        let paid = balance::split(sent_balance, provider.submit_fee);

        balance::join(&mut provider.balance, paid);

        let cur = clock::timestamp_ms(clock);
        let time = cur - joined_date;
        let score = if (time < YEAR) {
            1
        } else if (time < 3*YEAR) {
            2
        } else {
            3
        };

        transfer::transfer(Record {
           id: object::new(ctx),
           score,
           last_score_timestamp: cur,
           evidence: string::utf8(evidence)
        }, tx_context::sender(ctx));
    }

    public entry fun update(
          _: &ProviderCap,
          provider: &mut X,
          record: &mut Record,
          clock: &Clock, // address 0x6
          joined_date: u64, // in ms
          evidence: vector<u8>, // Backend needs to generate this evidence
          payment: &mut Coin<SUI>,
        ) {
        assert!(coin::value(payment) >= provider.update_fee, EInsufficientBalance);

        let sent_balance = coin::balance_mut(payment);
        let paid = balance::split(sent_balance, provider.update_fee);

        balance::join(&mut provider.balance, paid);

        let cur = clock::timestamp_ms(clock);
        let time = cur - joined_date;
        let score = if (time < YEAR) {
            1
        } else if (time < 3*YEAR) {
            2
        } else {
            3
        };
        
        assert!(score != record.score, ESameScore);
        record.score = score;
        record.evidence = string::utf8(evidence);
    }

    public fun withdraw(_: &ProviderCap, provider: &mut X, ctx: &mut TxContext): Coin<SUI> {
        let amount = balance::value(&provider.balance);
        coin::take(&mut provider.balance, amount, ctx)
    }
 }


