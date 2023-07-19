// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*

𝓢𝓾𝓼𝓹𝓮𝓬𝓽 𝓐𝓻𝓻𝓮𝓼𝓽𝓮𝓭 𝓑𝔂 𝓣𝓻𝓾𝓼𝓽 𝓛𝓪𝓫

*/

contract SuspectArrestedByTrustLab is ERC721A, Ownable {
    string  public baseURI;

    uint256 public immutable _mintPrice = 0.007 ether;
    uint32 public immutable _txLimit = 10;
    uint32 public immutable _maxSupply = 10000;
    uint32 public immutable _walletLimit = 10;

    bool public activePublic = false;

    mapping(address => uint256) public publicMinted;
    mapping(address => bool) public freeMinted;
    mapping(address => bool) public goldMinted;
    mapping(address => bool) public silverMinted;
    mapping(address => bool) public bronzeMinted;

    bytes32 public goldMerkleRoot;
    bytes32 public silverMerkleRoot;
    bytes32 public bronzeMerkleRoot;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Suspect Arrested By Trust Lab", "Suspect") {
        _safeMint(msg.sender, 22);
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function publicMint(uint32 amount) public payable callerIsUser {
        require(activePublic,"not now");
        require(publicMinted[msg.sender] < _txLimit, "only 10 tx");
        require(totalSupply() + amount <= _maxSupply,"sold out");
        require(msg.value >= amount * _mintPrice,"insufficient eth");
        require(amount <= _walletLimit,"only 10 amount");
        publicMinted[msg.sender] += 1;
        _safeMint(msg.sender, amount);
    }

    function freeMint() public callerIsUser {
        require(activePublic,"not now");
        require(!freeMinted[msg.sender], "already minted");
        require(totalSupply() + 1 <= _maxSupply,"sold out");
        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function goldMint(bytes32[] calldata proof) public callerIsUser {
        require(canMint(msg.sender,goldMerkleRoot, proof), "Failed wallet verification");
        require(!goldMinted[msg.sender], "already minted");
        require(totalSupply() + 10 <= _maxSupply,"sold out");
        goldMinted[msg.sender] = true;
        _safeMint(msg.sender, 10);
    }

    function silverMint(bytes32[] calldata proof) public callerIsUser {
        require(canMint(msg.sender,silverMerkleRoot, proof), "Failed wallet verification");
        require(!silverMinted[msg.sender], "already minted");
        require(totalSupply() + 6 <= _maxSupply,"sold out");
        silverMinted[msg.sender] = true;
        _safeMint(msg.sender, 6);
    }

    function bronzeMint(bytes32[] calldata proof) public callerIsUser {
        require(canMint(msg.sender,bronzeMerkleRoot, proof), "Failed wallet verification");
        require(!bronzeMinted[msg.sender], "already minted");
        require(totalSupply() + 3 <= _maxSupply,"sold out");
        bronzeMinted[msg.sender] = true;
        _safeMint(msg.sender, 3);
    }


    function canMint(address account, bytes32 merkleRoot, bytes32[] calldata proof) public pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(account)));
    }

    function setActivePublic(bool active) public onlyOwner{
        activePublic = active;
    }

    function setMerkleRootAndFlag(uint32 rootType,bytes32 merkleRoot) public onlyOwner {
        if (rootType == 0)
        {
            goldMerkleRoot = merkleRoot;
        }
        else if (rootType == 1)
        {
            silverMerkleRoot = merkleRoot;
        }
        else if (rootType == 2)
        {
            bronzeMerkleRoot = merkleRoot;
        }
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}