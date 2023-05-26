// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IV2KeeperJob.sol";
import "./interfaces/IBaseStrategy.sol";

import "./dependencies/Governable.sol";
import "./dependencies/Keep3rBondedJob.sol";

contract HarvestV2KeeperJob is IV2KeeperJob, Keep3rBondedJob, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _availableStrategies;

    mapping(address => uint256) public requiredAmount;
    mapping(address => uint256) public lastWorkAt;

    uint256 public workCooldown;

    constructor(address _governor) Governable(_governor) {
        workCooldown = 5 days;

        onlyEOA = true;

        requiredBond = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44; // KP3R Token
        requiredMinBond = 50 ether;
        requiredEarnings = 0;
        requiredAge = 0;
    }

    // --- Public View Functions --- //

    /// @inheritdoc IV2KeeperJob
    function workable(address _strategy) external view returns (bool _isWorkable) {
        if (!_workable(_strategy)) return false;
        return IBaseStrategy(_strategy).harvestTrigger(_getCallCosts(_strategy));
    }

    /// @inheritdoc IV2KeeperJob
    function strategies() public view returns (address[] memory _strategies) {
        _strategies = new address[](_availableStrategies.length());
        for (uint256 _i; _i < _availableStrategies.length(); _i++) {
            _strategies[_i] = _availableStrategies.at(_i);
        }
    }

    // --- Methods --- //

    /// @inheritdoc IV2KeeperJob
    function work(address _strategy) external upkeep whenNotPaused {
        _workInternal(_strategy);
    }

    function forceWork(address _strategy) external onlyGovernor {
        _forceWork(_strategy);
    }

    // --- Setters --- //

    /// @inheritdoc IV2KeeperJob
    function setWorkCooldown(uint256 _workCooldown) external onlyGovernor {
        _setWorkCooldown(_workCooldown);
    }

    /// @inheritdoc IV2KeeperJob
    function addStrategy(address _strategy, uint256 _requiredAmount) external onlyGovernor {
        _addStrategy(_strategy, _requiredAmount);
    }

    /// @inheritdoc IV2KeeperJob
    function addStrategies(address[] calldata _strategies, uint256[] calldata _requiredAmounts)
        external
        onlyGovernor
    {
        if (_strategies.length != _requiredAmounts.length) revert WrongLengths();
        for (uint256 _i; _i < _strategies.length; _i++) {
            _addStrategy(_strategies[_i], _requiredAmounts[_i]);
        }
    }

    /// @inheritdoc IV2KeeperJob
    function updateRequiredAmount(address _strategy, uint256 _requiredAmount) external onlyGovernor {
        _updateRequiredAmount(_strategy, _requiredAmount);
    }

    /// @inheritdoc IV2KeeperJob
    function updateRequiredAmounts(address[] calldata _strategies, uint256[] calldata _requiredAmounts)
        external
        onlyGovernor
    {
        if (_strategies.length != _requiredAmounts.length) revert WrongLengths();
        for (uint256 _i; _i < _strategies.length; _i++) {
            _updateRequiredAmount(_strategies[_i], _requiredAmounts[_i]);
        }
    }

    /// @inheritdoc IV2KeeperJob
    function removeStrategy(address _strategy) external onlyGovernor {
        _removeStrategy(_strategy);
    }

    function pause() external onlyGovernor {
        _pause();
    }

    function unpause() external onlyGovernor {
        _unpause();
    }

    // --- Internal Functions --- //

    function _setWorkCooldown(uint256 _workCooldown) internal {
        if (_workCooldown == 0) revert ZeroCooldown();
        workCooldown = _workCooldown;
    }

    function _addStrategy(address _strategy, uint256 _requiredAmount) internal {
        if (_availableStrategies.contains(_strategy)) revert StrategyAlreadyAdded();
        _setRequiredAmount(_strategy, _requiredAmount);
        emit StrategyAdded(_strategy, _requiredAmount);
        _availableStrategies.add(_strategy);
    }

    function _updateRequiredAmount(address _strategy, uint256 _requiredAmount) internal {
        if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
        _setRequiredAmount(_strategy, _requiredAmount);
        emit StrategyModified(_strategy, _requiredAmount);
    }

    function _removeStrategy(address _strategy) internal {
        if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
        delete requiredAmount[_strategy];
        _availableStrategies.remove(_strategy);
        emit StrategyRemoved(_strategy);
    }

    function _setRequiredAmount(address _strategy, uint256 _requiredAmount) internal {
        requiredAmount[_strategy] = _requiredAmount;
    }

    function _workable(address _strategy) internal view returns (bool) {
        if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
        if (workCooldown == 0 || block.timestamp > lastWorkAt[_strategy] + workCooldown) return true;
        return false;
    }

    function _getCallCosts(address _strategy) internal view returns (uint256 _callCost) {
        uint256 _gasAmount = requiredAmount[_strategy];
        if (_gasAmount == 0) return 0;
        return _gasAmount * _gasPrice();
    }

    function _gasPrice() internal view returns (uint256) {
        return block.basefee;
    }

    function _workInternal(address _strategy) internal {
        if (!_workable(_strategy)) revert StrategyNotWorkable();
        lastWorkAt[_strategy] = block.timestamp;
        _work(_strategy);
        emit KeeperWorked(_strategy);
    }

    function _forceWork(address _strategy) internal {
        _work(_strategy);
        emit ForceWorked(_strategy);
    }

    function _work(address _strategy) internal {
        IBaseStrategy(_strategy).harvest();
    }
}