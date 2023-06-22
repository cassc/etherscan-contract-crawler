// SPDX-License-Identifier: MIT
import "../interfaces/IRefunder.sol";
pragma solidity ^0.8.9;
contract RefunderPROX is IRefunder{

    function userRefundedAmountsUSD(address,string memory) external pure returns(uint256){
        return 0;

    }
    function userRefundedAmountsToken(address,string memory) external pure returns(uint256){
        return 0;
    }
    function ProjectRefundedTotal(string memory) external pure returns(uint256){
        return 0;
    }
}