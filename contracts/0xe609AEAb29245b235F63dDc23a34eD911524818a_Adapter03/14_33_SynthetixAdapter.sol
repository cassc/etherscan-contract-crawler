// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";

interface ISynthetix {
    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint256 minAmount
    ) external returns (uint256 amountReceived);

    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);
}

abstract contract Synthetix {
    // Atomic exchanges work only with sTokens, so no need to wrap/unwrap them

    struct SynthetixData {
        bytes32 trackingCode;
        bytes32 srcCurrencyKey;
        bytes32 destCurrencyKey;
        // 0 - exchangeAtomically
        // 1 - exchange
        int8 exchangeType;
    }

    function swapOnSynthetix(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        SynthetixData memory synthetixData = abi.decode(payload, (SynthetixData));

        Utils.approve(exchange, address(fromToken), fromAmount);

        if (synthetixData.exchangeType == 0) {
            ISynthetix(exchange).exchangeAtomically(
                synthetixData.srcCurrencyKey,
                fromAmount,
                synthetixData.destCurrencyKey,
                synthetixData.trackingCode,
                1
            );
        } else {
            ISynthetix(exchange).exchange(synthetixData.srcCurrencyKey, fromAmount, synthetixData.destCurrencyKey);
        }
    }
}