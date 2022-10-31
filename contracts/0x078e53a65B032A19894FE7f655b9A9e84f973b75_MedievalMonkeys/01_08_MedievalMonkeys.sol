// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MedievalMonkeys is ERC721A, Ownable, ReentrancyGuard {

    uint256 mintPrice = 0.015 ether;
    uint256 public MAX_SUPPLY = 5555;
    uint256 MAX_PER_TX_WHITELIST = 3;
    uint256 MAX_PER_WALLET_WHITELIST = 3;
    uint256 MAX_PER_TX_PUBLIC = 3;
    uint256 MAX_PER_WALLET_PUBLIC = 3;

    mapping(address => uint256) whitelistMints;
    mapping(address => uint256) publicMints;

    address signingAddress = 0x7Ee772A5A29A466ce725b3900fc773d71343dd52;

    string baseURI;
    string baseURIExtension = ".json";
    string unrevealedURI;

    bool isRevealed = false;
    uint256 public mintPhase = 0;

    constructor() ERC721A("Medieval Monkeys", "MM") {}

    /*

    Monkey Mint

    */

    function setMintingPhase(uint256 newMintPhase) external onlyOwner {
        mintPhase = newMintPhase;
    }

    function publicMintMonkey(uint256 quantity) external payable nonReentrant isPerson {
        require(mintPhase >= 2, "Public mint unopened.");
        require(quantity > 0, "Quantity must be non-zero.");
        require(quantity <= MAX_PER_TX_PUBLIC, "Mint quantity higher than max.");
        require(msg.value == quantity*mintPrice, "Invalid ether amount sent.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max supply reached.");
        require(publicMints[msg.sender]+quantity <= MAX_PER_WALLET_PUBLIC, "Wallet exceeds public maximum.");

        publicMints[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function whitelistMintMonkey(uint256 quantity, bytes memory signature) external payable nonReentrant isPerson {
        require(mintPhase >= 1, "Whitelist mint unopened.");
        require(quantity > 0, "Quantity must be non-zero.");
        require(quantity <= MAX_PER_TX_WHITELIST, "Mint quantity higher than max.");
        require(msg.value == quantity*mintPrice, "Invalid ether amount sent.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max supply reached.");
        require(whitelistMints[msg.sender]+quantity <= MAX_PER_WALLET_WHITELIST, "Wallet exceeds whitelist maximum.");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address receivedAddress = ECDSA.recover(message, signature);

        require(receivedAddress != address(0) && receivedAddress == signingAddress, "Invalid whitelist signature.");

        whitelistMints[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /*

    Reveal Process

    */

    function revealTheMonkeys(string memory newBaseURI) external onlyOwner {
        require(!isRevealed, "Revealed already.");
        isRevealed = true;
        baseURI = newBaseURI;
    }

    function updateBaseURI(string memory newBaseURI, string memory newBaseURIExtension) external onlyOwner {
        baseURI = newBaseURI;
        baseURIExtension = newBaseURIExtension;
    }

    function updateUnrevealedURI(string memory newUnrevealedURI) external onlyOwner {
        unrevealedURI = newUnrevealedURI;
    }

    /*

    ERC721A Overrides

    */

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        if(isRevealed){
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), baseURIExtension)) : '';
        }
        else{
            return unrevealedURI;
        }
   }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* 

    Other

    */

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Unable to withdraw.");
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    modifier isPerson() {
        require(tx.origin == msg.sender, "No contracts allowed.");
        _;
    }

    function setSigningAddress(address newAddress) external onlyOwner {
        signingAddress = newAddress;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A) returns (bool) {
        return interfaceId == type(IERC721A).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}