// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

interface IValidatorShare {
    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external returns (uint256 amountToDeposit);
    
    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn) external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;
    // https://goerli.etherscan.io/tx/0xa92befb3c1bca72e9492eb846c58168fc6511ad580a2703e8abf94e0c3682e26
    // https://goerli.etherscan.io/tx/0x452d26ed9d0fa2e634d26302fab71d0f00401690c79ca8c0c998fdefd2fdb9e8

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