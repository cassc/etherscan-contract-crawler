// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC721Beacon.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title ArttacaERC721Beacon
 * @dev This contract is a the Beacon to proxy Arttaca ERC721 collections.
 */
contract ArttacaERC721Beacon is UpgradeableBeacon {
    constructor(address _initBlueprint) UpgradeableBeacon(_initBlueprint) {
        transferOwnership(tx.origin);
    }
}