// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWrappedBribeFactory {
    
    function voter() external view returns(address);
    function createBribe(address existing_bribe) external returns (address);
    function oldBribeToNew(address _external_bribe_addr) external view returns(address);
}