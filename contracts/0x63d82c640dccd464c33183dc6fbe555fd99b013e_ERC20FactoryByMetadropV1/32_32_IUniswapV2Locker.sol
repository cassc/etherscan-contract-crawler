// Interface definition for UniswapV2Locker.sol

pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IERCBurn {
  function burn(uint256 _amount) external;

  function approve(address spender, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external returns (uint256);

  function balanceOf(address account) external view returns (uint256);
}

interface IMigrator {
  function migrate(
    address lpToken,
    uint256 amount,
    uint256 unlockDate,
    address owner
  ) external returns (bool);
}

interface IUniswapV2Locker {
  struct UserInfo {
    EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked
    mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
  }

  struct TokenLock {
    uint256 lockDate; // the date the token was locked
    uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
    uint256 initialAmount; // the initial lock amount
    uint256 unlockDate; // the date the token can be withdrawn
    uint256 lockID; // lockID nonce per uni pair
    address owner;
  }

  struct FeeStruct {
    uint256 ethFee; // Small eth fee to prevent spam on the platform
    IERCBurn secondaryFeeToken; // UNCX or UNCL
    uint256 secondaryTokenFee; // optional, UNCX or UNCL
    uint256 secondaryTokenDiscount; // discount on liquidity fee for burning secondaryToken
    uint256 liquidityFee; // fee on univ2 liquidity tokens
    uint256 referralPercent; // fee for referrals
    IERCBurn referralToken; // token the refferer must hold to qualify as a referrer
    uint256 referralHold; // balance the referrer must hold to qualify as a referrer
    uint256 referralDiscount; // discount on flatrate fees for using a valid referral address
  }

  function setDev(address payable _devaddr) external;

  /**
   * @notice set the migrator contract which allows locked lp tokens to be migrated to uniswap v3
   */
  function setMigrator(IMigrator _migrator) external;

  function setSecondaryFeeToken(address _secondaryFeeToken) external;

  /**
   * @notice referrers need to hold the specified token and hold amount to be elegible for referral fees
   */
  function setReferralTokenAndHold(
    IERCBurn _referralToken,
    uint256 _hold
  ) external;

  function setFees(
    uint256 _referralPercent,
    uint256 _referralDiscount,
    uint256 _ethFee,
    uint256 _secondaryTokenFee,
    uint256 _secondaryTokenDiscount,
    uint256 _liquidityFee
  ) external;

  /**
   * @notice whitelisted accounts dont pay flatrate fees on locking
   */
  function whitelistFeeAccount(address _user, bool _add) external;

  /**
   * @notice Creates a new lock
   * @param _lpToken the univ2 token address
   * @param _amount amount of LP tokens to lock
   * @param _unlock_date the unix timestamp (in seconds) until unlock
   * @param _referral the referrer address if any or address(0) for none
   * @param _fee_in_eth fees can be paid in eth or in a secondary token such as UNCX with a discount on univ2 tokens
   * @param _withdrawer the user who can withdraw liquidity once the lock expires.
   */
  function lockLPToken(
    address _lpToken,
    uint256 _amount,
    uint256 _unlock_date,
    address payable _referral,
    bool _fee_in_eth,
    address payable _withdrawer
  ) external payable;

  /**
   * @notice extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
   * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
   */
  function relock(
    address _lpToken,
    uint256 _index,
    uint256 _lockID,
    uint256 _unlock_date
  ) external;

  /**
   * @notice withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
   * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
   */
  function withdraw(
    address _lpToken,
    uint256 _index,
    uint256 _lockID,
    uint256 _amount
  ) external;

  /**
   * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees, and faster loading on our live block explorer
   */
  function incrementLock(
    address _lpToken,
    uint256 _index,
    uint256 _lockID,
    uint256 _amount
  ) external;

  /**
   * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
   * and withdraw a smaller portion
   */
  function splitLock(
    address _lpToken,
    uint256 _index,
    uint256 _lockID,
    uint256 _amount
  ) external payable;

  /**
   * @notice transfer a lock to a new owner, e.g. presale project -> project owner
   */
  function transferLockOwnership(
    address _lpToken,
    uint256 _index,
    uint256 _lockID,
    address payable _newOwner
  ) external;

  /**
   * @notice migrates liquidity to uniswap v3
   */
  function migrate(
    address _lpToken,
    uint256 _index,
    uint256 _lockID,
    uint256 _amount
  ) external;

  function getNumLocksForToken(
    address _lpToken
  ) external view returns (uint256);

  function getNumLockedTokens() external view returns (uint256);

  function getLockedTokenAtIndex(
    uint256 _index
  ) external view returns (address);

  // user functions
  function getUserNumLockedTokens(
    address _user
  ) external view returns (uint256);

  function getUserLockedTokenAtIndex(
    address _user,
    uint256 _index
  ) external view returns (address);

  function getUserNumLocksForToken(
    address _user,
    address _lpToken
  ) external view returns (uint256);

  function getUserLockForTokenAtIndex(
    address _user,
    address _lpToken,
    uint256 _index
  )
    external
    view
    returns (uint256, uint256, uint256, uint256, uint256, address);

  // whitelist
  function getWhitelistedUsersLength() external view returns (uint256);

  function getWhitelistedUserAtIndex(
    uint256 _index
  ) external view returns (address);

  function getUserWhitelistStatus(address _user) external view returns (bool);
}