// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";

interface IJarvisPool {
    struct MintParams {
        // Derivative to use
        address derivative;
        // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
        uint256 minNumTokens;
        // Amount of collateral that a user wants to spend for minting
        uint256 collateralAmount;
        // Maximum amount of fees in percentage that user is willing to pay
        uint256 feePercentage;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send synthetic tokens minted
        address recipient;
    }

    struct RedeemParams {
        // Derivative to use
        address derivative;
        // Amount of synthetic tokens that user wants to use for redeeming
        uint256 numTokens;
        // Minimium amount of collateral that user wants to redeem (anti-slippage)
        uint256 minCollateral;
        // Maximum amount of fees in percentage that user is willing to pay
        uint256 feePercentage;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send collateral tokens redeemed
        address recipient;
    }

    struct ExchangeParams {
        // Derivative of source pool
        address derivative;
        // Destination pool
        address destPool;
        // Derivative of destination pool
        address destDerivative;
        // Amount of source synthetic tokens that user wants to use for exchanging
        uint256 numTokens;
        // Minimum Amount of destination synthetic tokens that user wants to receive (anti-slippage)
        uint256 minDestNumTokens;
        // Maximum amount of fees in percentage that user is willing to pay
        uint256 feePercentage;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send synthetic tokens exchanged
        address recipient;
    }

    function mint(MintParams memory mintParams) external returns (uint256 syntheticTokensMinted, uint256 feePaid);

    function redeem(RedeemParams memory redeemParams) external returns (uint256 collateralRedeemed, uint256 feePaid);

    function exchange(ExchangeParams memory exchangeParams)
        external
        returns (uint256 destNumTokensMinted, uint256 feePaid);
}

contract Jarvis {
    enum MethodType {
        mint,
        redeem,
        exchange
    }

    struct JarvisData {
        uint256 opType;
        address derivatives;
        address destDerivatives;
        uint128 fee;
        address destPool;
        uint128 expiration;
    }

    function swapOnJarvis(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        JarvisData memory data = abi.decode(payload, (JarvisData));
        Utils.approve(exchange, address(fromToken), fromAmount);

        if (data.opType == uint256(MethodType.mint)) {
            IJarvisPool.MintParams memory mintParam = IJarvisPool.MintParams(
                data.derivatives,
                1,
                fromAmount,
                data.fee,
                data.expiration,
                address(this)
            );

            IJarvisPool(exchange).mint(mintParam);
        } else if (data.opType == uint256(MethodType.redeem)) {
            IJarvisPool.RedeemParams memory redeemParam = IJarvisPool.RedeemParams(
                data.derivatives,
                fromAmount,
                1,
                data.fee,
                data.expiration,
                address(this)
            );

            IJarvisPool(exchange).redeem(redeemParam);
        } else if (data.opType == uint256(MethodType.exchange)) {
            IJarvisPool.ExchangeParams memory exchangeParam = IJarvisPool.ExchangeParams(
                data.derivatives,
                data.destPool,
                data.destDerivatives,
                fromAmount,
                1,
                data.fee,
                data.expiration,
                address(this)
            );

            IJarvisPool(exchange).exchange(exchangeParam);
        } else {
            revert("Invalid opType");
        }
    }
}