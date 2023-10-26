// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Base.sol";

/**
 * @dev Extension of {ERC20} that adds a maxSupply to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20Base {
    uint256 private immutable _maxSupply;

    /**
     * @dev Sets the value of the `maxSupply`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 maxSupply_) {
        require(maxSupply_ > 0, "ERC20Capped: maxSupply is 0");
        _maxSupply = maxSupply_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(totalSupply() + amount <= maxSupply(), "ERC20Capped: maxSupply exceeded");
        super._mint(account, amount);
    }
}