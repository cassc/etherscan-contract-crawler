// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IPriceOracle {
    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return The price of this renewal or registration, in wei.
     */
    function price(string calldata name, uint expires, uint duration) external view returns(uint);
}