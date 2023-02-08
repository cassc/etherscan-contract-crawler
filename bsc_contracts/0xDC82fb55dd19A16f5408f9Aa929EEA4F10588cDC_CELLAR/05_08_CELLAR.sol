// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ICELLAR.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CELLAR is ICELLAR, ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 5000;

    uint256 public tokenPerAccountLimit = 2;

    uint256 public constant INTERNAL_SUPPLY = 50;

    string public baseURI;

    string public notRevealedURI;

    uint256 public mintPrice = 0.35 ether;

    uint256 public whiteListPrice = 0.3 ether;

    SaleStatus public saleStatus = SaleStatus.PAUSED;

    mapping(address => uint256) private _mintedCount;

    bytes32 public merkleRoot;

    address private _paymentAddress;

    bool private _internalMinted = false;

    constructor(address paymentAddress, string memory _notRevealedURI)
        ERC721A("CELLAR PASS", "CELLAR")
    {
        _paymentAddress = paymentAddress;
        notRevealedURI = _notRevealedURI;
    }

    modifier mintCheck(SaleStatus status, uint256 count) {
        require(saleStatus == status, "CELLAR: Not operational");
        require(
            _totalMinted() + count <= maxSupply,
            "CELLAR: Number of requested tokens will exceed max supply"
        );
        require(
            _mintedCount[msg.sender] + count <= tokenPerAccountLimit,
            "CELLAR: Number of requested tokens will exceed the limit per account"
        );
        _;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setTokenPerAccountLimit(uint256 limit) external onlyOwner {
        tokenPerAccountLimit = limit;
    }

    function setPaymentAddress(address paymentAddress)
        external
        override
        onlyOwner
    {
        _paymentAddress = paymentAddress;
    }

    function setSaleStatus(SaleStatus status) external override onlyOwner {
        saleStatus = status;
    }

    function setMintPrice(uint256 price) external override onlyOwner {
        mintPrice = price;
    }

    function setWhiteListPrice(uint256 price) external override onlyOwner {
        whiteListPrice = price;
    }

    function setMerkleRoot(bytes32 root) external override onlyOwner {
        merkleRoot = root;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        override
        onlyOwner
    {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseURL(string memory url) external override onlyOwner {
        baseURI = url;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : notRevealedURI;
    }

    function mintWhitelist(bytes32[] calldata merkleProof, uint256 count)
        external
        payable
        override
        mintCheck(SaleStatus.PRESALE, count)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "CELLAR: You are not whitelisted"
        );
        require(
            msg.value >= count * whiteListPrice,
            "CELLAR: Ether value sent is not sufficient"
        );
        _mintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function mint(uint256 count)
        external
        payable
        override
        mintCheck(SaleStatus.PUBLIC, count)
    {
        require(
            msg.value >= count * mintPrice,
            "CELLAR: Ether value sent is not sufficient"
        );
        _mintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function internalMint(address receiver) external override onlyOwner {
        require(!_internalMinted, "CELLAR: The interior has been mint");
        _internalMinted = true;
        _safeMint(receiver, INTERNAL_SUPPLY);
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "CELLAR: Insufficient balance");
        (bool success, ) = payable(_paymentAddress).call{value: balance}("");
        require(success, "CELLAR: Withdrawal failed");
    }

    function mintedCount(address mintAddress)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _mintedCount[mintAddress];
    }
}