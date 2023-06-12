// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IFeeRoyaltyCharger {
     function chargeTransferFeeAndRoyalty(
        address from, 
        address to, 
        uint256 transferFee, 
        uint256 royaltyPercent, 
        address royaltyBeneficiary,
        address _transferFeeToken
    ) external returns (uint256 feeIncrement);
}