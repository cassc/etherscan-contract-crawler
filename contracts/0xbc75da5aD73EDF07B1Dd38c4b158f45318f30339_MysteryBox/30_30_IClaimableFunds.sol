// SPDX-License-Identifier: PROPRIERTARY

// Author: Bohdan Malkevych
// Email: [email protected]

pragma solidity 0.8.17;

/**
@notice Interface created to standardize claiming funds by AggregationFunds contract
*/
interface IClaimableFunds {
    /**
    @notice Claim funds
    @param asset_ Asset to withdraw, 0x0 - is native coin (eth)
    @param target_ The target for the withdrawal 
    @param amount_ The amount of 
    */
    function claimFunds(
        address asset_,
        address payable target_,
        uint256 amount_
    ) external;

    /**
    @notice Returns the amount of funds available to claim
    @param owner_ Address of the owner of the asset
    @param asset_ Asset to withdraw, 0x0 - is native coin (eth)
    */
    function availableToClaim(address owner_, address asset_)
        external
        view
        returns (uint256);
}