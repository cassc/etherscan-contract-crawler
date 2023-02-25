// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface ICryptoPunks {
    function punkIndexToAddress(uint256 tokenId) external view returns(address);
}