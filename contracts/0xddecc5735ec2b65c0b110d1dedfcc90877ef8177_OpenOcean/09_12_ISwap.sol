// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

interface ISwap {
    struct GetExpectedReturnParams {
        uint256 srcAmount;
        address[] tradePath;
        uint256 feeBps;
        bytes extraArgs;
    }

    function getExpectedReturn(GetExpectedReturnParams calldata params)
        external
        view
        returns (uint256 destAmount);

    function getExpectedReturnWithImpact(GetExpectedReturnParams calldata params)
        external
        view
        returns (uint256 destAmount, uint256 priceImpact);

    struct GetExpectedInParams {
        uint256 destAmount;
        address[] tradePath;
        uint256 feeBps;
        bytes extraArgs;
    }

    function getExpectedIn(GetExpectedInParams calldata params)
        external
        view
        returns (uint256 srcAmount);

    function getExpectedInWithImpact(GetExpectedInParams calldata params)
        external
        view
        returns (uint256 srcAmount, uint256 priceImpact);

    struct SwapParams {
        uint256 srcAmount;
        uint256 minDestAmount;
        address[] tradePath;
        address recipient;
        uint256 feeBps;
        address payable feeReceiver;
        bytes extraArgs;
    }

    function swap(SwapParams calldata params) external payable returns (uint256 destAmount);
}