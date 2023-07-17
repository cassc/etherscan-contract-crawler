// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { SwapOperation } from "./SwapOperation.sol";
import { SwapTask } from "./SwapTask.sol";
import { Balance, BalanceOps } from "@gearbox-protocol/core-v2/contracts/libraries/Balances.sol";
import { MultiCall, MultiCallOps } from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";
import { SlippageMath } from "../helpers/SlippageMath.sol";
import { IAdapter } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { RouterResult, RouterResultOps } from "../data/RouterResult.sol";
import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";
// CREDIT
import { ICreditManagerV2 } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditManagerV2.sol";
import { ICreditConfigurator } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditConfigurator.sol";
import { ICreditAccount } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditAccount.sol";

import { CreditFacadeCalls, CreditFacadeMulticaller } from "@gearbox-protocol/core-v2/contracts/multicall/CreditFacadeCalls.sol";

struct TokenAdapters {
    address token;
    address depositAdapter;
    address withdrawAdapter;
}

/// @dev Internal struct is widely use inside Router
/// End user doesn't interact with it, it's created in Router and then used to manage
/// whole process
struct StrategyPathTask {
    address creditAccount;
    Balance[] balances;
    address target;
    address[] connectors;
    address[] adapters;
    uint256 slippagePerStep;
    bool force;
    //
    // for internal use
    uint8 targetType;
    TokenAdapters[] foundAdapters;
    uint256 gasPriceTargetRAY;
    uint256 gasUsage;
    uint256 initTargetBalance;
    MultiCall[] calls;
}

error NoSpaceForSlippageCallException();
error DifferentTargetComparisonException();

library StrategyPathTaskOps {
    using SlippageMath for uint256;
    using BalanceOps for Balance[];
    using MultiCallOps for MultiCall[];
    using CreditFacadeCalls for CreditFacadeMulticaller;

    function toSwapTask(
        StrategyPathTask memory task,
        uint256 tokenIndex,
        address target
    ) internal pure returns (SwapTask memory) {
        return
            SwapTask({
                swapOperation: SwapOperation.EXACT_INPUT_ALL,
                creditAccount: task.creditAccount,
                tokenIn: task.balances[tokenIndex].token,
                tokenOut: target,
                connectors: task.connectors,
                amount: task.balances[tokenIndex].balance,
                slippage: task.slippagePerStep,
                externalSlippage: true
            });
    }

    function toSwapTask(
        StrategyPathTask memory task,
        address tokenIn,
        uint256 amount,
        address tokenOut,
        bool isAllInput,
        bool externalSlippage
    ) internal pure returns (SwapTask memory) {
        return
            SwapTask({
                swapOperation: isAllInput
                    ? SwapOperation.EXACT_INPUT_ALL
                    : SwapOperation.EXACT_INPUT,
                creditAccount: task.creditAccount,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                connectors: task.connectors,
                amount: amount,
                slippage: task.slippagePerStep,
                externalSlippage: externalSlippage
            });
    }

    function amountOutWithSlippage(StrategyPathTask memory task, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return amount.applySlippage(task.slippagePerStep, true);
    }

    function isZeroBalance(StrategyPathTask memory task, address token)
        internal
        pure
        returns (bool)
    {
        return task.balances.getBalance(token) == 0;
    }

    function findAdapterByTarget(
        StrategyPathTask memory task,
        address targetContract
    ) internal view returns (address adapter) {
        for (uint256 i; i < task.adapters.length; ) {
            if (task.adapters[i] == address(0)) continue;
            try IAdapter(task.adapters[i]).targetContract() returns (
                address currentTarget
            ) {
                if (currentTarget == targetContract) {
                    return task.adapters[i];
                }
            } catch {}

            unchecked {
                ++i;
            }
        }

        revert("StrategyPathTask: Adapter for target contract not found");
    }

    function isolateAdapter(StrategyPathTask memory task, uint256 adapterIndex)
        internal
        pure
    {
        address[] memory newAdapters = new address[](1);
        newAdapters[0] = task.adapters[adapterIndex];
        task.adapters = newAdapters;
    }

    function getTokenDepositAdapter(StrategyPathTask memory task, address token)
        internal
        pure
        returns (address adapter)
    {
        for (uint256 i; i < task.foundAdapters.length; ) {
            if (task.foundAdapters[i].token == token) {
                return task.foundAdapters[i].depositAdapter;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getTokenWithdrawAdapter(
        StrategyPathTask memory task,
        address token
    ) internal pure returns (address adapter) {
        for (uint256 i; i < task.foundAdapters.length; ) {
            if (task.foundAdapters[i].token == token) {
                return task.foundAdapters[i].withdrawAdapter;
            }

            unchecked {
                ++i;
            }
        }
    }

    function addTokenDepositAdapter(
        StrategyPathTask memory task,
        address token,
        address adapter
    ) internal pure {
        uint256 len = task.foundAdapters.length;
        TokenAdapters[] memory res = new TokenAdapters[](len + 1);

        for (uint256 i; i < len; ) {
            if (task.foundAdapters[i].token == token) {
                task.foundAdapters[i].depositAdapter = adapter;
                return;
            }
            res[i] = task.foundAdapters[i];
            unchecked {
                ++i;
            }
        }

        res[len] = TokenAdapters({
            token: token,
            depositAdapter: adapter,
            withdrawAdapter: address(0)
        });
        task.foundAdapters = res;
    }

    function addTokenWithdrawAdapter(
        StrategyPathTask memory task,
        address token,
        address adapter
    ) internal pure {
        uint256 len = task.foundAdapters.length;
        TokenAdapters[] memory res = new TokenAdapters[](len + 1);

        for (uint256 i; i < len; ) {
            if (task.foundAdapters[i].token == token) {
                task.foundAdapters[i].withdrawAdapter = adapter;
                return;
            }
            res[i] = task.foundAdapters[i];
            unchecked {
                ++i;
            }
        }

        res[len] = TokenAdapters({
            token: token,
            depositAdapter: address(0),
            withdrawAdapter: adapter
        });
        task.foundAdapters = res;
    }

    function initSlippageControl(StrategyPathTask memory task) internal pure {
        if (task.calls.length != 0) revert NoSpaceForSlippageCallException();

        task.calls = new MultiCall[](1);
        task.initTargetBalance = task.balances.getBalance(task.target);
    }

    function updateSlippageControl(StrategyPathTask memory task) internal view {
        updateSlippageControl(task, getCreditFacade(task.creditAccount));
    }

    function updateSlippageControl(
        StrategyPathTask memory task,
        address creditFacade
    ) internal pure {
        Balance[] memory limit = new Balance[](1);
        limit[0] = Balance({
            token: task.target,
            balance: task.balances.getBalance(task.target) -
                task.initTargetBalance
        });

        // TODO: ADD CALL SIGNATURE CHECK!

        task.calls[0] = CreditFacadeMulticaller(creditFacade)
            .revertIfReceivedLessThan(limit);
    }

    function getCreditFacade(address creditAccount)
        private
        view
        returns (address creditFacade)
    {
        // TODO: Not sure this is implemented in the credit facade
        if (creditAccount == address(0))
            return 0xFAcAdEfAcadefaCadEfacADeFACAdEfACaDefAce;
        ICreditManagerV2 creditManager = ICreditManagerV2(
            ICreditAccount(creditAccount).creditManager()
        );

        creditFacade = creditManager.creditFacade();
    }

    function toRouterResult(StrategyPathTask memory task)
        internal
        pure
        returns (RouterResult memory r)
    {
        r.calls = task.calls;
        r.amount =
            task.balances.getBalance(task.target) -
            task.initTargetBalance;
        r.gasUsage = task.gasUsage;
    }

    function isBetter(
        StrategyPathTask memory task1,
        StrategyPathTask memory task2
    ) internal pure returns (bool) {
        if (
            task1.target != task2.target ||
            task1.gasPriceTargetRAY != task2.gasPriceTargetRAY
        ) revert DifferentTargetComparisonException();

        uint256 amount1 = task1.balances.getBalance(task1.target);
        uint256 amount2 = task2.balances.getBalance(task2.target);
        return
            safeIsGreater(
                amount1,
                (task1.gasUsage * task1.gasPriceTargetRAY) / RAY,
                amount2,
                (task2.gasUsage * task2.gasPriceTargetRAY) / RAY
            );
    }

    function safeIsGreater(
        uint256 amount1,
        uint256 gasCost1,
        uint256 amount2,
        uint256 gasCost2
    ) internal pure returns (bool isGreater) {
        if (amount1 >= gasCost1 && amount2 >= gasCost2) {
            return (amount1 - gasCost1) > (amount2 - gasCost2);
        }

        int256 diff1 = int256(amount1) - int256(gasCost1);
        int256 diff2 = int256(amount2) - int256(gasCost2);

        return diff1 > diff2;
    }

    function clone(StrategyPathTask memory task)
        internal
        pure
        returns (StrategyPathTask memory)
    {
        return
            StrategyPathTask({
                creditAccount: task.creditAccount,
                balances: task.balances.clone(),
                target: task.target,
                connectors: task.connectors,
                adapters: task.adapters,
                slippagePerStep: task.slippagePerStep,
                targetType: task.targetType,
                foundAdapters: task.foundAdapters,
                gasPriceTargetRAY: task.gasPriceTargetRAY,
                gasUsage: task.gasUsage,
                initTargetBalance: task.initTargetBalance,
                calls: task.calls.clone(),
                force: task.force
            });
    }

    function trim(StrategyPathTask[] memory tasks)
        internal
        pure
        returns (StrategyPathTask[] memory)
    {
        uint256 foundLen;

        for (uint256 i = 0; i < tasks.length; ++i) {
            if (tasks[i].calls.length > 0) ++foundLen;
        }

        StrategyPathTask[] memory trimmed = new StrategyPathTask[](foundLen);

        for (uint256 i = 0; i < foundLen; ++i) {
            trimmed[i] = tasks[i];
        }

        return trimmed;
    }
}