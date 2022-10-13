// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStructs.sol";

interface ICommunityStakingPool {
    
    function initialize(
        address stakingProducedBy_,
        address reserveToken_,
        address tradedToken_, 
        IStructs.StructAddrUint256[] memory donations_,
        uint64 lpFraction_,
        address lpFractionBeneficiary_,
        uint64 rewardsRateFraction_
    ) external;
    /*
    function stake(address addr, uint256 amount) external;
    function getMinimum(address addr) external view returns(uint256);
    */
    function unstake(address account, uint256 amount) external returns(uint256 affectedLPAmount, uint64 rewardsRateFraction);
    function unstakeAndRemoveLiquidity(address account, uint256 amount) external returns(uint256 affectedReservedAmount, uint256 affectedTradedAmount, uint64 rewardsRateFraction);
    function redeem(address account, uint256 amount) external returns(uint256 affectedLPAmount, uint64 rewardsRateFraction);
    function redeemAndRemoveLiquidity(address account, uint256 amount) external returns(uint256 affectedReservedAmount, uint256 affectedTradedAmount, uint64 rewardsRateFraction);
}