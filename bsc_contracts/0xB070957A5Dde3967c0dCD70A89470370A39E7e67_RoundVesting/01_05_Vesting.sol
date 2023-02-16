// SPDX-License-Identifier: MIT
//
//--------------------------
// 44 65 66 69 4d 6f 6f 6e
//--------------------------
//
//
// UI:
//
// - Is round active ==========================================> [bool]    isActive
// - Round end date ===========================================> [uint256] ROUND_END_DATE
// - Tokens left ==============================================> [uint256] availableTreasury
// - Return user liquid balance ===============================> [uint256] users[msg.sender].liquidBalance
// - Pending for claim for user ===============================> [uint256] users[msg.sender].pendingForClaim
// - Next unlock date for user ================================> [uint256] users[msg.sender].nextUnlockDate
// - Check allowance ==========================================> [uint256] USDT.allowance(msg.sender, address(this))
// - Buy tokens (recieve in USDT, input amount in Token) =======>           buyToken(uint256 _amount)
// - Check if user tokens unlocked and transfer them to user ==>           claimTokens()
// - Set allowance ============================================> call USDT contract from website directly
//                                                       approve amount = 200000000000000000000000000 wei
//                                                       this is WEI too much (🤡) but we'll never spend
//                                                       more than 50k, this allows us to track
//                                                       Token purchase amount limits
//
// DEPLOYMENT:
//
// - Deploy Token token
// - Deploy SeedRound, pass Token && USDT token addresses to constructor

pragma solidity ^0.8.4;

import "../libs/@openzeppelin/contracts/access/Ownable.sol";
import "../libs/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ITOKEN.sol";

contract RoundVesting is Ownable {

  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- ROUND PARAMETERS
  // -------------------------------------------------------------------------------------------------------


  // @notice                            round conditions
  uint256 constant public               ROUND_FUND = 20_000_000 ether;             
  uint256 constant public               LOCK_PERIOD = 30 days;
  uint256 constant public               TGE = 277;                              // 2.77% TGE
  uint256 constant public               CLAIM_PERCENT = 270;                  // 2.7%
  uint8 constant public                 NUM_CLAIMS = 36;                      // 36 claims to be performed in total      

  // @notice                            token interfaces
  address public                        TokenAddress;
  IToken                                TOKEN;

  // @notice                            round state
  uint256 public                        availableTreasury = ROUND_FUND;
  bool    public                        isActive;




  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- USER MANAGMENT
  // -------------------------------------------------------------------------------------------------------

  // @notice                            user state structure
  struct                                User {
    uint256                             totalTokenBalance;  // total num of tokens user have bought through the contract
    uint256                             tokensToIssue;      // num of tokens user have bought in current vesting period (non complete unlock cycle)
    uint256                             liquidBalance;      // amount of tokens the contract already sent to user
    uint256                             pendingForClaim;    // amount of user's tokens that are still locked
    uint256                             nextUnlockDate;     // unix timestamp of next claim unlock (defined by LOCK_PERIOD)
    uint16                              numUnlocks;         // months total
    bool                                isLocked;           // are tokens currently locked
    uint256                             initialPayout;      // takes into account TGE % for multiple purchases
    bool                                hasBought;          // used in token purchase mechanics
  }

  // @notice                            keeps track of users
  mapping(address => User) public       users;
  address[] public                      icoTokenHolders;


  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- EVENTS
  // -------------------------------------------------------------------------------------------------------

  event                                 TokenPurchased(address indexed user, uint256 amount);
  event                                 TokenClaimed(address indexed user,
                                                    uint256 amount,
                                                    uint256 claimsLeft,
                                                    uint256 nextUnlockDate);


  // FUNCTIONS
  //
  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- Constructor
  // -------------------------------------------------------------------------------------------------------

  // @param                             [address] token => token address
  // @param                             [address] usdt => USDT token address
  constructor(address token, address usdt) {
    TokenAddress = token;
    TOKEN = IToken(token);
    TOKEN.grantManagerToContractInit(address(this), ROUND_FUND);
    isActive = true;
  }


  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- Modifiers
  // -------------------------------------------------------------------------------------------------------

  // @notice                            checks if tokens could be sold
  // @param                             [uint256] amount => amount of tokens to sell
  modifier                              areTokensAvailable(uint256 amount) {
    require(availableTreasury - amount >= 0,
                      "Not enough tokens left!");
    _;
  }

  // @notice                            checks whether user's tokens are locked
  modifier                              checkLock() {
    require(users[msg.sender].pendingForClaim > 0,
                                      "Nothing to claim!");
    require(block.timestamp >= users[msg.sender].nextUnlockDate,
                                      "Tokens are still locked!");
    users[msg.sender].isLocked = false;
    _;
  }

  // @notice                            checks if round is active
  modifier                              ifActive() {
    if ( availableTreasury == 0) {
      isActive = false;
      revert("Round is not active!");
    }
    isActive = true;
    _;
  }

  // @notice                            checks if round is inactive
  modifier                              ifInactive() {
    if ( availableTreasury > 0) {
      isActive = true;
      revert("Round is still active!");
    }
    isActive = false;
    _;
  }




  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- ICO logic
  // -------------------------------------------------------------------------------------------------------

  // @notice                            checks if tokens are unlocked and transfers set % from pendingForClaim
  //                                    user will recieve all remaining tokens with the last claim
  function                              claimTokens() public checkLock() {
    address                             user = msg.sender;
    User  storage                       userStruct = users[user];
    uint256                             amountToClaim;

    require(userStruct.isLocked == false, "Tokens are locked!");
    if (userStruct.numUnlocks < NUM_CLAIMS - 1) {
      amountToClaim = (userStruct.tokensToIssue / 10_000) * CLAIM_PERCENT;
    }
    else if (userStruct.numUnlocks == NUM_CLAIMS - 1) {
      amountToClaim = userStruct.pendingForClaim;
    }
    else {
      revert("Everything is already claimed!");
    }
    userStruct.isLocked = true;
    TOKEN.mint(user, amountToClaim);
    userStruct.liquidBalance += amountToClaim;
    userStruct.pendingForClaim -= amountToClaim;
    userStruct.nextUnlockDate += LOCK_PERIOD;
    userStruct.numUnlocks += 1;

    emit TokenClaimed(user,
                     amountToClaim,
                     NUM_CLAIMS - userStruct.numUnlocks, // number of claims left to perform
                     userStruct.nextUnlockDate);
  }

  // @notice                            when user buys Token, TGE % is issued immediately
  //                                    remaining tokens are locked for 12 * LOCK_PERIOD = 12 months + 2 months cliff
  // @param                             [uint256] amount => amount of Token tokens to distribute
  // @param                             [address] _to => address to issue tokens to
  function                              _lockAndDistribute(uint256 _amount, address _to) private {
    User  storage                       userStruct = users[_to];
    uint256                             timestampNow = block.timestamp;

    uint256 immediateAmount = (_amount / 10_000) * TGE;
    TOKEN.mint(_to, immediateAmount);                                   // issue TGE % immediately
    userStruct.initialPayout += immediateAmount;
    userStruct.liquidBalance += immediateAmount;                        // issue TGE % immediately to struct
    userStruct.pendingForClaim += _amount - immediateAmount;            // save the rest
    userStruct.tokensToIssue = _amount;
    userStruct.numUnlocks = 0;
    if (!userStruct.hasBought) {
      icoTokenHolders.push(_to);
      userStruct.hasBought = true;
    }

    userStruct.totalTokenBalance += _amount;
    availableTreasury -= _amount;
    userStruct.nextUnlockDate = timestampNow;
    userStruct.isLocked = true;
  }

  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- Admin
  // -------------------------------------------------------------------------------------------------------

  // @notice                            allows admin to issue tokens with vesting rules to address
  // @param                             [uint256] _amount => amount of Token tokens to issue
  // @param                             [address] _to => address to issue tokens to
  function                              issueTokens(uint256 _amount, address _to) public areTokensAvailable(_amount) onlyOwner {
    _lockAndDistribute(_amount, _to);
    emit TokenPurchased(_to, _amount);
  }

  // @notice                            allows to withdraw remaining tokens after the round end
  // @param                             [address] _reciever => wallet to send tokens to
  function                              withdrawRemainingToken(address _reciever) public onlyOwner ifInactive {
    TOKEN.mint(_reciever, availableTreasury);
    availableTreasury = 0;
  }

  // @notice                            checks if round still active
  function                              checkIfActive() public returns(bool) {
    if (availableTreasury == 0) {
      isActive = false;
    }
    if (availableTreasury > 0) {
      isActive = true;
    }
    return(isActive);
  }
}