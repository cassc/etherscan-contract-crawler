//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import 'erc721a/contracts/ERC721A.sol';

contract MamaOkayBears is ERC721A, Ownable {

	uint public constant MAX_TOKENS = 5555;
	
	uint public CURR_MINT_COST = 0 ether;
	
	//---- Round based supplies
	string private CURR_ROUND_NAME = "Round 1";
	uint private CURR_ROUND_SUPPLY = 500;
	uint private CURR_ROUND_TIME = 0;
	uint private maxMintAmount = 2;
	uint private nftPerAddressLimit = 2;

	bool public hasSaleStarted = false;
	
	string public baseURI;
	
	constructor() ERC721A("Mama Okay Bears", "MOB") {
		setBaseURI("http://api.mamaokaybears.com/mob/");
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function mintNFT(uint _mintAmount) external payable {
		require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
		require(hasSaleStarted == true, "Sale hasn't started");
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
		require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");
		require((_mintAmount  + balanceOf(msg.sender)) <= nftPerAddressLimit, "Max NFT per address exceeded");

		CURR_ROUND_SUPPLY -= _mintAmount;
		_safeMint(msg.sender, _mintAmount);
		
	}

	
	function getInformations() external view returns (string memory, uint, uint, uint, uint,uint,uint, bool,bool)
	{
		return (CURR_ROUND_NAME,CURR_ROUND_SUPPLY,CURR_ROUND_TIME,CURR_MINT_COST,maxMintAmount,nftPerAddressLimit, totalSupply(), hasSaleStarted,false);
	}

	
	//only owner functions
	
	function setNewRound(uint _supply, uint cost, string memory name, uint perTransactionLimit, uint perAddressLimit, uint theTime, bool saleState) external onlyOwner {
		require(_supply <= (MAX_TOKENS - totalSupply()), "Exceeded supply");
		CURR_ROUND_SUPPLY = _supply;
		CURR_MINT_COST = cost;
		CURR_ROUND_NAME = name;
		maxMintAmount = perTransactionLimit;
		nftPerAddressLimit = perAddressLimit;
		CURR_ROUND_TIME = theTime;
		hasSaleStarted = saleState;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function Giveaways(uint numTokens, address recipient) public onlyOwner {
		require((totalSupply() + numTokens) <= MAX_TOKENS, "Exceeded supply");
		_safeMint(recipient, numTokens);
	}

	function withdraw(uint amount) public payable onlyOwner {
		require(payable(msg.sender).send(amount));
	}
	
	function setSaleStarted(bool _state) public onlyOwner {
		hasSaleStarted = _state;
	}
}