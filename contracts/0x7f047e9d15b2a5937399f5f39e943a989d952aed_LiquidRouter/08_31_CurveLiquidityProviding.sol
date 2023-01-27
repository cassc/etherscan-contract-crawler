// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {ICurvePool} from "src/interfaces/ICurvePool.sol";
import {IZapper3CRV} from "src/interfaces/IZapper3CRV.sol";
import {TokenUtils, Constants} from "src/common/TokenUtils.sol";
import {IZapperFraxBPCrypto} from "src/interfaces/IZapperFraxBPCrypto.sol";
import {IZapperFraxBPStable} from "src/interfaces/IZapperFraxBPStable.sol";

/// @title CurveLiquidityProviding
/// @notice Enables to add/remove liquidity to/from Curve pools.
abstract contract CurveLiquidityProviding {
    /// @notice Curve 3CRV Zap contract address.
    address internal constant ZAP_THREE_POOL = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    /// @notice Curve FraxBP Zap contract address.
    address internal constant ZAP_FRAX_STABLE = 0x08780fb7E580e492c1935bEe4fA5920b94AA95Da;

    /// @notice Curve FraxBP Crypto Zap contract address.
    address internal constant ZAP_FRAX_CRYPTO = 0x5De4EF4879F4fe3bBADF2227D2aC5d0E2D76C895;

    /// @notice Adds liquidity to the Curve 2 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidity(
        address pool,
        address[2] calldata tokens,
        address lpToken,
        uint256[2] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external payable {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        uint256 amountETH;
        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (tokens[i] == Constants._ETH) amountETH = underlyingAmounts[i];
            else if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], pool);
            unchecked {
                ++i;
            }
        }

        ICurvePool(pool).add_liquidity{value: amountETH}(underlyingAmounts, minMintAmount);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 3 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidity(
        address pool,
        address[3] calldata tokens,
        address lpToken,
        uint256[3] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external payable {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        uint256 amountETH;
        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (tokens[i] == Constants._ETH) amountETH = underlyingAmounts[i];
            else if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], pool);
            unchecked {
                ++i;
            }
        }

        ICurvePool(pool).add_liquidity{value: amountETH}(underlyingAmounts, minMintAmount);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 4 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidity(
        address pool,
        address[4] calldata tokens,
        address lpToken,
        uint256[4] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external payable {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        uint256 amountETH;
        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (tokens[i] == Constants._ETH) amountETH = underlyingAmounts[i];
            else if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], pool);
            unchecked {
                ++i;
            }
        }

        ICurvePool(pool).add_liquidity{value: amountETH}(underlyingAmounts, minMintAmount);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 3 pool using FraxBP Stable Zap.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidityFraxStable(
        address pool,
        address[3] calldata tokens,
        address lpToken,
        uint256[3] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], ZAP_FRAX_STABLE);
            unchecked {
                ++i;
            }
        }
        IZapperFraxBPStable(ZAP_FRAX_STABLE).add_liquidity(pool, underlyingAmounts, minMintAmount, recipient);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 3 pool using FraxBP Crypto Zap.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    function addLiquidityFraxCrypto(
        address pool,
        address[3] calldata tokens,
        address lpToken,
        uint256[3] memory underlyingAmounts,
        uint256 minMintAmount,
        bool useEth,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], ZAP_FRAX_CRYPTO);
            unchecked {
                ++i;
            }
        }
        IZapperFraxBPCrypto(ZAP_FRAX_CRYPTO).add_liquidity(pool, underlyingAmounts, minMintAmount, useEth, recipient);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 3 pool using Curve Zap.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidityThreePool(
        address pool,
        address[4] calldata tokens,
        address lpToken,
        uint256[4] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], ZAP_THREE_POOL);
            unchecked {
                ++i;
            }
        }
        IZapper3CRV(ZAP_THREE_POOL).add_liquidity(pool, underlyingAmounts, minMintAmount, recipient);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Removes liquidity from a Curve 2 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidity(
        address pool,
        address[2] calldata tokens,
        address lpToken,
        uint256 underlyingAmount,
        uint256[2] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        ICurvePool(pool).remove_liquidity(underlyingAmount, minAmounts);

        for (uint8 i; i < tokens.length;) {
            TokenUtils._transfer(tokens[i], recipient, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Removes liquidity from a Curve 3 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidity(
        address pool,
        address[3] calldata tokens,
        address lpToken,
        uint256 underlyingAmount,
        uint256[3] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        ICurvePool(pool).remove_liquidity(underlyingAmount, minAmounts);

        for (uint8 i; i < tokens.length;) {
            TokenUtils._transfer(tokens[i], recipient, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Removes liquidity from a Curve 4 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidity(
        address pool,
        address[4] calldata tokens,
        address lpToken,
        uint256 underlyingAmount,
        uint256[4] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        ICurvePool(pool).remove_liquidity(underlyingAmount, minAmounts);

        for (uint8 i; i < tokens.length;) {
            TokenUtils._transfer(tokens[i], recipient, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Removes liquidity from a Curve pool into a single token.
    /// @param pool Curve pool address.
    /// @param index Index of the token to receive.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmount Minimum amount of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityOneCoin(
        address pool,
        int128 index,
        address lpToken,
        uint256 underlyingAmount,
        uint256 minAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        ICurvePool(pool).remove_liquidity_one_coin(underlyingAmount, index, minAmount);

        address token = ICurvePool(pool).coins(uint8(int8(index)));
        TokenUtils._transfer(token, recipient, type(uint256).max);
    }

    /// @notice Removes liquidity from FraxBP stable pool.
    /// @param pool Curve pool address.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityFraxStable(
        address pool,
        address lpToken,
        uint256 underlyingAmount,
        uint256[3] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_FRAX_STABLE);

        IZapperFraxBPStable(ZAP_FRAX_STABLE).remove_liquidity(pool, underlyingAmount, minAmounts, recipient);
    }

    /// @notice Removes liquidity from FraxBP stable pool into a single token.
    /// @param pool Curve pool address.
    /// @param index Index of the token to receive.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmount Minimum amount of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityFraxStableOneCoin(
        address pool,
        int128 index,
        address lpToken,
        uint256 underlyingAmount,
        uint256 minAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_FRAX_STABLE);

        IZapperFraxBPStable(ZAP_FRAX_STABLE).remove_liquidity_one_coin(
            pool, underlyingAmount, index, minAmount, recipient
        );
    }

    /// @notice Removes liquidity from FraxBP crypto pool.
    /// @param pool Curve pool address.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param useEth Whether to use ETH or WETH.
    /// @param recipient Recipient address.
    function removeLiquidityFraxCrypto(
        address pool,
        address lpToken,
        uint256 underlyingAmount,
        uint256[3] calldata minAmounts,
        bool useEth,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_FRAX_CRYPTO);

        IZapperFraxBPCrypto(ZAP_FRAX_CRYPTO).remove_liquidity(pool, underlyingAmount, minAmounts, useEth, recipient);
    }

    /// @notice Removes liquidity from FraxBP crypto pool into a single token.
    /// @param pool Curve pool address.
    /// @param index Index of the token to receive.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmount Minimum amount of tokens to receive.
    /// @param useEth Whether to use ETH or WETH.
    /// @param recipient Recipient address.
    function removeLiquidityFraxCryptoOneCoin(
        address pool,
        uint256 index,
        address lpToken,
        uint256 underlyingAmount,
        uint256 minAmount,
        bool useEth,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_FRAX_CRYPTO);

        IZapperFraxBPCrypto(ZAP_FRAX_CRYPTO).remove_liquidity_one_coin(
            pool, underlyingAmount, index, minAmount, useEth, recipient
        );
    }

    /// @notice Removes liquidity from 3CRV pool.
    /// @param pool Curve pool address.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityThreePool(
        address pool,
        address lpToken,
        uint256 underlyingAmount,
        uint256[4] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_THREE_POOL);

        IZapper3CRV(ZAP_THREE_POOL).remove_liquidity(pool, underlyingAmount, minAmounts, recipient);
    }

    /// @notice Removes liquidity from 3CRV pool into a single token.
    /// @param pool Curve pool address.
    /// @param index Index of the token to receive.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmount Minimum amount of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityThreePoolOneCoin(
        address pool,
        int128 index,
        address lpToken,
        uint256 underlyingAmount,
        uint256 minAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_THREE_POOL);

        IZapper3CRV(ZAP_THREE_POOL).remove_liquidity_one_coin(pool, underlyingAmount, index, minAmount, recipient);
    }
}