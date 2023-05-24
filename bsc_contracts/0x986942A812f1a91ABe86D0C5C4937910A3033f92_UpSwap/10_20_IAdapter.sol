// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAdapter {
    /** Zapping Function */
    function zapIn(address _from, uint256 _amount, address _to) external returns (uint256);
    
    /** Unzapping Function */
    function zapOut(address _lp, uint256 _amount, address _from) external returns (uint256);
}