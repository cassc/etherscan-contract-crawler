//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKaijuKingz is IERC721 {
    function maxSupply() external returns (uint256);
    function maxGenCount() external returns (uint256);
    function RWaste() external returns (address);
}