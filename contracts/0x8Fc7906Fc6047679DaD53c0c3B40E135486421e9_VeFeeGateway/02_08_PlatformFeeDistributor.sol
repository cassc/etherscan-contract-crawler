// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract PlatformFeeDistributor is Ownable {
  using SafeERC20 for IERC20;

  /// @notice Emitted when the address of gauge contract is changed.
  /// @param _gauge The address of new guage contract.
  event UpdateGauge(address _gauge);

  /// @notice Emitted when the address of ve token fee distribution contract is changed.
  /// @param _veDistributor The address of new ve token fee distribution contract.
  event UpdateDistributor(address _veDistributor);

  /// @notice Emitted when the address of treasury contract is changed.
  /// @param _treasury The address of new treasury contract.
  event UpdateTreasury(address _treasury);

  /// @notice Emitted when a reward token is removed.
  /// @param _token The address of reward token.
  event RemoveRewardToken(address _token);

  /// @notice Emitted when a new reward token is added.
  /// @param _token The address of reward token.
  /// @param _gaugePercentage The percentage of token distributed to gauge contract, multipled by 1e9.
  /// @param _treasuryPercentage The percentage of token distributed to treasury contract, multipled by 1e9.
  event AddRewardToken(address _token, uint256 _gaugePercentage, uint256 _treasuryPercentage);

  /// @notice Emitted when the percentage is updated for existing reward token.
  /// @param _token The address of reward token.
  /// @param _gaugePercentage The percentage of token distributed to gauge contract, multipled by 1e9.
  /// @param _treasuryPercentage The percentage of token distributed to treasury contract, multipled by 1e9.
  event UpdateRewardPercentage(address _token, uint256 _gaugePercentage, uint256 _treasuryPercentage);

  /// @dev The fee denominator used for percentage calculation.
  uint256 private constant FEE_DENOMINATOR = 1e9;

  struct RewardInfo {
    // The address of reward token.
    address token;
    // The percentage of token distributed to gauge contract.
    uint32 gaugePercentage;
    // The percentage of token distributed to treasury contract.
    uint32 treasuryPercentage;
    // @note The rest token will be distributed to ve token fee distribution contract.
  }

  /// @notice The address of gauge contract, will trigger rewards distribution.
  address public gauge;

  /// @notice The address of treasury contract.
  address public treasury;

  /// @notice The address of ve token fee distribution contract.
  address public veDistributor;

  /// @notice The list of rewards token.
  RewardInfo[] public rewards;

  constructor(
    address _gauge,
    address _treasury,
    address _veDistributor,
    RewardInfo[] memory _rewards
  ) {
    require(_gauge != address(0), "zero gauge address");
    require(_treasury != address(0), "zero treasury address");
    require(_veDistributor != address(0), "zero ve distributor address");

    gauge = _gauge;
    treasury = _treasury;
    veDistributor = _veDistributor;

    for (uint256 i = 0; i < _rewards.length; i++) {
      rewards.push(_rewards[i]);
    }
  }

  /// @notice Return the number of reward tokens.
  function getRewardCount() external view returns (uint256) {
    return rewards.length;
  }

  /// @notice Claim and distribute pending rewards to gauge/treasury/distributor contract.
  /// @dev The function can only be called by gauge contract.
  function claim() external {
    address _gauge = gauge;
    require(msg.sender == _gauge, "not gauge");

    address _treasury = treasury;
    address _veDistributor = veDistributor;

    uint256 _length = rewards.length;
    for (uint256 i = 0; i < _length; i++) {
      RewardInfo memory _reward = rewards[i];
      uint256 _balance = IERC20(_reward.token).balanceOf(address(this));
      if (_balance > 0) {
        uint256 _gaugeAmount = (_reward.gaugePercentage * _balance) / FEE_DENOMINATOR;
        uint256 _treasuryAmount = (_reward.treasuryPercentage * _balance) / FEE_DENOMINATOR;
        uint256 _veAmount = _balance - _gaugeAmount - _treasuryAmount;

        if (_gaugeAmount > 0) {
          IERC20(_reward.token).safeTransfer(_gauge, _gaugeAmount);
        }
        if (_treasuryAmount > 0) {
          IERC20(_reward.token).safeTransfer(_treasury, _treasuryAmount);
        }
        if (_veAmount > 0) {
          IERC20(_reward.token).safeTransfer(_veDistributor, _veAmount);
        }
      }
    }
  }

  /// @notice Update the address of gauge contract.
  /// @param _gauge The address of new guage contract.
  function updateGauge(address _gauge) external onlyOwner {
    require(_gauge != address(0), "zero gauge address");

    gauge = _gauge;

    emit UpdateGauge(_gauge);
  }

  /// @notice Update the address of treasury contract.
  /// @param _treasury The address of new treasury contract.
  function updateTreasury(address _treasury) external onlyOwner {
    require(_treasury != address(0), "zero treasury address");

    treasury = _treasury;

    emit UpdateTreasury(_treasury);
  }

  /// @notice Update the address of distributor contract.
  /// @param _veDistributor The address of new distributor contract.
  function updateDistributor(address _veDistributor) external onlyOwner {
    require(_veDistributor != address(0), "zero distributor address");

    veDistributor = _veDistributor;

    emit UpdateDistributor(_veDistributor);
  }

  /// @notice Update reward percentage of existing reward token.
  /// @param _index The index of reward token.
  /// @param _gaugePercentage The percentage of token distributed to gauge contract, multipled by 1e9.
  /// @param _treasuryPercentage The percentage of token distributed to treasury contract, multipled by 1e9.
  function updateRewardPercentage(
    uint256 _index,
    uint32 _gaugePercentage,
    uint32 _treasuryPercentage
  ) external onlyOwner {
    require(_gaugePercentage <= FEE_DENOMINATOR, "gauge percentage too large");
    require(_treasuryPercentage <= FEE_DENOMINATOR, "treasury percentage too large");
    require(_gaugePercentage + _treasuryPercentage <= FEE_DENOMINATOR, "distributor percentage too small");
    require(_index < rewards.length, "index out of range");

    RewardInfo memory _info = rewards[_index];
    _info.gaugePercentage = _gaugePercentage;
    _info.treasuryPercentage = _treasuryPercentage;

    rewards[_index] = _info;
    emit UpdateRewardPercentage(_info.token, _gaugePercentage, _treasuryPercentage);
  }

  /// @notice Add a new reward token.
  /// @param _token The address of reward token.
  /// @param _gaugePercentage The percentage of token distributed to gauge contract, multipled by 1e9.
  /// @param _treasuryPercentage The percentage of token distributed to treasury contract, multipled by 1e9.
  function addRewardToken(
    address _token,
    uint32 _gaugePercentage,
    uint32 _treasuryPercentage
  ) external onlyOwner {
    require(_gaugePercentage <= FEE_DENOMINATOR, "gauge percentage too large");
    require(_treasuryPercentage <= FEE_DENOMINATOR, "treasury percentage too large");
    require(_gaugePercentage + _treasuryPercentage <= FEE_DENOMINATOR, "distributor percentage too small");

    for (uint256 i = 0; i < rewards.length; i++) {
      require(_token != rewards[i].token, "duplicated reward token");
    }

    rewards.push(RewardInfo(_token, _gaugePercentage, _treasuryPercentage));

    emit AddRewardToken(_token, _gaugePercentage, _treasuryPercentage);
  }

  /// @notice Remove an existing reward token.
  /// @param _index The index of reward token.
  function removeRewardToken(uint256 _index) external onlyOwner {
    uint256 _length = rewards.length;
    require(_index < _length, "index out of range");

    address _token = rewards[_index].token;
    if (_index != _length - 1) {
      rewards[_index] = rewards[_length - 1];
    }
    rewards.pop();

    emit RemoveRewardToken(_token);
  }
}