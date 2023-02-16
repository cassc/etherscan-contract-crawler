//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "./BTVLiquidity.sol";

import {Base64} from "../libraries/Base64.sol";

/**
 * @dev Interface of the BTV Encapsulator for as many unique ERC-20/NFT pairs as possible.
 */
abstract contract IBTVEncapsulator {
    function tokenContractOf(uint256 typeId) public view virtual returns (address);

    /**
     * @dev Mints {amount} of NFTs of {type ID}.
     * @param typeId is the index of the item type.
     * @param amount of NFTs to be minted
     */
    function swapForNFT(uint256 typeId, uint256 amount, address to) public virtual;
}