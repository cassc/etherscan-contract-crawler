// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";

interface IESVSP721 is IERC721Enumerable {
    function mint(address to_) external returns (uint256);

    function burn(uint256 tokenId_) external;
}