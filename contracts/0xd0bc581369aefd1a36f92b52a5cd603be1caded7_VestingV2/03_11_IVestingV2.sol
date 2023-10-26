// SPDX-License-Identifier: MIT

//**  vesting Contract interface */

pragma solidity ^0.8.10;

interface IVestingV2 {
  enum Type {
    Linear,
    Monthly,
    Interval
  }

  struct VestingInfo {
    string name;
    uint256 cliff;
    uint256 start;
    uint256 duration;
    uint256 initialUnlockPercent;
    bool revocable;
    Type vestType;
    uint256 interval;
    uint256 unlockPerInterval;
    uint256[] timestamps;
  }

  struct VestingPool {
    string name;
    uint256 cliff;
    uint256 start;
    uint256 duration;
    uint256 initialUnlockPercent;
    WhitelistInfo[] whitelistPool;
    mapping(address => HasWhitelist) hasWhitelist;
    bool revocable;
    Type vestType;
    uint256 interval;
    uint256 unlockPerInterval;
    uint256[] timestamps;
  }

  /**
   *
   * @dev WhiteInfo is the struct type which store whitelist information
   *
   */
  struct WhitelistInfo {
    address wallet;
    uint256 amount;
    uint256 distributedAmount;
    uint256 joinDate;
    uint256 revokeDate;
    bool revoke;
    bool disabled;
  }

  struct HasWhitelist {
    uint256 arrIdx;
    bool active;
  }

  event AddToken(address indexed token);
  event Claim(address indexed token, uint256 amount, uint256 indexed option, uint256 time);
  event AddWhitelist(address indexed wallet);
  event Revoked(address indexed wallet);
  event StatusChanged(address indexed wallet, bool status);

  function initialize(address _token, address _ico) external;

  function addVestingStrategy(
    string memory _name,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    uint256 _initialUnlockPercent,
    bool _revocable,
    uint256 _interval,
    uint16 _unlockPerInterval,
    uint8 _monthGap,
    Type _type
  ) external returns (bool);

  function setVestingStrategy(
    uint256 _strategy,
    string memory _name,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    uint256 _initialUnlockPercent,
    bool _revocable,
    uint256 _interval,
    uint16 _unlockPerInterval
  ) external returns (bool);

  function addWhitelist(
    address _wallet,
    uint256 _amount,
    uint256 _option
  ) external returns (bool);

  function setToken(address _addr) external returns (bool);

  function setIcoContract(address _ico) external returns (bool);

  function batchAddWhitelist(
    address[] memory wallets,
    uint256[] memory amounts,
    uint256 option
  ) external returns (bool);

  /**
   *
   * @dev set the address as whitelist user address
   *
   * @param {address} address of the user
   *
   * @return {bool} return status of the whitelist
   *
   */
  function setWhitelist(
    address _wallet,
    uint256 _amount,
    uint256 _option
  ) external returns (bool);

  function revoke(uint256 _option, address _wallet) external;

  function setVesting(
    uint256 _option,
    address _wallet,
    bool _status
  ) external;

  function transferToken(address _addr, uint256 _amount) external returns (bool);

  function claimDistribution(uint256 _option, address _wallet) external returns (bool);

  function getWhitelist(uint256 _option, address _wallet)
    external
    view
    returns (WhitelistInfo memory);

  function getAllVestingPools() external view returns (VestingInfo[] memory);

  function getTotalToken(address _addr) external view returns (uint256);

  function hasWhitelist(uint256 _option, address _wallet) external view returns (bool);

  function getVestAmount(uint256 _option, address _wallet) external view returns (uint256);

  function getReleasableAmount(uint256 _option, address _wallet) external view returns (uint256);

  function getWhitelistPool(uint256 _option) external view returns (WhitelistInfo[] memory);

  function getVestingInfo(uint256 _strategy) external view returns (VestingInfo memory);
}