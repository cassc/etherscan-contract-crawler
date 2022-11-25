// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IPriceOracle {
    /**
     * @dev Returns the price to register.
     * @param name The name being registered.
     * @return The price of this registration, in wei.
     */
    function price(string calldata name) external view returns(uint);
}