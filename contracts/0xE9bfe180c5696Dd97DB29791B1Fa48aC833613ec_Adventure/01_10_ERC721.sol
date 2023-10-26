//SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ERC721A } from "lib/ERC721A/contracts/ERC721A.sol";

contract Adventure is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint8 public mintPhase;

    uint256 public constant MAX_SUPPLY = 358;
    uint256 public constant MIN_MINT_PRICE = 0.0018 ether;

    string public baseURI;

    mapping(address => bool) public addressMinted;

    constructor(string memory _baseURI) ERC721A("Adventure", "ADV") Ownable(msg.sender) {
        baseURI = _baseURI;
    }

    modifier _validSignature(bytes32 message, bytes memory signature) {
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        (address signer) = prefixedHash.recover(signature);
        require(signer == 0x9c1fC608ca7a97052536E25d03933bE48FD8875a, "Invalid signature");
        require(!addressMinted[msg.sender], "Already minted");
        _;
    }

    modifier _mintConditions(bool isPublicMint) {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= MIN_MINT_PRICE, "Insufficient funds");
        require(mintPhase != 0, "Minting is not active");
        if (isPublicMint) {
            require(mintPhase == 2, "Public minting is not active");
        }
        _;
    }

    function allowlistMint(
        bytes memory signature,
        string calldata nonce
    )
        external
        payable
        _validSignature(keccak256(abi.encodePacked(msg.sender, nonce)), signature)
        _mintConditions(false)
    {
        _safeMint(msg.sender, 1);
        addressMinted[msg.sender] = true;
    }

    function setMintPhase(uint8 _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, "token/", tokenId.toString()));
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract"));
    }

    function publicMint() external payable _mintConditions(true) {
        _safeMint(msg.sender, 1);
        addressMinted[msg.sender] = true;
    }

    function teamMint() external onlyOwner {
        require(totalSupply() < 50, "Team already minted");
        _safeMint(msg.sender, 50);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 adminShare = (balance * 95) / 100;
        uint256 devTeamShare = balance - adminShare;
        payable(msg.sender).transfer(adminShare);
        payable(0x65D38b601d386f72DBc767995F47b2B136d45521).transfer(devTeamShare);
    }
}