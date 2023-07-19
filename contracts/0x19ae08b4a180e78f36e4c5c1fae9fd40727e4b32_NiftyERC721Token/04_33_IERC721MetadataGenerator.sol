// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface IERC721MetadataGenerator is IERC165 {    
    function tokenMetadata(uint256 tokenId, uint256 niftyType, bytes calldata data) external view returns (string memory);
}