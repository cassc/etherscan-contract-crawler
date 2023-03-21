// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IERC4906 {
    event MetadataUpdate(uint256 tokenID);

    event BatchMetadataUpdate(uint256 fromTokenID, uint256 toTokenID);
}