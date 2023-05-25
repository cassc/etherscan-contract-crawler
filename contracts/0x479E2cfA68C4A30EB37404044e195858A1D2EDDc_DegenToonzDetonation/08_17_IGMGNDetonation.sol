//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/IERC721A.sol";

interface IGMGNDetonation is IERC721A {
    function tokenData(uint256 _tokenId) view external returns (uint256, uint256);
}