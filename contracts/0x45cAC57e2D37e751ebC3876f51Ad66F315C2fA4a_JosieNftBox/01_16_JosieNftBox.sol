//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./JosieNftBoxMetadata.sol";
import "./WithOperatorFilter.sol";

contract JosieNftBox is ERC721, Ownable, WithOperatorFilter {
	// Metadata image
	JosieNftBoxMetadata public metadataContract;

	uint256 public currentTokenSupply;

	uint256 public START_TIMESTAMP;
	uint256 constant public ROLLS_PER_DAY = 5;
	uint256 constant SECONDS_BETWEEN_ROLLS = 86400;

	uint256 public tokensRolled;

	// Revealed token information
	mapping(uint256 => uint256) public revealedTokenVariant;
	uint256 constant NUM_REVEALED_VARIANTS = 12;

	// Random reveal variables
	uint256 internal _leftToRoll;
	mapping(uint256 => uint256) internal _idSwaps;
	mapping(uint256 => uint256) internal _prizeDrawnSwaps;
	uint256 internal _currentPrng;

	// Royalty configuration
	address public royaltyRecipient;
	uint256 public royaltyBps = 1000;

	// Prizes
	string[15] PRIZES = [
		"Filter - #17/100",
		"Looks like you've had a bit too much to think - #17/21",
		"Looks like you've had a bit too much to think - #15/21",
		"This is America - #57/70",
		"This is America - #60/70",
		"CyberBrokers - Phillip Whitlock #8128",
		"CyberBrokers - Sonia of the Twilight #8018",
		"CyberBrokers - Enya the Sickly #5513",
		"CyberBrokers - Soppy Vader #3141",
		"CyberBrokers - Everly of Uncouth #7612",
		"CyberBrokers - Tainted Stoyer #6123",
		"CyberBrokers - Zion Lackadaisical #423",
		"CyberBrokers - Nolan from Pretty #2274",
		"CyberBrokers - Macy Slurry #8905",
		"CyberBrokers - Deja of Monroe #5876"
	];

	event RevealToken(uint256 tokenId, string variant, string prize);

	constructor(
		address _metadataContractAddress
	)
		ERC721("Don't Feed the Pigeons", 'PIGEONS')
	{
		setMetadataContract(_metadataContractAddress);
		START_TIMESTAMP = block.timestamp;

		// Default royalty recipient
		royaltyRecipient = msg.sender;
	}

	/**
	 * Owner-only functions
	 **/
	function setIsOperatorFilterEnabled(bool _setting) external onlyOwner {
		isOperatorFilterEnabled = _setting;
	}

	function setMetadataContract(address _metadataContractAddress) public onlyOwner {
		metadataContract = JosieNftBoxMetadata(_metadataContractAddress);
	}

	function setRoyaltyRecipient(address _recipient) external onlyOwner {
		royaltyRecipient = _recipient;
	}

	function setRoyaltyBps(uint256 _bps) external onlyOwner {
		require(_bps < 10000, "Royalty basis points must be under 10,000 (100%)");
		royaltyBps = _bps;
	}

	function airdrop(
		address[] calldata addresses
	)
		external
		onlyOwner
	{
		require(addresses.length > 0, "Invalid addresses lengths");

		uint256 currentToken = totalSupply();

		for (uint256 idx; idx < addresses.length; idx++) {
			require(currentToken < 500, "At max supply.");

			_safeMint(
				addresses[idx],
				currentToken + idx + 1
			);
		}

		currentTokenSupply = currentToken + addresses.length;
	}

	function rollReveals()
		external
		onlyOwner
	{
		// If we've rolled all tokens, bail
		require(tokensRolled < totalSupply(), "Rolled all tokens");

		// Determine how many days passed, for how many days of rolls we need to perform
		uint256 tokensToRoll = numToRoll();

		// If we have no tokens to roll, bail
		require(tokensToRoll > 0, "No tokens to roll yet");

		// Cap the number of tokens to roll at 5 for gas concerns
		tokensToRoll = tokensToRoll > 5 ? 5 : tokensToRoll;

		// Copy the current data
		uint256 leftToRoll = totalSupply() - tokensRolled;
		uint256 currentPrng = _currentPrng;

		// Roll the tokens
		uint256 _tokenId;
		uint256 _prizeIndex;
		for (uint256 idx; idx < tokensToRoll; idx++) {
			// Generate the next random number
			currentPrng = _prng(currentPrng, leftToRoll, 1);

			// Pull the next token ID
			_tokenId = _pullRandomUniqueIndex(currentPrng, leftToRoll, _idSwaps);

			// Generate the revealed token variant
			revealedTokenVariant[_tokenId] = 1 + (_prng(currentPrng, leftToRoll, 42) % (NUM_REVEALED_VARIANTS));

			// Pull the prize index -- start at 0th index to map with the prize array
			_prizeIndex = (leftToRoll == 1) ? 500 : (_pullRandomUniqueIndex(_prng(currentPrng, leftToRoll, 69), leftToRoll - 1, _prizeDrawnSwaps) - 1);

			// Decrement the local mint counter
			leftToRoll--;

			// Reveal the token
			_revealToken(_tokenId, _prizeIndex);
		}

		// Store the latest values
		_currentPrng = currentPrng;

		// Update the count of tokens rolled
		tokensRolled += tokensToRoll;
	}

	function numToRoll()
		public
		view
		returns (
			uint256
		)
	{
		uint256 tokensToRoll = ((((block.timestamp - START_TIMESTAMP) / SECONDS_BETWEEN_ROLLS) + 1) * ROLLS_PER_DAY) - tokensRolled;

		// Do not exceed the number left to roll
		if (tokensToRoll > totalSupply() - tokensRolled) {
			tokensToRoll = totalSupply() - tokensRolled;
		}

		return tokensToRoll;
	}

	function _revealToken(
		uint256 _tokenId,
		uint256 _prizeIndex
	)
		private
	{
		string memory prize = "N/A";
		if (_prizeIndex < PRIZES.length) {
			prize = PRIZES[_prizeIndex];
		} else if (_prizeIndex == 500) {
			prize = 'CryptoPunk #9964';
		}
		emit RevealToken(_tokenId, metadataContract.VARIANT_NAMES(revealedTokenVariant[_tokenId]), prize);
	}

	/**
	 * Public functions
	 **/

	function totalSupply() public view returns (uint256) {
        return currentTokenSupply;
    }

	function tokenURI(
		uint256 _tokenId
	)
		public
		view
		virtual
		override
	returns (
		string memory
	) {
		require(address(metadataContract).code.length > 0, "Metadata contract not set");

		return metadataContract.constructTokenURI(
			_tokenId,
			revealedTokenVariant[_tokenId]
		);
	}


	/**
	 * Credit: created by dievardump (Simon Fremaux)
	 **/
	function _pullRandomUniqueIndex(
		uint256 currentPrng,
		uint256 leftToRoll,
		mapping(uint256 => uint256) storage _swaps
	)
		internal
		returns (uint256)
	{
		require(leftToRoll > 0, "No more unique indexes to pull");

		// get a random id
		uint256 index = 1 + (currentPrng % leftToRoll);
		uint256 chosenIndex = _swaps[index];
		if (chosenIndex == 0) {
			chosenIndex = index;
		}

		uint256 temp = _swaps[leftToRoll];

		// "swap" indexes so we don't lose any unminted ids
		// either it's id _leftToRoll or the id that was swapped with it
		if (temp == 0) {
			_swaps[index] = leftToRoll;
		} else {
			// get some refund
			_swaps[index] = temp;
			delete _swaps[leftToRoll];
		}

		return chosenIndex;
	}

	function _prng(
		uint256 currentPrng,
		uint256 leftToRoll,
		uint256 blockOffset
	)
		internal
		view
		returns (uint256)
	{
		return uint256(
			keccak256(
				abi.encodePacked(
					blockhash(block.number - blockOffset),
					block.difficulty,
					currentPrng,
					leftToRoll
				)
			)
		);
	}

	/**
	 * OpenSea
	 **/

	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}

	function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}

	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
		public
		override
		onlyAllowedOperator(from)
	{
		super.safeTransferFrom(from, to, tokenId, data);
	}


	/**
	 * On-Chain Royalties & Interface
	 **/
	function supportsInterface(bytes4 interfaceId)
		public
		view
		override
		returns (bool)
	{
		return interfaceId == this.royaltyInfo.selector || super.supportsInterface(interfaceId);
	}

	function royaltyInfo(uint256, uint256 amount)
		public
		view
		returns (address, uint256)
	{
		return (royaltyRecipient, (amount * royaltyBps) / 10000);
	}
}