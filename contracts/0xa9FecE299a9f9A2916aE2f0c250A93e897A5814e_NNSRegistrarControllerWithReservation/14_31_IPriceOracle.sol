pragma solidity >=0.8.4;

interface IPriceOracle {
     /**
     * @dev Returns the price to register a name.
     * @param name The name being registered.
     * @return The price of this registration, in wei.
     */
    function price(string calldata name) external view returns(uint);
}