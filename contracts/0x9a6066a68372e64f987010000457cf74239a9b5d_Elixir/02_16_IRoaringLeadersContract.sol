// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRoaringLeadersContract is IERC721 {

    function burnForElixir(uint256 tokenId) external;
}