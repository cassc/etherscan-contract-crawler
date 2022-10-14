// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStructs.sol";

interface ICommunityStakingPoolErc20 {
    
    function initialize(
        address stakingProducedBy_,
        address token_,
        IStructs.StructAddrUint256[] memory donations_,
        uint64 lpFraction_,
        address lpFractionBeneficiary_,
        uint64 rewardsRateFraction_
    ) external;

    function redeem(address account, uint256 amount) external returns(uint256 affectedAmount, uint64 rewardsRateFraction);
}