/*
   ▄████▄  ██▀███  ▓██   ██▓ ██▓███  ▄▄▄█████▓ ▒█████
  ▒██▀ ▀█ ▓██ ▒ ██▒ ▒██  ██▒▓██░  ██ ▓  ██▒ ▓▒▒██▒  ██▒
  ▒▓█    ▄▓██ ░▄█ ▒  ▒██ ██░▓██░ ██▓▒▒ ▓██░ ▒░▒██░  ██▒
  ▒▓▓▄ ▄██▒██▀▀█▄    ░ ▐██▓░▒██▄█▓▒ ▒░ ▓██▓ ░ ▒██   ██░
  ▒ ▓███▀ ░██▓ ▒██▒  ░ ██▒▓░▒██▒ ░  ░  ▒██▒ ░ ░ ████▓▒░
  ░ ░▒ ▒  ░ ▒▓ ░▒▓░   ██▒▒▒ ▒▓▒░ ░  ░  ▒ ░░   ░ ▒░▒░▒░
    ░  ▒    ░▒ ░ ▒░ ▓██ ░▒░ ░▒ ░         ░      ░ ▒ ▒░
  ░          ░   ░  ▒ ▒ ░░  ░░         ░ ░    ░ ░ ░ ▒
  ░ ░        ░      ░ ░                           ░ ░
▒███████▒ ▒█████    ███▄ ▄███▓  ▄▄▄▄     ██▓█████▒███████▒
▒ ▒ ▒ ▄▀░▒██▒  ██▒ ▓██▒▀█▀ ██▒ ▓█████▄ ▒▓██▓█   ▀▒ ▒ ▒ ▄▀░
░ ▒ ▄▀▒░ ▒██░  ██▒ ▓██    ▓██░ ▒██▒ ▄██░▒██▒███  ░ ▒ ▄▀▒░
  ▄▀▒   ░▒██   ██░ ▒██    ▒██  ▒██░█▀   ░██▒▓█  ▄  ▄▀▒   ░
▒███████▒░ ████▓▒░▒▒██▒   ░██▒▒░▓█  ▀█▓ ░██░▒████▒███████▒
░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░░ ▒░   ░  ░░░▒▓███▀▒ ░▓ ░░ ▒░ ░▒▒ ▓░▒░▒
░ ▒ ▒ ░ ▒  ░ ▒ ▒░ ░░  ░      ░░▒░▒   ░   ▒  ░ ░  ░ ▒ ▒ ░ ▒
░ ░ ░ ░ ░░ ░ ░ ▒   ░      ░     ░    ░   ▒    ░  ░ ░ ░ ░ ░
  ░ ░        ░ ░  ░       ░   ░ ░        ░    ░    ░ ░
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Crypto Zombiez contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract CryptoZombiez is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Address for address;

    // Minting
    bool public presaleActive = false;
    bool public saleActive = false;
    uint256 public maxMintPerTransaction = 5;
    uint256 public maxPresaleMintPerAccount = 3;
    uint256 public price = 0.05 ether;
    uint256 public constant MAX_SUPPLY = 5555;

    // Base URI
    string private baseURI;

    // Whitelisting verification
    mapping (address => uint256) public presaleClaimed;
    address private signVerifier;

    event Mint(address recipient, uint256 tokenId);

    constructor() ERC721("CryptoZombiez", "ZOMBIE") {
        signVerifier = 0x98c5D9A61e042D4a7DFCB49fef196AEA99294F89;
        baseURI = "ipfs://QmUnXNqRckGWzjT97tKZnBv5peHn8FsHNtMHy91NjSkWYZ/";
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    // @dev Generate hash to prove whitelist eligibility
    function getSigningHash(address recipient) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(recipient));
    }

    // @dev Sets a new signature verifier
    function setSignVerifier(address verifier) external onlyOwner {
        signVerifier = verifier;
    }

    // @dev Dynamically set the max mints a user can do in the main sale
    function setMaxMintPerTransaction(uint256 maxMint) external onlyOwner {
        maxMintPerTransaction = maxMint;
    }

    // @dev Dynamically set the max mints a user can do in the main sale
    function setMaxPresaleMintPerAccount(uint256 maxMint) external onlyOwner {
        maxPresaleMintPerAccount = maxMint;
    }

    function isValidSignature(address recipient, bytes memory sig) private view returns (bool) {
        bytes32 message = getSigningHash(recipient).toEthSignedMessageHash();
        return ECDSA.recover(message, sig) == signVerifier;
    }

    // @dev Returns number of remaining mints for approved address
    function getAvailablePresaleMints(address recipient, bytes memory sig) external view returns (uint256) {
        require(isValidSignature(recipient, sig), "Account is not authorized for presale");
        return maxPresaleMintPerAccount - presaleClaimed[msg.sender];
    }

    function presaleMint(bytes memory sig, uint256 numberOfMints) external payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 claimed = presaleClaimed[msg.sender];

        require(presaleActive, "Presale must be active to mint");
        require(isValidSignature(msg.sender, sig), "Account is not authorized for presale");
        require(numberOfMints <= maxPresaleMintPerAccount - claimed, "Amount exceeds mintable limit");
        require(numberOfMints > 0, "The minimum number of mints is 1");
        require(supply.add(numberOfMints) <= MAX_SUPPLY, "Further minting would exceed max supply");
        require(price.mul(numberOfMints) == msg.value, "Ether value sent is not correct");
        require(address(this).balance >= msg.value, "Insufficient balance to mint");

        presaleClaimed[msg.sender] = claimed + numberOfMints;

        for (uint256 i; i < numberOfMints; i++) {
            uint256 tokenId = supply + i;
            emit Mint(msg.sender, tokenId);
            _safeMint(msg.sender, tokenId);
        }
    }

    function mint(uint256 numberOfMints) public payable nonReentrant {
        uint256 supply = totalSupply();

        require(saleActive, "Sale must be active to mint");
        require(numberOfMints <= maxMintPerTransaction, "Amount exceeds mintable limit");
        require(numberOfMints > 0, "The minimum number of mints is 1");
        require(supply.add(numberOfMints) <= MAX_SUPPLY, "Further minting would exceed max supply");
        require(price.mul(numberOfMints) == msg.value, "Ether value sent is not correct");
        require(address(this).balance >= msg.value, "Insufficient balance to mint");

        for (uint256 i; i < numberOfMints; i++) {
            uint256 tokenId = supply + i;
            emit Mint(msg.sender, tokenId);
            _safeMint(msg.sender, tokenId);
        }
    }

    // @dev Check if sale has been sold out
    function isSaleFinished() private view returns (bool) {
        return totalSupply() >= MAX_SUPPLY;
    }

    // @dev List tokens per owner
    function walletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // @dev Private mint function reserved for company.
    function ownerMintToAddress(address recipient, uint256 numberOfMints) external onlyOwner nonReentrant {
        uint256 supply = totalSupply();

        require(numberOfMints > 0, "The minimum number of mints is 1");
        require(supply.add(numberOfMints) <= MAX_SUPPLY, "Further minting would exceed max supply");

        for (uint256 i; i < numberOfMints; i++) {
            uint256 tokenId = supply + i;
            emit Mint(recipient, tokenId);
            _safeMint(recipient, tokenId);
        }
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}