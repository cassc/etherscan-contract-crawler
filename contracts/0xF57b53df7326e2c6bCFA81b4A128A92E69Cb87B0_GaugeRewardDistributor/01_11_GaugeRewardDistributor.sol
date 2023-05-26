// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./PlatformFeeDistributor.sol";
import "./ICurveGaugeV4V5.sol";

contract GaugeRewardDistributor is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  enum GaugeType {
    // used for empty gauge
    None,
    // claim from reward contract
    CurveGaugeV1V2V3,
    // explicitly call deposit_reward_token
    CurveGaugeV4V5
  }

  event UpdateDistributor(address _oldDistributor, address _newDistributor);
  event UpdateGaugeType(address _gauge, GaugeType _type);
  event AddRewardToken(uint256 _index, address _token, address[] _gauges, uint32[] _percentages);
  event RemoveRewardToken(uint256 _index, address _token);
  event UpdateRewardToken(address _token, address[] _gauges, uint32[] _percentages);

  struct RewardDistribution {
    address gauge;
    uint32 percentage;
  }

  struct GaugeRewards {
    GaugeType gaugeType;
    EnumerableSet.AddressSet tokens;
    mapping(address => uint256) pendings;
  }

  struct GaugeInfo {
    GaugeType gaugeType;
    address[] tokens;
    uint256[] pendings;
  }

  /// @dev The fee denominator used for percentage calculation.
  uint256 private constant FEE_DENOMINATOR = 1e9;

  /// @notice The address of PlatformFeeDistributor contract.
  address public distributor;

  /// @notice Mapping from reward token address to distribution information.
  mapping(address => RewardDistribution[]) public distributions;

  /// @notice The list of reward tokens.
  address[] public rewardTokens;

  /// @dev Mapping from gauge address to gauge type and rewards.
  mapping(address => GaugeRewards) private gauges;

  /// @notice Return the gauge information given the gauge address.
  /// @param _gauge The address of the gauge.
  function getGaugeInfo(address _gauge) external view returns (GaugeInfo memory) {
    GaugeInfo memory _info;
    uint256 _length = gauges[_gauge].tokens.length();

    _info.gaugeType = gauges[_gauge].gaugeType;
    _info.tokens = new address[](_length);
    _info.pendings = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      _info.tokens[i] = gauges[_gauge].tokens.at(i);
      _info.pendings[i] = gauges[_gauge].pendings[_info.tokens[i]];
    }

    return _info;
  }

  /// @notice Return the reward distribution given the token address.
  /// @param _token The address of the token.
  function getDistributionInfo(address _token) external view returns (RewardDistribution[] memory) {
    return distributions[_token];
  }

  /// @notice Claim function called by Curve Gauge V1, V2 or V3.
  function claim() external {
    require(gauges[msg.sender].gaugeType == GaugeType.CurveGaugeV1V2V3, "sender not allowed");
    _claimFromDistributor(new address[](0), new uint256[](0));
    _transferToGauge(msg.sender);
  }

  /// @notice Donate rewards to this contract
  /// @dev You can call this function to force distribute rewards to gauges.
  /// @param _tokens The list of address of reward tokens to donate.
  /// @param _amounts The list of amount of reward tokens to donate.
  function donate(address[] memory _tokens, uint256[] memory _amounts) external nonReentrant {
    require(_tokens.length == _amounts.length, "length mismatch");
    for (uint256 i = 0; i < _tokens.length; i++) {
      require(distributions[_tokens[i]].length > 0, "not reward token");
      uint256 _before = IERC20(_tokens[i]).balanceOf(address(this));
      IERC20(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
      _amounts[i] = IERC20(_tokens[i]).balanceOf(address(this)).sub(_before);
    }

    _claimFromDistributor(_tokens, _amounts);
  }

  /// @notice Update the address of PlatformFeeDistributor.
  /// @param _newDistributor The new address of PlatformFeeDistributor.
  function updateDistributor(address _newDistributor) external onlyOwner {
    address _oldDistributor = distributor;
    require(_oldDistributor != _newDistributor, "update the same address");

    distributor = _newDistributor;

    emit UpdateDistributor(_oldDistributor, _newDistributor);
  }

  /// @notice Update gauge types
  /// @dev You can only update from `None` to others or others to `None.
  /// @param _gauges The list of gauge addresses to update.
  /// @param _types The corresponding list of guage types to update.
  function updateGaugeTypes(address[] calldata _gauges, GaugeType[] calldata _types) external onlyOwner {
    require(_gauges.length == _types.length, "length mismatch");
    for (uint256 i = 0; i < _gauges.length; i++) {
      GaugeType _oldType = gauges[_gauges[i]].gaugeType;
      if (_oldType == GaugeType.None) {
        require(_types[i] != GaugeType.None, "invalid type");
      } else {
        require(_types[i] == GaugeType.None, "invalid type");
      }
      gauges[_gauges[i]].gaugeType = _types[i];

      emit UpdateGaugeType(_gauges[i], _types[i]);
    }
  }

  /// @notice Add a new reward token to distribute.
  /// @param _token The address of reward token.
  /// @param _gauges The list of gauges.
  /// @param _percentages The percentage distributed to each gauge.
  function addRewardToken(
    address _token,
    address[] calldata _gauges,
    uint32[] calldata _percentages
  ) external onlyOwner {
    require(_gauges.length == _percentages.length, "length mismatch");
    uint256 _length = rewardTokens.length;
    uint256 _emptyIndex = _length;
    for (uint256 i = 0; i < _length; i++) {
      address _rewardToken = rewardTokens[i];
      require(_rewardToken != _token, "duplicated reward token");
      if (_rewardToken == address(0)) _emptyIndex = i;
    }
    if (_emptyIndex == _length) {
      rewardTokens.push(_token);
    } else {
      rewardTokens[_emptyIndex] = _token;
    }

    RewardDistribution[] storage _distributions = distributions[_token];
    uint256 _sum;
    for (uint256 i = 0; i < _gauges.length; i++) {
      for (uint256 j = 0; j < i; j++) {
        require(_gauges[i] != _gauges[j], "duplicated gauge");
      }
      _distributions.push(RewardDistribution(_gauges[i], _percentages[i]));
      _sum = _sum.add(_percentages[i]);
      gauges[_gauges[i]].tokens.add(_token);
    }
    require(_sum == FEE_DENOMINATOR, "sum mismatch");

    emit AddRewardToken(_emptyIndex, _token, _gauges, _percentages);
  }

  /// @notice Remove a reward token.
  /// @param _index The index of the reward token.
  function removeRewardToken(uint256 _index) external onlyOwner {
    _claimFromDistributor(new address[](0), new uint256[](0));

    address _token = rewardTokens[_index];
    {
      uint256 _length = distributions[_token].length;
      for (uint256 i = 0; i < _length; i++) {
        gauges[distributions[_token][i].gauge].tokens.remove(_token);
      }
    }
    delete distributions[_token];
    rewardTokens[_index] = address(0);

    emit RemoveRewardToken(_index, _token);
  }

  /// @notice Update reward distribution for reward token.
  /// @param _index The index of the reward token.
  /// @param _gauges The list of gauges.
  /// @param _percentages The percentage distributed to each gauge.
  function updateRewardDistribution(
    uint256 _index,
    address[] calldata _gauges,
    uint32[] calldata _percentages
  ) external onlyOwner {
    _claimFromDistributor(new address[](0), new uint256[](0));

    address _token = rewardTokens[_index];
    {
      uint256 _length = distributions[_token].length;
      for (uint256 i = 0; i < _length; i++) {
        gauges[distributions[_token][i].gauge].tokens.remove(_token);
      }
    }
    delete distributions[_token];

    RewardDistribution[] storage _distributions = distributions[_token];
    uint256 _sum;
    for (uint256 i = 0; i < _gauges.length; i++) {
      for (uint256 j = 0; j < i; j++) {
        require(_gauges[i] != _gauges[j], "duplicated gauge");
      }
      _distributions.push(RewardDistribution(_gauges[i], _percentages[i]));
      _sum = _sum.add(_percentages[i]);
      gauges[_gauges[i]].tokens.add(_token);
    }
    require(_sum == FEE_DENOMINATOR, "sum mismatch");

    emit UpdateRewardToken(_token, _gauges, _percentages);
  }

  /// @dev Internal function to tranfer rewards to gauge directly. Caller shoule make sure the
  /// `GaugeType` is `CurveGaugeV1V2V3`.
  /// @param _gauge The address of gauge.
  function _transferToGauge(address _gauge) internal {
    GaugeRewards storage _rewards = gauges[_gauge];
    uint256 _length = _rewards.tokens.length();
    for (uint256 i = 0; i < _length; i++) {
      address _token = _rewards.tokens.at(i);
      uint256 _pending = _rewards.pendings[_token];
      if (_pending > 0) {
        _rewards.pendings[_token] = 0;
        IERC20(_token).safeTransfer(_gauge, _pending);
      }
    }
  }

  /// @dev Internal function to claim rewards from PlatformFeeDistributor
  /// @param _tokens The list of extra reward tokens donated to this contract.
  /// @param _amounts The list of amount of extra reward tokens donated to this contract.
  function _claimFromDistributor(address[] memory _tokens, uint256[] memory _amounts) internal {
    // claim from distributor and distribute to gauges
    address _distributor = distributor;
    if (_distributor != address(0)) {
      uint256 _length = rewardTokens.length;
      uint256[] memory _before = new uint256[](_length);
      for (uint256 i = 0; i < _length; i++) {
        if (rewardTokens[i] == address(0)) continue;
        _before[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
      }
      PlatformFeeDistributor(_distributor).claim();
      for (uint256 i = 0; i < _length; i++) {
        address _token = rewardTokens[i];
        if (_token == address(0)) continue;
        uint256 _claimed = IERC20(_token).balanceOf(address(this)).sub(_before[i]);
        if (_claimed > 0) {
          _distributeReward(_token, _claimed);
        }
      }
    }
    // distribute donated rewards to gauges.
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_amounts[i] > 0) {
        _distributeReward(_tokens[i], _amounts[i]);
      }
    }
  }

  /// @dev Internal function to distribute reward to gauges.
  /// @param _token The address of reward token.
  /// @param _amount The amount of reward token.
  function _distributeReward(address _token, uint256 _amount) internal {
    RewardDistribution[] storage _distributions = distributions[_token];
    uint256 _length = _distributions.length;
    for (uint256 i = 0; i < _length; i++) {
      RewardDistribution memory _distribution = _distributions[i];
      if (_distribution.percentage > 0) {
        uint256 _part = _amount.mul(_distribution.percentage) / FEE_DENOMINATOR;
        GaugeRewards storage _gauge = gauges[_distribution.gauge];
        if (_gauge.gaugeType == GaugeType.CurveGaugeV1V2V3) {
          // @note Curve Gauge V1, V2 or V3 need explicit claim.
          _gauge.pendings[_token] = _part.add(_gauge.pendings[_token]);
        } else if (_gauge.gaugeType == GaugeType.CurveGaugeV4V5) {
          // @note rewards can be deposited to Curve Gauge V4 or V5 directly.
          IERC20(_token).safeApprove(_distribution.gauge, 0);
          IERC20(_token).safeApprove(_distribution.gauge, _part);
          ICurveGaugeV4V5(_distribution.gauge).deposit_reward_token(_token, _part);
        } else {
          // no gauge to distribute, just send to owner
          IERC20(_token).safeTransfer(owner(), _part);
        }
      }
    }
  }
}