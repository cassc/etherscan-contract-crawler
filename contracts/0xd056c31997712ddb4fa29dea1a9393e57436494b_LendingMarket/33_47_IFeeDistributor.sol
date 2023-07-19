//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface IFeeDistributor {
    event SalvageFees(
        address indexed token,
        uint256 indexed epoch,
        uint256 amount
    );

    event ClaimFees(
        address indexed receiver,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount
    );

    function checkpoint(address token) external;
}