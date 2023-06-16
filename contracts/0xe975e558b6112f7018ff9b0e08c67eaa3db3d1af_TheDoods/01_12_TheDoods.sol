//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract TheDoods is ERC721, Ownable {
	using Counters
	for Counters.Counter;
	Counters.Counter private _tokenIds;
	
	
	uint public constant MAX_TOKENS = 6969;
	uint public constant MAX_TOKENS_VIP = 0;
	
	
	uint public CURR_MINT_COST = 0.033 ether;
	
	//---- Round based supplies
	string public CURR_ROUND_NAME = "Private";
	string public CURR_ROUND_PASSWORD = "0";
	uint public CURR_ROUND_SUPPLY = 4500;
	uint public CURR_ROUND_TIME = 1642017600000;
	
	uint public maxMintAmount = 3;
	uint public nftPerAddressLimit = 3;
	uint public currentVIPs = 0;
	uint public currentNormal = 0;
	
	bool public hasSaleStarted = false;
	bool public onlyWhitelisted = false;
	
	string public baseURI;
	
	mapping(address => uint) public addressMintedBalance;
	mapping (address => bool) whitelistUserAddresses;

	
	
	
	constructor() ERC721("The Doods", "TheDoods") {
		setBaseURI("http://api.thedoods.org/doods/");
	}

	function totalSupply() public view returns(uint) {
		return _tokenIds.current();
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function mintNFT(uint _mintAmount) public payable {
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
		require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
		require(hasSaleStarted == true, "Sale hasn't started");
		require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");
		
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "User is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT per address exceeded");
        }
        
		
		for (uint256 i = 1; i <= _mintAmount; i++) {
			addressMintedBalance[msg.sender]++;
			_tokenIds.increment();
			CURR_ROUND_SUPPLY--;
			currentNormal = currentNormal + 1;
			_safeMint(msg.sender, currentNormal);
		}

	}

	
	function isWhitelisted(address _user) public view returns (bool) {
		return whitelistUserAddresses[_user];
	}
	
   function getInformations() public view returns (string memory)
   {
	   string memory information = string(abi.encodePacked(CURR_ROUND_NAME,",", Strings.toString(CURR_ROUND_SUPPLY),",",Strings.toString(CURR_ROUND_TIME),",",Strings.toString(CURR_MINT_COST),",",Strings.toString(maxMintAmount), ",",CURR_ROUND_PASSWORD));
	   return information;
   }
	
	
	//only owner functions
	
	function setNewRound(uint _supply, uint cost, string memory name, uint maxMint, uint perAddressLimit, uint theTime, string memory password) public onlyOwner {
		require(_supply <= MAX_TOKENS - totalSupply(), "Exceeded supply");
		CURR_ROUND_SUPPLY = _supply;
		CURR_MINT_COST = cost;
		CURR_ROUND_NAME = name;
		maxMintAmount = maxMint;
		nftPerAddressLimit = perAddressLimit;
		CURR_ROUND_TIME = theTime;
		CURR_ROUND_PASSWORD = password;
	}
	
	function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
		nftPerAddressLimit = _limit;
	}

	function setmaxMintAmount(uint _newmaxMintAmount) public onlyOwner {
		maxMintAmount = _newmaxMintAmount;
	}

	function setCurrentSupply(uint numSupply) public onlyOwner{
		require(numSupply<=MAX_TOKENS - totalSupply(), "Can't add new character NFTs. Would exceed supply");
		CURR_ROUND_SUPPLY = numSupply;
	}

	function setCost(uint _newCost) public onlyOwner {
		CURR_MINT_COST = _newCost;
	}
	
	
	function whitelistAddresses (address[] calldata users) public onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			whitelistUserAddresses[users[i]] = true;
		}
	}


	function removeWhitelistAddresses (address[] calldata users) external onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			delete whitelistUserAddresses[users[i]];
		}
	}
	
	function setOnlyWhitelisted(bool _state) public onlyOwner {
		onlyWhitelisted = _state;
	}


	function setBaseURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	function getBaseURI() public onlyOwner view returns(string memory) {
		return baseURI;
	}

	function reserveVIP(uint numTokens, address recipient) public onlyOwner {
		require((currentVIPs + numTokens) <= MAX_TOKENS_VIP, "Exceeded VIP supply");
		uint index;
		for(index = 1; index <= numTokens; index++) {
			_tokenIds.increment();
			currentVIPs = currentVIPs + 1;
			uint theToken = currentVIPs + MAX_TOKENS;
			addressMintedBalance[recipient]++;
			_safeMint(recipient, theToken);
		}
	}

	function Giveaways(uint numTokens, address recipient) public onlyOwner {
		require((_tokenIds.current() + numTokens) <= MAX_TOKENS, "Exceeded supply");
		uint index;
		// Reserved for the people who helped build this project
		for(index = 1; index <= numTokens; index++) {
			_tokenIds.increment();
			currentNormal = currentNormal + 1;
			addressMintedBalance[recipient]++;
			_safeMint(recipient, currentNormal);
		}
	}

	function withdrawAll() public payable onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}
	
	
	function setSaleStarted(bool _state) public onlyOwner {
		hasSaleStarted = _state;
	}
}