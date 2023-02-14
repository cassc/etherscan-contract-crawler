// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with the Zoinks contract.
*/
interface IZoinks {
    function mint(uint256 amount) external;
}