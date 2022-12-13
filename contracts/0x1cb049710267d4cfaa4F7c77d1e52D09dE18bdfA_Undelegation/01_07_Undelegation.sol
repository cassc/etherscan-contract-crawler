// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Undelegation is Ownable, Pausable, ReentrancyGuard {
  IERC20 public staderToken;
  ///@notice when user unstakes, the corresponding staked amount can be withdrawn after the unbonding time
  ///@dev current undelegation time is 7 days
  uint256 public unbondingTime = 604800; //

  ///@notice address of staking contract
  address public stakingContractAddress;

  /// @notice information about amount unstaked along with the timestamp when the unstake was initiated
  struct Undelegate {
    uint256 timestamp;
    uint256 amount;
  }
  ///@notice mapping of user address to the array of Undelegate Object
  mapping(address => Undelegate[]) public undelegationsMap;

  /// @notice event emitted after call function receive
  event Received(address from, uint256 amount);
  /// @notice event emitted after call function fallback
  event Fallback(address from, uint256 amount);
  /// @notice event emitted after call function undelegate
  event Undelegated(address indexed to, uint256 amount,uint256 index);
  /// @notice event emitted after call function withdraw
  event Withdrawn(address indexed from, uint256 amount,uint256 index);
  /// @notice event emitted on successful updating of unbonding time
  event NewUnbondingTime(uint256 to, uint256 from);
  ///@notice event emitted on successful updating the staking contract address
  event StakingAddressChanged(address indexed newAddress, address oldAddress);

  /// @notice constructor of undelegation contract
  constructor(IERC20 _staderToken) {
    staderToken = _staderToken; 
  }

  /************************************
   * Staking contract call functions *
   ************************************/

  /// @notice sets an entry in the user undelegations map
  function undelegate(address to, uint256 amount) external returns (uint256) {
    require(amount > 0, 'Undelegate amount must be greater than 0');
    require(msg.sender == stakingContractAddress, 'Only staking contract can undelegate');
    uint256 index = undelegationsMap[to].length;
    undelegationsMap[to].push(Undelegate(block.timestamp, amount));
    emit Undelegated(to, amount,index);
    return amount;
  }

  /**********************
   * User functions      *
   **********************/

  /// @notice transfers the SD tokens from the contract balance to the user account
  /// @param index the index of the user's undelegation data
  function withdraw(uint256 index) external whenNotPaused nonReentrant {
    Undelegate storage undelegateData = undelegationsMap[msg.sender][index];
    require(undelegateData.amount != 0 && undelegateData.timestamp != 0, 'Undelegation not found');
    require(
      undelegateData.timestamp + unbondingTime <= block.timestamp,
      'Release time not reached'
    );

    uint256 amount = undelegateData.amount;
    delete undelegationsMap[msg.sender][index];
    emit Withdrawn(msg.sender, amount,index);
    require(staderToken.transfer(msg.sender, amount), 'Transfer failed');
  }

  /**********************
   * Setter functions   *
   **********************/

  /// @notice Update Staking contract address for checking call sender for the undelegate function
  /// @param _stakingContractAddress new address of staking contract
  function setStakingContractAddress(address _stakingContractAddress) external onlyOwner {
    require(_stakingContractAddress != address(0), 'Staking contract address cannot be 0');
    emit StakingAddressChanged(_stakingContractAddress, stakingContractAddress);
    stakingContractAddress = _stakingContractAddress;
  }

  /// @notice Update unbondingTime value
  /// @param _unbondingTime time in seconds
  function setUnbondingTime(uint256 _unbondingTime) external onlyOwner {
    require(unbondingTime != _unbondingTime, 'Unbonding time unchanged');
    emit NewUnbondingTime(unbondingTime, _unbondingTime);
    unbondingTime = _unbondingTime;
  }

  /// @notice Pauses the contract
  /// @dev The contract must be in the unpaused ot normal state
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpauses the contract and returns it to the normal state
  /// @dev The contract must be in the paused state
  function unpause() external onlyOwner {
    _unpause();
  }
}