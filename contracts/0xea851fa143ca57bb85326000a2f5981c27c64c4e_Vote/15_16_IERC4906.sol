// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC4906 is IERC165, IERC721 {
	event MetadataUpdate(uint256 _tokenId);
	event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}