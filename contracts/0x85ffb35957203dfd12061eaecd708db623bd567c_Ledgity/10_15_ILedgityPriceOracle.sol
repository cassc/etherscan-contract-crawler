pragma solidity ^0.6.12;

interface ILedgityPriceOracle {
    /**
     * @dev Update average price.
     * @return `true` if update successful; `false` if period has not yet elapsed.
     */
    function tryUpdate() external returns (bool);

    /**
     * @dev Update average price. Reverts if period has not yet elapsed.
     */
    function update() external;

    /**
     * @dev Returns the price of tokens.
     */
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}