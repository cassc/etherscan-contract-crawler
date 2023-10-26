// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Provision} from "../DataStructure/Storage.sol";

interface ISupplyPositionFacet is IERC721 {
    function position(uint256) external view returns (Provision memory);

    function totalSupply() external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}