// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IReferralVault {
    function getCodeId(string memory code, address player)
        external
        view
        returns (uint256);

    function deposit(
        uint256 amount,
        address player,
        address token,
        uint256 nftId
    ) external;

    function getReferralShare(uint256 nftId) external view returns (uint256);
}