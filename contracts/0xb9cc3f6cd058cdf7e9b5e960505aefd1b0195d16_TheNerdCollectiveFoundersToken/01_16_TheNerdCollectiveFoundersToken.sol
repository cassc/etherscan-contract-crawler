// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "erc721a/contracts/ERC721A.sol"; 

contract TheNerdCollectiveFoundersToken is ERC721A, Ownable, ReentrancyGuard {
    string  public _baseTokenURI = "https://tnc-api.vercel.app/api/meta/";
    bool    public _paused = false;            
    uint256 public _maxTokens = 628;
    bytes32 public _merkleRoot = 0xd553621fd98027ab868cffe7898c50bd86d04832f232c8d12124f1d955313cea;
    
    mapping(address => uint256) private _walletMints;

    constructor() ERC721A("The Nerd Collective Founders Token", "FT") {}

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        _merkleRoot = _root;
    }

    function setPause(bool val) public onlyOwner {
        _paused = val;
    }

    function setMaxTokens(uint256 val) public onlyOwner {
        _maxTokens = val;
    }

    function mint(uint256 _amount, uint256 _walletLimit, bytes32[] calldata merkleProof) public
    {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, _walletLimit));
        require(MerkleProof.verify(merkleProof, _merkleRoot, node), "Invalid proof");
        require(_walletMints[msg.sender] + _amount <= _walletLimit, "Exceeds wallet limit");
        require(totalSupply() + _amount <= _maxTokens,              "All tokens have already been minted!");
        require(!_paused,                                           "Mint paused" );
        
        _safeMint(msg.sender, _amount);
        _walletMints[msg.sender] += _amount;
    }

    function bulkMint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= _maxTokens, "All tokens have already been minted!");
        _safeMint( _to, _amount);
    }
}