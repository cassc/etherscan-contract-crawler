// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract HealthyDicks is ERC721ABurnable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    bool public revealed = false;
    enum Sale{NONE, CODE, WHITELIST, SALE}
    Sale public sale;
    string public baseURI;
    uint256 public maxSupply = 5000;
    uint256 public maxPerWallet = 2;
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    address whitelistSigningKey = address(0);
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant MINTER_TYPEHASH = keccak256("Minter(address wallet,uint256 amount,string token)");

    mapping(address => uint256) public mintedList;
    mapping(bytes32 => uint256) public mintedCodes;

    constructor(
        string memory name,
        string memory symbol,
        string memory _uri,
        address _signerAddress
    ) ERC721A(name, symbol) {
        baseURI = _uri;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        whitelistSigningKey = _signerAddress;
    }

    modifier checkClaim(bytes calldata _signature, uint256 _amount, string memory _token) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender, _amount, hashString(_token)))
            )
        );
        address recoveredAddress = digest.recover(_signature);
        require(recoveredAddress == whitelistSigningKey, "Invalid Signature");
        _;
    }

    function publicMint(uint256 _mintAmount) external nonReentrant {
        require(sale == Sale.SALE, "sale not started.");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(_mintAmount > 0, "mint amount too small.");
        require(mintedList[msg.sender] + _mintAmount <= maxPerWallet, "Attempt to mint more than allowed.");
        mintedList[msg.sender] += _mintAmount;
        _mint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount, bytes calldata _signature, uint256 _maxAmount, string memory _token) external nonReentrant checkClaim(_signature, _maxAmount, _token) {
        uint256 _mintedCount = mintedList[msg.sender];
        require(sale == Sale.CODE || sale == Sale.WHITELIST, "sale not started.");
        require(_mintAmount > 0, "mint amount too small.");
        require(_maxAmount > 0, "no max mint selected.");
        require(_mintedCount + _mintAmount <= _maxAmount, "Attempt to mint more than allowed.");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        if (sale == Sale.CODE && getStrLength(_token) > 0) {
            require(mintedCodes[hashString(_token)] < _maxAmount, "Attempt to mint more than allowed.");
            mintedCodes[hashString(_token)] += _mintAmount;
        }
        mintedList[msg.sender] += _mintAmount;
        _mint(msg.sender, _mintAmount);
    }

    function getStrLength(string memory _token) internal pure returns (uint256) {
        uint256 length = bytes(_token).length;
        return length;
    }

    function hashString(string memory _token) internal pure returns (bytes32) {
        bytes32 key = keccak256(bytes(_token));
        return key;
    }

    function airdrop(uint256 _mintAmount, address _to) external onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        mintedList[_to] += _mintAmount;
        _mint(_to, _mintAmount);
    }

    function withdraw() external payable onlyOwner nonReentrant {
        (bool so,) = payable(msg.sender).call{value : address(this).balance}("");
        require(so, "WITHDRAW ERROR");
    }

    function setReveal(bool _reveal) external onlyOwner {
        revealed = _reveal;
    }

    function setSale(Sale _sale) external onlyOwner {
        sale = _sale;
    }

    function setWhitelistSigningAddress(address _newSigningKey) external onlyOwner {
        whitelistSigningKey = _newSigningKey;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxPerWallet(uint256 _max) external onlyOwner {
        maxPerWallet = _max;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!revealed) {
            return hiddenMetadataUri;
        } else {
            string memory uri = super.tokenURI(tokenId);
            return string(abi.encodePacked(uri, uriSuffix));
        }
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }
}