// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";

contract CutiePepes is
    ERC721A,
    ERC2981,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    Ownable
{
    uint256 public price = 0.069 ether;
    uint256 public reserved = 200;
    uint256 public maxSupply = 3333;
    uint256 public maxPerMint = 50;
    uint256 public maxPerWhitelist = 10;

    string private baseTokenURI;
    string private contractUri;

    bytes32 internal merkleRoot;

    uint64 public whitelistStartTimestamp = 1668974400;
    uint64 public whitelistEndTimestamp = 1668977999;
    uint64 public publicStartTimestamp = 1668978000;
    uint64 public publicEndTimestamp = 10000000000000;

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        _setDefaultRoyalty(0xE49575c1974C4Af4c475fD3e9635aCc9A573892b, 750);
    }

    // Mint functions

    function _mintTokens(
        uint256 _quantity,
        uint256 _value,
        address _receiver,
        bool isFree
    ) internal {
        require(
            _totalMinted() + _quantity + reserved <= maxSupply,
            "Max supply exceeded"
        );

        require(
            _quantity > 0 && _quantity <= maxPerMint,
            "Invalid mint amount"
        );

        if (!isFree) {
            require(
                _value >=
                    mintPricePerQuantity(_quantity + _numberMinted(_receiver)) -
                        mintPricePerQuantity(_numberMinted(_receiver)),
                "Insufficient funds"
            );
        }

        _safeMint(_receiver, _quantity);
    }

    function mint(uint256 _quantity)
        external
        payable
        nonReentrant
        isPublicSaleActive
    {
        _mintTokens(_quantity, msg.value, msg.sender, false);
    }

    function mintWhitelist(uint256 _quantity, bytes32[] memory _merkleProof)
        external
        payable
        nonReentrant
        isWhitelistSaleActive
    {
        require(
            isWhitelisted(merkleRoot, msg.sender, _merkleProof),
            "Invalid merkle proof"
        );

        require(
            _numberMinted(msg.sender) + _quantity <= maxPerWhitelist,
            "Exceeds max amount for whitelist"
        );

        _mintTokens(_quantity, msg.value, msg.sender, false);
    }

    function mintTeam(uint256 _quantity, address _receiver)
        external
        nonReentrant
        onlyOwner
    {
        require(_totalMinted() + _quantity <= maxSupply, "Max supply exceeded");
        require(_quantity <= reserved, "Max reserved exceeded");

        require(_quantity % 50 == 0, "Can only mint a multiple of 50");

        reserved = reserved - _quantity;

        uint256 numChunks = _quantity / 50;
        for (uint256 i = 0; i < numChunks; i++) {
            _mintTokens(50, 0, _receiver, true);
        }
    }

    // Helper functions

    function mintPricePerQuantity(uint256 _quantity)
        public
        view
        returns (uint256)
    {
        if (_quantity == 0) {
            return 0;
        }

        return price * (_quantity - 1);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function isWhitelisted(
        bytes32 _root,
        address _receiver,
        bytes32[] memory _proof
    ) public pure returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_receiver));

        return MerkleProof.verify(_proof, _root, _leaf);
    }

    // Admin functions

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Max supply cannot be increased");
        require(_maxSupply >= _totalMinted() + reserved, "Invalid new supply");

        maxSupply = _maxSupply;
    }

    function setWhitelistTimestamp(uint64 _startTime, uint64 _endTime)
        public
        onlyOwner
    {
        whitelistStartTimestamp = _startTime;
        whitelistEndTimestamp = _endTime;
    }

    function setPublicTimestamp(uint64 _startTime, uint64 _endTime)
        public
        onlyOwner
    {
        publicStartTimestamp = _startTime;
        publicEndTimestamp = _endTime;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function updateMaxPerMint(uint256 _maxPerMint)
        public
        onlyOwner
        nonReentrant
    {
        maxPerMint = _maxPerMint;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // Configuration

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Modifiers

    modifier isPublicSaleActive() {
        require(
            (block.timestamp >= publicStartTimestamp &&
                block.timestamp < publicEndTimestamp),
            "This sale is not active"
        );
        _;
    }

    modifier isWhitelistSaleActive() {
        require(
            (block.timestamp >= whitelistStartTimestamp &&
                block.timestamp < whitelistEndTimestamp),
            "This sale is not active"
        );
        _;
    }

    // OpenSea overwrites

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}