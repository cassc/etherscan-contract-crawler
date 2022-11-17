//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

/**
 * @dev Interface of the Base Registrar Implementation of ENS.
 */
interface IBaseRegistrarImplement {
    function reclaim(uint256 id, address owner) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}