// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IQueensAndKingsAvatars is IERC721 {
    function mint(uint256 _tokenId, address _to) external payable;

    function removeTrait(uint16 _tokenId) external;

    function internalToExternalMapping(uint16 _iTokenId) external view returns (uint256);
}