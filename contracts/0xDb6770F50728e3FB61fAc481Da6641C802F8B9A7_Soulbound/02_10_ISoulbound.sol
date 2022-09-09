// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


interface ISoulbound is IERC165 {

    event SoulboundMinted(address indexed to);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function id(address owner) external view returns (uint256 id);

    function mint() external;

}