// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface IPriceFeedData {

    // --- Function --- //

    function kalmPriceInUsd() external view returns (uint256);
    
    function lpPriceInUsd(address lp) external view returns (uint256);

    function otherPriceInUsd(address asset) external view returns (uint256);
}