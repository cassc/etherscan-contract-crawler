// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFirstOwner {
    /**
     * @notice Returns the address of the first owner of the given `tokenId`.
     */
    function firstOwner(uint256 tokenId)
        external
        view
        returns (address payable);
}