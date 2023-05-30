// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract LBPNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant LBP_GIFT = 500;
    uint256 public constant LBP_PUBLIC = 9499;
    uint256 public constant LBP_MAX = LBP_PUBLIC + LBP_GIFT;
    uint256 public constant LBP_PRICE = 0.03 ether;
    uint256 public constant LBP_PRIVATE_PRICE = 0.02 ether;
    uint256 public constant LBP_PER_MINT = 5;
    
    mapping(string => bool) private _usedNonces;
    
    string private _contractURI;
    string private _tokenBaseURI = "https://api.babypunks.net/metadata/";
    address private _signerAddress = 0xFDA548926C2c3161B9409A3027FFcce9E7d6Ef25;
    address private _privateSignerAddress = 0xa5b69c2E15BdC33B32df777dC7c659e40176b259;

    string public proof;
    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    bool public saleLive;
    bool public locked;
    
    constructor() ERC721("Lil Baby Punk", "LBP") {}
    
    modifier notLocked {
      require(!locked, "Contract metadata methods are locked");
      _;
    }

    function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(sender, qty, nonce)))
      );
      return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature, bool isPrivate) private view returns(bool) {
      return (isPrivate ? _privateSignerAddress : _signerAddress) == hash.recover(signature);
    }
    
    function buy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
      require(saleLive, "SALE_CLOSED");
      require(matchAddresSigner(hash, signature, false), "DIRECT_MINT_DISALLOWED");
      require(!_usedNonces[nonce], "HASH_USED");
      require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
      require(totalSupply() < LBP_MAX, "OUT_OF_STOCK");
      require(publicAmountMinted + tokenQuantity <= LBP_PUBLIC, "EXCEED_PUBLIC");
      require(tokenQuantity <= LBP_PER_MINT, "EXCEED_LBP_PER_MINT");
      require(LBP_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
      
      for(uint256 i = 0; i < tokenQuantity; i++) {
          publicAmountMinted++;
          _safeMint(msg.sender, totalSupply() + 1);
      }
      
      _usedNonces[nonce] = true;
    }

    function privateBuy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
      require(saleLive, "SALE_CLOSED");
      require(matchAddresSigner(hash, signature, true), "DIRECT_MINT_DISALLOWED");
      require(!_usedNonces[nonce], "HASH_USED");
      require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
      require(totalSupply() < LBP_MAX, "OUT_OF_STOCK");
      require(publicAmountMinted + tokenQuantity <= LBP_PUBLIC, "EXCEED_PUBLIC");
      require(tokenQuantity <= LBP_PER_MINT, "EXCEED_LBP_PER_MINT");
      require(LBP_PRIVATE_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
      
      for(uint256 i = 0; i < tokenQuantity; i++) {
          publicAmountMinted++;
          _safeMint(msg.sender, totalSupply() + 1);
      }
      
      _usedNonces[nonce] = true;
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= LBP_MAX, "MAX_MINT");
        require(giftedAmount + receivers.length <= LBP_GIFT, "GIFTS_EMPTY");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function lockMetadata() external onlyOwner {
        locked = true;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function setPrivateSignerAddress(address addr) external onlyOwner {
        _privateSignerAddress = addr;
    }

    function setBothSignerAddresses(address addr, address addr2) external onlyOwner {
        _signerAddress = addr;
        _privateSignerAddress = addr2;
    }    

    function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
        proof = hash;
    }
    
    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }    
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}