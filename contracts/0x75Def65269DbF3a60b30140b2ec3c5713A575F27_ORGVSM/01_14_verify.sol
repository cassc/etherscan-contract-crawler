// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ORGVSM is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public cost = 0.15 ether;
    uint256 public maxSupply = 1000;
    // change to true, on deploy
    bool public paused = true;
    uint256 public maxMintAmount = 2;
    bytes32 merkleRoot;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    //internal functions
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    

    function walletOfOwner(address _owner) public view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    //owner functions
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function increaseMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply > maxSupply, "Can not set a new maxSupply lower than the previous supply");
        maxSupply = _newMaxSupply;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }


    // MERKLE TREE VERIFICATION FUNCTIONS   
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 _leafNode, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, merkleRoot, _leafNode);
    }


    function _getCurrentCollectionMintedAmountFor(address account) internal view returns (uint256) {
        uint[] memory currentCollectionLimits = new uint[](2);
        if (maxSupply <= 1000) {
            currentCollectionLimits[0] = 1;
            currentCollectionLimits[1] = 1000;
        }
        if (maxSupply > 1000 && maxSupply <= 2000) {
            currentCollectionLimits[0] = 1001;
            currentCollectionLimits[1] = 2000;
        }
        if (maxSupply > 2000 && maxSupply <= 3000) {
            currentCollectionLimits[0] = 2001;
            currentCollectionLimits[1] = 3000;
        }
        if (maxSupply > 3000 && maxSupply <= 4000) {
            currentCollectionLimits[0] = 3001;
            currentCollectionLimits[1] = 4000;
        }
        if (maxSupply > 4000 && maxSupply <= 5000) {
            currentCollectionLimits[0] = 4001;
            currentCollectionLimits[1] = 5000;
        }
        if (maxSupply > 5000 && maxSupply <= 6000) {
            currentCollectionLimits[0] = 5001;
            currentCollectionLimits[1] = 6000;
        }

        uint256 mintedCounter = 0;
        for (uint256 i = 0; i < balanceOf(account); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(account, i);
            if (tokenId >= currentCollectionLimits[0] && tokenId <= currentCollectionLimits[1]){
                mintedCounter = mintedCounter + 1;
            }
        }

        return mintedCounter;
    }

    function mint(
        uint256 _mintAmount,
        bytes32[] calldata proof
    ) public payable {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "Minted amount would exceed maxSupply");

        if (msg.sender != owner()){
            require(_verify(_leaf(msg.sender), proof), "You are not on the white list");
            uint256 currectCollectionMints = _getCurrentCollectionMintedAmountFor(msg.sender);

            require(currectCollectionMints < 2, 'Address already owns max hold amount');
            require((currectCollectionMints + _mintAmount) <= 2, 'Address would exceed max hold amount');

            require(!paused, "Contract is paused");
            require(msg.value >= cost * _mintAmount, "Insufficient funds sent to transaction");
            require(_mintAmount <= maxMintAmount, "Mint limit exceeded");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    } 

    function setMerkleRoot(bytes32 root) onlyOwner public 
    {
        merkleRoot = root;
    }

}