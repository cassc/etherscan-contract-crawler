// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
    ██████╗░██████╗░░█████╗░
    ██╔══██╗██╔══██╗██╔══██╗
    ██████╔╝██████╦╝██║░░╚═╝
    ██╔═══╝░██╔══██╗██║░░██╗
    ██║░░░░░██████╦╝╚█████╔╝
    ╚═╝░░░░░╚═════╝░░╚════╝░
    
    POLAR BEAR CLUB - 2021 (v1.0.0-Iceberg)
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract PBCNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant PBC_GIFT = 499;
    uint256 public constant PBC_PUBLIC = 9500;
    uint256 public constant PBC_MAX = PBC_PUBLIC + PBC_GIFT;
    uint256 public constant PBC_PRICE = 0.08 ether;
    uint256 public constant PBC_PER_MINT = 5;
    
    mapping(string => bool) private _usedNonces;
    
    string private _contractURI;
    string private _tokenBaseURI = "https://api.pbc.gg/metadata/";
    address private _signerAddress = 0x929384300CA2871866A3Ea11A93AC43A8bB44aD8;

    string public proof;
    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    bool public saleLive;
    bool public locked;
    
    constructor() ERC721("Polar Bear Club", "PBC") {}
    
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
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }
    
    function buy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
        require(totalSupply() < PBC_MAX, "OUT_OF_STOCK");
        require(publicAmountMinted + tokenQuantity <= PBC_PUBLIC, "EXCEED_PUBLIC");
        require(tokenQuantity <= PBC_PER_MINT, "EXCEED_PBC_PER_MINT");
        require(PBC_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
        _usedNonces[nonce] = true;
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= PBC_PRICE, "MAX_MINT");
        require(giftedAmount + receivers.length <= PBC_GIFT, "GIFTS_EMPTY");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // Owner functions for enabling presale, sale, revealing and setting the provenance hash
    function lockMetadata() external onlyOwner {
        locked = true;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
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