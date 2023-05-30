// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPolymorphicFacesRoot is IERC721 {

    function setMaxSupply(uint256 maxSupply) external;
}