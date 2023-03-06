// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;

interface IAuction {
    function timeRebalance(
        address keeper,
        uint256 minAmountEth,
        uint256 minAmountUsdc,
        uint256 minAmountOsqth
    ) external;

    function priceRebalance(
        address keeper,
        uint256 auctionTriggerTime,
        uint256 minAmountEth,
        uint256 minAmountUsdc,
        uint256 minAmountOsqth
    ) external;

    function getParams(uint256 _auctionTriggerTime)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}