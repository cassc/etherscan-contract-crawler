pragma solidity 0.8.17;

import "Ownable.sol";


contract CrossLedgerOracle is Ownable
{
	event DataUpdated(uint256 indexed chainId, uint256 portfolioScore, uint256 totalAssets);

	mapping (uint256 => uint256) public portfolioScore;
	mapping (uint256 => uint256) public totalAssets;

	function updateData(uint256 chainId, uint256 _portfolioScore, uint256 _totalAssets) public onlyOwner
	{
		portfolioScore[chainId] = _portfolioScore;
		totalAssets[chainId] = _totalAssets;
		emit DataUpdated(chainId, _portfolioScore, _totalAssets);
	}

	function setPortfolioScoreBatch(uint256[] memory chains, uint256[] memory scores, uint256[] memory assets) public onlyOwner
	{
		require(chains.length == scores.length, "chains and scores length mismatch");
		require(chains.length == assets.length, "chains and assets length mismatch");
		for (uint i = 0; i < chains.length; i++) {
			portfolioScore[chains[i]] = scores[i];
			totalAssets[chains[i]] = assets[i];
			emit DataUpdated(chains[i], scores[i], assets[i]);
		}
	}

}