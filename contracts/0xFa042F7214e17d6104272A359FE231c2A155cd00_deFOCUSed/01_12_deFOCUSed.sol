// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface i_deFOCUSedURI {
  function buildMetaPart(uint256 _tokenId, string memory _description, address _artistAddy, uint256 _royaltyBps, string memory _collection, string memory _website, string memory _externalURL)
    external
    view
    returns (string memory);

  function buildContractURI(string memory _description, string memory _externalURL, uint256 _royaltyBps, address _artistAddy, string memory _svg)
    external
    view
    returns (string memory);


  function buildTokenURI(string memory _metaP, uint256 _tokenEntropy, bytes32 _abEntropy, bool _svgMode)
    external
    view
    returns (string memory);
}

interface i_ArtBlocks {
  function tokenIdToHash(uint256 fullTokenId)
    external
    view
    returns (bytes32);

  function ownerOf(uint256 fullTokenId)
    external
    view
    returns (address);
}

/// @title deFOCUSed Main Contract
/// @author Matto
/// @notice This is a customized ERC-721 contract for deFOCUSed NFTs.
/// @dev SVG image and metadata is generated fully on-chain.
/// @custom:security-contact [email protected]
contract deFOCUSed is ERC721, Ownable, ReentrancyGuard {
  using Strings for string;
  bool public URIcontractLocked = false;
  mapping(uint256 => uint256) public tokenEntropyMap;
  mapping(uint256 => bytes32) public abEntropyMap;
  uint8[1000] public claimed;
  string public artist = "Matto";
  string public description;
  string public collection = "deFOCUSed";
  string public website = "https://matto.xyz/project/defocused/";
  string public externalURL;
  address public artistAddy = 0x983f10B69c6C8d72539750786911359619DF313d;
  address public URIcontract;
  address private abContract = 0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270;
  uint256 public royaltyBps = 750;
  uint256 public exampleId = 0;
	
  constructor() ERC721("deFOCUSed", "deFOC") {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "No contracts");
    _;
  }
	
	function deFOCUSthatFOCUS(uint16 FOCUSnumber_forExample_1)
	external
    nonReentrant
    callerIsUser
	{
    require(claimed[FOCUSnumber_forExample_1] == 0, "That FOCUS has been deFOCUSed.");
    require(msg.sender == i_ArtBlocks(abContract).ownerOf(FOCUSnumber_forExample_1 + 181000000), "Requesting account must own the FOCUS.");
    bytes32 abEntropy = i_ArtBlocks(abContract).tokenIdToHash(FOCUSnumber_forExample_1 + 181000000);
    require(abEntropy != 0x0000000000000000000000000000000000000000000000000000000000000000, "That FOCUS doesn't exist.");
    abEntropyMap[FOCUSnumber_forExample_1] = abEntropy;
    createTokenEntropy(FOCUSnumber_forExample_1);
    claimed[FOCUSnumber_forExample_1] = 1;
    _safeMint(msg.sender, FOCUSnumber_forExample_1);
	}

  function Matto_deFOCUS(uint16 _FOCUSnumber)
	external 
	onlyOwner
	{
    require(claimed[_FOCUSnumber] == 0, "That FOCUS has been deFOCUSed.");
    address _addy = i_ArtBlocks(abContract).ownerOf(_FOCUSnumber + 181000000);
    bytes32 abEntropy = i_ArtBlocks(abContract).tokenIdToHash(_FOCUSnumber + 181000000);
    require(abEntropy != 0x0000000000000000000000000000000000000000000000000000000000000000, "That FOCUS doesn't exist.");
    abEntropyMap[_FOCUSnumber] = abEntropy;
    createTokenEntropy(_FOCUSnumber);
    claimed[_FOCUSnumber] = 1;
    _safeMint(_addy, _FOCUSnumber);
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
    tokenEntropyMap[_tokenId] = tE;
  }

  function contractURI()
    public
    view
    virtual
    returns (string memory) 
  {
    string memory svg = getSVG(exampleId);
    string memory contractURIstring = i_deFOCUSedURI(URIcontract).buildContractURI(description, externalURL, royaltyBps, artistAddy, svg);
    return contractURIstring;
  }

  function tokenURI(uint256 _tokenId) 
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(claimed[_tokenId] == 1, "That token doesn't exist");
    string memory metaPart = i_deFOCUSedURI(URIcontract).buildMetaPart(_tokenId, description, artistAddy, royaltyBps, collection, website, externalURL);
    string memory URIBase64 = i_deFOCUSedURI(URIcontract).buildTokenURI(metaPart, tokenEntropyMap[_tokenId], abEntropyMap[_tokenId], false);
    return URIBase64;
  }

	function getSVG(uint256 _tokenId)
		public
		view
		virtual
		returns (string memory)
	{
    require(claimed[_tokenId] == 1, "That token doesn't exist");
    string memory metaPart = i_deFOCUSedURI(URIcontract).buildMetaPart(_tokenId, description, artistAddy, royaltyBps, collection, website, externalURL);
    string memory svg = i_deFOCUSedURI(URIcontract).buildTokenURI(metaPart, tokenEntropyMap[_tokenId], abEntropyMap[_tokenId], true);
    return svg;
	}

  function getRoyalties(uint256 _tokenId)
    external
    view
    returns (address, uint256)
  {
    return (artistAddy, royaltyBps);
  }

  function royaltyInfo(uint256 _tokenId, uint256 value)
		public
		view
		returns (address, uint256)
	{
    return (artistAddy, value * royaltyBps / 10000);
	}

  // The following functions are contract controls.

  function DANGER_LockURIcontract(uint256 _password)
        external
        onlyOwner
    {
        require(_password == 1234, "Wrong password!");
        URIcontractLocked = true;
  }
	
	function updateArtistAddy(address _artistAddy)
		external 
		onlyOwner 
	{
    artistAddy = _artistAddy;
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

	function updateExampleId(uint16 _example)
		external 
		onlyOwner 
	{
    exampleId = _example;
  }

  function updateURIcontract(address _URIcontract)
		external 
		onlyOwner 
	{
    require(URIcontractLocked == false, "URI contract locked");
    URIcontract = _URIcontract;
  }
}