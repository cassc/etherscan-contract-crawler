// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Round is Ownable {
  uint256 public immutable LOCK_PERIOD;
  uint256 public immutable TGE;                            
  uint256 public immutable CLIFF;                       
  uint256 public immutable CLAIM_PERCENT;              
  uint256 public immutable NUM_CLAIMS;                      

  /// @notice token interfaces
  address public immutable TokenAddress;
  IERC20 public immutable TOKEN;

  /// @notice round state
  uint256 public availableTreasury;

  /// @notice user state structure
  struct User {
    uint256 totalTokenBalance;  // total num of tokens user have bought through the contract
    uint256 tokensToIssue;      // num of tokens user have bought in current vesting period (non complete unlock cycle)
    uint256 liquidBalance;      // amount of tokens the contract already sent to user
    uint256 pendingForClaim;    // amount of user's tokens that are still locked
    uint256 nextUnlockDate;     // unix timestamp of next claim unlock (defined by LOCK_PERIOD)
    uint256 numUnlocks;          // months total
    uint256 initialPayout;      // takes into account TGE % for multiple purchases
    bool hasBought;             // used in token purchase mechanics
  }

  /// @notice keeps track of users
  mapping(address => User) public users;

  address[] public icoTokenHolders;
  mapping(address => uint256) public holderIndex;

  event TokenPurchased(address indexed user, uint256 amount);
  event TokenRemoved(address indexed user, uint256 amount);
  event TokenClaimed(
    address indexed user,
    uint256 amount,
    uint256 claimsLeft,
    uint256 nextUnlockDate
  );

  /// @param token => token address
  constructor(
    address token,
    uint256 lock_period,
    uint256 tge,
    uint256 cliff,
    uint256 claim_percent,
    uint256 num_claims
  ) {
    TokenAddress = token;
    TOKEN = IERC20(token);
    LOCK_PERIOD = lock_period;
    TGE = tge;
    CLIFF = cliff;
    CLAIM_PERCENT = claim_percent;
    NUM_CLAIMS = num_claims;
  }

  function replenishTreasury(uint256 amount) external onlyOwner {
    TOKEN.transferFrom(msg.sender, address(this), amount);
    availableTreasury += amount;
  }

  /// @notice checks whether user's tokens are locked
  modifier checkLock() {
    require(
      users[msg.sender].pendingForClaim > 0,
      "Nothing to claim!"
    );
    require(
      block.timestamp >= users[msg.sender].nextUnlockDate,
      "Tokens are still locked!"
    );
    _;
  }

  function getUnclaimed(address user) public view returns (
    uint256 amountToClaim, 
    uint256 unclaimedPeriods
  ) {
      User storage userStruct = users[user];

      if (users[user].nextUnlockDate > block.timestamp) return (0, 0);

      unclaimedPeriods = 1 + (block.timestamp - users[user].nextUnlockDate) / LOCK_PERIOD;

      if (userStruct.numUnlocks + unclaimedPeriods <= NUM_CLAIMS) {
        amountToClaim = (userStruct.tokensToIssue * CLAIM_PERCENT * unclaimedPeriods) / 10_000;
      } else amountToClaim = userStruct.pendingForClaim;
  }

  /// @notice checks if tokens are unlocked and transfers set % from pendingForClaim
  /// user will recieve all remaining tokens with the last claim
  function claimTokens() public checkLock() {
    address user = msg.sender;
    User storage userStruct = users[user];

    (uint256 amountToClaim, uint256 unclaimedPeriods) = getUnclaimed(user);

    userStruct.liquidBalance += amountToClaim;  
    userStruct.pendingForClaim -= amountToClaim;
    userStruct.nextUnlockDate += LOCK_PERIOD * unclaimedPeriods;
    userStruct.numUnlocks += unclaimedPeriods;
    TOKEN.transfer(user, amountToClaim);

    emit TokenClaimed(
      user,
      amountToClaim,
      NUM_CLAIMS > userStruct.numUnlocks ? NUM_CLAIMS - userStruct.numUnlocks : 0, // number of claims left to perform
      userStruct.nextUnlockDate
    );
  }

  /// @notice when user buys Token, TGE % is issued immediately
  /// @param _amount => amount of Token tokens to distribute
  /// @param _to => address to issue tokens to
  function _lockAndDistribute(uint256 _amount, address _to) private {
    require(availableTreasury >= _amount, "Treasury drained");

    User  storage userStruct = users[_to];
    uint256 timestampNow = block.timestamp;

    uint256 immediateAmount = (_amount / 100) * TGE;
    if (immediateAmount > 0) {
        TOKEN.transfer(_to, immediateAmount);  // issue TGE % immediately
        userStruct.initialPayout += immediateAmount;
        userStruct.liquidBalance += immediateAmount;  // issue TGE % immediately to struct
    }
                
    userStruct.pendingForClaim += _amount - immediateAmount;  // save the rest
    userStruct.tokensToIssue = _amount;
    userStruct.numUnlocks = 0;
    if (!userStruct.hasBought) {
      icoTokenHolders.push(_to);
      holderIndex[_to] = icoTokenHolders.length - 1;
      userStruct.hasBought = true;
    }

    userStruct.totalTokenBalance += _amount;
    availableTreasury -= _amount;
    userStruct.nextUnlockDate = timestampNow + (CLIFF > 0 ? CLIFF : LOCK_PERIOD); // lock tokens depends on cliff and lock period
  }

  /// @notice allows admin to issue tokens with vesting rules to address
  /// @param _amount => amount of Token tokens to issue
  /// @param _to => address to issue tokens to
  function issueTokens(uint256 _amount, address _to) external onlyOwner {
    _lockAndDistribute(_amount, _to);
    emit TokenPurchased(_to, _amount);
  }

  /// @notice remove data from user
  /// @param _from => user address
  /// @param _confirmation => confirmation to remove
  function removeTokens(address _from, bool _confirmation) external onlyOwner {
    require(_confirmation, "Confirmation needed");
    require(users[_from].hasBought, "Unknown user");

    uint256 residue = users[_from].pendingForClaim;

    delete users[_from];

    uint256 lastIdx = icoTokenHolders.length - 1;
    uint256 idx = holderIndex[_from];

    holderIndex[icoTokenHolders[lastIdx]] = idx;
    icoTokenHolders[idx] = icoTokenHolders[lastIdx];
    icoTokenHolders.pop();

    emit TokenRemoved(_from, residue);
  }
}