// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Maiko is ERC721ABurnable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    bool public revealed = true;
    bool public mintable = false;
    string public baseURI;
    address whitelistSigningKey = address(0);
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant MINTER_TYPEHASH = keccak256("Minter(address wallet,uint256 amount)");

    mapping(address => uint256) public mintedList;

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

    modifier checkClaim(bytes calldata _signature, uint256 _amount) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender, _amount))
            )
        );
        address recoveredAddress = digest.recover(_signature);
        require(recoveredAddress == whitelistSigningKey, "Invalid Signature");
        _;
    }

    function mint(uint256 _mintAmount, bytes calldata _signature, uint256 _maxAmount) external nonReentrant checkClaim(_signature, _maxAmount) {
        require(mintable, "Sale has not started yet");
        uint256 _mintedCount = mintedList[msg.sender];
        require(_mintAmount > 0, "You did not select any count");
        require(_maxAmount > 0, "You did not select any count");
        require(_mintedCount + _mintAmount <= _maxAmount, "Attempt to mint more than allowed.");
        require(_mintAmount <= 20, "Not more than 20 at a time");

        mintedList[msg.sender] += _mintAmount;
        _mint(msg.sender, _mintAmount);
    }

    function airdrop(uint256 _mintAmount, address _to) external onlyOwner {
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

    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
    }

    function setWhitelistSigningAddress(address _newSigningKey) external onlyOwner {
        whitelistSigningKey = _newSigningKey;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!revealed) {
            return baseURI;
        } else {
            string memory uri = super.tokenURI(tokenId);
            return uri;
        }
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return baseURI;
    }
}