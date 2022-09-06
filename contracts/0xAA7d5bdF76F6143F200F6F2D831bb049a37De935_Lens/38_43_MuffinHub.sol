// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/hub/IMuffinHub.sol";
import "./interfaces/IMuffinHubCallbacks.sol";
import "./libraries/utils/SafeTransferLib.sol";
import "./libraries/utils/PathLib.sol";
import "./libraries/math/Math.sol";
import "./libraries/Pools.sol";
import "./MuffinHubBase.sol";

contract MuffinHub is IMuffinHub, MuffinHubBase {
    using Math for uint256;
    using Pools for Pools.Pool;
    using Pools for mapping(bytes32 => Pools.Pool);
    using PathLib for bytes;

    error InvalidTokenOrder();
    error NotAllowedSqrtGamma();
    error InvalidSwapPath();
    error NotEnoughIntermediateOutput();
    error NotEnoughFundToWithdraw();

    /// @dev To reduce bytecode size of this contract, we offload position-related functions, governance functions and
    /// various view functions to a second contract (i.e. MuffinHubPositions.sol) and use delegatecall to call it.
    address internal immutable positionController;

    constructor(address _positionController) {
        positionController = _positionController;
        governance = msg.sender;
    }

    /*===============================================================
     *                           ACCOUNTS
     *==============================================================*/

    /// @inheritdoc IMuffinHubActions
    function deposit(
        address recipient,
        uint256 recipientAccRefId,
        address token,
        uint256 amount,
        bytes calldata data
    ) external {
        uint256 balanceBefore = getBalanceAndLock(token);
        IMuffinHubCallbacks(msg.sender).muffinDepositCallback(token, amount, data);
        checkBalanceAndUnlock(token, balanceBefore + amount);

        accounts[token][getAccHash(recipient, recipientAccRefId)] += amount;
        emit Deposit(recipient, recipientAccRefId, token, amount, msg.sender);
    }

    /// @inheritdoc IMuffinHubActions
    function withdraw(
        address recipient,
        uint256 senderAccRefId,
        address token,
        uint256 amount
    ) external {
        bytes32 accHash = getAccHash(msg.sender, senderAccRefId);
        uint256 balance = accounts[token][accHash];
        if (balance < amount) revert NotEnoughFundToWithdraw();
        unchecked {
            accounts[token][accHash] = balance - amount;
        }
        SafeTransferLib.safeTransfer(token, recipient, amount);
        emit Withdraw(msg.sender, senderAccRefId, token, amount, recipient);
    }

    /*===============================================================
     *                      CREATE POOL / TIER
     *==============================================================*/

    /// @notice Check if the given sqrtGamma is allowed to be used to create a pool or tier
    /// @dev It first checks if the sqrtGamma is in the whitelist, then check if the pool hasn't had that fee tier created.
    function isSqrtGammaAllowed(bytes32 poolId, uint24 sqrtGamma) public view returns (bool) {
        uint24[] storage allowed = poolAllowedSqrtGammas[poolId].length != 0
            ? poolAllowedSqrtGammas[poolId]
            : defaultAllowedSqrtGammas;
        unchecked {
            for (uint256 i; i < allowed.length; i++) {
                if (allowed[i] == sqrtGamma) {
                    Tiers.Tier[] storage tiers = pools[poolId].tiers;
                    for (uint256 j; j < tiers.length; j++) if (tiers[j].sqrtGamma == sqrtGamma) return false;
                    return true;
                }
            }
        }
        return false;
    }

    /// @inheritdoc IMuffinHubActions
    function createPool(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        uint256 senderAccRefId
    ) external returns (bytes32 poolId) {
        if (token0 >= token1 || token0 == address(0)) revert InvalidTokenOrder();

        Pools.Pool storage pool;
        (pool, poolId) = pools.getPoolAndId(token0, token1);
        if (!isSqrtGammaAllowed(poolId, sqrtGamma)) revert NotAllowedSqrtGamma();

        uint8 tickSpacing = poolDefaultTickSpacing[poolId];
        if (tickSpacing == 0) tickSpacing = defaultTickSpacing;
        (uint256 amount0, uint256 amount1) = pool.initialize(sqrtGamma, sqrtPrice, tickSpacing, defaultProtocolFee);
        accounts[token0][getAccHash(msg.sender, senderAccRefId)] -= amount0;
        accounts[token1][getAccHash(msg.sender, senderAccRefId)] -= amount1;

        emit PoolCreated(token0, token1, poolId);
        emit UpdateTier(poolId, 0, sqrtGamma, sqrtPrice, 1);
        pool.unlock();
        underlyings[poolId] = Pair(token0, token1);
    }

    /// @inheritdoc IMuffinHubActions
    function addTier(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint256 senderAccRefId
    ) external returns (uint8 tierId) {
        (Pools.Pool storage pool, bytes32 poolId) = pools.getPoolAndId(token0, token1);
        if (!isSqrtGammaAllowed(poolId, sqrtGamma)) revert NotAllowedSqrtGamma();

        uint256 amount0;
        uint256 amount1;
        (amount0, amount1, tierId) = pool.addTier(sqrtGamma);
        accounts[token0][getAccHash(msg.sender, senderAccRefId)] -= amount0;
        accounts[token1][getAccHash(msg.sender, senderAccRefId)] -= amount1;

        emit UpdateTier(poolId, tierId, sqrtGamma, pool.tiers[tierId].sqrtPrice, 0);
        pool.unlock();
    }

    /*===============================================================
     *                            SWAP
     *==============================================================*/

    /// @inheritdoc IMuffinHubActions
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired,
        address recipient,
        uint256 recipientAccRefId,
        uint256 senderAccRefId,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut) {
        Pools.Pool storage pool;
        (pool, , amountIn, amountOut) = _computeSwap(
            tokenIn,
            tokenOut,
            tierChoices,
            amountDesired,
            SwapEventVars(senderAccRefId, recipient, recipientAccRefId)
        );
        _transferSwap(tokenIn, tokenOut, amountIn, amountOut, recipient, recipientAccRefId, senderAccRefId, data);
        pool.unlock();
    }

    /// @inheritdoc IMuffinHubActions
    function swapMultiHop(SwapMultiHopParams calldata p) external returns (uint256 amountIn, uint256 amountOut) {
        bytes memory path = p.path;
        if (path.invalid()) revert InvalidSwapPath();

        bool exactIn = p.amountDesired > 0;
        bytes32[] memory poolIds = new bytes32[](path.hopCount());
        unchecked {
            int256 amtDesired = p.amountDesired;
            SwapEventVars memory evtData = exactIn
                ? SwapEventVars(p.senderAccRefId, msg.sender, p.senderAccRefId)
                : SwapEventVars(p.senderAccRefId, p.recipient, p.recipientAccRefId);

            for (uint256 i; i < poolIds.length; i++) {
                if (exactIn) {
                    if (i == poolIds.length - 1) {
                        evtData.recipient = p.recipient;
                        evtData.recipientAccRefId = p.recipientAccRefId;
                    }
                } else {
                    if (i == 1) {
                        evtData.recipient = msg.sender;
                        evtData.recipientAccRefId = p.senderAccRefId;
                    }
                }

                (address tokenIn, address tokenOut, uint256 tierChoices) = path.decodePool(i, exactIn);

                // For an "exact output" swap, it's possible to not receive the full desired output amount. therefore, in
                // the 2nd (and following) swaps, we request more token output so as to ensure we get enough tokens to pay
                // for the previous swap. The extra token is not refunded and thus results in an extra cost (small in common
                // token pairs).
                uint256 amtIn;
                uint256 amtOut;
                (, poolIds[i], amtIn, amtOut) = _computeSwap(
                    tokenIn,
                    tokenOut,
                    tierChoices,
                    (exactIn || i == 0) ? amtDesired : amtDesired - Pools.SWAP_AMOUNT_TOLERANCE,
                    evtData
                );

                if (exactIn) {
                    if (i == 0) amountIn = amtIn;
                    amtDesired = int256(amtOut);
                } else {
                    if (i == 0) amountOut = amtOut;
                    else if (amtOut < uint256(-amtDesired)) revert NotEnoughIntermediateOutput();
                    amtDesired = -int256(amtIn);
                }
            }
            if (exactIn) {
                amountOut = uint256(amtDesired);
            } else {
                amountIn = uint256(-amtDesired);
            }
        }
        (address _tokenIn, address _tokenOut) = path.tokensInOut(exactIn);
        _transferSwap(_tokenIn, _tokenOut, amountIn, amountOut, p.recipient, p.recipientAccRefId, p.senderAccRefId, p.data);
        unchecked {
            for (uint256 i; i < poolIds.length; i++) pools[poolIds[i]].unlock();
        }
    }

    /// @dev Data to emit in "Swap" event in "_computeSwap" function
    struct SwapEventVars {
        uint256 senderAccRefId;
        address recipient;
        uint256 recipientAccRefId;
    }

    function _computeSwap(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired, // Desired swap amount (positive: exact input, negative: exact output)
        SwapEventVars memory evtData
    )
        internal
        returns (
            Pools.Pool storage pool,
            bytes32 poolId,
            uint256 amountIn,
            uint256 amountOut
        )
    {
        bool isExactIn = tokenIn < tokenOut;
        bool isToken0 = (amountDesired > 0) == isExactIn; // i.e. isToken0In == isExactIn
        (pool, poolId) = isExactIn ? pools.getPoolAndId(tokenIn, tokenOut) : pools.getPoolAndId(tokenOut, tokenIn);
        Pools.SwapResult memory result = pool.swap(isToken0, amountDesired, tierChoices, poolId);

        emit Swap(
            poolId,
            msg.sender,
            evtData.recipient,
            evtData.senderAccRefId,
            evtData.recipientAccRefId,
            result.amount0,
            result.amount1,
            result.amountInDistribution,
            result.amountOutDistribution,
            result.tierData
        );

        unchecked {
            // overflow is acceptable and protocol is expected to collect protocol fee before overflow
            if (result.protocolFeeAmt != 0) tokens[tokenIn].protocolFeeAmt += uint248(result.protocolFeeAmt);
            (amountIn, amountOut) = isExactIn
                ? (uint256(result.amount0), uint256(-result.amount1))
                : (uint256(result.amount1), uint256(-result.amount0));
        }
    }

    function _transferSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient,
        uint256 recipientAccRefId,
        uint256 senderAccRefId,
        bytes calldata data
    ) internal {
        if (tokenIn == tokenOut) {
            (amountIn, amountOut) = amountIn.subUntilZero(amountOut);
        }
        if (recipientAccRefId == 0) {
            SafeTransferLib.safeTransfer(tokenOut, recipient, amountOut);
        } else {
            accounts[tokenOut][getAccHash(recipient, recipientAccRefId)] += amountOut;
        }
        if (senderAccRefId != 0) {
            bytes32 accHash = getAccHash(msg.sender, senderAccRefId);
            (accounts[tokenIn][accHash], amountIn) = accounts[tokenIn][accHash].subUntilZero(amountIn);
        }
        if (amountIn > 0) {
            uint256 balanceBefore = getBalanceAndLock(tokenIn);
            IMuffinHubCallbacks(msg.sender).muffinSwapCallback(tokenIn, tokenOut, amountIn, amountOut, data);
            checkBalanceAndUnlock(tokenIn, balanceBefore + amountIn);
        }
    }

    /*===============================================================
     *                         VIEW FUNCTIONS
     *==============================================================*/

    /// @inheritdoc IMuffinHubView
    function getDefaultParameters() external view returns (uint8 tickSpacing, uint8 protocolFee) {
        return (defaultTickSpacing, defaultProtocolFee);
    }

    /// @inheritdoc IMuffinHubView
    function getPoolParameters(bytes32 poolId) external view returns (uint8 tickSpacing, uint8 protocolFee) {
        Pools.Pool storage pool = pools[poolId];
        return (pool.tickSpacing, pool.protocolFee);
    }

    /// @inheritdoc IMuffinHubView
    function getTier(bytes32 poolId, uint8 tierId) external view returns (Tiers.Tier memory) {
        return pools[poolId].tiers[tierId];
    }

    /// @inheritdoc IMuffinHubView
    function getTiersCount(bytes32 poolId) external view returns (uint256) {
        return pools[poolId].tiers.length;
    }

    /// @inheritdoc IMuffinHubView
    function getTick(
        bytes32 poolId,
        uint8 tierId,
        int24 tick
    ) external view returns (Ticks.Tick memory) {
        return pools[poolId].ticks[tierId][tick];
    }

    /// @inheritdoc IMuffinHubView
    function getPosition(
        bytes32 poolId,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (Positions.Position memory) {
        return Positions.get(pools[poolId].positions, owner, positionRefId, tierId, tickLower, tickUpper);
    }

    /// @inheritdoc IMuffinHubView
    function getStorageAt(bytes32 slot) external view returns (bytes32 word) {
        assembly {
            word := sload(slot)
        }
    }

    /*===============================================================
     *                FALLBACK TO POSITION CONTROLLER
     *==============================================================*/

    /// @dev Adapted from openzepplin v4.4.1 proxy implementation
    fallback() external {
        address _positionController = positionController;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _positionController, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}