// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IMasterVault} from "src/interfaces/IMasterVault.sol";
import {IProposal} from "src/interfaces/IProposal.sol";

/// @title This proposal rebalances 13.4% of total TVL from Arbitrum to Polygon and decreases Arbitrum score
contract Proposal_230911_00_Zero_Arbitrum is IProposal
{
	function execute() external
	{
		IMasterVault masterVault = IMasterVault(0x66A3188a218c4fA5a151FE6cDefe7ffE59606304);

		// Set new score for Arbitrum network.
		uint256[] memory chainIds = new uint256[](4);
		uint256[] memory scores = new uint256[](4);
		chainIds[0] = 1;
		scores[0] = 300;
		chainIds[1] = 137;
		scores[1] = 434;
		chainIds[2] = 1284;
		scores[2] = 266;
		chainIds[3] = 42161;
		scores[3] = 0;

		masterVault.updateScores(chainIds, scores);

		masterVault.rebalance(42161, 137, 1000, 1);
	}
}