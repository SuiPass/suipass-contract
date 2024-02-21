module suipass::credit {

  use sui::object::{Self, ID, UID};
  use std::string::{Self, String};
  use sui::transfer;

  struct Record has key {
    creditId: ID,
    score: u16,
    last_score_timestamp: u64,
    evidence: String
  }

  const THRESHOLD: u16 = 30; // 30/100

  // Only some controllers(who have the persmission to run suipass service) can call addRecord
  public entry fun addRecord(id: ID, score: u16, evidence: vector<u8>) {
  }

  public entry fun updateRecord(id: ID, record: &mut Record, score: u16, evidence: vector<u8>) {
  }

  public entry fun checkHumanity(): bool {
      return false
  }
}

