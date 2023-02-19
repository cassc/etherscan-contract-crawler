// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DefaultOperatorFilterer.sol";
import "./Delegates.sol";

contract Hempbased is
    ERC721A,
    ReentrancyGuard,
    Delegated,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using ECDSA for bytes32;

    mapping(address => uint256) private whitelistMintAddresses;
    mapping(address => uint256) private publicMintAddresses;

    bytes32 constant HASH_1 = keccak256("BATCH_1");
    address public SIGNER = 0x54039C037d777476E0D3068E53BD7B09131389d5;
    address public crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

    // ======== SUPPLY ========
    uint256 public MAX_SUPPLY = 4000;
    uint256 public WHITELIST_ALLOCATION = 2;
    uint256 public PUBLIC_ALLOCATION = 2;

    // ======== PRICE ========
    uint256 public whitelistPrice = 0.03 ether;
    uint256 public mintPrice = 0.042 ether;

    // ======== SALE TIME ========
    uint256 public whitelistBatchTime = 1676826000; // Date and time (GMT): Sunday, 19 February 2023 17:00:00
    uint256 public publicBatchTime = 1676847600; // Date and time (GMT): Sunday, 19 February 2023 23:00:00

    // ======== METADATA ========
    bool public isRevealed = false;
    string public _baseTokenURI;
    string public notRevealedURI;
    string public baseExtension = ".json";

    // ======== CONSTRUCTOR ========
    constructor() ERC721A("Hempbased", "HMBD") {}

    // ======== MINTING ========
    function crossmintPublic(address _to, uint256 _quantity) public payable
        hasMintStarted(publicBatchTime)
        ethValueCheck(mintPrice * _quantity) {
        require(msg.sender == crossmintAddress,
        "This function is for Crossmint only."
        );
        _safeMint(_to, _quantity);
    }

    function whitelistMint(bytes memory _signature, uint256 _quantity)
        external
        payable
        withinWhitelistAllocatedSupply(_quantity)
        hasMintStarted(whitelistBatchTime)
        signerIsValid(HASH_1, _signature)
        ethValueCheck(whitelistPrice * _quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity)
        external
        payable
        hasMintStarted(publicBatchTime)
        withinPublicAllocatedSupply(_quantity)
        ethValueCheck(mintPrice * _quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity)
        external
        onlyOwner
        withinSupply(_quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    // ======== SETTERS ========
    function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    function setSigner(address _signer) external onlyOwner {
        SIGNER = _signer;
    }

    function setBaseURI(string calldata baseURI) external onlyDelegates {
        _baseTokenURI = baseURI;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setPrice(uint256 _whitelist, uint256 _public)
        external
        onlyOwner
    {
        whitelistPrice = _whitelist;
        mintPrice = _public;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyDelegates {
        notRevealedURI = _notRevealedURI;
    }

    function setIsRevealed(bool _reveal) external onlyDelegates {
        isRevealed = _reveal;
    }

    function setMintTime(uint256 _whitelist, uint256 _public)
        external
        onlyDelegates
    {
        whitelistBatchTime = _whitelist;
        publicBatchTime = _public;
    }

    // ======== WITHDRAW ========

    function withdraw() external onlyOwner {
        (bool gs, ) = payable(owner()).call{
            value: (address(this).balance)
        }("");
        require(gs);
    }

    // ========= GETTERS ===========
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
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
    ) public override(ERC721A) payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) payable  onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ===== MODIFIERS =====

    modifier withinSupply(uint256 _quantity) {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeded max supply");
        _;
    }

    modifier withinWhitelistAllocatedSupply(uint256 _quantity) {
        require(
            whitelistMintAddresses[msg.sender] + _quantity <= WHITELIST_ALLOCATION,
            "Exceeded individual whitelist allocation"
        );
        whitelistMintAddresses[msg.sender] = whitelistMintAddresses[msg.sender] +
            _quantity;
        _;
    }

    modifier withinPublicAllocatedSupply(uint256 _quantity) {
        require(
            publicMintAddresses[msg.sender] + _quantity <= PUBLIC_ALLOCATION,
            "Exceeded individual public allocation"
        );
        publicMintAddresses[msg.sender] = publicMintAddresses[msg.sender] +
            _quantity;
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