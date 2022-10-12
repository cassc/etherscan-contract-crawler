// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/MentalHealthCoalition.sol";

/// @title Initiative2
/// Minter for The All Together Series, part of The Mental Health Coalition NFT Collection
contract Initiative2 is Ownable {

	/// Indicates that the provided wallet is ineligible for airdrop
	/// @param wallet The wallet address that was found to be ineligible
	error IneligibleWallet(address wallet);

	/// Indicates that an invalid amount of tokens to mint was provided
	error InvalidAmount();

	/// Indicates that an invalid sum of ETH was provided during mint
	error InvalidPrice();

	/// Indicates that there are no more tokens in this sale to be minted
	error SoldOut();

	/// Maximum quantity of tokens that can be minted at once
	uint256 public constant MAX_MINT_QUANTITY = 10;

	/// The per-token mint price
	uint256 public constant MINT_PRICE = 0.08 ether;

	/// The total number of tokens that will be minted in this sale
	uint256 public constant MAX_MINT = 500;

	/// @dev Reference to the MentalHealthCoalition ERC-1155 contract
	MentalHealthCoalition private immutable _mentalHealthCoalition;

	/// @dev The number of tokens currently minted by this contract
	uint256 private _minted;

	/// @dev The recipient of the raised funds
	address payable private immutable _recipient;

	/// @dev A seed used in selected specific token ids for mint
	uint256 private _seed;

	/// Constructs the `Initiative1` minting contract
	/// @param mentalHealthCoalition The address of the `MentalHealthCoalition` ERC-1155 contract
	/// @param recipient The recipient of the raised funds
	/// @param seed The initial seed used for token selection
	constructor(address mentalHealthCoalition, address payable recipient, uint256 seed) Ownable() payable {
		require(mentalHealthCoalition != address(0) && recipient != address(0), "constructor: invalid inputs");
		_mentalHealthCoalition = MentalHealthCoalition(mentalHealthCoalition);
		_recipient = recipient;
		_seed = seed;
	}

	/// @return Returns the available supply of tokens minted by this contract
	function availableSupply() external view returns (uint256) {
		if (_minted >= MAX_MINT) return 0;
		return MAX_MINT - _minted;
	}

	/// Airdrops tokens to the provided wallets based on the amounts per token id
	/// @dev Used to reward certain wallets based on their current holdings
	/// @param wallets The wallets that will receive the airdrop
	/// @param tokenIds For each wallet, the token ids to airdrop
	/// @param amountsById For each wallet, the amounts to mint for each token id
	/// @param resultSeed The resulting seed as returned by calculateAirdrop
	function airdrop(address[] calldata wallets, uint256[][] calldata tokenIds, uint256[][] calldata amountsById, uint256 resultSeed) external onlyOwner {
		uint256[] memory blank = new uint256[](0);
		unchecked {
			for (uint index = 0; index < wallets.length; index++) {
				_mentalHealthCoalition.mintBurnBatch(wallets[index], tokenIds[index], amountsById[index], blank, blank);
			}
		}
		_seed = resultSeed;
	}

	/// Used with airdrop to calculate the spread while saving gas
	/// @param wallets The collection of wallets with which to calculate the airdrop
	/// @return tokenIds The calculated tokenIds parameter for the airdrop call
	/// @return amountsById The calculated amountsById parameter for the airdrop call
	/// @return resultSeed The calculated resultSeed parameter for the airdrop call
	function calculateAirdrop(address[] calldata wallets) external view onlyOwner returns (uint256[][] memory tokenIds, uint256[][] memory amountsById, uint256 resultSeed) {
		tokenIds = new uint256[][](wallets.length);
		amountsById = new uint256[][](wallets.length);
		uint256 seed = _seed;
		for (uint index = 0; index < wallets.length; index++) {
			uint amount = _specialOwnershipAmount(wallets[index]);
			if (amount == 0) revert IneligibleWallet(wallets[index]);
			(uint256[] memory walletTokenIds, uint256[] memory walletAmountsById, uint256 walletResultSeed) = _distributeMint(amount, seed);
			tokenIds[index] = walletTokenIds;
			amountsById[index] = walletAmountsById;
			seed = walletResultSeed;
		}
		resultSeed = seed;
	}

	/// Mints the provided type and quantity of The All Together tokens
	/// @dev There are some optimizations to reduce minting gas costs, which have been thoroughly unit tested
	/// @param amount The amount to mint
	function mintKennethisms(uint256 amount) external payable {
		// Check for a valid mint
		if (amount == 0 || amount > MAX_MINT_QUANTITY) revert InvalidAmount();
		if (msg.value != MINT_PRICE * amount) revert InvalidPrice();
		unchecked { // bounds for `amount` and `_minted` are known and won't cause an overflow
			uint totalMinted = _minted + amount;
			if (totalMinted > MAX_MINT) revert SoldOut();
			_minted = totalMinted;
		}
		// Obtain the mint amounts
		(uint256[] memory tokenIds, uint256[] memory amountsById, uint256 resultSeed) = _distributeMint(amount, _seed);
		_seed = resultSeed;
		// Call the minting function
		uint256[] memory blank = new uint256[](0);
		_mentalHealthCoalition.mintBurnBatch(_msgSender(), tokenIds, amountsById, blank, blank);
	}

	/// @dev Withdraws proceeds for donation
	function withdrawProceeds() external {
        require(owner() == _msgSender() || _recipient == _msgSender(), "Ownable: caller is not the owner");
		uint256 balance = address(this).balance;
		if (balance > 0) {
			Address.sendValue(_recipient, balance);
		}
	}

	/// Distributes the amounts of tokens to mint based on the amount and a seed, which supports airdrops and regular mints
	function _distributeMint(uint256 amount, uint256 seed) private view returns (uint256[] memory tokenIds, uint256[] memory amountsById, uint256 resultSeed) {
		// Determine the token ids that will be minted using a pseudo-random function
		bytes32 seedBytes = _hashSeed(seed);
		uint count = 0; // Determines the size of the input arrays for minting
		uint8[4] memory amounts = [0, 0, 0, 0];
		unchecked { // bounds for `index`, `amount`, and `count` are all known and do not need to be checked for overflows
			for (uint index = 0; index < amount; ++index) {
				uint tokenId = _selectTokenId(uint8(seedBytes[index]));
				uint currentAmount = amounts[tokenId];
				if (currentAmount == 0) ++count;
				amounts[tokenId] = uint8(currentAmount + 1);
			}
		}
		// Now prepare the arrays to be passed into the minting function
		tokenIds = new uint256[](count);
		amountsById = new uint256[](count);
		count = 0; // Reset count as an index into the arrays above
		unchecked { // bounds for `index`, `amount`, and `count` are all known and do not need to be checked for overflows
			for (uint index = 0; index < amounts.length; ++index) {
				uint current = amounts[index];
				// Are we minting this token id?
				if (current == 0) continue;
				tokenIds[count] = index + 8; // We mint token ids 8-11
				amountsById[count] = current;
				// Have we finished checking non-0 ids?
				if (++count == tokenIds.length) break;
			}
		}
		resultSeed = uint256(seedBytes);
	}

	/// Hashes a seed along with a few other variables to improve randomness of selection
	function _hashSeed(uint256 initialSeed) private view returns (bytes32) {
		return keccak256(abi.encodePacked(blockhash(block.number - 1), _msgSender(), initialSeed >> 1));
	}

	/// Bespoke function that picks a token id based on the random input's spread within the desired percentages
	function _selectTokenId(uint8 seedByte) private pure returns (uint256) {
		// Unit tests will confirm that this provides the desired spread of randomness
		if (seedByte < 153) return 0; // Token 0 has a 60% chance (0-152)
		if (seedByte < 204) return 1; // Token 1 has a 20% chance (153-203)
		if (seedByte < 243) return 2; // Token 2 has a 15% chance (204-242)
		return 3; // Token 3 has a 5% chance (243-255)
	}

	/// Returns the owned amount of special tokens by the provided wallet
	function _specialOwnershipAmount(address wallet) private view returns (uint256 amount) {
		amount = _mentalHealthCoalition.balanceOf(wallet, 4);
		amount += _mentalHealthCoalition.balanceOf(wallet, 5);
		amount += _mentalHealthCoalition.balanceOf(wallet, 6);
		amount += _mentalHealthCoalition.balanceOf(wallet, 7);
	}
}