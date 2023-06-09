// SPDX-License-Identifier: MIT
//
//  ********  **     **    ******   **        **  *******  
// /**/////  /**    /**   **////** /**       /** /**////** 
// /**       /**    /**  **    //  /**       /** /**    /**
// /*******  /**    /** /**        /**       /** /**    /**
// /**////   /**    /** /**        /**       /** /**    /**
// /**       /**    /** //**    ** /**       /** /**    ** 
// /******** //*******   //******  /******** /** /*******  
// ////////   ///////     //////   ////////  //  ///////   
//
// by collect-code 2022
// https://collect-code.com/
//
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IEuclidRandomizer.sol";
import "./IEuclidFormula.sol";
import "./EuclidShuffle.sol";
import "./Whitelist.sol";

/// @custom:security-contact [email protected]
contract Euclid is ERC721, ERC721Enumerable, Ownable {
	using SafeMath for uint256;
	using Strings for uint256;

	IEuclidRandomizer randomizer;
	IEuclidFormula formula;

	EuclidShuffle.ShuffleState tokenShuffle;
	mapping(uint256 => uint128) public tokenIdToHash;
	address payee;
	uint256 payeePercentage;

	struct State {
		uint8 phase;							// 0:paused, 1:whitelist, 2:public
		uint256 price1;						// Phase1 price in pwei/finney (ETH/1000)
		uint256 price2;						// Phase2 price in pwei/finney (ETH/1000)
		uint256 maxBuyout;				// max a user can mint at once
		uint256 maxSupply;				// total tokens that can be minted
		uint256 availableSupply;	// available to mint
		uint256 mintedCount;			// excluding token zero
	}
	State internal state_;

	struct TokenInfo {
		uint256 tokenNumber;
		uint256 tokenId;
		uint128 hash;
	}

	WhitelistStorage whitelist;

	event Minted(address indexed to, uint256 indexed tokenNumber, uint256 indexed tokenId, uint128 hash);
	event ChangedPhase(uint8 indexed phase, uint256 indexed price1, uint256 indexed price2);

	constructor(uint256 maxSupply, address randomizer_, address formula_) ERC721("Euclid", "EU") {
		randomizer = IEuclidRandomizer(randomizer_);
		formula = IEuclidFormula(formula_);
		EuclidShuffle.initialize(tokenShuffle, uint32(maxSupply));
		state_ = State(
			0,					// phase
			50,					// price1
			168,				// price2
			12,					// maxBuyout
			maxSupply,	// maxSupply
			maxSupply,	// availableSupply
			0						// mintedCount
		);
	}

	// Required by Interfaces
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}
	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	//---------------------------
	// Admin
	//
	function setPhase(uint8 newPhase, uint256 newPrice1InPwei, uint256 newPrice2InPwei) onlyOwner public {
		state_.phase = newPhase;
		if(newPrice1InPwei > 0) state_.price1 = newPrice1InPwei;
		if(newPrice2InPwei > 0) state_.price2 = newPrice2InPwei;
		emit ChangedPhase(state_.phase, state_.price1, state_.price2);
	}
	function setupWhitelistContract(address contractAddress, uint8 newMintsPerSource, uint8 newMintsPerBuilt) onlyOwner public {
		Whitelist.setupContract(whitelist, contractAddress, newMintsPerSource, newMintsPerBuilt);
	}
	function setPayee(address newPayeeAddress, uint256 newPayeePercentage) onlyOwner public {
		payee = newPayeeAddress;
		payeePercentage = Math.min(newPayeePercentage, 100);
	}
	function withdraw() onlyOwner public {
		payable(msg.sender).transfer(address(this).balance);
	}
	function giftCode(address to, uint256 quantity) onlyOwner public returns (uint256) {
		validatePurchase(quantity, 0);
		return mintCode(to, quantity);
	}

	//---------------------------
	// Internal
	//
	function validatePurchase(uint256 quantity, uint8 phase) internal {
		require(state_.mintedCount < state_.maxSupply, "CC:SoldOut");
		require(quantity > 0 && quantity <= state_.availableSupply && quantity <= state_.maxBuyout, "CC:QuantityNotAvailable");
		require(msg.sender == owner() || (msg.value > 0 && msg.value == calculatePriceForQuantity(quantity, phase)), "CC:BadValue");
	}
	function mintCode(address to, uint256 quantity) internal returns(uint256) {
		uint256 tokenId = 0;
		for(uint256 i = 0 ; i < quantity ; i++) {
			if(totalSupply() > 0) {
				state_.mintedCount = state_.mintedCount.add(1);
			}
			uint128 seed = randomizer.makeSeed(address(this), to, block.number, state_.mintedCount);
			if(state_.mintedCount > 0) {
				tokenId = EuclidShuffle.getNextShuffleId(randomizer, tokenShuffle, seed);
			}
			_safeMint(to, tokenId);
			tokenIdToHash[tokenId] = seed;
			emit Minted(to, state_.mintedCount, tokenId, seed);
		}
		state_.availableSupply = state_.maxSupply - state_.mintedCount;
		if (payee != address(0) && payeePercentage > 0 && msg.value > 0) {
			payable(payee).transfer(msg.value.div(100).mul(payeePercentage));
		}
		return state_.mintedCount;
	}

	//---------------------------
	// Public
	//
	function getState() public view returns (State memory) {
		return state_;
	}
	// Get all whitelisted Tokens of a user, mapped to claimable amount per Token
	function getWhitelistedTokens(address to) public view returns (uint256[] memory, uint8[] memory) {
		return Whitelist.getAvailableMintsForUser(whitelist, to);
	}
	// Get available mints for a whitelisted token
	function getWhitelistAvailableMints(uint256 tokenId, uint256 /*flags*/) public view returns (uint8) {
		return Whitelist.calcAvailableMintsPerTokenId(whitelist, tokenId);
	}
	// Claim Euclid Token using whitelisted Token, during whitelist sale phase
	function claimCode(address to, uint256[] memory tokenIds) public payable returns (uint256) {
		require(totalSupply() > 0, "CC:Unreleased");
		require(state_.phase >= 1, "CC:ChromiumSaleIsPaused");
		uint8 quantity = Whitelist.claimTokenIds(whitelist, tokenIds); // will revert if not owner or none available
		validatePurchase(quantity, 1);
		return mintCode(to, quantity);
	}
	// Purchase Euclid Token(s), during public sale phase
	function buyCode(address to, uint256 quantity) public payable returns (uint256) {
		require(totalSupply() > 0, "CC:Unreleased");
		require(state_.phase == 2, "CC:PublicSaleIsPaused");
		validatePurchase(quantity, 2);
		return mintCode(to, quantity);
	}
	// Get Token prices in WEI
	function calculatePriceForQuantity(uint256 quantity, uint8 phase) public view returns (uint256) {
		return quantity * (phase == 1 ? state_.price1 : state_.price2) * 1_000_000_000_000_000; // 1 ETH=1_000_000_000_000_000_000
	}
	// Get array of prices in WEI, for all allowed purchase quantities
	function getPrices(uint8 phase) public view returns (uint256[] memory result)
	{
		result = new uint[](totalSupply() == 0 ? 0 : Math.min(state_.availableSupply, state_.maxBuyout));
		for(uint256 i = 0 ; i < result.length ; i++) {
			result[i] = calculatePriceForQuantity(i+1, phase);
		}
	}
	// Get all minted tokenIds
	function getMintedTokenIds(uint32 offset, uint32 pageSize) public view returns (uint32[] memory result) {
		if(offset < totalSupply()) {
			uint32 maxPageSize = uint32(totalSupply()) - offset;
			result = new uint32[](pageSize == 0 || pageSize > maxPageSize ? maxPageSize : pageSize);
			for(uint32 i = 0; i < result.length; i++) {
					result[i] = tokenShuffle.ids[offset+i];
			}
		}
	}
	// Get all Token Ids owned by someone
	function getOwnedTokens(address from) public view returns (uint256[] memory result) {
		result = new uint[](balanceOf(from));
		for(uint256 i = 0 ; i < result.length ; i++) {
			result[i] = tokenOfOwnerByIndex(from, i);
		}
	}
	// Get public token info
	function getTokenInfo(address /*from*/, uint32 tokenNumber) public view returns (TokenInfo memory) {
		uint256 tokenId = tokenNumber == 0 ? 0 : tokenShuffle.ids[tokenNumber];
		return TokenInfo(tokenNumber, tokenId, tokenIdToHash[tokenId]);
	}
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), 'CC:BadTokenId');
		uint128 hash = tokenIdToHash[tokenId];
		return string(abi.encodePacked(
			'https://collect-code.com/api/token/euclid/', tokenId.toString(),
			'/metadata?v=1&hash=', (hash > 0 ? uint256(hash).toHexString(16) : '0x0'),
			'&formula=', formula.generateFormula(hash, tokenId)
		));
	}
}