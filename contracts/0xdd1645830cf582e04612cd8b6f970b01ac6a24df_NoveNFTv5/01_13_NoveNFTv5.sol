// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DefaultOperatorFilterer.sol";

/**
 /$$   /$$  /$$$$$$  /$$    /$$ /$$$$$$$$ /$$   /$$ /$$$$$$$$ /$$$$$$$$
| $$$ | $$ /$$__  $$| $$   | $$| $$_____/| $$$ | $$| $$_____/|__  $$__/
| $$$$| $$| $$  \ $$| $$   | $$| $$      | $$$$| $$| $$         | $$   
| $$ $$ $$| $$  | $$|  $$ / $$/| $$$$$   | $$ $$ $$| $$$$$      | $$   
| $$  $$$$| $$  | $$ \  $$ $$/ | $$__/   | $$  $$$$| $$__/      | $$   
| $$\  $$$| $$  | $$  \  $$$/  | $$      | $$\  $$$| $$         | $$   
| $$ \  $$|  $$$$$$/   \  $/   | $$$$$$$$| $$ \  $$| $$         | $$   
|__/  \__/ \______/     \_/    |________/|__/  \__/|__/         |__/   
 */

contract NoveNFTv5 is
    ERC721ABurnable,
    ReentrancyGuard,
    Ownable,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using ECDSA for bytes32;
    address private SIGNER = 0x1EFB5e6931d52D8c939D7ce54393A33fF7f6CFC7;

    // ======== MINT BATCH FLAG ========
    uint8 public currentMintBatch = 0;

    // ======== SUPPLY ========
    uint256 public MAX_SUPPLY = 8888;

    // ======== PRICE ========
    uint256 public whitelistPrice = 0.1 ether;
    uint256 public publicMintPrice = 0.12 ether;

     // ======== METADATA ========
    bool public isRevealed = false;
    string public _baseTokenURI;
    string public notRevealedURI;
    string public baseExtension = ".json";

    bytes32 constant HASH_1 = keccak256("BATCH_1");

    // ======== CONSTRUCTOR ========
    constructor() ERC721A("Nove NFT", "NOVE") {}

    // ======== MINTING whitelist Mint Batch 1 ========
    function whitelistMint(bytes memory _signature, uint256 _quantity)
        external
        payable
        mintBatchCheck(1)
        checkMintLimit(2)
        signerIsValid(HASH_1, _signature)
        withinSupply(_quantity)
        priceEthCheck(whitelistPrice, _quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    // ======== MINTING public Mint Batch 2 ========

    /**
    * @dev A function use to mint for public.
    */
    function publicMint(uint256 _quantity)
        external
        payable
        mintBatchCheck(2)
        withinSupply(_quantity)
        priceEthCheck(publicMintPrice, _quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    /**
    * @dev Allows the owner to mint for teams.
    */
    function teamMint(address[] calldata _to, uint256[] calldata _quantity)
        external
        onlyOwner
        checkTeamMintParameters(_to,_quantity)
    {
        for (uint256 i = 0; i < _to.length; i++) {
           _safeMint(_to[i], _quantity[i]);
        }
    }

    // ======== SETTERS ========

    /**
    * @dev Only owner sets the current Mint Batch.
    */
    function setCurrentMintBatch(uint8 _batch) 
        external onlyOwner 
    {
        currentMintBatch = _batch;
    }
     
    /**
    * @dev Only owner can set the new signer address.
    */
    function setSigner(address _newSigner)
        external
        onlyOwner
    {
        SIGNER = _newSigner;
    }
     
    /**
    * @dev Only owner can set the base URI.
    */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
     
    /**
    * @dev Only owner can set the max supply.
    */
    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    /**
    * @dev Only owner can set the whitelist price
    */
    function setWhitelistPrice(uint256 _whitelist)
        external
        onlyOwner
    {
        whitelistPrice = _whitelist;
    }
     
    /**
    * @dev Only owner can set the public price.
    */
    function setPublicPrice(uint256 _publicMintPrice)
        external
        onlyOwner
    {
        publicMintPrice = _publicMintPrice;
    }

    /**
    * @dev Only owner can set the not revealed URI.
    */
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setIsRevealed(bool _reveal) external onlyOwner {
        isRevealed = _reveal;
    }

    // ======== WITHDRAW ========

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // ========= GETTERS ===========

    /**
    * @dev A function to check the TokenURI if a particular tokenId.
    */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        if (!isRevealed) {
            return notRevealedURI;
        }

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    baseExtension
                )
            );
    }

    /**
    * @dev Internal function for retrieving the startTokenID.
    */
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    // ===== OPENSEA OVERRIDES =====

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A)  onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ===== MODIFIERS =====

    /**
    * @dev Checks the Team Mint Parameters.
    *  1. If the array of addresses are the same length of the array of quantity.
    *  2. If the total array of quantity doesn't exceed the max supply.
    */
    modifier checkTeamMintParameters(address[] calldata _to, uint256[] calldata _quantity) {
        require(_to.length == _quantity.length, "_to address and _quantity length Mismatch!");

        uint totalQuantity = 0;
        for(uint i; i < _quantity.length; ++i) {
            totalQuantity += _quantity[i];
        }

        require( totalSupply() + totalQuantity <= MAX_SUPPLY, "Exceeded max supply" );
        _;
    }

    /**
    * @dev A modifier to check if the quantity is within the range the Max Supply.
    */
    modifier withinSupply(uint256 _quantity) {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeded max supply");
        _;
    }

    /**
    * @dev A modifier function that checks the mint batch.
    */
    modifier mintBatchCheck(uint8 _mintBatch) {
        require(currentMintBatch == _mintBatch,"Incorrect mint batch");
        _;
    }

    /**
    * @dev A modifier function to check if the signer is valid.
    */
    modifier signerIsValid(bytes32 _hash, bytes memory _signature) {
        bytes32 messagehash = keccak256(
            abi.encodePacked(address(this), _hash, msg.sender)
        );
        address signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );
        require(signer == SIGNER, "Signature not valid");
        _;
    }

    /**
    * @dev A modifier function to check if the price is correct based on the quantity
    */
    modifier priceEthCheck(uint256 _price, uint256 _quantity) {
        require(msg.value >= (_price * _quantity), "Not enough eth sent");
        _;
    }

    /**
    * @dev A modifier function to check mint limit per wallet.
    */
    modifier checkMintLimit(uint _limit) {
        require(this.balanceOf(msg.sender) < _limit, "Exceeded max mint limit per Wallet");
        _;
    }
}