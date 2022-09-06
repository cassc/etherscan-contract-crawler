// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct DecreaseWithV3FlashswapMultihopConnectorParams {
    uint256 withdrawAmount; // Amount that will be withdrawn
    uint256 maxSupplyTokenRepayAmount; // Max amount of supply that will be used to repay the debt (slippage is enforced here)
    uint256 borrowTokenRepayAmount; // Amount of debt that will be repaid
    address platform; // Lending platform
    address supplyToken; // Token to be supplied
    address borrowToken; // Token to be borrowed
    bytes path;
}

// Struct that is received by UniswapV3SwapCallback
struct SwapCallbackData {
    uint256 withdrawAmount;
    uint256 maxSupplyTokenRepayAmount;
    uint256 borrowTokenRepayAmount;
    uint256 positionDebt;
    address platform;
    address lender;
    bytes path;
}

struct FlashCallbackData {
    uint256 withdrawAmount;
    uint256 repayAmount;
    uint256 positionDebt;
    address platform;
    address lender;
    bytes path;
}

interface IDecreaseWithV3FlashswapMultihopConnector {
    function decreasePositionWithV3FlashswapMultihop(DecreaseWithV3FlashswapMultihopConnectorParams calldata params)
        external;
}