// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// CREDIT
import { ICreditManagerV2 } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditManagerV2.sol";
import { ICreditConfigurator } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditConfigurator.sol";
import { ICreditAccount } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditAccount.sol";
import { GasPricer } from "./helpers/GasPricer.sol";

//DATA
import { PathOption, PathOptionOps } from "./data/PathOption.sol";
import { MultiCall, MultiCallOps } from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";
import { Balance, BalanceOps } from "@gearbox-protocol/core-v2/contracts/libraries/Balances.sol";
import { StrategyPathTask, StrategyPathTaskOps, TokenAdapters } from "./data/StrategyPathTask.sol";
import { RouterResult, RouterResultOps } from "./data/RouterResult.sol";
import { SwapTask, SwapTaskOps } from "./data/SwapTask.sol";
import { SwapOperation } from "./data/SwapOperation.sol";
import { WAD } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";
import { PERCENTAGE_FACTOR } from "@gearbox-protocol/core-v2/contracts/libraries/PercentageMath.sol";

// TOKENS AND COMPONENTS
import "./data/RouterComponent.sol";
import "./data/TokenType.sol";

// PATHFINDERS
import { IRouter, UnsupportedRouterComponent } from "./interfaces/IRouter.sol";
import { IPathResolver } from "./interfaces/IPathResolver.sol";
import { IClosePathResolver } from "./interfaces/IClosePathResolver.sol";
import { ISwapAggregator } from "./interfaces/ISwapAggregator.sol";
import { IRouterComponent } from "./interfaces/IRouterComponent.sol";
import { ResolverConfigurator } from "./resolvers/ResolverConfigurator.sol";

struct TokenToTokenType {
    address token;
    uint8 tokenType;
}

struct TokenTypeToResolver {
    uint8 tokenType0;
    uint8 tokenType1;
    uint8 resolver;
}

contract Router is Ownable, GasPricer, IRouter {
    using BalanceOps for Balance[];
    using MultiCallOps for MultiCall[];
    using PathOptionOps for PathOption[];
    using RouterResultOps for RouterResult;
    using StrategyPathTaskOps for StrategyPathTask;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => uint8) public tokenTypes;
    mapping(uint8 => mapping(uint8 => uint8)) public resolvers;

    mapping(uint8 => address) public override componentAddressById;

    // Contract version
    uint256 public constant version = 1;

    EnumerableSet.UintSet connectedResolvers;

    constructor(
        address _addressProvider,
        TokenToTokenType[] memory tokenToTokenTypes
    ) GasPricer(_addressProvider) {
        unchecked {
            connectedResolvers.add(uint256(RC_SWAP_AGGREGATOR));
            connectedResolvers.add(uint256(RC_CLOSE_PATH_RESOLVER));
            connectedResolvers.add(uint256(RC_CURVE_LP_PATH_RESOLVER));
            connectedResolvers.add(uint256(RC_YEARN_PATH_RESOLVER));
            connectedResolvers.add(uint256(RC_CONVEX_PATH_RESOLVER));

            uint256 len = tokenToTokenTypes.length;

            for (uint256 i; i < len; i++) {
                TokenToTokenType memory ttt = tokenToTokenTypes[i];
                tokenTypes[ttt.token] = ttt.tokenType;
            }

            TokenTypeToResolver[11] memory ttrs = [
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_NORMAL_TOKEN,
                    resolver: RC_SWAP_AGGREGATOR
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_CURVE_LP_TOKEN,
                    resolver: RC_CURVE_LP_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_CURVE_LP_TOKEN,
                    resolver: RC_CURVE_LP_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_YEARN_ON_NORMAL_TOKEN,
                    resolver: RC_YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_YEARN_ON_CURVE_TOKEN,
                    resolver: RC_YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_YEARN_ON_CURVE_TOKEN,
                    resolver: RC_YEARN_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_CONVEX_LP_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_NORMAL_TOKEN,
                    tokenType1: TT_CONVEX_STAKED_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_CONVEX_LP_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CURVE_LP_TOKEN,
                    tokenType1: TT_CONVEX_STAKED_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                }),
                TokenTypeToResolver({
                    tokenType0: TT_CONVEX_LP_TOKEN,
                    tokenType1: TT_CONVEX_STAKED_TOKEN,
                    resolver: RC_CONVEX_PATH_RESOLVER
                })
            ];

            len = ttrs.length;

            for (uint256 i; i < len; ++i) {
                _setResolver(ttrs[i]);
            }
        }
    }

    function findAllSwaps(SwapTask calldata swapTask)
        external
        override
        returns (RouterResult[] memory result)
    {
        StrategyPathTask memory task = createStrategyPathTask(
            swapTask.creditAccount,
            swapTask.tokenOut,
            swapTask.connectors,
            swapTask.slippage,
            false
        );

        if (task.balances.getBalance(swapTask.tokenIn) < swapTask.amount) {
            task.balances.setBalance(swapTask.tokenIn, swapTask.amount);
        }

        task.initTargetBalance = task.balances.getBalance(task.target);

        StrategyPathTask[] memory tasks = ISwapAggregator(
            componentAddressById[RC_SWAP_AGGREGATOR]
        ).findAllSwaps(
                swapTask.tokenIn,
                swapTask.amount,
                swapTask.swapOperation == SwapOperation.EXACT_INPUT_ALL,
                task
            );

        uint256 len = tasks.length;
        result = new RouterResult[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                result[i] = tasks[i].toRouterResult();
            }
        }
    }

    function findOneTokenPath(
        address tokenIn,
        uint256 amount,
        address tokenOut,
        address creditAccount,
        address[] calldata connectors,
        uint256 slippage
    ) external override returns (RouterResult memory) {
        StrategyPathTask memory task = createStrategyPathTask(
            creditAccount,
            tokenOut,
            connectors,
            slippage,
            false
        );

        if (task.balances.getBalance(tokenIn) < amount) {
            task.balances.setBalance(tokenIn, amount);
        }

        uint8 ttIn = tokenTypes[tokenIn];
        uint8 ttOut = tokenTypes[task.target];
        task.targetType = ttOut;

        task.initSlippageControl();
        task = getResolver(ttIn, ttOut).findOneTokenPath(
            ttIn,
            tokenIn,
            amount,
            task
        );
        task.updateSlippageControl();

        return task.toRouterResult();
    }

    function findOpenStrategyPath(
        address creditManager,
        Balance[] calldata balances,
        address target,
        address[] calldata connectors,
        uint256 slippage
    ) external override returns (Balance[] memory, RouterResult memory) {
        StrategyPathTask memory task = createOpenStrategyPathTask(
            ICreditManagerV2(creditManager),
            balances,
            target,
            connectors,
            slippage
        );

        uint8 ttOut = tokenTypes[task.target];
        task.targetType = ttOut;

        task.initSlippageControl();

        task = getResolver(TT_NORMAL_TOKEN, ttOut).findOpenStrategyPath(task);

        task.updateSlippageControl(
            ICreditManagerV2(creditManager).creditFacade()
        );

        return (task.balances, task.toRouterResult());
    }

    function findBestClosePath(
        address creditAccount,
        address[] calldata connectors,
        uint256 slippage,
        PathOption[] memory pathOptions,
        uint256 loops,
        bool force
    ) external returns (RouterResult memory result, uint256 gasPriceTargetRAY) {
        ICreditManagerV2 creditManager = ICreditManagerV2(
            ICreditAccount(creditAccount).creditManager()
        );

        StrategyPathTask memory task = createStrategyPathTask(
            creditAccount,
            creditManager.underlying(),
            connectors,
            slippage,
            force
        );

        task.initSlippageControl();

        task = IClosePathResolver(componentAddressById[RC_CLOSE_PATH_RESOLVER])
            .findBestClosePath(task, pathOptions, loops);

        task.updateSlippageControl();
        return (task.toRouterResult(), task.gasPriceTargetRAY);
    }

    function getResolver(uint8 ttIn, uint8 ttOut)
        public
        view
        returns (IPathResolver)
    {
        return IPathResolver(componentAddressById[resolvers[ttIn][ttOut]]);
    }

    function isRouterConfigurator(address account)
        external
        view
        returns (bool)
    {
        return account == owner();
    }

    function createStrategyPathTask(
        address creditAccount,
        address target,
        address[] calldata connectors,
        uint256 slippage,
        bool force
    ) public view returns (StrategyPathTask memory task) {
        ICreditManagerV2 creditManager = ICreditManagerV2(
            ICreditAccount(creditAccount).creditManager()
        );

        Balance[] memory balances;

        uint256 len = creditManager.collateralTokensCount();
        balances = new Balance[](len);
        {
            for (uint256 i; i < len; ++i) {
                (address token, ) = creditManager.collateralTokens(i);
                uint256 balance = IERC20(token).balanceOf(creditAccount);
                balances[i] = Balance({
                    token: token,
                    balance: balance > 10 ? balance : 0
                });
            }
        }

        MultiCall[] memory calls;

        return
            StrategyPathTask({
                creditAccount: creditAccount,
                balances: balances,
                target: target,
                connectors: connectors,
                adapters: getAdapters(creditManager),
                foundAdapters: new TokenAdapters[](0),
                slippagePerStep: slippage,
                gasPriceTargetRAY: getGasPriceTokenOutRAY(target),
                initTargetBalance: 0,
                gasUsage: 0,
                targetType: tokenTypes[target],
                calls: calls,
                force: force
            });
    }

    function createOpenStrategyPathTask(
        ICreditManagerV2 creditManager,
        Balance[] calldata balances,
        address target,
        address[] calldata connectors,
        uint256 slippage
    ) public view returns (StrategyPathTask memory task) {
        MultiCall[] memory calls;

        return
            StrategyPathTask({
                creditAccount: address(0),
                balances: balances,
                target: target,
                connectors: connectors,
                adapters: getAdapters(creditManager),
                foundAdapters: new TokenAdapters[](0),
                slippagePerStep: slippage,
                gasPriceTargetRAY: getGasPriceTokenOutRAY(target),
                initTargetBalance: 0,
                gasUsage: 0,
                targetType: tokenTypes[target],
                calls: calls,
                force: false
            });
    }

    function getAdapters(ICreditManagerV2 creditManager)
        public
        view
        returns (address[] memory result)
    {
        ICreditConfigurator configurator = ICreditConfigurator(
            creditManager.creditConfigurator()
        );
        address[] memory allowedContracts = configurator.allowedContracts();

        uint256 len = allowedContracts.length;
        result = new address[](len);
        for (uint256 i; i < len; ) {
            result[i] = creditManager.contractToAdapter(allowedContracts[i]);
            unchecked {
                ++i;
            }
        }
    }

    ///
    /// CONFIGURATION
    ///

    function setPathComponentBatch(address[] memory componentAddresses)
        external
        onlyOwner
    {
        uint256 len = componentAddresses.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                _setPathComponent(componentAddresses[i]);
            }
        }

        _updatePathComponentsInResolvers();
    }

    function setPathComponent(address componentAddress) external onlyOwner {
        _setPathComponent(componentAddress);
        _updatePathComponentsInResolvers();
    }

    function _setPathComponent(address componentAddress) internal {
        try IRouterComponent(componentAddress).getComponentId() returns (
            uint8 pfc
        ) {
            if (componentAddressById[pfc] != componentAddress) {
                componentAddressById[pfc] = componentAddress;

                emit RouterComponentUpdate(pfc, componentAddress);
            }
        } catch {
            revert UnsupportedRouterComponent(componentAddress);
        }
    }

    function _updatePathComponentsInResolvers() internal {
        uint256 len = connectedResolvers.length();

        unchecked {
            for (uint256 i; i < len; ++i) {
                uint8 pfc = uint8(connectedResolvers.at(i));
                address resolver = componentAddressById[pfc];

                if (resolver != address(0)) {
                    ResolverConfigurator(resolver).updateComponents();
                }
            }
        }
    }

    function setTokenTypesBatch(TokenToTokenType[] memory tokensToTokenTypes)
        external
        onlyOwner
    {
        uint256 len = tokensToTokenTypes.length;
        for (uint256 i; i < len; i++) {
            _setTokenType(tokensToTokenTypes[i]);
        }
    }

    function _setTokenType(TokenToTokenType memory ttt) internal {
        if (tokenTypes[ttt.token] != ttt.tokenType) {
            tokenTypes[ttt.token] = ttt.tokenType;
            emit TokenTypeUpdate(ttt.token, ttt.tokenType);
        }
    }

    function setResolversBatch(
        TokenTypeToResolver[] calldata tokenTypeToResolvers
    ) external onlyOwner {
        uint256 len = tokenTypeToResolvers.length;
        for (uint256 i; i < len; i++) {
            _setResolver(tokenTypeToResolvers[i]);
        }
        _updatePathComponentsInResolvers();
    }

    function _setResolver(TokenTypeToResolver memory ttr) internal {
        if (resolvers[ttr.tokenType0][ttr.tokenType1] != ttr.resolver) {
            resolvers[ttr.tokenType0][ttr.tokenType1] = ttr.resolver;
            resolvers[ttr.tokenType1][ttr.tokenType0] = ttr.resolver;

            connectedResolvers.add(uint256(ttr.resolver));

            emit ResolverUpdate(ttr.tokenType0, ttr.tokenType1, ttr.resolver);
        }
    }
}