// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITuxERC20 {
    function mint(address to, uint256 amount) external;

    function feature(
        uint256 auctionId,
        uint256 amount,
        address from
    ) external;

    function cancel(
        uint256 auctionId,
        address from
    ) external;

    function updateFeatured() external;
    function payouts() external;
}