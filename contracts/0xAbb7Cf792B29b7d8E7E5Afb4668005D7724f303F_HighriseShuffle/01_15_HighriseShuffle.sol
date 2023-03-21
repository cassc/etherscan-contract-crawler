// SPDX-License-Identifier: SPDX-License
/// @author aboltc
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Highrises.sol";

// hytha 0xb79C26FAFaaFEB2835FF175d025Db1b9DEEEDF5E

contract HighriseShuffle is Ownable {
	uint8[] private ordering;
	uint128 private orderingIndex = 0;
	uint128 private maxIndex = 8; // this represents a ceiling of all shuffled
	uint256 public listPrice = 500000000000000000; // 0.5 eth
	address public hytha;
	Highrises public highrises;

	constructor(
		uint8[] memory _ordering,
		address highrisesContractAddress,
		address _hytha
	) {
		require(_ordering.length == 8, "WRONG_ORDERING_SIZE");

		ordering = _ordering;
		highrises = Highrises(highrisesContractAddress);
		hytha = _hytha;
	}

	/**
	 * --------------
	 * State
	 */

	/**
	 * God forbid we need this
	 */
	function updateMaxIndex(uint128 _maxIndex) public onlyOwner {
		maxIndex = _maxIndex;
	}

	/**
	 * God forbid we need this
	 */
	function updateOrdering(uint8[] memory _ordering) public onlyOwner {
		ordering = _ordering;
	}

	/**
	 * Transfer token from hytha to sender.
	 */
	function mint() public payable returns (uint128) {
		require(
			highrises.ownerOf(ordering[orderingIndex]) == hytha,
			"NOT_OWNER"
		);
		require(
			highrises.isApprovedForAll(hytha, address(this)),
			"NOT_APPROVED"
		);
		require(orderingIndex < maxIndex, "MINTED_OUT");
		require(listPrice <= msg.value, "LOW_ETH");

		uint128 currentOrdering = ordering[orderingIndex];

		highrises.safeTransferFrom(hytha, msg.sender, currentOrdering);

		// Increment order
		orderingIndex = orderingIndex + 1;

		// But return previous
		return currentOrdering;
	}

	/**
	 * Withdraw to hytha
	 */
	function withdraw() public {
		uint256 balance = address(this).balance;
		payable(hytha).transfer(balance);
	}

	/**
	 * --------------
	 * Views
	 */

	/**
	 * Check if contract has minted out.
	 */
	function isMintedOut() public view returns (bool) {
		return ordering.length == 7;
	}

	/**
	 * Check if hytha approved
	 */
	function didHythaApprove() public view returns (bool) {
		return highrises.isApprovedForAll(hytha, address(this));
	}

	/**
	 * Check if hytha is owner
	 */
	function isHythaOwner() public view returns (bool) {
		return highrises.ownerOf(ordering[orderingIndex]) == hytha;
	}
}