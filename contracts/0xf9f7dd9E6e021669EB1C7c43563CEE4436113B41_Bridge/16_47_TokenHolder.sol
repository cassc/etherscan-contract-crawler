//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/// @title Token Holder
/// @notice This is a helper contract.
/// @author Piotr "pibu" Buda
abstract contract TokenHolder is ERC1155Holder, ERC721Holder {

}