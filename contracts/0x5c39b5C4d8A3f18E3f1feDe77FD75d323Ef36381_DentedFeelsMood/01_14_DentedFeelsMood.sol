// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DentedFeelsMood is ERC721, Ownable { 
using Strings for uint256;
using SafeMath for uint256;
using Counters for Counters.Counter;

string public baseURI;

uint256 public maxSupply = 1000;
uint256 public maxMintAmount = 1;
uint256 public limitPerTicket = 1;
bytes32 public merkleRoot;

bool public paused = true;

mapping(string => uint256) public ticketMintedBalance;
Counters.Counter private _tokenIdCounter;

constructor(
string memory _name,
string memory _symbol,
string memory _initBaseURI
) ERC721(_name, _symbol) { 
	setBaseURI(_initBaseURI);
}
    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI; 
    }
   
	// Public
    function mint(string memory _ticket, bytes32[] calldata _merkleProof, uint256 _mintAmount) public payable {
		uint256 ticketMintedCount = ticketMintedBalance[_ticket]; 
        uint256 supply = _tokenIdCounter.current();

		require(!paused, "Contract is paused");
        require(_mintAmount <= maxMintAmount, "Mint limit exceeded");
        require(_mintAmount > 0, "You need to Mint at least 1 Dented"); 
		require(supply.add(_mintAmount) <= maxSupply, "Not enough Denteds for request");
		require(ticketMintedCount + _mintAmount <= limitPerTicket, "No more Denteds for this Ticket");

		bytes32 leaf = keccak256(abi.encodePacked(_ticket));
		require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You do not have a valid mint ticket");

        for(uint256 i = 0; i < _mintAmount; i++) {
            uint256 mintIndex = _tokenIdCounter.current();
            if (mintIndex < maxSupply) {
                ticketMintedBalance[_ticket]++;
                _tokenIdCounter.increment();
				uint256 newTokenId = _tokenIdCounter.current();
                _safeMint(msg.sender, newTokenId);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) { 
		require(_exists(tokenId), "Token doesn't exist" );
		string memory currentBaseURI = _baseURI(); 
		return bytes(currentBaseURI).length > 0
			? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
			: ""; 
    }

    // Support functions
    function reserveTokens(uint256 _amount) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        require(supply.add(_amount) <= maxSupply, "Not enough Denteds for request"); 
		for(uint256 i = 0; i < _amount; i++) {
            uint256 mintIndex = _tokenIdCounter.current();
            if (mintIndex < maxSupply) {
                _tokenIdCounter.increment();
				uint256 newTokenId = _tokenIdCounter.current();
                _safeMint(msg.sender, newTokenId);
            }
        }
    }
	function getTokenCount() public view returns (uint256) {
		return _tokenIdCounter.current(); 
    }
	function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner() {
        merkleRoot = _merkleRoot;
    }
    function setMaxSupply(uint256 _maxSupply) public onlyOwner() {
        maxSupply = _maxSupply;
    }
	function setPerTicketLimit(uint256 _limit) public onlyOwner() {
        limitPerTicket = _limit; 
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI; 
    }
    function pause() public onlyOwner {
        paused = true;
    }
    function unpause() public onlyOwner {
        paused = false;
    }
}