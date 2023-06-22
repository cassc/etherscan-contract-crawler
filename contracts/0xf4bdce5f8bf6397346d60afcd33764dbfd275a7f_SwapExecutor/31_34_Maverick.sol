// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IMaverickPool {
    struct State {
        int32 activeTick;
        uint8 status;
        uint128 binCounter;
        uint64 protocolFeeRatio;
    }

    function getState() external view returns (State memory);

    function swap(
        address recipient,
        uint256 amount,
        bool tokenAIn,
        bool exactOutput,
        uint256 sqrtPriceLimit,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut);
}

interface IMaverickSwapCallback {
    function swapCallback(
        uint256 amountIn,
        uint256 amountOut,
        bytes calldata data
    ) external;
}

interface IMaverickFactory {
    function isFactoryPool(address pool) external view returns (bool);
}