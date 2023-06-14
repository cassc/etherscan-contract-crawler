// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPTokenFactory {
    
    /*** User Interface ***/
    function feeTo() external view returns(address);
    function beacon() external view returns(address);
    function controller() external view returns(address);
    function nftTransferManager() external view returns(address);
    function allNFTsLength() external view returns(uint256);
    function allNFTs(uint256 index) external view returns(address);
    function getNftAddress(address ptokenAddr) external view returns(address);
    function getPiece(address nftAddr) external view returns(address);
    function parameters() external view returns (address, bytes memory);
    function createPiece(address nftAddr) external returns(address pieceTokenAddr);

    /*** Admin Functions ***/
    function setFeeTo(address feeTo_) external;
}