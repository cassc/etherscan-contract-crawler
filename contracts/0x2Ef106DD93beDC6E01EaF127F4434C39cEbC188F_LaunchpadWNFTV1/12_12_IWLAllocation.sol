// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol
pragma solidity 0.8.11;

interface IWLAllocation {

    function spendAllocation(address _user, address _erc20, uint256 _amount) external returns (bool);
    function availableAllocation(address _user, address _erc20) external view returns (uint256 allocation); 

}