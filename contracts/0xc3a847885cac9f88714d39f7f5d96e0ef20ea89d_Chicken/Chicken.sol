/**
 *Submitted for verification at Etherscan.io on 2023-09-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Chicken {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function chicken(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}