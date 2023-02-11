// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IStrategy.sol";

abstract contract StrategyConnector {
    using Address for address;

    function _strategyInitialize(
        address strategy,
        address token,
        bytes memory data
    ) internal {
        strategy.functionDelegateCall(
            abi.encodeWithSelector(IStrategy.initialize.selector, token, data)
        );
    }

    function _strategyDeposit(
        address strategy,
        address token,
        uint256 amount
    ) internal {
        strategy.functionDelegateCall(
            abi.encodeWithSelector(IStrategy.deposit.selector, token, amount)
        );
    }

    function _strategyWithdraw(
        address strategy,
        address token,
        uint256 amount
    ) internal {
        strategy.functionDelegateCall(
            abi.encodeWithSelector(IStrategy.withdraw.selector, token, amount)
        );
    }

    function _strategyExit(address strategy, address token) internal {
        strategy.functionDelegateCall(
            abi.encodeWithSelector(IStrategy.exit.selector, token)
        );
    }

    function _strategyCollectExtra(
        address strategy,
        address token,
        address to,
        bytes memory data
    ) internal {
        strategy.functionDelegateCall(
            abi.encodeWithSelector(
                IStrategy.collectExtra.selector,
                token,
                to,
                data
            )
        );
    }

    function _strategyBalance(address strategy, address token)
        internal
        returns (uint256)
    {
        bytes memory result = strategy.functionDelegateCall(
            abi.encodeWithSelector(IStrategy.getBalance.selector, token)
        );
        return abi.decode(result, (uint256));
    }
}