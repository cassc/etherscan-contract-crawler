// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _maxCap;
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 maxCap_) {
        require(maxCap_ > 0, "ERC20Capped: cap is 0");
        _maxCap = maxCap_;
        _cap = maxCap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function maxCap() public view virtual returns (uint256) {
        return _maxCap;
    }

    /**
     * @dev Returns the maxCap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function _setCap(uint256 cap_) internal virtual {
      require(_maxCap >= cap_, "ERC20Capped: cap is over maxCap");
      _cap = cap_;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        uint256 totalSupply = ERC20.totalSupply() + amount;
        require(totalSupply <= cap(), "ERC20Capped: cap exceeded");
        require(totalSupply <= maxCap(), "ERC20Capped: maxCap exceeded");
        super._mint(account, amount);
    }
}