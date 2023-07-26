// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IVoterID {
    /**
        Minting function
    */
    function createIdentityFor(address newId, uint tokenId, string memory uri) external;

    /**
        Who's in charge around here
    */
    function owner() external view returns (address);

    /**
        How many of these things exist?
    */
    function totalSupply() external view returns (uint);
}