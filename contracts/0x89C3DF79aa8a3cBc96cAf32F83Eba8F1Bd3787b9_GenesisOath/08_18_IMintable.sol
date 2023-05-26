// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

pragma solidity ^0.8.0;

interface IMintable is IERC1155, IERC1155MetadataURI {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    function setURI(uint256 tokenId, string calldata uri) external;

    function totalSupply(uint256 id) external view returns (uint256);
}