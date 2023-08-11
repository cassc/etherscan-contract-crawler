// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @author YLDR <[email protected]>
contract PortfolioScoreOracle is Ownable {
    event ScoreDataUpdated(address indexed vault, uint256 score);

    mapping(address => uint256) public portfolioScore;

    function setPortfolioScore(address vault, uint256 score) public onlyOwner {
        portfolioScore[vault] = score;
        emit ScoreDataUpdated(vault, score);
    }

    function setPortfolioScoreBatch(address[] memory vaults, uint256[] memory scores) public onlyOwner {
        require(vaults.length == scores.length, "vaults and scores length mismatch");
        for (uint256 i = 0; i < vaults.length; i++) {
            portfolioScore[vaults[i]] = scores[i];
            emit ScoreDataUpdated(vaults[i], scores[i]);
        }
    }
}