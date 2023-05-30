// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HolyShxxtLeague is ERC721, Ownable {
    using Strings for uint256;
    
    string public baseURI;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public totalSupply;
    address public holyShxxtSuperDraft;
    bool public revealed = false;
    uint256 public seed;

    event SetHolyShxxtSuperDraft(address holyShxxtSuperDraft);
    event SetBaseURI(string baseURI);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    modifier onlyOwnerOrStore() {
        require(
            holyShxxtSuperDraft == msg.sender || owner() == msg.sender,
            "caller must be HolyShxxtSuperDraft or owner"
        );
        _;
    }

    function setHolyShxxtSuperDraft(address _holyShxxtSuperDraft) external onlyOwner {
        holyShxxtSuperDraft = _holyShxxtSuperDraft;
        emit SetHolyShxxtSuperDraft(_holyShxxtSuperDraft);
    }

    function reveal(uint256 randomNumber) external onlyOwner {
        require( !revealed, "Blind box already revealed!");

        if (randomNumber > 0) seed = randomNumber;
        else seed = 1;

        revealed = true;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
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
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            uint256 j = uint256(keccak256(abi.encode(randomSeed, i))) % MAX_SUPPLY;
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
            uint256 blindbox = _tokenId % 5;
            return string(abi.encodePacked(base, blindbox.toString())); //blind box
        }

        return string(abi.encodePacked(base, metadataOf(_tokenId)));
    }

    function mint(address _to) public onlyOwnerOrStore {
        require(totalSupply < MAX_SUPPLY, "Exceeds max supply");
        _mint(_to, totalSupply);
        totalSupply += 1;
    }
}