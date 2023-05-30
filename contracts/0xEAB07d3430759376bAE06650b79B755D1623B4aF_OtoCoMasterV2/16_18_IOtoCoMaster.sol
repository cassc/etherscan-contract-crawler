// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOtoCoMaster {

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev See {OtoCoMaster-baseFee}.
     */
    function baseFee() external view returns (uint256 fee);

    receive() external payable;
}