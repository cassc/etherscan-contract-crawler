// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                                  
     ▄█▀▀▀█▄█   ▀███▀▀▀██▄    ▄█▀▀▀█▄█
    ▄██    ▀█     ██    ██   ▄██    ▀█
    ▀███▄         ██    ██   ▀███▄    
      ▀█████▄     ██▀▀▀█▄▄     ▀█████▄
    ▄     ▀██     ██    ▀█   ▄     ▀██
    ██     ██     ██    ▄█   ██     ██
    █▀█████▀    ▄████████    █▀█████▀ 
                                 
    
    Sneaky Bat Syndicate / 2021 / Companions
*/
                                          
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SneakyBatSyndicate is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    mapping(string => bool) private _usedNonces;
    string private _contractURI;
    string private _tokenBaseURI = "https://svs.gg/api/bats/metadata/";
    address private _signerAddress = 0x801FD7eB0b813F0eB0E20409e23b63D3C3aDB39c;

    mapping(uint256 => bool) public claimed;
    string public proof;
    bool public released;
    bool public locked;
    
    constructor() ERC721("Sneaky Bat Syndicate", "SBS") { }
    
    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
    
    function isClaimed(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function hashTransaction(address sender, uint256[] memory tokens, string memory nonce) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, tokens, nonce)))
        );
        
        return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }
    
    function buy(bytes32 hash, bytes memory signature, string memory nonce, uint256[] memory tokens) external {
        require(released, "NOT_RELEASED");
        require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(hashTransaction(msg.sender, tokens, nonce) == hash, "HASH_FAIL");
        require(tokens.length > 0, "NO_VAMPIRES_OWNED");
        
        for(uint256 i = 0; i < tokens.length; i++) {            
            if(isClaimed(tokens[i])) {
                continue;
            }
            
            _safeMint(msg.sender, tokens[i]);
        }
    }
    
    function unleash() external onlyOwner {
        released = !released;
    }

    function lock() external onlyOwner {
        locked = true;
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