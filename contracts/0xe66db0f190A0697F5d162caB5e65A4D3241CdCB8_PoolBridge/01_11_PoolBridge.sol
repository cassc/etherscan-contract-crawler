// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";
import {IStakingPools} from "./interfaces/IStakingPools.sol";

/// @title Pool Bridge
///
/// @dev This is the contract for the bridging of pool rewards to the  multisig.
///
/// Initially, the contract deployer is given both the admin and minter role. This allows them to pre-mine tokens,
/// transfer admin to a timelock contract, and lastly,
/// the deployer must revoke their admin role and minter role.
contract PoolBridge is AccessControl {

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev the poolToken address
  IDetailedERC20 public poolToken;
  /// @dev the ALCX address
  IDetailedERC20 public alchemixToken;
  /// @dev the multisig address
  address public multisig;
  /// @dev the stakingPools address
  IStakingPools public stakingPools;

  constructor(IDetailedERC20 _poolToken, IDetailedERC20 _token, IStakingPools _stakingPools, address _multisig) public {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    poolToken = _poolToken;
    alchemixToken = _token;
    stakingPools = _stakingPools;
    multisig = _multisig;
  }

  /// @dev A modifier which checks that the caller has the minter role.
  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "AlchemixToken: only admin");
    _;
  }

  /// This function provides.
  function flushToMultisig() external  {
    uint256 _balance = alchemixToken.balanceOf(address(this));
    alchemixToken.transfer(multisig, _balance);
  }

  /// @dev fetches tokens from stakingPools.
  ///
  /// This function fetches tokens when available.
  function claimFromStakingPools(uint256 _poolId) external  {
    stakingPools.claim(_poolId);
  }

  /// @dev claims tokens from stakingPools and sends them to the treasury.
  ///
  /// This function fetches tokens when available, and sends them to the treasury.
  function claimAndFlush(uint256 _poolId) external  {
    stakingPools.claim(_poolId);
    uint256 _balance = alchemixToken.balanceOf(address(this));
    alchemixToken.transfer(multisig, _balance);
  }

  /// @dev approves poolToken for deposit.
  ///
  /// This function approves.
  function approvePoolToken(uint256 _amount) external onlyAdmin {
    poolToken.approve(address(stakingPools), _amount);
  }

  /// @dev exits poolTokens from stakingPools.
  ///
  /// This function exits tokens when available.
  function exitFromStakingPools(uint256 _poolId, uint256 _withdrawAmount) external onlyAdmin {
    stakingPools.withdraw(_poolId, _withdrawAmount);
  }

  /// @dev deposits poolToken in stakingPools.
  ///
  /// This function stakes the token.
  function stakePoolToken(uint256 _poolId, uint256 _depositAmount) external onlyAdmin {
    stakingPools.deposit(_poolId, _depositAmount);
  }

  /// @dev transfers out ERC20s.
  ///
  /// This function stakes the token.
  function transferOut(IDetailedERC20 _token, uint256 _amount) external onlyAdmin {
    _token.transfer(multisig, _amount);
  }

}