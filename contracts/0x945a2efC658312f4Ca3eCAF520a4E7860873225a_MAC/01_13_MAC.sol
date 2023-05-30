// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                          
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract MAC is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public totalSupply = 0;

    string private _tokenBaseURI = "https://meta.internet.game/mac/";
    address private _signerAddress = 0xaff26FEfe8C82F233Bf240c96c5129E674C363AA;

    mapping(address => bool) private _usedNonces;
    
    constructor() ERC721("Metaverse Access Card", "MAC") {
    }

    function hashTransaction(address sender) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(sender)))
      );
      
      return hash;
    }
    
    function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }

    function mint(bytes32 hash, bytes memory signature) external payable {
        require(matchAddressSigner(hash, signature), "Not the correct signer");
        require(hashTransaction(msg.sender) == hash, "Incorrect hash");
        require(!_usedNonces[msg.sender], "You already minted.");
        
        _usedNonces[msg.sender] = true;
        totalSupply++;

        _safeMint(msg.sender, totalSupply);
    }

    function adminMint(address addr, uint tokenCount) external onlyOwner {
        for (uint256 i = 0; i < tokenCount; i++) {
            totalSupply++;
            _safeMint(addr, totalSupply);
        }
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