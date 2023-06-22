// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TwoFiveSixFactories is Ownable {
    address[] public twoFiveSixFactories;
    address public royaltySplitterFactory;

    /**
     * @dev Set the royalty splitter factory address
     * @notice Only the contract owner can call this function
     * @param a The new royalty splitter factory contract address
     */
    function addTwoFiveSixFactoryAddress(address a) public onlyOwner {
        twoFiveSixFactories.push(a);
    }

    /**
     * @dev Set the royalty splitter factory address
     * @notice Only the contract owner can call this function
     * @param newAddress The new royalty splitter factory contract address
     */
    function setRoyaltySplitterFactoryAddress(
        address newAddress
    ) public onlyOwner {
        royaltySplitterFactory = newAddress;
    }
}