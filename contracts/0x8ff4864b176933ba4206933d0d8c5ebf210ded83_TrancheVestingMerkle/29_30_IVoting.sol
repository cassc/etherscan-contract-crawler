// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";

interface IVoting is IVotes {
	event SetVoteFactor(uint256 voteFactor);

	// an total current voting power
	function getTotalVotes() external view returns (uint256);

	// a weighting factor used to convert token holdings to voting power (eg in basis points)
	function getVoteFactor(address account) external view returns (uint256);
}