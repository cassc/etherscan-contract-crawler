// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/IERC721A.sol";

interface IMurakamiLuckyCatCoinBank is IERC721A {
    function burn(uint256 tokenId) external;
}