// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShortDurationYieldCoin {
    /**
     * @dev mint money market coin to an address. Can only be called by authorized minter
     * @param _recipient    where to mint token to
     * @param _amount       amount to mint
     *
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @dev burn money market coin from an address. Can only be called by holder
     * @param _amount       amount to burn
     *
     */
    function burn(uint256 _amount) external;
}