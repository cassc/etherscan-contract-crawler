// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WawWeapon is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    // Controlled variables
    uint256 private claimCountTracker;
    mapping(uint256 => uint256) public tokenIdToClaimId;
    mapping(uint256 => address) public tokenIdToClaimant;
    mapping(address => uint256[]) public claimantToTokenIds;
    
    uint256 public MAX_SUPPLY = 2000;
    string  public baseTokenURI = "";
    bool public status = false;

    event claimedAgainstTokenId(address indexed claimant, uint256 indexed tokenId, uint256 timestamp);

    // Config variables
    ERC721 qualifyingToken;

    constructor(
        address _qualifyingTokenAddress
    ) 
    ERC721A("WaW Weapon", "WaWW") {
        qualifyingToken = ERC721(_qualifyingTokenAddress);
    }


    function ownerMint(address to, uint amount) external onlyOwner {
		require(
			_totalMinted() + amount <= MAX_SUPPLY,
			'Exceeds max supply'
		);
		_safeMint(to, amount);
	  }

    function claimAgainstTokenIds(uint256[] memory _tokenIds) public {
        require(_tokenIds.length > 2  && _tokenIds.length % 3 == 0, "Please provide three WaW in a pair");
        uint32 pairs = uint32(_tokenIds.length / 3);
        //require(_tokenIds.length > 0, "ClaimAgainstERC721::claimAgainstTokenIds: no token IDs provided");
        require(status, "Claim is not live yet.");
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(tokenIdToClaimant[tokenId] == address(0), "Token with provided ID has already been claimed against");
            require(qualifyingToken.ownerOf(tokenId) == msg.sender, "Sender does not own specified token");
            tokenIdToClaimant[tokenId] = msg.sender;
            claimantToTokenIds[msg.sender].push(tokenId);
            emit claimedAgainstTokenId(msg.sender, tokenId, block.timestamp);
            // Do anything else that needs to happen for each tokenId here
        }
        claimCountTracker += _tokenIds.length;
        // Do anything else that needs to happen once per collection of claim(s) here
        _safeMint(msg.sender, pairs);
    }

    function claimCount() public view returns(uint256) {
        return claimCountTracker;
    }

    function claimantClaimCount(address _claimant) public view returns(uint256) {
        return claimantToTokenIds[_claimant].length;
    }

    function claimantToClaimedTokenIds(address _claimant) public view returns(uint256[] memory) {
        return claimantToTokenIds[_claimant];
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    
    function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : baseTokenURI;
	}

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }


    function setStatus(bool _status) external onlyOwner
    {
        status = _status;
    }

}