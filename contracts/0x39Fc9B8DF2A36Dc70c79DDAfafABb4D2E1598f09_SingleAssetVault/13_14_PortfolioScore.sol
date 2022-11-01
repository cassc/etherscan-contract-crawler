pragma solidity 0.8.15;

import "Ownable.sol";


contract PortfolioScore is Ownable
{
	event ScoreDataUpdated(address indexed vault, uint256 score);

	mapping (address => uint256) public portfolioScore;

	function setPortfolioScore(address vault, uint256 score) public onlyOwner
	{
		portfolioScore[vault] = score;
		emit ScoreDataUpdated(vault, score);
	}
}