// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

interface IValidatorShare {
    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external returns (uint256 amountToDeposit);

    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn) external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;

    function getLiquidRewards(address user) external view returns (uint256);

    function restake() external returns (uint256 amountRestaked, uint256 liquidReward);

    function unbondNonces(address) external view returns (uint256); // automatically generated getter of a public mapping

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(address, address, uint256) external;

    function unbonds_new(address, uint256) external view returns (uint256, uint256);

    function exchangeRate() external view returns (uint256);

    function getTotalStake(address) external view returns (uint256, uint256);
}