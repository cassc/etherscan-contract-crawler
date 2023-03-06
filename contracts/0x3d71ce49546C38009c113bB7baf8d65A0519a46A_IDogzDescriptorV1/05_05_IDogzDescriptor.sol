// SPDX-License-Identifier: MIT

/*********************************
 *     __
 * o-''))_____\\
 *    "--__/ * * *)
 *      c_c__/-c____/
 *
 *          *
 *      *
 *********************************/

pragma solidity ^0.8.9;

interface IDogzDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}