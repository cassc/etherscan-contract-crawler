// SPDX-License-Identifier: None

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an customer mintable ERC 721
 */
interface ICustomMintable  {


    /**
     * @dev mint new token to address with fix voting power and expire time
     *
     * Requirements:
     *
     * - caller must have minter role
     */
    function mint(address to, uint256 votingPower, uint256 expires) external;
}