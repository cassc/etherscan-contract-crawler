// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKingzInTheShell is IERC721 {
    function isHolder(address) external view returns (bool);
}