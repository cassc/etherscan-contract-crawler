// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BrushStrokes is ERC721Enumerable, Ownable {
    event NewTokenHash(uint256 indexed tokenId, bytes32 indexed tokenHash);

    using ECDSA for bytes32;
    using Strings for uint256;

    bool public earlyMintIsActive = false;
    bool public mintIsActive = false;
    uint256 public freeMintCount = 0;
    uint256 public earlyMintCount = 0;
    uint256 constant public MAX_SUPPLY = 1111;
    uint256 constant public FREE_MINT_SUPPLY = 111;
    uint256 constant public EARLY_MINT_SUPPLY = 500;
    uint256 constant public BRUSHSTROKES_PRICE = 0.05 ether;

    mapping(bytes32 => bool) private usedHashes;
    mapping(address => uint256) private walletMintNumber;
    mapping(uint256 => bytes32) public tokenIdToHash;

    string public script; // base64 encoded generative script
    string private _tokenBaseURI;
    address private _signatureVerifier = 0x805c057A31B31c84F7759698298aD4dC6F8fA622;
    
    constructor() ERC721("BrushStrokes", "BRUSHSTROKES") {
    }

    // onlyOwner functions

    function setScript(string memory genScript) public onlyOwner {
        script = genScript;
    }

    function flipEarlyMintState() public onlyOwner {
        earlyMintIsActive = !earlyMintIsActive;
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _tokenBaseURI = baseURI_;
    }

    // public functions

    function earlyMint(bytes memory signature, uint256 nonce) public payable {
        require(earlyMintIsActive, "Early minting is not active at the moment");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(earlyMintCount + 1 <= EARLY_MINT_SUPPLY, "Early mint is over");
        require(walletMintNumber[msg.sender] + 1 <= 1, "Mint would exceed max mint for wallet during early mint");
        require(BRUSHSTROKES_PRICE == msg.value, "Sent ether value is incorrect");

        bytes32 messageHash = hashMessage(msg.sender, nonce);
        require(messageHash.recover(signature) == _signatureVerifier, "Unrecognizable Hash");
        require(!usedHashes[messageHash], "Reused Hash");
        usedHashes[messageHash] = true;

        walletMintNumber[msg.sender] += 1;
        earlyMintCount += 1;
        setTokenIdToHash(totalSupply() + 1);
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function freeMint(bytes memory signature, uint256 nonce) public {
        require(mintIsActive, "Minting is not active at the moment");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(freeMintCount + 1 <= FREE_MINT_SUPPLY, "Free mint is over");
        require(walletMintNumber[msg.sender] + 1 <= 3, "Mint would exceed max mint for wallet");

        bytes32 messageHash = hashMessage(msg.sender, nonce);
        require(messageHash.recover(signature) == _signatureVerifier, "Unrecognizable Hash");
        require(!usedHashes[messageHash], "Reused Hash");
        usedHashes[messageHash] = true;

        walletMintNumber[msg.sender] += 1;
        freeMintCount += 1;
        setTokenIdToHash(totalSupply() + 1);
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mint(bytes memory signature, uint256 nonce) public payable {
        require(mintIsActive, "Minting is not active at the moment");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(walletMintNumber[msg.sender] + 1 <= 3, "Mint would exceed max mint for wallet");
        require(BRUSHSTROKES_PRICE == msg.value, "Sent ether value is incorrect");
        
        bytes32 messageHash = hashMessage(msg.sender, nonce);
        require(messageHash.recover(signature) == _signatureVerifier, "Unrecognizable Hash");
        require(!usedHashes[messageHash], "Reused Hash");
        usedHashes[messageHash] = true;

        walletMintNumber[msg.sender] += 1;
        setTokenIdToHash(totalSupply() + 1);
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    // internal functions

    function hashMessage(address sender, uint256 nonce) internal pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, nonce))));
        return hash;
    }

    function setTokenIdToHash(uint256 tokenId) internal {
        bytes32 hash = keccak256(abi.encodePacked(block.number, block.timestamp, msg.sender));
        tokenIdToHash[tokenId]=hash;
        emit NewTokenHash(tokenId, hash);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }
}