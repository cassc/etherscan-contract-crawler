// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import './Keep3rJob.sol';
import '../../interfaces/external/IKeep3rHelper.sol';
import '../../interfaces/utils/IKeep3rMeteredJob.sol';

abstract contract Keep3rMeteredJob is IKeep3rMeteredJob, Keep3rJob {
  /// @inheritdoc IKeep3rMeteredJob
  address public keep3rHelper = 0xeDDe080E28Eb53532bD1804de51BD9Cd5cADF0d4;
  /// @inheritdoc IKeep3rMeteredJob
  uint256 public gasBonus = 102_000;
  /// @inheritdoc IKeep3rMeteredJob
  uint256 public gasMultiplier = 10_000;
  /// @inheritdoc IKeep3rMeteredJob
  uint32 public constant BASE = 10_000;
  /// @inheritdoc IKeep3rMeteredJob
  uint256 public maxMultiplier = 15_000;

  // setters

  /// @inheritdoc IKeep3rMeteredJob
  function setKeep3rHelper(address _keep3rHelper) public onlyGovernor {
    _setKeep3rHelper(_keep3rHelper);
  }

  /// @inheritdoc IKeep3rMeteredJob
  function setGasBonus(uint256 _gasBonus) external onlyGovernor {
    _setGasBonus(_gasBonus);
  }

  /// @inheritdoc IKeep3rMeteredJob
  function setMaxMultiplier(uint256 _maxMultiplier) external onlyGovernor {
    _setMaxMultiplier(_maxMultiplier);
  }

  /// @inheritdoc IKeep3rMeteredJob
  function setGasMultiplier(uint256 _gasMultiplier) external onlyGovernor {
    _setGasMultiplier(_gasMultiplier);
  }

  // modifiers

  modifier upkeepMetered() {
    uint256 _initialGas = gasleft();
    _isValidKeeper(msg.sender);
    _;
    uint256 _gasAfterWork = gasleft();
    uint256 _reward = IKeep3rHelper(keep3rHelper).getRewardAmountFor(msg.sender, _initialGas - _gasAfterWork + gasBonus);
    _reward = (_reward * gasMultiplier) / BASE;
    IKeep3rV2(keep3r).bondedPayment(msg.sender, _reward);
    emit GasMetered(_initialGas, _gasAfterWork, gasBonus);
  }

  // internals

  function _setKeep3rHelper(address _keep3rHelper) internal {
    keep3rHelper = _keep3rHelper;
    emit Keep3rHelperSet(_keep3rHelper);
  }

  function _setGasBonus(uint256 _gasBonus) internal {
    gasBonus = _gasBonus;
    emit GasBonusSet(gasBonus);
  }

  function _setMaxMultiplier(uint256 _maxMultiplier) internal {
    maxMultiplier = _maxMultiplier;
    emit MaxMultiplierSet(maxMultiplier);
  }

  function _setGasMultiplier(uint256 _gasMultiplier) internal {
    if (_gasMultiplier > maxMultiplier) revert MaxMultiplier();
    gasMultiplier = _gasMultiplier;
    emit GasMultiplierSet(gasMultiplier);
  }

  function _calculateCredits(uint256 _gasUsed) internal view returns (uint256 _credits) {
    return IKeep3rHelper(keep3rHelper).getRewardAmount(_gasUsed);
  }
}