// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface iBLONKSuri {
  function buildMetaPart(uint256 _tokenId, string memory _description, address _artistAddy, uint256 _royaltyBps, string memory _collection, string memory _website, string memory _externalURL)
    external
    view
    returns (string memory);

  function buildContractURI(string memory _description, string memory _externalURL, uint256 _royaltyBps, address _artistAddy, string memory _svg)
    external
    view
    returns (string memory);

  function getBase64TokenURI(string memory _legibleURI)
    external
    view
    returns (string memory);

  function getLegibleTokenURI(string memory _metaP, uint256 _tokenEntropy, uint256 _ownerEntropy)
    external
    view
    returns (string memory);

  function buildPreviewSVG(uint256 _tokenEntropy, uint256 _addressEntropy)
    external
    view
    returns (string memory);
}

/// @title BLONKS Main Contract
/// @author Matto
/// @notice This is a customized ERC-721 contract for BLONKS NFTs.
/// @dev SVG image and metadata is generated fully on-chain. Beause a token's owner's address changes how the image renders, a preview function is included.
/// @custom:security-contact [email protected]
contract BLONKSmain is ERC721, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for string;

  Counters.Counter private _tokenIdCounter;
  bool public publicMintActive = false;
  bool public URIcontractLocked = false;
  uint256 public cost = .0420 ether;
  mapping(uint256 => uint256) public tokenEntropyMap;
  string public artist = "Matto";
  string public description;
  string public collection = "BLONKS";
  string public website = "https://BLONKS.xyz";
  string public externalURL;
  address public artistAddy = 0xA6a4Fe416F8Bf46bc3bCA068aC8b1fC4DF760653;
  address public donationAddy = 0x9D5025B327E6B863E5050141C987d988c07fd8B2;
  uint256 public constant donationPercent = 50;
  address public URIcontract;
  uint256 public royaltyBps = 300;
  uint16 public maxSupply = 4444;
  string public license = "BLONKS NFTS ARE CC0";
  uint16 public exampleBLONK = 0;
	
  constructor() ERC721("BLONKS", "BLONKS") {}

  function mattoMint(address to)
    public 
    onlyOwner
  {
    require(_tokenIdCounter.current() < maxSupply, "All BLONKS have been minted.");
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    createTokenEntropy(tokenId);
    _safeMint(to, tokenId);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "No contracts");
    _;
  }
	
	function publicMintThatBlonk()
		external 
		payable
    nonReentrant
    callerIsUser
	{
    require(publicMintActive, "Minting is disabled");
    require(msg.value == cost, "Incorrect value sent");
    require(_tokenIdCounter.current() < maxSupply, "All BLONKS have been minted.");
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    createTokenEntropy(tokenId);
    _safeMint(msg.sender, tokenId);
	}

	function createTokenEntropy(uint256 _tokenId)
		internal
	{
    uint256 tE = uint256(keccak256(abi.encodePacked(
      artist, 
      _tokenId,
      block.number,
      block.timestamp,
      block.difficulty)));
    tokenEntropyMap[_tokenId] = (tE / 100) * 100 + (block.basefee % 100);  
  }
		
	function getOwnerEntropy(uint256 _tokenId)
		public
		view
		virtual
		returns (uint256)
	{
		uint256 oE = uint256(uint160(ownerOf(_tokenId)));
		return oE;
	}

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_tokenId < _tokenIdCounter.current(), "That token doesn't exist");
    string memory legibleURItemp = legibleTokenURI(_tokenId);
    string memory URIBase64 = iBLONKSuri(URIcontract).getBase64TokenURI(legibleURItemp);
    return URIBase64;
  }

	function legibleTokenURI(uint256 _tokenId)
		public
		view
		virtual
		returns (string memory)
  {
    require(_tokenId < _tokenIdCounter.current(), "That token doesn't exist");
    string memory metaP = iBLONKSuri(URIcontract).buildMetaPart(_tokenId, description, artistAddy, royaltyBps, collection, website, externalURL);
    string memory legibleURI = iBLONKSuri(URIcontract).getLegibleTokenURI(metaP, tokenEntropyMap[_tokenId], getOwnerEntropy(_tokenId));
    return legibleURI;
	}

  function contractURI()
    public
    view
    virtual
    returns (string memory) 
  {
    uint256 addressEntropy = uint256(uint160(ownerOf(exampleBLONK)));
    string memory svg = iBLONKSuri(URIcontract).buildPreviewSVG(tokenEntropyMap[exampleBLONK], addressEntropy);
    string memory contractURIstring = iBLONKSuri(URIcontract).buildContractURI(description, externalURL, royaltyBps, artistAddy, svg);
    return contractURIstring;
  }

	function getSVG(uint256 _tokenId)
		public
		view
		virtual
		returns (string memory)
	{
    require(_tokenId < _tokenIdCounter.current(), "That token doesn't exist");
    string memory svg = previewSVG(_tokenId, ownerOf(_tokenId));
    return svg;
	}

	function previewSVG(uint256 _tokenId, address _addy)
		public
		view
		virtual
		returns (string memory)
	{
    uint256 addressEntropy = uint256(uint160(_addy));
    require(_tokenId < _tokenIdCounter.current(), "That token doesn't exist");
    string memory svg = iBLONKSuri(URIcontract).buildPreviewSVG(tokenEntropyMap[_tokenId], addressEntropy);
    return svg;
	}

  function getRoyalties(uint256 _tokenId)
    external
    view
    returns (address, uint256)
  {
    require(_tokenId < _tokenIdCounter.current(), "That token doesn't exist");
    return (artistAddy, royaltyBps);
  }

  function royaltyInfo(uint256 _tokenId, uint256 value)
		public
		view
		returns (address, uint256)
	{
    require(_tokenId < _tokenIdCounter.current(), "That token doesn't exist");
    return (artistAddy, value * royaltyBps / 10000);
	}

  // The following functions are contract controls.

	function toggleMint() 
		external 
		onlyOwner 
	{
		publicMintActive = !publicMintActive;
	}

  function lowerSupply(uint16 _lowerSupply)
    external
    onlyOwner
  { 
    require(_lowerSupply < maxSupply, "Supply can only be lowered");
    maxSupply = _lowerSupply;
  }

  function DANGER_LockURIcontract()
    external
    payable
    onlyOwner
  {
    require(msg.value == 2 * cost, "Incorrect value sent");
    URIcontractLocked = true;
  }
	
	function updateArtistAddy(address _artistAddy)
		external 
		onlyOwner 
	{
    artistAddy = _artistAddy;
  }

	function updateDonationAddy(address _donationAddy)
		external 
		onlyOwner 
	{
    donationAddy = _donationAddy;
  }

	function updateRoyaltyBps(uint256 _royaltyBps)
		external 
		onlyOwner 
	{
    royaltyBps = _royaltyBps;
  }

	function updateDescription(string memory _description)
		external 
		onlyOwner 
	{
    description = _description;
  }

	function updateCollection(string memory _collection)
		external 
		onlyOwner 
	{
    collection = _collection;
  }

	function updateWebsite(string memory _website)
		external 
		onlyOwner 
	{
    website = _website;
  }

	function updateExternalURL(string memory _externalURL)
		external 
		onlyOwner 
	{
    externalURL = _externalURL;
  }

	function updateCost(uint256 _cost)
		external 
		onlyOwner 
	{
    cost = _cost;
  }

	function updateExampleBLONK(uint16 _example)
		external 
		onlyOwner 
	{
    exampleBLONK = _example;
  }

  function updateURIcontract(address _URIcontract)
		external 
		onlyOwner 
	{
    require(URIcontractLocked == false, "URI contract locked");
    URIcontract = _URIcontract;
  }

  function withdraw()
    external
    onlyOwner
  {
    require(artistAddy != address(0), "Artist address not set");
    require(donationAddy != address(0), "Donation address not set");
    uint256 donationAmount = address(this).balance * donationPercent / 100;
    payable(artistAddy).transfer(address(this).balance - donationAmount);
    payable(donationAddy).transfer(donationAmount);
  }
}