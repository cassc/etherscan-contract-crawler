/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev NFT ERC721 base contract
 *
 */
contract NFBaseToken is ERC721, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Constructor for NFBaseToken
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) public ERC721(_tokenName, _tokenSymbol) {
    }

}