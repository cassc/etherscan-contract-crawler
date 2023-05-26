pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @title ERC20Decimals
 * @dev Extension of {ERC20} that adds decimals storage slot.
 */
abstract contract ERC20Decimals is ERC20 {
    uint8 private immutable _decimals;

    /**
     * @dev Sets the value of the `decimals`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}