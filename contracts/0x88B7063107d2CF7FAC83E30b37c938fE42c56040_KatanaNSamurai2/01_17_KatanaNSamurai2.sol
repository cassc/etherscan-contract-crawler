// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './ERC721B.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//  _  __ _   _   _____   ___       ___
// | |/ /| \ | | / ____| |__ \     / _ \
// | ' / |  \| || (___      ) |   | | | |
// |  <  | . ` | \___ \    / /    | | | |
// | . \ | |\  | ____) |  / /_  _ | |_| |
// |_|\_\|_| \_||_____/  |____|(_) \___/

contract KatanaNSamurai2 is Ownable, EIP712, ERC721B {

	using SafeMath for uint256;
	using Strings for uint256;

	// Sales variables
	// ------------------------------------------------------------------------
	uint public MAX_SAMURAI = 6666;
	uint public STAGE_LIMIT = 666;
	uint public PRICE = 0.075 ether;
	uint public numPresale = 0;
	uint public numSale = 0;
	uint public numClaim = 0;
	uint public numGiveaway = 0;
	uint public totalSupply = 0;
	bool public hasSaleStarted = true;
	bool public hasPresaleStarted = true;
	bool public hasClaimStarted = true;
	string private _baseTokenURI = "http://api.ramen.katanansamurai.art/Metadata/";

	mapping (address => uint256) public hasClaimed;
	mapping (address => uint256) public hasPresale;

    uint256 public saleStartTimestamp = 1642518000; // Public Sale start time in epoch format
    uint256 public presaleStartTimestamp = 1642410000; // PreSale start time in epoch format

	// Events
	// ------------------------------------------------------------------------
	event mintEvent(address owner, uint256 quantity, uint256 totalSupply);
	
	// Constructor
	// ------------------------------------------------------------------------
	constructor()
	EIP712("Katana N Samurai 2", "1.0.0")  
	ERC721B("Katana N Samurai 2", "KNS2.0"){}

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyPublicSale() {
		require(hasSaleStarted == true, "PUBLIC_SALE_NOT_ACTIVE");
        require(block.timestamp >= saleStartTimestamp, "NOT_IN_PUBLIC_SALE_TIME");
        _;
    }

    modifier onlyPresale() {
		require(hasPresaleStarted == true, "PRESALE_NOT_ACTIVE");
        require(block.timestamp >= presaleStartTimestamp, "NOT_IN_PRESALE_TIME");
        _;
    }

	// Verify functions
	// ------------------------------------------------------------------------
	function verify(uint256 maxClaimNum, bytes memory SIGNATURE) public view returns (bool){
		address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("NFT(address addressForClaim,uint256 maxClaimNum)"), _msgSender(), maxClaimNum))), SIGNATURE);

		return owner() == recoveredAddr;
	}

	// Claim functions
	// ------------------------------------------------------------------------
	function claimSamurai(uint256 quantity, uint256 maxClaimNum, bytes memory SIGNATURE) external {

		require(hasClaimStarted == true, "Claim hasn't started.");
		require(verify(maxClaimNum, SIGNATURE), "Not eligible for claim.");
		require(quantity > 0 && hasClaimed[msg.sender].add(quantity) <= maxClaimNum, "Exceed the quantity that can be claimed");

		for (uint i = 0; i < quantity; i++) {
			_safeMint(msg.sender, totalSupply);
			totalSupply = totalSupply.add(1);
		}

		numClaim = numClaim.add(quantity);
		hasClaimed[msg.sender] = hasClaimed[msg.sender].add(quantity);

		emit mintEvent(msg.sender, quantity, totalSupply);
	}

	// Presale functions
	// ------------------------------------------------------------------------
	function mintPresaleSamurai(uint256 quantity, uint256 maxClaimNumOnPresale, bytes memory SIGNATURE) external payable onlyPresale{
		require(totalSupply.add(quantity) <= STAGE_LIMIT, "This stage is sold out!");
		require(verify(maxClaimNumOnPresale, SIGNATURE), "Not eligible for presale.");
		require(quantity > 0 && hasPresale[msg.sender].add(quantity) <= maxClaimNumOnPresale, "Exceeds max presale number.");
		require(msg.value >= PRICE.mul(quantity), "Ether value sent is below the price.");
		require(totalSupply.add(quantity) <= MAX_SAMURAI, "Exceeds MAX_SAMURAI.");

		for (uint i = 0; i < quantity; i++) {
			_safeMint(msg.sender, totalSupply);
			totalSupply = totalSupply.add(1);
		}

		numPresale = numPresale.add(quantity);
		hasPresale[msg.sender] = hasPresale[msg.sender].add(quantity);

		emit mintEvent(msg.sender, quantity, totalSupply);
	}

	// Giveaway functions
	// ------------------------------------------------------------------------
	function giveawayMintSamurai(address _to, uint256 quantity) external onlyOwner{
		require(totalSupply.add(quantity) <= MAX_SAMURAI, "Exceeds MAX_SAMURAI.");

		for (uint i = 0; i < quantity; i++) {
			_safeMint(_to, totalSupply);
			totalSupply = totalSupply.add(1);
		}

		numGiveaway = numGiveaway.add(quantity);
		emit mintEvent(_to, quantity, totalSupply);
	}

	// Mint functions
	// ------------------------------------------------------------------------
	function mintPublicSaleSamurai(uint256 numPurchase) external payable onlyPublicSale{
		require(numPurchase > 0 && numPurchase <= 50, "You can mint minimum 1, maximum 50 samurais.");
		require(totalSupply.add(numPurchase) <= STAGE_LIMIT, "This stage is sold out!");
		require(totalSupply.add(numPurchase) <= MAX_SAMURAI, "Sold out!");
		require(msg.value >= PRICE.mul(numPurchase), "Ether value sent is below the price.");

		for (uint i = 0; i < numPurchase; i++) {
			_safeMint(msg.sender, totalSupply);
			totalSupply = totalSupply.add(1);
		}

		numSale = numSale.add(numPurchase);
		emit mintEvent(msg.sender, numPurchase, totalSupply);
	}

	// Base URI Functions
	// ------------------------------------------------------------------------
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "TOKEN_NOT_EXISTS");
		
		return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
	}

    // Burn Functions
    // ------------------------------------------------------------------------
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

	// setting functions
	// ------------------------------------------------------------------------
	function setURI(string calldata _tokenURI) external onlyOwner {
		_baseTokenURI = _tokenURI;
	}

	function setSTAGE_LIMIT(uint _STAGE_LIMIT) external onlyOwner {
		STAGE_LIMIT = _STAGE_LIMIT;
	}

	function setMAX_SAMURAI(uint _MAX_num) external onlyOwner {
		MAX_SAMURAI = _MAX_num;
	}

	function set_PRICE(uint _price) external onlyOwner {
		PRICE = _price;
	}

    function setPresale(bool _hasPresaleStarted,uint256 _presaleStartTimestamp) external onlyOwner {
        hasPresaleStarted = _hasPresaleStarted;
        presaleStartTimestamp = _presaleStartTimestamp;
    }

    function setPublicSale(bool _hasSaleStarted,uint256 _saleStartTimestamp) external onlyOwner {
        hasSaleStarted = _hasSaleStarted;
        saleStartTimestamp = _saleStartTimestamp;
    }

	function setClaim(bool _hasClaimStarted) external onlyOwner {
		hasClaimStarted = _hasClaimStarted;
	}

	// Withdrawal functions
	// ------------------------------------------------------------------------
	function withdrawAll() public payable onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}
}