// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
───────▄▀▀▀▀▀▀▀▀▀▀▄▄
────▄▀▀░░░░░░░░░░░░░▀▄
──▄▀░░░░░░░░░░░░░░░░░░▀▄
──█░░░░░░░░░░░░░░░░░░░░░▀▄
─▐▌░░░░░░░░▄▄▄▄▄▄▄░░░░░░░▐▌
─█░░░░░░░░░░░▄▄▄▄░░▀▀▀▀▀░░█
▐▌░░░░░░░▀▀▀▀░░░░░▀▀▀▀▀░░░▐▌
█░░░░░░░░░▄▄▀▀▀▀▀░░░░▀▀▀▀▄░█
█░░░░░░░░░░░░░░░░▀░░░▐░░░░░▐▌
▐▌░░░░░░░░░▐▀▀██▄░░░░░░▄▄▄░▐▌
─█░░░░░░░░░░░▀▀▀░░░░░░▀▀██░░█
─▐▌░░░░▄░░░░░░░░░░░░░▌░░░░░░█
──▐▌░░▐░░░░░░░░░░░░░░▀▄░░░░░█
───█░░░▌░░░░░░░░▐▀░░░░▄▀░░░▐▌
───▐▌░░▀▄░░░░░░░░▀░▀░▀▀░░░▄▀
───▐▌░░▐▀▄░░░░░░░░░░░░░░░░█
───▐▌░░░▌░▀▄░░░░▀▀▀▀▀▀░░░█
───█░░░▀░░░░▀▄░░░░░░░░░░▄▀
──▐▌░░░░░░░░░░▀▄░░░░░░▄▀
─▄▀░░░▄▀░░░░░░░░▀▀▀▀█▀
▀░░░▄▀░░░░░░░░░░▀░░░▀▀▀▀▄▄▄▄▄
 /$$      /$$                     /$$       /$$       /$$      /$$ /$$       /$$                 /$$      /$$                         /$$      
| $$  /$ | $$                    | $$      | $$      | $$  /$ | $$|__/      | $$                | $$  /$ | $$                        | $$      
| $$ /$$$| $$  /$$$$$$   /$$$$$$ | $$  /$$$$$$$      | $$ /$$$| $$ /$$  /$$$$$$$  /$$$$$$       | $$ /$$$| $$  /$$$$$$  /$$  /$$$$$$ | $$   /$$
| $$/$$ $$ $$ /$$__  $$ /$$__  $$| $$ /$$__  $$      | $$/$$ $$ $$| $$ /$$__  $$ /$$__  $$      | $$/$$ $$ $$ /$$__  $$|__/ |____  $$| $$  /$$/
| $$$$_  $$$$| $$  \ $$| $$  \__/| $$| $$  | $$      | $$$$_  $$$$| $$| $$  | $$| $$$$$$$$      | $$$$_  $$$$| $$  \ $$ /$$  /$$$$$$$| $$$$$$/ 
| $$$/ \  $$$| $$  | $$| $$      | $$| $$  | $$      | $$$/ \  $$$| $$| $$  | $$| $$_____/      | $$$/ \  $$$| $$  | $$| $$ /$$__  $$| $$_  $$ 
| $$/   \  $$|  $$$$$$/| $$      | $$|  $$$$$$$      | $$/   \  $$| $$|  $$$$$$$|  $$$$$$$      | $$/   \  $$|  $$$$$$/| $$|  $$$$$$$| $$ \  $$
|__/     \__/ \______/ |__/      |__/ \_______/      |__/     \__/|__/ \_______/ \_______/      |__/     \__/ \______/ | $$ \_______/|__/  \__/
                                                                                                                  /$$  | $$                    
                                                                                                                 |  $$$$$$/                    
                                                                                                                  \______/                     
*/
// ----------------------------------------------------------------------------
// 
// FEATURES:
//    %7 maximum ownership to ensure decentralization
//    ~%1.5 total marketing, prizes, airdrops, and bounties
//    variable staking based on current supply / max supply. (decreases as current suppply increases)
//    Variable burn rate based on current supply / max supply (increases as current supply increases)
//    All sales tax is burned, except 0.25% for continued liquidity and marketing over life of project
//
// TOKENOMICS
// Initial Supply = 420 420 420 69
// Max Supply = 420,000,000,000
// ALL additional supply after initial release is created through staking rewards(fair distribution)
//
// In other words about 90% of the total supply is up for grabs through staking. 
//
// LEARN MOAR:
//    Website  https://wwwojak.com
//
// ----------------------------------------------------------------------------

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "./Ownable.sol";
import "./Stakeable.sol";


contract WWWojak is Ownable, Stakeable, ERC20 {
  
// define contract wallets CHANGED TO INTERNAL
// marketing wallet; Pamp It!!
  address internal constant bogdanov1Wallet = 0x93780f0ebe25a52c709D22CfDefD02FC96E2b065;
// Main supply wallet; Damp It!!
  address internal constant bogdanov2Wallet = 0x938A2C973f556A70B6b26c11B2fCAED6ff35B9Bd;


  // 1 divided by Tax rate
  uint internal taxRate = 420;
  uint internal burnRate = 50;
  uint public maxSupply = 420000000000 * 10 ** decimals();


  /**
  * @notice _balances is a mapping that contains a address as KEY 
  * and the balance of the address as the value
  */
  mapping (address => uint256) private _balances;
  /**
  * @notice _allowances is used to manage and control allownace
  * An allowance is the right to use another accounts balance, or part of it
   */
   mapping (address => mapping (address => uint256)) private _allowances;

  /**
  * @notice constructor will be triggered when we create the Smart contract
  * _name = name of the token
  * _short_symbol = Short Symbol name for the token
  * token_decimals = The decimal precision of the Token, defaults 18
  * _totalSupply is how much Tokens there are totally 
  */
//  constructor(string memory token_name, string memory short_symbol, uint8 token_decimals, uint256 token_totalSupply) ERC20("WWWojak", "WWWJ") {
  constructor() ERC20("WWWojak", "WWWJ") { 
      _mint(msg.sender, 42042042069 * 10 ** decimals());
      _mint(bogdanov1Wallet,  6942042069 * 10 ** decimals());

  }

    /**
    * Add functionality like burn to the _stake afunction
    *
     */
    function stake(uint256 _amount) public {
      // Make sure staker actually has balances to stake.
      require(_amount <= balanceOf(msg.sender), "ERC20: Cannot stake more than you own");
      require(grandTotalSupply() < maxSupply, "ERC20: Cannot stake right now. No available slots. Try again later");
        _stake(_amount);
                // Burn the amount of tokens on the sender
        _burn(msg.sender, _amount);
    }



    /**
    * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake(uint256 amount, uint256 stake_index)  public {
      uint256 amount_to_mint = _withdrawStake(amount, stake_index);
      uint256 newSupply = amount_to_mint + grandTotalSupply();
      require(newSupply < maxSupply, "ERC20: Cannot mint right now. Total supply exceeded. Try withdrawing less or again later");
      // Return staked tokens to user
      _mint(msg.sender, amount_to_mint);
    }

    function withdrawAllStakes()  public {
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[stakes[msg.sender]].user]].address_stakes);
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
            withdrawStake(summary.stakes[s].amount, s);
       }}
    

    function transfer(address to, uint amount) public override returns (bool) {

  // check sender bal
    uint balanceReceiver = balanceOf(to);
    uint balanceSender = balanceOf(msg.sender);
    require(balanceSender >= amount, "ERC20: Insufficient Funds for Transfer");
    require(amount + balanceReceiver <= maxSupply / 14, "ERC20: A single token holder cannot own more than ~7% of the supply");
  // impose tax
    uint taxAmount = amount / taxRate;
    uint burnAmount = amount / currentBurnRate(); 
    uint transferAmount = amount - taxAmount - burnAmount;
  // transfer tokens net of tax, tax portion, burn remainder
    _transfer(msg.sender, to, transferAmount); 
    _transfer(msg.sender, bogdanov1Wallet, taxAmount);
    _burn(msg.sender, burnAmount);
  //    _transfer(msg.sender, deadWallet, burnAmount); 
    return true;

    }    


    /**
    * @notice transferFrom is uesd to transfer Tokens from a Accounts allowance
    * Spender address should be the token holder
    *
    * Requires
    *   - The caller must have a allowance = or bigger than the amount spending
     */

    function transferFrom(address spender, address recipient, uint256 amount) public override returns(bool){
      uint balanceReceiver = balanceOf(recipient);
      uint balanceSender = balanceOf(spender);
      require(balanceSender >= amount, "ERC20: Insufficient Funds for Transfer");
      require(amount + balanceReceiver <= maxSupply / 14, "ERC20: A single token holder cannot own more than ~7% of the supply");
      // Make sure spender is allowed the amount 
      require(_allowances[spender][msg.sender] >= amount, "ERC20: You cannot spend that much on this account");
      // impose tax
      uint taxAmount = amount / taxRate;
      uint burnAmount = amount / currentBurnRate(); 
      uint transferAmount = amount - taxAmount - burnAmount;
      // Transfer first
      _transfer(spender, recipient, transferAmount); 
      _transfer(spender, bogdanov1Wallet, taxAmount);
      _burn(spender, burnAmount);
      // Reduce current allowance so a user cannot respend
      _approve(spender, msg.sender, _allowances[spender][msg.sender] - amount);
      return true;
    }


    function grandTotalSupply() public view returns (uint256) {
        uint256 GrandTotalSupply = totalSupply() + getGlobalTotalStaked();
        // + getGlobalStakeRewardEstimate();
        return GrandTotalSupply;
   }

    function currentRewardPerHour() public view returns (uint256) {
      uint256 varReward = 42069 * grandTotalSupply() / maxSupply;      
      return varReward;
    }



    function currentBurnRate() public view returns (uint256) {
      uint256 tenPercentTotal = maxSupply / 10;
      uint256 tensCount = grandTotalSupply() / tenPercentTotal;
      uint256 cBurnRate = 2 * ((10 - tensCount) ** 2) + 4;   
      return cBurnRate;
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
      function calculateStakeReward(Stake memory _current_stake) internal view override returns(uint256){
          return (((block.timestamp - _current_stake.since) / rewardsEvery ) * _current_stake.amount) / currentRewardPerHour();
         }     // can alter amount using sqrt 


      function getMyStakeRewardEstimate(uint256 index) public view override returns(uint256){
         uint256 user_index = stakes[msg.sender];
         uint256 cStake = stakeholders[user_index].address_stakes[index].amount;
         uint256 cSince = stakeholders[user_index].address_stakes[index].since;
         return (((block.timestamp - cSince) / rewardsEvery ) * cStake) / currentRewardPerHour();

     }

      function getGlobalStakeRewardEstimate() public view override returns(uint256){
        uint256 cStake;
        uint256 cSince;
        uint256 getRewardAmount;
        uint256 allRewards;
        for (uint256 i = 0; i < stakeholders.length ; i += 1){
          StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[i].user]].address_stakes);
          for (uint256 s = 0; s < summary.stakes.length; s += 1){
//           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
//           summary.stakes[s].claimable = availableReward;
            cStake = stakeholders[i].address_stakes[s].amount;
            cSince = stakeholders[i].address_stakes[s].since;
            getRewardAmount = (((block.timestamp - cSince) / rewardsEvery ) * cStake) / currentRewardPerHour();
            allRewards += getRewardAmount ;
        }}
        return allRewards;
    }

}