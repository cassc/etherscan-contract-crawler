// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./GaugeVoting.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";

/**
 * @title   GaugeVotingLens
 * @author  WombexFinance
 */
contract GaugeVotingLens {
    GaugeVoting public gaugeVoting;

    struct Pool {
        address lpToken;
        address rewards;
        bool isActive;
        int256 votes;
        int256 delta;
        string name;
        string symbol;
    }

    constructor(GaugeVoting _gaugeVoting) {
        gaugeVoting = _gaugeVoting;
    }

    function getPools() public view returns (Pool[] memory pools) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        (int256[] memory deltas, int256[] memory votes) = gaugeVoting.getVotesDelta();
        if (deltas.length == 0) {
            deltas = new int256[](lpTokens.length);
            votes = new int256[](lpTokens.length);
        }
        pools = new Pool[](lpTokens.length);
        for(uint256 i = 0; i < lpTokens.length; i++) {
            pools[i] = Pool(lpTokens[i], gaugeVoting.lpTokenRewards(lpTokens[i]), uint256(gaugeVoting.lpTokenStatus(lpTokens[i])) == 2, votes[i], deltas[i], ERC20(lpTokens[i]).name(), ERC20(lpTokens[i]).symbol());
        }
    }

    function getUserVotes(address _user) public view returns (uint256[] memory votes) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        votes = new uint256[](lpTokens.length);
        for(uint256 i = 0; i < lpTokens.length; i++) {
            votes[i] = IERC20(gaugeVoting.lpTokenRewards(lpTokens[i])).balanceOf(_user);
        }
    }
}