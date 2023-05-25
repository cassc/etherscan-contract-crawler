// SPDX-License-Identifier: MIT

//** Decubate Vesting Factory Contract */
//** Author Vipin : Decubate Crowfunding 2021.5 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDecubateVesting {
  /**
   *
   * @dev this event will call when new token added to the contract
   * currently, we are supporting DCB token and this will be used for future implementation
   *
   */
  event AddToken(address indexed token);

  /**
   *
   * @dev this event will be called each time a user claims some tokens
   *
   */
  event Claim(
    address indexed token,
    uint256 amount,
    uint256 indexed option,
    uint256 time
  );

  /**
   *
   * @dev this event calls when new whitelist member joined to the pool
   *
   */
  event AddWhitelist(address indexed wallet);

  /**
   *
   * @dev this event call when distirbuted token revoked
   *
   */
  event Revoked(address indexed wallet);

  /**
   *
   * @dev this event call when token claim status is changed for a user
   *
   */
  event StatusChanged(address indexed wallet, bool status);

  /**
   *
   * @dev define vesting informations like x%, x months
   *
   */
  struct VestingInfo {
    string name;
    uint256 cliff;
    uint256 start;
    uint256 duration;
    uint256 initialUnlockPercent;
    bool revocable;
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
  }

  struct MaxTokenTransferValue {
    uint256 amount;
    bool active;
  }

  /**
   *
   * @dev WhiteInfo is the struct type which store whitelist information
   *
   */
  struct WhitelistInfo {
    address wallet;
    uint256 dcbAmount;
    uint256 distributedAmount;
    uint256 joinDate;
    bool revoke;
    bool disabled;
  }

  struct HasWhitelist {
    uint256 arrIdx;
    bool active;
  }

  /**
   *
   * inherit functions will be used in contract
   *
   */

  function getVestAmount(uint256 _option, address _wallet)
    external
    view
    returns (uint256);

  function getReleasableAmount(uint256 _option, address _wallet)
    external
    view
    returns (uint256);

  function getVestingInfo(uint256 _strategy)
    external
    view
    returns (VestingInfo memory);

  function addVestingStrategy(
    string memory _name,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    uint256 _initialUnlockPercent,
    bool _revocable
  ) external returns (bool);

  function setVestingStrategy(
    uint256 _strategy,
    string memory _name,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    uint256 _initialUnlockPercent,
    bool _revocable
  ) external returns (bool);

  function addWhitelist(
    address _wallet,
    uint256 _dcbAmount,
    uint256 _option
  ) external returns (bool);

  function getWhitelist(uint256 _option, address _wallet)
    external
    view
    returns (WhitelistInfo memory);

  function setWhitelist(
    address _wallet,
    uint256 _dcbAmount,
    uint256 _option
  ) external returns (bool);

  function setToken(address _addr) external returns (bool);

  function getToken() external view returns (address);

  function claimDistribution(uint256 _option, address _wallet)
    external
    returns (bool);

  function getWhitelistPool(uint256 _option)
    external
    view
    returns (WhitelistInfo[] memory);
}