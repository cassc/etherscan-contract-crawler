// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                          
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract GameToken is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    bool public whitelistOpen = false;
    bool public saleOpen = false;

    uint256 public totalSupply = 0;
    uint256 public whitelistMinted = 0;
    uint256 public publicMinted = 0;

    uint256 public constant whitelistPrice = 0.05 ether;
    uint256 public constant bronzelistPrice = 0.075 ether;
    uint256 public constant startingPrice = 0.1 ether;
    uint256 public constant priceIncrement = 0.025 ether;
    uint256 public constant maxPerTier = 1000;
    uint256 public constant maxMintsPerTransaction = 2;

    string private _tokenBaseURI = "https://meta.internet.game/gametoken/";
    address private _signerAddress = 0xaba537dE1a301134092B1f22Ca9dA1C6A6958Bbd;

    mapping(string => bool) private _usedNonces;
    
    constructor() ERC721("Internet Game Token", "INTERNET_GAME_TOKEN") {
    }

    function hashTransaction(address sender, string memory nonce, string memory list, uint256 timestamp) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(sender, nonce, list, timestamp)))
      );
      
      return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }

    function whitelistMint(bytes32 hash, bytes memory signature, string memory nonce, string memory list, uint256 timestamp) external payable {
        uint price = 0;
        if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked('whitelist'))) price = whitelistPrice;
        else if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked('bronzelist'))) price = bronzelistPrice;

        require(whitelistOpen, "Whitelist minting is not open");
        require(matchAddresSigner(hash, signature), "Nice try.");
        require(hashTransaction(msg.sender, nonce, list, timestamp) == hash, "Nice try.");
        require(!_usedNonces[nonce], "You already minted.");

        require(price <= msg.value, "ETH value sent is not enough");
        
        _usedNonces[nonce] = true;
        whitelistMinted++;
        totalSupply++;

        _safeMint(msg.sender, totalSupply);
    }

    function mint(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity, string memory list, uint256 timestamp) external payable {
        require(saleOpen, "Minting is not open");
        require(block.timestamp > timestamp, "Not your turn yet");
        require(tokenQuantity <= maxMintsPerTransaction, "Exceeds max mints per transaction");
        require(matchAddresSigner(hash, signature), "Nice try.");
        require(hashTransaction(msg.sender, nonce, list, timestamp) == hash, "Nice try.");
        require(!_usedNonces[nonce], "You already minted");

        uint price = mintPrice();
        require(price * tokenQuantity <= msg.value, "ETH value sent is not enough");
         _usedNonces[nonce] = true;

        for (uint256 i = 0; i < tokenQuantity; i++) {
            totalSupply++;
            publicMinted++;
            _safeMint(msg.sender, totalSupply);
        }       
    }

    function adminMint(address addr, uint tokenCount) external onlyOwner {
        for (uint256 i = 0; i < tokenCount; i++) {
            totalSupply++;
            _safeMint(addr, totalSupply);
        }
    }

    function mintPrice() public view virtual returns (uint256) {
        uint tier = publicMinted / maxPerTier;
        uint price = startingPrice + (priceIncrement * tier);
        return price;
    }
    
    function toggleSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function toggleWhitelist() external onlyOwner {
        whitelistOpen = !whitelistOpen;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}