// contracts/SoulToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./SoulProtection.sol";

contract SoulToken is ERC20Burnable, SoulProtection {
	constructor() ERC20("Spirits of Nintia", "SOULS") {
		// Initial supply of 1 billion tokens
		_mint(_msgSender(), 1000000000 * 10**18);
		_transferWhitelist[_msgSender()] = true;
	}

	/**
	 * @dev _transfer function of SoulToken
	 *
   * Our transfer function rejects the transaction if the sender is a whale or a bot.
   * The definitions for "whale" and "bot" are explained at {isWhale} and {isBot} functions.

   * Every transaction has a % fee that goes to our Game Reward Pool. This fee is calculated
   * at function {getRewardPoolFeeAmount}.
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal override {
		uint256 rewardPoolFeeAmount = 0;

		if (!isWalletWhitelisted(sender) && !isWalletWhitelisted(recipient)) {
			// We are pausing before adding liquidity and unpausing moments after.
			// This way, we can do our anti-bot and anti-whale setup
			require(!areTransfersPaused(), "SoulToken: transfers are paused");

			// Reject transaction if amount is too large
			require(!isWhale(amount), "SoulToken: amount is too high");

			// If user is buying (_liquidityPool[sender] is true), he's the recipient (cooldown the recipient)
			// If user is selling (_liquidityPool[sender] is false), he's the sender (cooldown the sender)
			address walletToCooldown = _liquidityPool[sender] ? recipient : sender;

			require(!isBot(walletToCooldown), "SoulToken: wait for your cooldown");

			// Saving current timestamp for walletToCooldown last transaction
			lastTransactionTime[walletToCooldown] = block.timestamp;

			// Calculate the fee that goes to the game reward pool
			rewardPoolFeeAmount = getRewardPoolFeeAmount(amount);
      super._transfer(sender, rewardPoolAddress, rewardPoolFeeAmount);
		}
    
		super._transfer(sender, recipient, amount - rewardPoolFeeAmount);
	}
}