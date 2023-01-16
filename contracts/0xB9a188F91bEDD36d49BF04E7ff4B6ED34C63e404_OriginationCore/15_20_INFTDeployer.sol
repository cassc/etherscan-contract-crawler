//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface INFTDeployer {
    function vestingEntryNFTImplementation() external view returns (address);

    function deployVestingEntryNFT() external returns (address nft);
}