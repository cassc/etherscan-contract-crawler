// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./proxies/VestingEntryNFTProxy.sol";

/**
 * Manages deployment of vesting entry nft proxies
 * NFTs are deployed on pool deployment
 * They keep track of vesting entries for user
 */
contract NFTDeployer {
    address public vestingEntryNFTImplementation;

    constructor(address _vestingEntryNFTImplementation) {
        vestingEntryNFTImplementation = _vestingEntryNFTImplementation;
    }

    function deployVestingEntryNFT() external returns (address pool) {
        VestingEntryNFTProxy proxy = new VestingEntryNFTProxy(
            vestingEntryNFTImplementation
        );
        return address(proxy);
    }
}