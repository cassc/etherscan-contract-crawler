//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract MechPartsAfterglowToken is ERC1155Burnable, Ownable {

	// Auto-approved operators
	address[] public autoApprovedOperators;

	// Metadata
	string public name = 'TPL Mech Afterglow';
	string public symbol = 'TPLAFTERGLOW';

	// Royalty configuration
	address public royaltyRecipient;
	uint256 public royaltyBps = 500;

	/**
	 * Management
	 */

	constructor()
		ERC1155("ipfs://Qmdo1GeuYE9UohkUr4WqBSsxqLs653zGd6nVkLrGGNhiwW/{id}.json")
		Ownable()
	{
		// Default royalty recipient
		royaltyRecipient = msg.sender;
	}

	/**
	 * Override the approval to include contracts we support
	 **/
	function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
		for (uint256 idx; idx < autoApprovedOperators.length; idx++) {
			if (operator == autoApprovedOperators[idx]) {
				return true;
			}
		}

		return super.isApprovedForAll(account, operator);
	}


	/**
	 * Ownership functions
	 **/
	function setURI(string memory baseURI)
		external
		onlyOwner
	{
		_setURI(baseURI);
	}

	function airdrop(
		address[] calldata addresses,
		uint256[] calldata tokenIds,
		uint256[] calldata amounts
	)
		external
		onlyOwner
	{
		require(addresses.length > 0 && addresses.length == tokenIds.length && tokenIds.length == amounts.length, "Invalid array lengths");

		for (uint256 idx; idx < addresses.length; idx++) {
			_mint(
				addresses[idx],
				tokenIds[idx],
				amounts[idx],
				""
			);
		}
	}

	function addAutoApprovedOperator(address operator) external onlyOwner {
		autoApprovedOperators.push(operator);
	}

	function removeAutoApprovedOperatorByIndex(uint256 idx) external onlyOwner {
		require(idx < autoApprovedOperators.length, "Index greater than autoApprovedOperators length");
		autoApprovedOperators[idx] = autoApprovedOperators[autoApprovedOperators.length-1];
		autoApprovedOperators.pop();
	}

	function setRoyaltyRecipient(address _recipient)
		external
		onlyOwner
	{
		royaltyRecipient = _recipient;
	}

	function setRoyaltyBps(uint256 _bps)
		external
		onlyOwner
	{
		require(_bps < 10000, "Royalty basis points must be under 10,000 (100%)");
		royaltyBps = _bps;
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