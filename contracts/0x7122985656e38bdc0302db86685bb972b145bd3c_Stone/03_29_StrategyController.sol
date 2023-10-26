// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {Strategy} from "./Strategy.sol";
import {AssetsVault} from "../AssetsVault.sol";

contract StrategyController {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant ONE_HUNDRED_PERCENT = 1e6;

    address public stoneVault;
    address payable public immutable assetsVault;

    EnumerableSet.AddressSet private strategies;

    mapping(address => uint256) public ratios;

    struct StrategyDiff {
        address strategy;
        bool isDeposit;
        uint256 amount;
    }

    modifier onlyVault() {
        require(stoneVault == msg.sender, "not vault");
        _;
    }

    constructor(
        address payable _assetsVault,
        address[] memory _strategies,
        uint256[] memory _ratios
    ) {
        require(_assetsVault != address(0), "ZERO ADDRESS");

        uint256 length = _strategies.length;
        for (uint256 i; i < length; i++) {
            require(_strategies[i] != address(0), "ZERO ADDRESS");
        }

        stoneVault = msg.sender;
        assetsVault = _assetsVault;

        _initStrategies(_strategies, _ratios);
    }

    function onlyRebaseStrategies() external {
        _rebase(0, 0);
    }

    function forceWithdraw(
        uint256 _amount
    ) external onlyVault returns (uint256 actualAmount) {
        uint256 balanceBeforeRepay = address(this).balance;

        if (balanceBeforeRepay >= _amount) {
            _repayToVault();

            actualAmount = balanceBeforeRepay;
        } else {
            actualAmount =
                _forceWithdraw(_amount - balanceBeforeRepay) +
                balanceBeforeRepay;
        }
    }

    function setStrategies(
        address[] memory _strategies,
        uint256[] memory _ratios
    ) external onlyVault {
        _setStrategies(_strategies, _ratios);
    }

    function addStrategy(address _strategy) external onlyVault {
        require(!strategies.contains(_strategy), "already exist");

        strategies.add(_strategy);
    }

    function rebaseStrategies(
        uint256 _in,
        uint256 _out
    ) external payable onlyVault {
        _rebase(_in, _out);
    }

    function destroyStrategy(address _strategy) external onlyVault {
        _destoryStrategy(_strategy);
    }

    function _rebase(uint256 _in, uint256 _out) internal {
        require(_in == 0 || _out == 0, "only deposit or withdraw");

        if (_in != 0) {
            AssetsVault(assetsVault).withdraw(address(this), _in);
        }
        uint256 total = getAllStrategyValidValue();
        if (total < _out) {
            total = 0;
        } else {
            total = total + _in - _out;
        }

        uint256 length = strategies.length();
        StrategyDiff[] memory diffs = new StrategyDiff[](length);
        uint256 head;
        uint256 tail = length - 1;
        for (uint i; i < length; i++) {
            address strategy = strategies.at(i);
            if (ratios[strategy] == 0) {
                _clearStrategy(strategy, true);
                continue;
            }
            uint256 newPosition = (total * ratios[strategy]) /
                ONE_HUNDRED_PERCENT;
            uint256 position = getStrategyValidValue(strategy);

            if (newPosition < position) {
                diffs[head] = StrategyDiff(
                    strategy,
                    false,
                    position - newPosition
                );
                head++;
            } else if (newPosition > position) {
                diffs[tail] = StrategyDiff(
                    strategy,
                    true,
                    newPosition - position
                );
                if (tail != 0) {
                    tail--;
                }
            }
        }

        length = diffs.length;
        for (uint256 i; i < length; i++) {
            StrategyDiff memory diff = diffs[i];

            if (diff.amount == 0) {
                continue;
            }

            if (diff.isDeposit) {
                if (address(this).balance < diff.amount) {
                    diff.amount = address(this).balance;
                }
                _depositToStrategy(diff.strategy, diff.amount);
            } else {
                _withdrawFromStrategy(diff.strategy, diff.amount);
            }
        }

        _repayToVault();
    }

    function _repayToVault() internal {
        if (address(this).balance != 0) {
            TransferHelper.safeTransferETH(assetsVault, address(this).balance);
        }
    }

    function _depositToStrategy(address _strategy, uint256 _amount) internal {
        Strategy(_strategy).deposit{value: _amount}();
    }

    function _withdrawFromStrategy(
        address _strategy,
        uint256 _amount
    ) internal {
        Strategy(_strategy).withdraw(_amount);
    }

    function _forceWithdraw(
        uint256 _amount
    ) internal returns (uint256 actualAmount) {
        uint256 length = strategies.length();
        for (uint i; i < length; i++) {
            address strategy = strategies.at(i);

            uint256 withAmount = (_amount * ratios[strategy]) /
                ONE_HUNDRED_PERCENT;

            if (withAmount != 0) {
                actualAmount =
                    Strategy(strategy).instantWithdraw(withAmount) +
                    actualAmount;
            }
        }

        _repayToVault();
    }

    function getStrategyValue(
        address _strategy
    ) public returns (uint256 _value) {
        return Strategy(_strategy).getAllValue();
    }

    function getStrategyValidValue(
        address _strategy
    ) public returns (uint256 _value) {
        return Strategy(_strategy).getInvestedValue();
    }

    function getStrategyPendingValue(
        address _strategy
    ) public returns (uint256 _value) {
        return Strategy(_strategy).getPendingValue();
    }

    function getAllStrategiesValue() public returns (uint256 _value) {
        uint256 length = strategies.length();
        for (uint i; i < length; i++) {
            _value = _value + getStrategyValue(strategies.at(i));
        }
    }

    function getAllStrategyValidValue() public returns (uint256 _value) {
        uint256 length = strategies.length();
        for (uint i; i < length; i++) {
            _value = _value + getStrategyValidValue(strategies.at(i));
        }
    }

    function getAllStrategyPendingValue() public returns (uint256 _value) {
        uint256 length = strategies.length();
        for (uint i; i < length; i++) {
            _value = _value + getStrategyPendingValue(strategies.at(i));
        }
    }

    function getStrategies()
        public
        view
        returns (address[] memory addrs, uint256[] memory portions)
    {
        uint256 length = strategies.length();

        addrs = new address[](length);
        portions = new uint256[](length);

        for (uint256 i; i < length; i++) {
            address addr = strategies.at(i);
            addrs[i] = addr;
            portions[i] = ratios[addr];
        }
    }

    function _initStrategies(
        address[] memory _strategies,
        uint256[] memory _ratios
    ) internal {
        require(_strategies.length == _ratios.length, "invalid length");

        uint256 totalRatio;
        uint256 length = _strategies.length;
        for (uint i; i < length; i++) {
            strategies.add(_strategies[i]);
            ratios[_strategies[i]] = _ratios[i];
            totalRatio = totalRatio + _ratios[i];
        }
        require(totalRatio <= ONE_HUNDRED_PERCENT, "exceed 100%");
    }

    function _setStrategies(
        address[] memory _strategies,
        uint256[] memory _ratios
    ) internal {
        uint256 length = _strategies.length;
        require(length == _ratios.length, "invalid length");

        uint256 oldLength = strategies.length();
        for (uint i; i < oldLength; i++) {
            ratios[strategies.at(i)] = 0;
        }
        uint256 totalRatio;
        for (uint i; i < length; i++) {
            require(
                Strategy(_strategies[i]).controller() == address(this),
                "controller mismatch"
            );
            strategies.add(_strategies[i]);
            ratios[_strategies[i]] = _ratios[i];
            totalRatio = totalRatio + _ratios[i];
        }
        require(totalRatio <= ONE_HUNDRED_PERCENT, "exceed 100%");
    }

    function clearStrategy(address _strategy) public onlyVault {
        _clearStrategy(_strategy, false);
    }

    function _clearStrategy(address _strategy, bool _isRebase) internal {
        Strategy(_strategy).clear();

        if (!_isRebase) {
            _repayToVault();
        }
    }

    function _destoryStrategy(address _strategy) internal {
        require(_couldDestroyStrategy(_strategy), "still active");

        strategies.remove(_strategy);

        _repayToVault();
    }

    function _couldDestroyStrategy(
        address _strategy
    ) internal returns (bool status) {
        return
            ratios[_strategy] == 0 && Strategy(_strategy).getAllValue() < 1e4;
    }

    function setNewVault(address _vault) external onlyVault {
        stoneVault = _vault;
    }

    receive() external payable {}
}