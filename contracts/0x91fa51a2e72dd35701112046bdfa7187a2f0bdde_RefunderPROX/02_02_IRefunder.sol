// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;



interface IRefunder{

    function userRefundedAmountsUSD(address,string memory) external view returns(uint256);
    function userRefundedAmountsToken(address,string memory) external view returns(uint256);
    function ProjectRefundedTotal(string memory) external view returns(uint256);
    
}