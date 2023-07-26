// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

interface IArtxchainsERC1155 {
    function setRoyaltyInfo(uint256 _tokenId, uint256 royaltyPercentage, address royaltyReceiver) external;
    function mint(address account, uint256 id, uint256 amount, uint256 royaltyPercentage, bytes memory data) external;
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}