// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IVesting {
    function cancelled() external returns (bool);

    function totalClaimedAmount() external returns (uint256);
    
    function amount() external returns (uint256);

    function initialise(address _recipient, uint40 _start, uint40 _duration, uint256 _amount, bool _isCancellable)
        external;

    function claim() external;
}