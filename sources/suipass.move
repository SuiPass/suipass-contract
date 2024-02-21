module suipass::suipass {
    // This module sumarizes all supported credits,
    // allows users to mint their passport NFT (Need to check if NFT can be updated, OR users will hold a lot of passports since their credit can be expire)
  const THRESHOLD: u16 = 30; // 30/100

  public entry fun checkHumanity(): bool {
      return false
  }
}
/*
total = 100
x = 10  -> 3 6 9 
linkedin = 20
*/
