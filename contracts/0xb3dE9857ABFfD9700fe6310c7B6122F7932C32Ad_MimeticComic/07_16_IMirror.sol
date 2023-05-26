// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMirror {
    function ownerOf(uint256 tokenId_) 
        external 
        view 
        returns (
            address
        );

    function isOwnerOf(
          address account
        , uint256[] calldata _tokenIds
    ) 
        external 
        view 
        returns (
            bool
        );
}