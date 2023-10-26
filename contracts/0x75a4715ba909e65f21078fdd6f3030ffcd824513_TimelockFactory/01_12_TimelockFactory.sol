// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CREATE3} from "lib/solmate/src/utils/CREATE3.sol";

import {TimelockedDelegator} from "./TimelockedDelegator.sol";

contract TimelockFactory {
  // ============ events ============
  event TimelockDeployed(
    address indexed timelock,
    address indexed token,
    address indexed beneficiary,
    address admin,
    uint256 cliffDuration,
    uint256 startTime,
    uint256 duration
  );

  // ============ public functions ============

  /**
   * @notice Deploys a LineatTokenTimelock with create3.
   * 
   * @dev Salt generated from token, beneficiary, amount, and deployer.
   * @dev Funding is optional. If funding is provided, the timelock will be funded with the funding amount.
   * 
   * @param _token Token to unlock
   * @param _beneficiary Unlocking address
   * @param _admin Clawback admin
   * @param _cliffDuration Duration of cliff in seconds
   * @param _startTime Unlock start time in seconds
   * @param _duration Duration of the unlock schedule in seconds
   * @param _amount The amount to unlock
   * @param _funding The initial funding amount
   */
  function deployTimelock(
    address _token,
    address _beneficiary,
    address _admin,
    uint256 _cliffDuration,
    uint256 _startTime,
    uint256 _duration,
    uint256 _amount,
    uint256 _funding
  ) public returns (address _deployed) {
    _deployed = _deployTimelock(_token, _beneficiary, _admin, _cliffDuration, _startTime, _duration, _amount);

    if (_funding > 0) {
      // fund timelock
      IERC20(_token).transferFrom(msg.sender, _deployed, _funding);
    }
  }

  /**
   * @notice Computes the address of a timelock contract.
   * 
   * @param _deployer The address that will deploy the contract
   * @param _token The token to unlock
   * @param _beneficiary The address that will claim unlocks
   * @param _startTime The start time
   * @param _amount The amount to unlock
   */
  function computeTimelockAddress(
    address _deployer,
    address _token,
    address _beneficiary,
    uint256 _startTime,
    uint256 _amount
  ) public view returns (address _computed) {
    // Get salt
    bytes32 salt = _getSalt(_token, _beneficiary, _deployer, _startTime, _amount);

    // Deploy timelock
    _computed = CREATE3.getDeployed(salt);
  }

  // ============ internal functions ============
  function _deployTimelock(
    address _token,
    address _beneficiary,
    address _admin,
    uint256 _cliffDuration,
    uint256 _startTime,
    uint256 _duration,
    uint256 _amount
  ) internal returns (address _deployed) {
    // Get salt
    bytes32 salt = _getSalt(_token, _beneficiary, msg.sender, _startTime, _amount);

    // Get bytecode
    bytes memory creation = type(TimelockedDelegator).creationCode;
    bytes memory bytecode = abi.encodePacked(
      creation,
      abi.encode(_token, _beneficiary, _admin, _cliffDuration, _startTime, _duration)
    );

    // Deploy timelock
    _deployed = CREATE3.deploy(salt, bytecode, 0);
    emit TimelockDeployed(_deployed, _token, _beneficiary, _admin, _cliffDuration, _startTime, _duration);
  }

  function _getSalt(
    address _token,
    address _beneficiary,
    address _deployer,
    uint256 _startTime,
    uint256 _amount
  ) internal pure returns (bytes32 _salt) {
    _salt = keccak256(abi.encodePacked(_token, _beneficiary, _deployer, _startTime, _amount));
  }

}