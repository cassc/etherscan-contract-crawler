// SPDX-License-Identifier: MIT

// @title:     THROW STONE by Yusuke Hanai
// @desc:      A total of 1125 “THROW STONE” NFTs are airdropped exclusively for “People In The Place They Love” holders as community rewards, created by FWENCLUB. With 250 editions of 4 designs, this special digital art piece could be used to embellish your space as a fine detailed ornament in METAVERSE. 125  pieces of special edition will be reserved for wood panel raffle winners. The art is inspired by a notable sculpture by Yusuke Hanai, which he would like to applaud people who fight hard against tough times through this work.
// @twitter:   https://twitter.com/fwenclub
// @instagram: https://instagram.com/fwenclub
// @discord:   https://discord.gg/fwenclub
// @url:       https://www.fwenclub.com/

/*
* ███████╗░██╗░░░░░░░██╗███████╗███╗░░██╗░█████╗░██╗░░░░░██╗░░░██╗██████╗░
* ██╔════╝░██║░░██╗░░██║██╔════╝████╗░██║██╔══██╗██║░░░░░██║░░░██║██╔══██╗
* █████╗░░░╚██╗████╗██╔╝█████╗░░██╔██╗██║██║░░╚═╝██║░░░░░██║░░░██║██████╦╝
* ██╔══╝░░░░████╔═████║░██╔══╝░░██║╚████║██║░░██╗██║░░░░░██║░░░██║██╔══██╗
* ██║░░░░░░░╚██╔╝░╚██╔╝░███████╗██║░╚███║╚█████╔╝███████╗╚██████╔╝██████╦╝
* ╚═╝░░░░░░░░╚═╝░░░╚═╝░░╚══════╝╚═╝░░╚══╝░╚════╝░╚══════╝░╚═════╝░╚═════╝░
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../erc/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error MetadataFrozen();
error ExceedMaxSupply();
error RoyaltyPercentageExceed();
error ArrayLengthMismatch();

contract TSYH is ERC721, IERC2981, Ownable {
    using Strings for uint256;

    // ======== Royalties ==========
    address private _royaltyAddress;
    uint256 private _royaltyPercent;

    // =============== Supply ===============
    uint256 public constant maxSupply = 1125;
    uint256 public totalSupply;

    // ======= Metadata =======
    bool public metadataFrozen;
    string private _baseURI;

    /**
     * @dev Initializes the contract by setting royalty info.
     */
    constructor(address royaltyAddress ) {
        _royaltyAddress = royaltyAddress;
        _royaltyPercent = 6;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return "THROW STONE by Yusuke Hanai";
    }

    /**
     * @dev Returns the token collection symbol
     */
    function symbol() public view virtual override returns (string memory) {
        return "TSYH";
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets `metadataFrozen` true
     *
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function freezeMetadata() public virtual onlyOwner {
        metadataFrozen = true;
    }

    /**
     * @dev Sets base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     * @param baseURI base URI to set
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        if (metadataFrozen) { revert MetadataFrozen(); }
        _baseURI = baseURI;
    }

    /**
     * @dev Returns the URI for a given token ID
     * Throws if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) { revert NonExistentToken(); }
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Creates a new token for every address in `tos`. TokenIds will be automatically assigned
     * @param tos owners of new tokens
     *
     * Requirements:
     *
     * - `saleOn` must be false,
     * - the caller must be the contract owner.
     */
    function privateMint(address[] memory tos) external onlyOwner {
        for (uint256 i = 0; i < tos.length; i++) {
            _mint(tos[i], totalSupply + 1 + i);
        }
        totalSupply += tos.length;

        if (totalSupply > maxSupply) { revert ExceedMaxSupply(); }
    }

    /**
     * @dev Set royalty info for all tokens
     * @param royaltyReceiver address to receive royalty fee
     * @param royaltyPercentage percentage of royalty fee
     *
     * Requirements:
     *
     * - the caller must be the contract owner.
     */
    function setRoyaltyInfo(address royaltyReceiver, uint256 royaltyPercentage) public onlyOwner {
        if (royaltyPercentage > 100) { revert RoyaltyPercentageExceed(); }
        _royaltyAddress = royaltyReceiver;
        _royaltyPercent = royaltyPercentage;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount){
        if (!_exists(tokenId)) { revert NonExistentToken(); }
        return (_royaltyAddress, (salePrice * _royaltyPercent) / 100);
    }
}