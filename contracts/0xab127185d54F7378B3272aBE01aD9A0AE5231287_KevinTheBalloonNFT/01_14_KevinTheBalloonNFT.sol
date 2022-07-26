// SPDX-License-Identifier: MIT
// Kevin (The Balloon) NFT v1.0.0
// Creator: The @Mankins Family

// _  _ ____ _  _ _ _  _     _  ___ _  _ ____    ___  ____ _    _    ____ ____ _  _  _
// |_/  |___ |  | | |\ |    |    |  |__| |___    |__] |__| |    |    |..| |  | |\ |   |
// | \_ |___  \/  | | \|    |_   |  |  | |___    |__] |  | |___ |___ |__| |__| | \|  _|
//                                                                     /
// https://www.kevintheballoon.com/                                   /

pragma solidity ^0.8.15;

import {ERC721AQueryable, ERC721A, IERC721A} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC2981, IERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title Kevin (The Balloon) NFT
 */
contract KevinTheBalloonNFT is
    ERC721A,
    ERC721AQueryable,
    ERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    /* ============ EVENTS ============ */
    event PriceChanged(uint256 value);
    event ProvenanceUpdated(string procenance);

    /* ============ VARS ============ */
    uint256 public mintPrice = 0.055 ether;
    uint256 public collectionSize = 12345;
    uint256 public freeMintCutoff = 1234; // after this many tokens, the free mints are disabled
    string public baseURI = "https://www.kevintheballoon.com/collection/kevin/";

    /* ============ PROVENANCE ============ */
    // Did anything change? provenance is defined by: sha256(concatOfAllImagesSha256SortedByEdition)
    string public provenance = "";

    /* ============ CONSTRUCTOR ============ */
    constructor() ERC721A("Kevin The Balloon", unicode"kevin🎈") {
        _setDefaultRoyalty(owner(), 500);
        _pause();
    }

    /* ============ ACCESS CONTROL/SANITY MODIFIERS ============ */
    modifier callerIsUser() {
        require(
            msg.sender == tx.origin,
            "Transactions from contracts not allowed"
        );
        _;
    }

    modifier canMintNFTs(uint256 quantity) {
        require(quantity > 0, "Invalid mint amount");
        require(
            totalSupply() + quantity <= collectionSize,
            "Supply would exceed collection size"
        );
        _;
    }

    modifier freeMintsAvailable(uint256 quantity) {
        // if the cutoff is set to 0, then free mints are disabled
        // if cutoff is set to collectionSize, then free mints are always available
        require(
            totalSupply() + quantity <= freeMintCutoff,
            "No more free mints"
        );
        _;
    }

    modifier isCorrectPayment(uint256 unitPrice, uint256 count) {
        require((unitPrice * count) <= msg.value, "Incorrect payment amount");
        _;
    }

    /* ============ OWNER-ONLY ADMIN FUNCTIONS ============ */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 newMintPrice) external onlyOwner {
        // Make it possible to change the mintPrice
        mintPrice = newMintPrice;
        emit PriceChanged(newMintPrice);
    }

    function setProvenance(string calldata _provenance) external onlyOwner {
        // shouldn't change...but mistakes happen emit for record
        provenance = _provenance;
        emit ProvenanceUpdated(_provenance);
    }

    function setFreeMintCutoff(uint256 _freemintCutoff) external onlyOwner {
        freeMintCutoff = _freemintCutoff;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /* ============ MINTING RELATED FUNCTIONS ============ */
    function airDropMint(uint256 quantity, address user)
        external
        canMintNFTs(quantity)
        nonReentrant
        onlyOwner
    {
        // airdrop the nft to user
        _safeMint(user, quantity);
    }

    function freeMint(uint256 quantity)
        external
        whenNotPaused
        canMintNFTs(quantity)
        freeMintsAvailable(quantity)
        nonReentrant
        callerIsUser
    {
        // allow the user to mint a limited number of free nfts
        require(quantity < 5, "max of 4 allowed at a time");
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity)
        external
        payable
        whenNotPaused
        canMintNFTs(quantity)
        isCorrectPayment(mintPrice, quantity)
        nonReentrant
        callerIsUser
    {
        // mint the nft to the caller, up to 50 per call
        require(quantity < 51, "max of 50 allowed");
        _safeMint(msg.sender, quantity);
    }

    /* ============ FUNCTION OVERRIDES ============ */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "URIQueryForNonexistentToken");
        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString(), ".json"))
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC721A, ERC2981, ERC721A)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721A, IERC721A)
        returns (bool isOperator)
    {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        // for Polygon's Mumbai testnet, use 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        // otherwise, use the default isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }
}