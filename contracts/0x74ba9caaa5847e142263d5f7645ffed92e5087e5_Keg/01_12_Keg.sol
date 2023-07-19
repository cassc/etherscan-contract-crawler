// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
    Authors: @shdw_dev, @JefftheWorm
*/
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Keg.sol";

contract Keg is ERC721, Ownable {
    using Strings for uint256;
    
    // state variables:
    string public                   baseURI;
    string public                   baseExtension = '.json';

    uint256 public constant         totalMints = 10000;
    uint256 public constant         price = 0.05 ether;
    uint128 public constant         maxPublicMintPerTx = 20;
    uint128 public constant         maxAllowlistMintPerAddress = 3;

    bytes32 public                  allowlistMerkleRoot;

    bool public                     paused = true;
    bool public                     allowlistMintPeriod = true;
    bool public                     reveal = false;

    constructor( 
        string memory _initURI
        
    ) ERC721("Keg Plebs", "Keg Plebs") {

        setBaseURI(_initURI);
        _safeMint(msg.sender, 20);
    }
    
    function publicMint(uint256 _mintAmt) external payable {
        require(!paused && !allowlistMintPeriod                 , "Minting is paused.");
        require(totalSupply() + _mintAmt < totalMints + 1       , "Exceeds total supply.");
        require(msg.sender == tx.origin                         , "Minter is not a User");
        require(_mintAmt < maxPublicMintPerTx + 1               , "Exceeds max batch mint amount.");
        require(_mintAmt * price == msg.value                   , "Insufficient funds.");

        _safeMint(msg.sender, _mintAmt); 
    }

    // allowlist mint -- verifies that the sender address is in the merkle tree
    function allowlistMint(uint256 _mintAmt, bytes32[] memory proof) external payable {
        string memory payload = string(abi.encodePacked(msg.sender));

        require(!paused && allowlistMintPeriod                                      , "Minting is paused.");
        require(totalSupply() + _mintAmt < totalMints + 1                           , "Exceeds total supply.");
        require(_verify(_leaf(payload), proof)                                      , "Allowlist proof provided is invalid.");
        require(_totalMints(msg.sender) + _mintAmt < maxAllowlistMintPerAddress + 1 , "Exceeds max mints per address.");
        require(_mintAmt * price == msg.value                                       , "Incorrect eth amount.");
        
        _safeMint(msg.sender, _mintAmt); 
    }
    
    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if(tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index;

        for(uint256 i = 0; i < totalSupply(); i++) {
            if(ownerOf(i) == _owner) {
                tokenIds[index] = i; 
                index++;
            }
        }
        return tokenIds;
    }

    function tokenURI(uint256 _tokenId) external view override returns(string memory) {
        require(_exists(_tokenId) , "Token DNE");
        if(!reveal) {
            return baseURI;
        }

        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension));
    }

    // hashes address string for a leaf node in the merkle tree
    function _leaf(string memory _payload) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_payload));
    }

    // verifies an address is in the merkle tree
    function _verify(bytes32 leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, allowlistMerkleRoot, leaf);
    }

    // contract owner only
    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    // update baseURI
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    // pause minting
    function pause(bool _state) external onlyOwner {
        paused = _state;
    }
    
    // turn off allowlist minting
    function toggleAllowlisted() external onlyOwner {
        allowlistMintPeriod = !allowlistMintPeriod;
        delete allowlistMerkleRoot;
    }

    // reveal minted kegplebs
    function _reveal() external onlyOwner {
        reveal = true;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Error");
    }
}