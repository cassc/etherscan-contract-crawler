// SPDX-License-Identifier: MIT
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,.........................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@,...................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected],[email protected]@[email protected]@...
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@......*@.....
@@@@@@@@@@@@@@@@@@@@@#..%@@@@[email protected]@@@@@@@[email protected]@@........
@@@@@@@@@@@@@@@@................................................................
@@@@@@@@@@@@@@..................................................................
@@@@@@@@@@@@@...................................................................
@@@@@@@@@@@@@...................................................................
@@@@@@@@@@@@@@[email protected]@[email protected]&................
@@@@@@@@@@@@@@@@[email protected]@@@@[email protected]@@@...................
@@@@@@@@@@@@@@@@@@@@@@@@@@@.....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...................................................                            
 / ____|                                             (_)             
 | (___     __ _   _   _    __ _   _ __   _ __ ___    _    ___   ___ 
  \___ \   / _` | | | | |  / _` | | '__| | '_ ` _ \  | |  / _ \ / __|
  ____) | | (_| | | |_| | | (_| | | |    | | | | | | | | |  __/ \__ \
 |_____/   \__, |  \__,_|  \__,_| |_|    |_| |_| |_| |_|  \___| |___/
         |_| 
*/

pragma solidity >=0.8.0 <0.9.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";


contract SQUARMIES is Ownable, ERC721A, ReentrancyGuard {

    string public SQUARMIES_PROVENANCE;
    string private baseURI;
    bool public revealed = false;
    bool public paused = false;
    uint256 public cost = 0.059 ether;
    uint256 public maxWhitelist = 3;
    bytes32 public root;
    enum Sale{NON, WHITELIST, SALE}
    Sale public sale;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A(_name, _symbol, maxBatchSize_, collectionSize_) {
        baseURI = _uri;
        
    }

    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    function mintSquares(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable callerIsUser  {
        uint256 supply = totalSupply();
        uint256 actualCost = cost;
        require(!paused);
        require(_mintAmount > 0, "mint amount > 0");
        require(supply + _mintAmount <= collectionSize, "max NFT limit exceeded");
        if (msg.sender != owner()) {
            require(sale != Sale.NON, "Sale has not started yet");
            if (sale == Sale.WHITELIST) {
                bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
                require(MerkleProof.verify(_merkleProof, root, _leaf), "invalid proof");
                uint256 ownerMintedCount = balanceOf(msg.sender);
                require(ownerMintedCount + _mintAmount <= maxWhitelist,"max mint amount exceeded");
                }  
                
                else { require(_mintAmount <= maxBatchSize, "max mint amount exceeded");}
                
            require(msg.value >= actualCost * _mintAmount, "insufficient funds");
        }
        _safeMint(msg.sender, _mintAmount);
    }
     
    // What did Squarmies say to Circle Square? Chat Aud up on Discord and tell her your answer 

    //  For team members + giveaways
    function airdropSquares(uint256 _mintAmount, address destination) public onlyOwner  {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "mint amount > 0");
        require(_mintAmount <= maxBatchSize, "mint amount < batch");
        require(supply + _mintAmount <= collectionSize, "max NFT limit exceeded");
        _safeMint(destination, _mintAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!revealed) {
            return baseURI;
        } else {
            string memory uri = super.tokenURI(tokenId);
            return uri;
        }
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function setProvenance(string memory provenance) public onlyOwner  {
        SQUARMIES_PROVENANCE = provenance;
    }

    function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
    }

    function setRoot(bytes32 _root) public onlyOwner  {
        root = _root;
    }

    function setSale(Sale _sale) public onlyOwner  {
        sale = _sale;
    }
    function setReveal(bool _reveal) public onlyOwner {
        revealed = _reveal;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxWhitelist(uint256 _amount) public onlyOwner {
        maxWhitelist = _amount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

 
    function withdraw() public payable onlyOwner nonReentrant{
        (bool os,) = payable(msg.sender).call{value : address(this).balance}("");
        require(os, "WITHDRAW ERROR");
    }
    
    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
    
    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

   

}