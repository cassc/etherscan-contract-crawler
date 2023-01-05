interface ICurveAMOv5Helper {
  function calcFraxAndUsdcWithdrawable ( address _curveAMOAddress, address _poolAddress, address _poolLpTokenAddress, uint256 _lpAmount ) external view returns ( uint256[4] memory _withdrawables );
  function getTknsForLPAtCurrRatio ( address _curveAMOAddress, address _poolAddress, address _poolLpTokenAddress, uint256 _lpAmount ) external view returns ( uint256[] memory _withdrawables );
  function showAllocations ( address _curveAMOAddress, uint256 _poolArrayLength ) external view returns ( uint256[10] memory allocations );
  function showOneStepBurningLp ( address _curveAMOAddress, address _poolAddress ) external view returns ( uint256 _oneStepBurningLp );
  function showPoolAssetBalances ( address _curveAMOAddress, address _poolAddress ) external view returns ( uint256[] memory _assetBalances );
  function showPoolRewards(address _curveAMOAddress, address _rewardsContractAddress) external view returns (uint256 _crvReward, uint256[] memory _extraRewardAmounts, address[] memory _extraRewardTokens);
}