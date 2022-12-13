// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';

/// @title A rewards distributer contract
/// @author Stader Labs
/// @notice Distribute rewards on the provided Staker Contract according count of epochs and defined emission rate
contract Rewards is Ownable, Pausable, ReentrancyGuard {
  IERC20 public staderToken;
  /// @notice emission rate value for the calculation distribution rewards
  /// @dev  Unit is SD per second
  uint256 public emissionRate = 500;
  /// @notice information about start time, when the current contract instance was deployed
  uint256 public genesisTimestamp;
  /// @notice timestamp when the distribution rewards function was called in the last time
  uint256 public lastRedeemedTimestamp;
  /// @notice count of called distribution rewards function
  uint256 public epoch = 0;
  /// @notice address of staker contract
  address payable public stakingContractAddress;

  /// @notice event emitted while call function received
  event Received(address, uint256 amount);
  /// @notice event emitted while call function is triggered
  event Fallback(address, uint256 amount);
  /// @notice event emitted on successful transfer of rewards
  event DistributedRewards(address indexed stakerAddress, uint256 amount, uint256 timestamp);
  /// @notice event emitted on successful updating of emission rate
  event NewEmissionRate(uint256 amount);

  /// @notice Check for zero address before setting the address
  /// @dev Modifier
  /// @param _address the address to check
  modifier checkZeroAddress(address _address) {
    require(_address != address(0), 'Address cannot be zero');
    _;
  }

  /// @dev Constructor
  /// @param _stakingContractAddress the address of staker contract
  constructor(IERC20 _staderToken, address payable _stakingContractAddress) {
    require(_stakingContractAddress != address(0), 'Address cannot be a zero');
    staderToken = _staderToken;
    stakingContractAddress = _stakingContractAddress;
    genesisTimestamp = block.timestamp;
    lastRedeemedTimestamp = genesisTimestamp;
  }

  /**********************
   * Main functions      *
   **********************/

  /** @notice Send SD to the staking contract address based on the last redeemed timestamp.
     Example: if emissionRate is 20 SD per seconds & difference between last redeemed timestamp & current timestamp is 86400 seconds (1 Day)
     then the staker contract will receive 1,72,8000 SD (20 * 86400)
    send 10*10 SD token to the staking contract.
     */
  /// @dev currently we will distribute the rewards every 24 hours and is controlled by offchain function
  function distributeStakingRewards() external whenNotPaused nonReentrant {
    require(staderToken.balanceOf(address(this)) > 0, 'Contract balance should be greater than 0');
    uint256 currentTimestamp = block.timestamp;
    uint256 epochDelta = (currentTimestamp - lastRedeemedTimestamp);
    lastRedeemedTimestamp = currentTimestamp;
    epoch++;
    uint256 epochRewards = (epochDelta * emissionRate);

    uint256 totalRewards = staderToken.balanceOf(address(this));
    if (epochRewards > totalRewards) epochRewards = totalRewards; // this is important
    emit DistributedRewards(stakingContractAddress, epochRewards, currentTimestamp);
    require(
      staderToken.transfer(stakingContractAddress, epochRewards),
      'Failed to transfer rewards'
    );
  }

  /**********************
   * Setter functions   *
   **********************/

  /// @notice Emission rate is defined by SD per second.
  /// @param _emissionRate new value for the emission rate
  function setEmissionRate(uint256 _emissionRate) external onlyOwner {
    require(emissionRate != _emissionRate, 'Emission rate unchanged');
    require(_emissionRate > 0, 'Emission rate cannot be 0');
    emissionRate = _emissionRate;
    emit NewEmissionRate(emissionRate);
  }

  /// @notice Update staker contract address for the distribution rewards
  /// @param _stakingContractAddress new address of staker contract
  function setStakingContractAddress(address payable _stakingContractAddress)
    external
    checkZeroAddress(_stakingContractAddress)
    onlyOwner
  {
    require(stakingContractAddress != _stakingContractAddress, 'Staking address unchanged');
    stakingContractAddress = _stakingContractAddress;
  }

  /**********************
   * Getter functions   *
   **********************/

  /// @notice Get current Emission rate for calculating APY
  function getEmissionRate() external view returns (uint256) {
    return emissionRate;
  }

  /// @notice Get Last Redeemed Timestamp
  function getLastRedeemedTimestamp() external view returns (uint256) {
    return lastRedeemedTimestamp;
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

  /**********************
   * Fallback functions *
   **********************/

  /// @notice when no other function matches (not even the receive function)
  fallback() external payable {
    emit Fallback(msg.sender, msg.value);
  }

  /// @notice for empty calldata (and any value)
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}