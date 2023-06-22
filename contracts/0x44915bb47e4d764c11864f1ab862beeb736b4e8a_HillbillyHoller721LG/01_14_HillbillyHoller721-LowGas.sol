// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HillbillyHoller721LG is ERC721, Ownable { 
using Strings for uint256;
using SafeMath for uint256;
using Counters for Counters.Counter;

string public baseURI;
string public baseExtension = ".json";
string public notRevealedUri;

uint256 public constant hillbillyPrice = 50000000000000000; //0.05 ETH
uint256 public maxSupply = 3500;
uint256 public maxMintAmount = 5;
uint256 public whitelistedPerAddressLimit = 2; 
uint256 public standardPerAddressLimit = 5;
bytes32 public merkleRoot;

bool public revealed = false;
bool public onlyWhitelisted = true;
bool public paused = true;

mapping(address => uint256) public addressMintedBalance;
Counters.Counter private _tokenIdCounter;

constructor(
string memory _name,
string memory _symbol,
string memory _initBaseURI,
string memory _initNotRevealedUri
) ERC721(_name, _symbol) { setBaseURI(_initBaseURI); setNotRevealedURI(_initNotRevealedUri);

}
    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI; 
    }
   
	// Public
    function mint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public payable {
        uint256 userMintedCount = addressMintedBalance[msg.sender]; 
        uint256 supply = _tokenIdCounter.current();
		require(!paused, "Contract is paused");
        require(_mintAmount <= maxMintAmount, "Don't be greedy- Hillbilly limit exceeded");
        require(hillbillyPrice.mul(_mintAmount) <= msg.value, "Ethereum value sent is not correct");
        require(_mintAmount > 0, "You need to Mint at least 1 Hillbilly"); 
		require(supply.add(_mintAmount) <= maxSupply, "Not enough Hillbillies for request");
		require(userMintedCount + _mintAmount <= standardPerAddressLimit, "No more Hillbillies :(");

        if (msg.sender != owner()) { 
            if(onlyWhitelisted == true) {
				bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You are not whitelisted, please wait for public minting");
				uint256 whitelistedMintedCount = addressMintedBalance[msg.sender];
                require(whitelistedMintedCount + _mintAmount <= whitelistedPerAddressLimit, "Exceeded 2 Hillbillies per whitelisted address");
            } 
			if(onlyWhitelisted == false) {
				require (msg.value >= hillbillyPrice * _mintAmount, "insufficient funds"); 
        	}
    	}

        for(uint256 i = 0; i < _mintAmount; i++) {
            uint256 mintIndex = _tokenIdCounter.current();
            if (mintIndex < maxSupply) {
                addressMintedBalance[msg.sender]++;
                _tokenIdCounter.increment();
				uint256 newTokenId = _tokenIdCounter.current();
                _safeMint(msg.sender, newTokenId);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) { 
		require(_exists(tokenId), "Token doesn't exist" );

		if(revealed == false) {
            return bytes(notRevealedUri).length > 0
			? string(abi.encodePacked(notRevealedUri, tokenId.toString(), baseExtension))
			: ""; 
		}
		
		string memory currentBaseURI = _baseURI(); 
		return bytes(currentBaseURI).length > 0
			? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
			: ""; 
    }

    // Support functions
    function reserveBillies(uint256 _amount) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        require(supply.add(_amount) <= maxSupply, "Not enough Hillbillies for request"); 
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
	function setRevealed(bool _revealed) public onlyOwner() {
        revealed = _revealed; 
    }
	function setOnlyWhitelisted(bool _state) public onlyOwner {
    	onlyWhitelisted = _state; 
    }
    function setStandardPerAddressLimit(uint256 _limit) public onlyOwner() {
        standardPerAddressLimit = _limit; 
    }
	function setWhitelistedPerAddressLimit(uint256 _limit) public onlyOwner() {
        whitelistedPerAddressLimit = _limit; 
    }
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner() {
        maxMintAmount = _newMaxMintAmount; 
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI; 
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI; 
    }
    function pause() public onlyOwner {
        paused = true;
    }
    function unpause() public onlyOwner {
        paused = false;
    }
    function withdraw() public payable onlyOwner { 
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success); 
    }

}