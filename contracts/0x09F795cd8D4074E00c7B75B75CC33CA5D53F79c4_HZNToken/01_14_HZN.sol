// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DefaultOperatorFilterer.sol";

/*
hhhhhhh
h:::::h
h:::::h
h:::::h
 h::::h hhhhh       zzzzzzzzzzzzzzzzznnnn  nnnnnnnn
 h::::hh:::::hhh    z:::::::::::::::zn:::nn::::::::nn
 h::::::::::::::hh  z::::::::::::::z n::::::::::::::nn
 h:::::::hhh::::::h zzzzzzzz::::::z  nn:::::::::::::::n
 h::::::h   h::::::h      z::::::z     n:::::nnnn:::::n
 h:::::h     h:::::h     z::::::z      n::::n    n::::n
 h:::::h     h:::::h    z::::::z       n::::n    n::::n
 h:::::h     h:::::h   z::::::z        n::::n    n::::n
 h:::::h     h:::::h  z::::::zzzzzzzz  n::::n    n::::n
 h:::::h     h:::::h z::::::::::::::z  n::::n    n::::n
 h:::::h     h:::::hz:::::::::::::::z  n::::n    n::::n
 hhhhhhh     hhhhhhhzzzzzzzzzzzzzzzzz  nnnnnn    nnnnnn
*/

contract HZNToken is
    ERC721ABurnable,
    ReentrancyGuard,
    Ownable,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using ECDSA for bytes32;

    mapping(address => bool) private whitelistMintAddresses;
    mapping(address => bool) private waitlistMintAddress;

    bytes32 constant HASH_1 = keccak256("BATCH_1");
    bytes32 constant HASH_2 = keccak256("BATCH_2");
    address constant SIGNER = 0x8983B079f9bD27F6Aec4bd637016b22b0E80D729;

    // ======== SUPPLY ========
    uint256 public MAX_SUPPLY = 1111;

    // ======== PRICE ========
    uint256 public whitelistPrice = 0.097 ether;
    uint256 public waitlistPrice = 0.097 ether;

    // ======== SALE TIME ========
    uint256 public whitelistBatchTime = 1668183060; // 11.11AM EST
    uint256 public waitlistBatchTime = 1668193860; // 2.11PM EST

    // ======== METADATA ========
    bool public isRevealed = false;
    string public _baseTokenURI;
    string public notRevealedURI;
    string public baseExtension = ".json";

    // ======== CONSTRUCTOR ========
    constructor() ERC721A("HZN", "HZN") {}

    // ======== MINTING ========
    function whitelistMint(bytes memory _signature)
        external
        payable
        hasMintStarted(whitelistBatchTime)
        signerIsValid(HASH_1, _signature)
        withinSupply(1)
        ethValueCheck(whitelistPrice)
        alreadyMinted(whitelistMintAddresses)
    {
        _safeMint(msg.sender, 1);
    }

    function waitListMint(bytes memory _signature)
        external
        payable
        hasMintStarted(waitlistBatchTime)
        signerIsValid(HASH_2, _signature)
        withinSupply(1)
        ethValueCheck(waitlistPrice)
        alreadyMinted(waitlistMintAddress)
    {
        _safeMint(msg.sender, 1);
    }

    function teamMint(uint256 _quantity)
        external
        onlyOwner
        withinSupply(_quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    // ======== SETTERS ========

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setPrice(uint256 _whitelist, uint256 _waitlist)
        external
        onlyOwner
    {
        whitelistPrice = _whitelist;
        waitlistPrice = _waitlist;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setIsRevealed(bool _reveal) external onlyOwner {
        isRevealed = _reveal;
    }

    function setMintTime(uint256 _whitelist, uint256 _waitlist)
        external
        onlyOwner
    {
        whitelistBatchTime = _whitelist;
        waitlistBatchTime = _waitlist;
    }

    // ======== WITHDRAW ========

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // ========= GETTERS ===========
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
    ) public override(ERC721A, IERC721A) payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) payable  onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721A) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ===== MODIFIERS =====

    modifier withinSupply(uint256 _quantity) {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeded max supply");
        _;
    }

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

    modifier alreadyMinted(mapping(address => bool) storage _map) {
        require(!_map[msg.sender], "Already minted");
        _map[msg.sender] = true;
        _;
    }

    modifier ethValueCheck(uint256 _price) {
        require(msg.value >= _price, "Not enough eth sent");
        _;
    }

    modifier hasMintStarted(uint256 _startTime) {
        require(block.timestamp >= _startTime, "Not yet started");
        _;
    }
}