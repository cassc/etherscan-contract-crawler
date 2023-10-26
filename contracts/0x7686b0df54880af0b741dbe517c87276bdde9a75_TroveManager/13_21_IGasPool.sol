// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IGasPool {
    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event THUSDTokenAddressChanged(address _thusdTokenAddress);

    // --- Functions ---
    function sendTHUSD(address _account, uint256 _amount) external;
}