// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

enum Stage {
    NotStarted,
    PreSale,
    PublicSale
}

contract KFTTEST is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_PER_MINT_NUM = 5;
    uint256 public constant PRESALE_PRICE_PER_TOKEN = 0.01 ether;
    uint256 public constant PUBLICSALE_PRICE_PER_TOKEN = 0.05 ether;

    Stage public _stage = Stage.NotStarted;

    string private _baseTokenURI;

    address private _signer;
    address private _finance;

    //whitelist records
    mapping(bytes => bool) public signatureUsed;

    constructor() ERC721A("KFTTEST", "KFTT") {
    }

    /** 
    * Stage
    */
    function setStage(Stage stage) external onlyOwner {
        _stage = stage;
    }

    /** 
    * Metadata
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseUri) external onlyOwner {
        _baseTokenURI = baseUri;
    }

    /** 
    * Whitelist
    */
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ECDSA.recover(messageDigest, signature);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    /** 
    * Minting
    */
    function reserve(address to, uint32 num) external onlyOwner nonReentrant {
      require(totalSupply() + num <= MAX_SUPPLY, "Not enough NFTs left to reserve");
      _safeMint(to, num);
    }

    function mintAllowList(uint32 num, bytes memory signature) external payable nonReentrant {  
        require(_stage == Stage.PreSale, "PreSale is not started");
        require(num <= MAX_PER_MINT_NUM, "Exceeded max token purchase");
        require(totalSupply() + num <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRESALE_PRICE_PER_TOKEN * num <= msg.value, "Ether value sent is not correct");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        require(recoverSigner(hash, signature) == _signer, "Address is not in allowlist");
        require(!signatureUsed[signature], "Signature has already been used.");

        _safeMint(msg.sender, num);
        signatureUsed[signature] = true;
    }

    function mint(uint32 num) external payable nonReentrant {
        require(_stage == Stage.PublicSale, "Public Sale is not started");
        require(num <= MAX_PER_MINT_NUM, "Exceeded max token purchase");
        require(totalSupply() + num <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PUBLICSALE_PRICE_PER_TOKEN * num <= msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, num);
    }

    /** 
    * Withdraw
    */
    function setFinance(address finance) external onlyOwner {
        _finance = finance;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint balance = address(this).balance;
        payable(_finance).transfer(balance);
    }
}