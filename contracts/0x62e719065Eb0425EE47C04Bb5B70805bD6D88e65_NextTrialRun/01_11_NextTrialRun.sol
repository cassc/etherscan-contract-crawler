// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NextTrialRun is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 6000; //set max supply
    
    string public baseURI;
    uint256 public totalSupply;
    address public nextTrialRunOrientation;
    bool public revealed = false;
    uint256 public seed;

    event SetNextTrialRunOrientation(address nextTrialRunOrientation);
    event SetBaseURI(string baseURI);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    //modifier to check owner or store condition
    modifier onlyOwnerOrStore() 
    {
        require(
            nextTrialRunOrientation == msg.sender || owner() == msg.sender,
            "caller must be NextTrialRunOrientation or owner"
        );
        _;
    }

    function setNextTrialRunOrientation(address _nextTrialRunOrientation) 
        external 
        onlyOwner 
    {
        nextTrialRunOrientation = _nextTrialRunOrientation;
        emit SetNextTrialRunOrientation(_nextTrialRunOrientation);
    }

    function reveal(uint256 randomNumber) 
        external 
        onlyOwner 
    {
        require( !revealed, "Blind box already revealed!");

        if (randomNumber > 0) seed = randomNumber;
        else seed = 1;

        revealed = true;
    }

    function setBaseURI(string memory _baseURI) 
        external 
        onlyOwner 
    {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return baseURI;
    }

    function metadataOf(uint256 tokenId) 
        public 
        view 
        returns (string memory) 
    {
        require( tokenId < totalSupply, "Invalid token id");

        if (seed == 0) return "";

        uint256[] memory metaIds = new uint256[](MAX_SUPPLY);
        uint256 randomSeed = seed;

        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            metaIds[i] = i;
        }

        // shuffle meta id
        for (uint256 i = 51; i < MAX_SUPPLY; i++) {
            uint256 j = (uint256(keccak256(abi.encode(randomSeed, i))) % (MAX_SUPPLY - 51)) + 51;
            (metaIds[i], metaIds[j]) = (metaIds[j], metaIds[i]);
        }

        return metaIds[tokenId].toString();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory base = _baseURI();
        
        //only blind box before reveal
        if (!revealed) {
            return string(abi.encodePacked(base, _tokenId.toString())); //blind box
        }

        return string(abi.encodePacked(base, metadataOf(_tokenId)));
    }

    function mint(address _to) 
        public 
        onlyOwnerOrStore 
    {
        require(totalSupply < MAX_SUPPLY, "Max supply reached");
        _mint(_to, totalSupply);
        totalSupply += 1;
    }
}