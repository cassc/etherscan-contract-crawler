//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IVestingEntryNFT {
    struct VestingAmounts {
        uint256 tokenAmount; // total amount to be claimed at end of vesting
        uint256 tokenAmountClaimed; // already claimed token amount
    }

    function mint(
        address from,
        uint256 tokenId,
        VestingAmounts memory vestingAmounts
    ) external;
}