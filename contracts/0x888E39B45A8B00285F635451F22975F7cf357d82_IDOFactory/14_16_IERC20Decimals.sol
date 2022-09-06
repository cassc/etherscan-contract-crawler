pragma solidity ^0.8.0;


interface IERC20Decimals {
    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);
}