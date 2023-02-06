// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IPassengersCrate is IERC1155Upgradeable {
    function mintToken(address to,uint256 tokenId) external;
    function burnToken(uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
}