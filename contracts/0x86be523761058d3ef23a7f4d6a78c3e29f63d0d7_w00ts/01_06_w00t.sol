// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract w00ts is ERC721A, Ownable {

    constructor() ERC721A("w00ts", "w00t") {
        }

    uint256 public maxMint = 1; 
    uint256 public maxSupply = 1000; 
    uint256 public maxReserved = 100;   
    uint256 public mintPrice = 0 ether;
    string public baseURI = "";
    bytes32 public root;
    
    struct History {
        uint64 minted;
        uint64 claimed;
    }
    mapping(address => History) public history;

    function mint(uint256 _mintAmount) public payable {
        require(_mintAmount < maxMint + 1, "Error - TX Limit Exceeded");
        require(totalSupply() + _mintAmount < maxSupply - maxReserved + 1, "Error - Max Supply Exceeded");
        require(history[msg.sender].minted + _mintAmount < maxMint + 1,"Error - Wallet Minted");
        require(msg.value >= mintPrice * _mintAmount,"Error - Insufficient Funds");
        history[msg.sender].minted += uint64(_mintAmount);
        _safeMint(msg.sender, _mintAmount);
    }

    function claim(bytes32[] memory _proof, uint8 _maxAllocation, uint256 _claimAmount) public {
        require(totalSupply() + _claimAmount < maxSupply + 1, "Error - Max Supply Exceeded");
        require(MerkleProof.verify(_proof,root,keccak256(abi.encodePacked(msg.sender, _maxAllocation))),"Error - Verify Qualification");
        require(history[msg.sender].claimed + _claimAmount < _maxAllocation + 1,"Error - Wallet Claimed");

        history[msg.sender].claimed += uint64(_claimAmount);
        maxReserved -= uint64(_claimAmount);
        _safeMint(msg.sender, _claimAmount);
    }

    function _baseURI() internal view override(ERC721A) virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function setRoot(bytes32 root_) public onlyOwner {
        root = root_;
    }
 
    function setSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }
    function setReserved(uint256 maxReserved_) public onlyOwner {
        maxReserved = maxReserved_;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}