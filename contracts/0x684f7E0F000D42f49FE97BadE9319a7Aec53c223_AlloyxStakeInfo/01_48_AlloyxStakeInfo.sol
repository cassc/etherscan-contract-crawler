// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IAlloyxStakeInfo.sol";
import "../utils/AdminUpgradeable.sol";
import "../config/AlloyxConfig.sol";
import "../config/ConfigHelper.sol";

/**
 * @title AlloyxStakeInfo
 * @notice This contract contains all the operations related to calculation of staker info, the staker reward will be proportional to the duration and amount of stakes
 * @author AlloyX
 */
contract AlloyxStakeInfo is IAlloyxStakeInfo, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct StakeInfo {
    uint256 amount;
    uint256 since;
  }

  AlloyxConfig public config;
  mapping(address => EnumerableSet.AddressSet) internal totalStakers;
  mapping(address => uint256) public totalPastTemporalStakeMap;
  mapping(address => mapping(address => uint256)) public pastTemporalStakeMap;
  mapping(address => mapping(address => StakeInfo)) public stakesMap;
  mapping(address => uint256) public totalCurrentStakeMap;
  mapping(address => StakeInfo) public totalActiveStakeMap;

  event AlloyxConfigUpdated(address indexed who, address configAddress);

  /**
   * @notice Initialize the contract
   * @param _configAddress the address of configuration contract
   */
  function initialize(address _configAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
  }

  /**
   * @notice If user operation is paused
   */
  modifier isPaused() {
    require(config.isPaused(), "all user operations should be paused");
    _;
  }

  /**
   * @notice Only stake desk can perform
   */
  modifier onlyStakeDesk() {
    require(msg.sender == config.stakeDeskAddress(), "restricted to stake desk");
    _;
  }

  /**
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Retrieve the stake for a stakeholder.
   * @param _vaultAddress The vault address
   * @param _stakeholder The stakeholder to retrieve the stake for.
   * @return Stake The amount staked and the time since when it's staked.
   */
  function stakeOf(address _vaultAddress, address _stakeholder) public view returns (StakeInfo memory) {
    return stakesMap[_vaultAddress][_stakeholder];
  }

  /**
   * @notice Retrieve the stake for a vault.
   * @param _vaultAddress The vault address
   * @return stakes The amount staked and the time since when it's staked.
   */
  function totalStake(address _vaultAddress) public view returns (uint256) {
    return totalActiveStakeMap[_vaultAddress].amount;
  }

  /**
   * @notice Retrieve the stake for a stakeholder.
   * @param _staker The staker
   * @return stakes The amount staked and the time since when it's staked.
   */
  function totalStakeForUser(address _staker) external view override returns (uint256) {
    return totalCurrentStakeMap[_staker];
  }

  /**
   * @notice A method for a stakeholder to reset the timestamp of the stake.
   * @param _vaultAddress The vault address
   * @param _stakeholder The stakeholder to retrieve the stake for.
   */
  function resetStakeTimestamp(address _vaultAddress, address _stakeholder) internal {
    addPastTemporalStake(_vaultAddress, _stakeholder, stakesMap[_vaultAddress][_stakeholder]);
    stakesMap[_vaultAddress][_stakeholder] = StakeInfo(stakesMap[_vaultAddress][_stakeholder].amount, block.timestamp);
  }

  /**
   * @notice A method for a stakeholder to reset the timestamp of the stake.
   * @param _vaultAddress The vault address
   */
  function getAllStakers(address _vaultAddress) external view override returns (address[] memory) {
    address[] memory result = totalStakers[_vaultAddress].values();
    return result;
  }

  // TODO: NEED TO CHANGE THIS ONE, BECAUSE OF TRAVERSAL WILL EXHAUST GAS
  /**
   * @notice Remove all stakes with regards to one vault
   * @param _vaultAddress The vault address
   */
  function removeAllStake(address _vaultAddress) external override onlyStakeDesk {
    for (uint256 i = 0; i < totalStakers[_vaultAddress].length(); i++) {
      address staker = totalStakers[_vaultAddress].at(i);
      StakeInfo memory info = stakeOf(_vaultAddress, staker);
      totalCurrentStakeMap[staker] = totalCurrentStakeMap[staker].sub(info.amount);
      addPastTemporalStake(_vaultAddress, staker, info);
      stakesMap[_vaultAddress][staker] = StakeInfo(0, block.timestamp);
      updateTotalStakeInfoAndPastTemporalStake(_vaultAddress, 0, info.amount, 0, 0);
    }
  }

  /**
   * @notice Add stake for a staker
   * @param _vaultAddress The vault address
   * @param _staker The person intending to stake
   * @param _stake The size of the stake to be created.
   */
  function addStake(
    address _vaultAddress,
    address _staker,
    uint256 _stake
  ) external override onlyStakeDesk {
    addPastTemporalStake(_vaultAddress, _staker, stakesMap[_vaultAddress][_staker]);
    stakesMap[_vaultAddress][_staker] = StakeInfo(stakesMap[_vaultAddress][_staker].amount.add(_stake), block.timestamp);
    totalStakers[_vaultAddress].add(_staker);
    totalCurrentStakeMap[_staker] = totalCurrentStakeMap[_staker].add(_stake);
    updateTotalStakeInfoAndPastTemporalStake(_vaultAddress, _stake, 0, 0, 0);
  }

  /**
   * @notice Remove stake for a staker
   * @param _vaultAddress The vault address
   * @param _staker The person intending to remove stake
   * @param _stake The size of the stake to be removed.
   */
  function removeStake(
    address _vaultAddress,
    address _staker,
    uint256 _stake
  ) external override onlyStakeDesk {
    require(stakeOf(_vaultAddress, _staker).amount >= _stake, "User has insufficient dura coin staked");
    addPastTemporalStake(_vaultAddress, _staker, stakesMap[_vaultAddress][_staker]);
    stakesMap[_vaultAddress][_staker] = StakeInfo(stakesMap[_vaultAddress][_staker].amount.sub(_stake), block.timestamp);
    totalCurrentStakeMap[_staker] = totalCurrentStakeMap[_staker].sub(_stake);
    updateTotalStakeInfoAndPastTemporalStake(_vaultAddress, 0, _stake, 0, 0);
  }

  /**
   * @notice Add the stake to past temporal stake
   * @param _vaultAddress The vault address
   * @param _stake the stake to be added into the reward
   */
  function addPastTemporalStake(
    address _vaultAddress,
    address _staker,
    StakeInfo memory _stake
  ) internal {
    uint256 additionalPastTemporalStake = calculateTemporalStake(_vaultAddress, _stake);
    pastTemporalStakeMap[_vaultAddress][_staker] = pastTemporalStakeMap[_vaultAddress][_staker].add(additionalPastTemporalStake);
  }

  /**
   * @notice Update the stake info and past temporal stakes for a vault based on the increase or decrease of stake and past temporal stakes
   * @param _vaultAddress The vault address
   * @param _increaseInStake the stake to be added into the info
   * @param _decreaseInStake the stake to be removed from the info
   * @param _increaseInPastTemporalStakes the increase in the past temporal stakes
   * @param _decreaseInPastTemporalStakes the decrease in the past temporal stakes
   */
  function updateTotalStakeInfoAndPastTemporalStake(
    address _vaultAddress,
    uint256 _increaseInStake,
    uint256 _decreaseInStake,
    uint256 _increaseInPastTemporalStakes,
    uint256 _decreaseInPastTemporalStakes
  ) internal {
    uint256 additionalPastTemporalStake = calculateTemporalStake(_vaultAddress, totalActiveStakeMap[_vaultAddress]);
    totalPastTemporalStakeMap[_vaultAddress] = totalPastTemporalStakeMap[_vaultAddress].add(additionalPastTemporalStake);
    totalPastTemporalStakeMap[_vaultAddress] = totalPastTemporalStakeMap[_vaultAddress].add(_increaseInPastTemporalStakes).sub(_decreaseInPastTemporalStakes);
    totalActiveStakeMap[_vaultAddress] = StakeInfo(totalActiveStakeMap[_vaultAddress].amount.add(_increaseInStake).sub(_decreaseInStake), block.timestamp);
  }

  /**
   * @notice A method for a stakeholder to clear a stake with some leftover temporal stakes
   * @param _vaultAddress The vault address
   * @param _staker the address of the staker
   * @param _temporalStake the leftover temporal stake
   */
  function resetStakeTimestampWithTemporalStake(
    address _vaultAddress,
    address _staker,
    uint256 _temporalStake
  ) external override onlyStakeDesk {
    resetStakeTimestamp(_vaultAddress, _staker);
    adjustTotalStakeWithTemporalStake(_vaultAddress, _staker, _temporalStake);
    pastTemporalStakeMap[_vaultAddress][_staker] = _temporalStake;
  }

  /**
   * @notice Adjust total stakes with leftover temporal stakes
   * @param _vaultAddress The vault address
   * @param _temporalStakes the leftover temporal stakes
   */
  function adjustTotalStakeWithTemporalStake(
    address _vaultAddress,
    address _staker,
    uint256 _temporalStakes
  ) internal {
    uint256 increaseInPastTemporalStake = 0;
    uint256 decreaseInPastTemporalStake = 0;
    if (pastTemporalStakeMap[_vaultAddress][_staker] >= _temporalStakes) {
      decreaseInPastTemporalStake = pastTemporalStakeMap[_vaultAddress][_staker].sub(_temporalStakes);
    } else {
      increaseInPastTemporalStake = _temporalStakes.sub(pastTemporalStakeMap[_vaultAddress][_staker]);
    }
    updateTotalStakeInfoAndPastTemporalStake(_vaultAddress, 0, 0, increaseInPastTemporalStake, decreaseInPastTemporalStake);
  }

  /**
   * @notice Calculate temporal stakes from the stake info
   * @param _vaultAddress The vault address
   * @param _stake the stake info to calculate reward based on
   */
  function calculateTemporalStake(address _vaultAddress, StakeInfo memory _stake) internal view returns (uint256) {
    return _stake.amount.mul(block.timestamp.sub(_stake.since));
  }

  /**
   * @notice Total receiver temporal stakes
   * @param _vaultAddress The vault address
   * @param _receiver the address of receiver
   */
  function receiverTemporalStake(address _vaultAddress, address _receiver) external view override returns (uint256) {
    StakeInfo memory stakeValue = stakeOf(_vaultAddress, _receiver);
    return pastTemporalStakeMap[_vaultAddress][_receiver].add(calculateTemporalStake(_vaultAddress, stakeValue));
  }

  /**
   * @notice Total vault temporal stakes
   * @param _vaultAddress The vault address
   */
  function vaultTemporalStake(address _vaultAddress) external view override returns (uint256) {
    return calculateTemporalStake(_vaultAddress, totalActiveStakeMap[_vaultAddress]).add(totalPastTemporalStakeMap[_vaultAddress]);
  }
}