// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ERC721Alien.sol";

/**
    @author GJK
    L for Lazy
    A genernal way to discover Lazy mint Token On Etherum
    Background: The high gas fee in ETH high(And will be higher and higher) force NFTers 
        almost stop Create/Trading NFT on ETH mainnet, 
        A free gas way of NFT should be consider as a option to adopt.

 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721L is ERC721Alien {
    using Strings for uint256;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_
    ) ERC721Alien(name_, symbol_, maxBatchSize_) {}

    /**
     * @dev return the collection Base MetaData URI
     */
    function getCollectionURI() public view virtual returns (string memory) {
        string memory collectionURI_ = _collectionBaseURI();
        if (bytes(collectionURI_).length > 0) {
            return collectionURI_;
        } else {
            return _baseURI();
        }
    }

    /**
     * @dev collection Base URI for computing {collectionURI}. If set, the resulting URI for collection Level return.
     * Empty by default, can be overriden in child contracts.
     */
    function _collectionBaseURI()
        internal
        view
        virtual
        returns (string memory)
    {
        return "";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Support LazyMint, to be query by standard way
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Returns whether `tokenId` exists.
     * Tokens start existing when they are minted (`_mint`),
     *
     * Can be Use to detect the TokenId is exist or not.
        If not exist, can be consider a lazy mint(If it should/can be minted, but not be minted yet)
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
}