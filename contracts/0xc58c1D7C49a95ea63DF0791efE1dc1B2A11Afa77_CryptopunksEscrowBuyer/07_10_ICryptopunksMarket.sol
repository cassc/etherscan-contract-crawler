// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice The interface of functions for the Cryptopunks contract

 */
interface ICryptopunksMarket {
    function punkIndexToAddress(uint256 punkId) external view returns (address);

    function buyPunk(uint256 punkId) external payable;

    function transferPunk(address to, uint256 punkIndex) external;

    function getPunk(uint256 punkIndex) external;

    function setInitialOwner(address owner, uint256 punkId) external;

    function allInitialOwnersAssigned() external;

    function offerPunkForSale(uint256 punkId, uint256 price) external;
}