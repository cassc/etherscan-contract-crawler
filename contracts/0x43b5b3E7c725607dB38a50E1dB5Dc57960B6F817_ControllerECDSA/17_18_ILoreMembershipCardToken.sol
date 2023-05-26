// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../nft/IOwnable.sol";

interface ILoreMembershipCardToken is IERC721Upgradeable, IOwnable {
    event LoreMembershipCardTransferred(address indexed squad, address indexed from, address indexed to, uint256 tokenId, bytes data);
    function setBaseURI(string memory newBaseURI) external;
    function setURIDescriptor(address newURIDescriptor) external;
    function mintBatch(address[] memory squads, address[] memory to) external;
    function mint(address _squad, address to) external;
    function adminTransfer(address from, address to, uint256 tokenId) external;
    function squadOfToken(uint256 tokenId) external view returns (address);
    function contractURI() external view returns (string memory);
    function tokenFor(address _squad, address owner) external view returns (uint256);
}