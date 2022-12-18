// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoomNFT {
    function mint(
        address _to, 
        uint256 _uid, 
        string memory _uri
    ) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}