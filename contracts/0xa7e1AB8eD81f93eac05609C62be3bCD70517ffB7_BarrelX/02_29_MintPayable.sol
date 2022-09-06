// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JupiterNFT.sol';

/**
 * @dev Jupiter Payable contract that allows an operator to withdrawn
 */
abstract contract MintPayable is JupiterNFT {
    /**
     * @dev allows an operator to widthdraw stocked eth on the contract
     */
    function withdraw () external {
        require(operators[msg.sender], "only operators");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}