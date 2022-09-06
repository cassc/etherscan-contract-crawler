// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct IncreaseWithV3FlashswapMultihopParams {
    uint256 principalAmount; // Amount that will be used as principal
    uint256 supplyAmount;
    uint256 maxBorrowAmount;
    address platform; // Lending platform
    address supplyToken; // Token to be supplied
    address borrowToken; // Token to be borrowed
    bytes path;
}

// Struct that is received by UniswapV3SwapCallback
struct SwapCallbackData {
    uint256 principalAmount;
    uint256 supplyAmount;
    uint256 maxBorrowAmount;
    address platform;
    bytes path;
}

struct FlashCallbackData {
    uint256 principalAmount;
    uint256 flashAmount;
    address platform;
    bytes path;
}

interface IIncreaseWithV3FlashswapMultihopConnector {
    function increasePositionWithV3FlashswapMultihop(IncreaseWithV3FlashswapMultihopParams calldata params) external;
}