// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

/// @title IFeeDistributorFront
/// @author Interface for public use of the `FeeDistributor` contract
/// @dev This interface is used for user related function
interface IFeeDistributorFront {
    function token() external returns (address);

    function claim(address _addr) external returns (uint256);

    function claim(address[20] memory _addr) external returns (bool);
}