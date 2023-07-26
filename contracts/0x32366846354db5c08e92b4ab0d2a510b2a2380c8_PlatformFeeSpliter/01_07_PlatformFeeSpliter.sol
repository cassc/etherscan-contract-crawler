// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract PlatformFeeSpliter is Ownable {
  using SafeERC20 for IERC20;

  /**********
   * Events *
   **********/

  /// @notice Emitted when the address of staker contract is updated.
  /// @param staker The address of new staker contract.
  event UpdateStaker(address staker);

  /// @notice Emitted when the address of treasury contract is updated.
  /// @param treasury The address of new treasury contract.
  event UpdateTreasury(address treasury);

  /// @notice Emitted when the address of ecosystem contract is updated.
  /// @param ecosystem The address of new ecosystem contract.
  event UpdateEcosystem(address ecosystem);

  /// @notice Emitted when a new reward token is added.
  /// @param token The address of reward token.
  /// @param burner The address of token burner contract.
  /// @param stakerRatio The ratio of token distributed to liquidity stakers, multipled by 1e9.
  /// @param treasuryRatio The ratio of token distributed to treasury, multipled by 1e9.
  /// @param lockerRatio The ratio of token distributed to ve token lockers, multipled by 1e9.
  event AddRewardToken(address token, address burner, uint256 stakerRatio, uint256 treasuryRatio, uint256 lockerRatio);

  /// @notice Emitted when the percentage is updated for existing reward token.
  /// @param token The address of reward token.
  /// @param stakerRatio The ratio of token distributed to liquidity stakers, multipled by 1e9.
  /// @param treasuryRatio The ratio of token distributed to treasury, multipled by 1e9.
  /// @param lockerRatio The ratio of token distributed to ve token lockers, multipled by 1e9.
  event UpdateRewardTokenRatio(address token, uint256 stakerRatio, uint256 treasuryRatio, uint256 lockerRatio);

  /// @notice Emitted when the address of token burner is updated.
  /// @param token The address of reward token.
  /// @param burner The address of token burner contract.
  event UpdateRewardTokenBurner(address token, address burner);

  /// @notice Emitted when a reward token is removed.
  /// @param token The address of reward token.
  event RemoveRewardToken(address token);

  /*************
   * Constants *
   *************/

  /// @dev The fee denominator used for ratio calculation.
  uint256 private constant FEE_PRECISION = 1e9;

  /***********
   * Structs *
   ***********/

  struct RewardInfo {
    // The address of reward token.
    address token;
    // The ratio of token distributed to liquidity stakers, multipled by 1e9.
    uint32 stakerRatio;
    // The ratio of token distributed to treasury, multipled by 1e9.
    uint32 treasuryRatio;
    // The ratio of token distributed to ve token lockers, multipled by 1e9.
    uint32 lockerRatio;
    // @note The rest token will transfer to ecosystem fund for future usage.
  }

  /*************
   * Variables *
   *************/

  /// @notice The address of contract used to hold treasury fund.
  address public treasury;

  /// @notice The address of contract used to hold ecosystem fund.
  address public ecosystem;

  /// @notice The address of contract used to distribute incentive for liquidity stakers.
  address public staker;

  /// @notice The list of rewards token.
  RewardInfo[] public rewards;

  /// @notice Mapping from reward token address to corresponding token burner.
  mapping(address => address) public burners;

  /***************
   * Constructor *
   ***************/

  constructor(
    address _treasury,
    address _ecosystem,
    address _staker
  ) {
    _ensureNonZeroAddress(_treasury, "treasury");
    _ensureNonZeroAddress(_ecosystem, "ecosystem");
    _ensureNonZeroAddress(_staker, "staker");

    treasury = _treasury;
    ecosystem = _ecosystem;
    staker = _staker;
  }

  /// @notice Return the number of reward tokens.
  function getRewardCount() external view returns (uint256) {
    return rewards.length;
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Claim and distribute pending rewards to staker/treasury/locker/ecosystem contract.
  /// @dev The function can only be called by staker contract.
  function claim() external {
    address _staker = staker;
    require(msg.sender == _staker, "not staker");

    address _treasury = treasury;
    address _ecosystem = ecosystem;

    uint256 _length = rewards.length;
    for (uint256 i = 0; i < _length; i++) {
      RewardInfo memory _reward = rewards[i];
      uint256 _balance = IERC20(_reward.token).balanceOf(address(this));
      if (_balance > 0) {
        uint256 _stakerAmount = (_reward.stakerRatio * _balance) / FEE_PRECISION;
        uint256 _treasuryAmount = (_reward.treasuryRatio * _balance) / FEE_PRECISION;
        uint256 _lockerAmount = (_reward.lockerRatio * _balance) / FEE_PRECISION;
        uint256 _ecosystemAmount = _balance - _stakerAmount - _treasuryAmount - _lockerAmount;

        if (_stakerAmount > 0) {
          IERC20(_reward.token).safeTransfer(_staker, _stakerAmount);
        }
        if (_treasuryAmount > 0) {
          IERC20(_reward.token).safeTransfer(_treasury, _treasuryAmount);
        }
        if (_lockerAmount > 0) {
          IERC20(_reward.token).safeTransfer(burners[_reward.token], _lockerAmount);
        }
        if (_ecosystemAmount > 0) {
          IERC20(_reward.token).safeTransfer(_ecosystem, _ecosystemAmount);
        }
      }
    }
  }

  /************************
   * Restricted Functions *
   ************************/

  /// @notice Update the address of treasury contract.
  /// @param _treasury The address of new treasury contract.
  function updateTreasury(address _treasury) external onlyOwner {
    _ensureNonZeroAddress(_treasury, "treasury");

    treasury = _treasury;

    emit UpdateTreasury(_treasury);
  }

  /// @notice Update the address of ecosystem contract.
  /// @param _ecosystem The address of new ecosystem contract.
  function updateEcosystem(address _ecosystem) external onlyOwner {
    _ensureNonZeroAddress(_ecosystem, "ecosystem");

    ecosystem = _ecosystem;

    emit UpdateEcosystem(_ecosystem);
  }

  /// @notice Update the address of staker contract.
  /// @param _staker The address of new staker contract.
  function updateStaker(address _staker) external onlyOwner {
    _ensureNonZeroAddress(_staker, "staker");

    staker = _staker;

    emit UpdateStaker(_staker);
  }

  /// @notice Add a new reward token.
  /// @param _token The address of reward token.
  /// @param _burner The address of corresponding token burner.
  /// @param _stakerRatio The ratio of token distributed to liquidity stakers, multipled by 1e9.
  /// @param _treasuryRatio The ratio of token distributed to treasury, multipled by 1e9.
  /// @param _lockerRatio The ratio of token distributed to ve token lockers, multipled by 1e9.
  function addRewardToken(
    address _token,
    address _burner,
    uint32 _stakerRatio,
    uint32 _treasuryRatio,
    uint32 _lockerRatio
  ) external onlyOwner {
    _checkRatioRange(_stakerRatio, _treasuryRatio, _lockerRatio);
    _ensureNonZeroAddress(_burner, "burner");

    require(burners[_token] == address(0), "duplicated reward token");
    burners[_token] = _burner;

    rewards.push(RewardInfo(_token, _stakerRatio, _treasuryRatio, _lockerRatio));

    emit AddRewardToken(_token, _burner, _stakerRatio, _treasuryRatio, _lockerRatio);
  }

  /// @notice Update reward ratio of existing reward token.
  /// @param _index The index of reward token.
  /// @param _stakerRatio The ratio of token distributed to liquidity stakers, multipled by 1e9.
  /// @param _treasuryRatio The ratio of token distributed to treasury, multipled by 1e9.
  /// @param _lockerRatio The ratio of token distributed to ve token lockers, multipled by 1e9.
  function updateRewardTokenRatio(
    uint256 _index,
    uint32 _stakerRatio,
    uint32 _treasuryRatio,
    uint32 _lockerRatio
  ) external onlyOwner {
    _checkRatioRange(_stakerRatio, _treasuryRatio, _lockerRatio);
    require(_index < rewards.length, "index out of range");

    RewardInfo memory _info = rewards[_index];
    _info.stakerRatio = _stakerRatio;
    _info.treasuryRatio = _treasuryRatio;
    _info.lockerRatio = _lockerRatio;

    rewards[_index] = _info;
    emit UpdateRewardTokenRatio(_info.token, _stakerRatio, _treasuryRatio, _lockerRatio);
  }

  /// @notice Update the token burner of existing reward token.
  /// @param _token The address of the reward token.
  /// @param _burner The address of corresponding token burner.
  function updateRewardTokenBurner(address _token, address _burner) external onlyOwner {
    _ensureNonZeroAddress(_burner, "new burner");
    _ensureNonZeroAddress(burners[_token], "old burner");

    burners[_token] = _burner;

    emit UpdateRewardTokenBurner(_token, _burner);
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

    burners[_token] = address(0);

    emit RemoveRewardToken(_token);
  }

  /**********************
   * Internal Functions *
   **********************/

  function _checkRatioRange(
    uint32 _stakerRatio,
    uint32 _treasuryRatio,
    uint32 _lockerRatio
  ) internal pure {
    require(_stakerRatio <= FEE_PRECISION, "staker ratio too large");
    require(_treasuryRatio <= FEE_PRECISION, "treasury ratio too large");
    require(_lockerRatio <= FEE_PRECISION, "locker ratio too large");
    require(_stakerRatio + _treasuryRatio + _lockerRatio <= FEE_PRECISION, "ecosystem ratio too small");
  }

  function _ensureNonZeroAddress(address _addr, string memory _name) internal pure {
    require(_addr != address(0), string(abi.encodePacked(_name, " address should not be zero")));
  }
}