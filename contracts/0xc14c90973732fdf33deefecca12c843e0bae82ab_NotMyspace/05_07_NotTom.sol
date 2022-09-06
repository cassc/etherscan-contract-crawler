/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Strings.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";


contract NotMyspace is ERC721A, Ownable {
    using Strings for uint;
    string public _baseTokenURI = "ipfs://QmbZm6PNNJLz8h4nsGCsHGsCuY8qcnPipHGn71iKEQDnfP/";
    uint public maxPerWallet = 2;
    uint public maxSupply = 2003;
    bool public paused = true;
    bool public presaleOnly = true;
    bool public revealed = false;
    bytes32 public merkleRoot;

    mapping(address => uint) public addressMintedBalance;

  constructor(
    ) ERC721A("Not Tom", "NT")payable{
        _mint(msg.sender, 100);
    }

    
    modifier mintCompliance(uint256 quantity) {
        require(paused == false, "Contract is paused");
        require(_totalMinted() + quantity <= maxSupply, "Collection is capped.");
        require(tx.origin == msg.sender, "No contracts!");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You can't mint this many.");
        _;
    }



  function mint(uint256 quantity) mintCompliance(quantity) external payable
    {
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

    function mintPresale(uint256 quantity, bytes32[] calldata proof) mintCompliance(quantity) external payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;    
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }    

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        string memory currentBaseURI = _baseURI();
        if(revealed == true) {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
        } else {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI))
            : "";
        } 
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setPause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setPresaleOnly(bool _state) external onlyOwner {
        presaleOnly = _state;
    }

    function reveal(bool _state, string memory baseURI) external onlyOwner {
        revealed = _state;
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}