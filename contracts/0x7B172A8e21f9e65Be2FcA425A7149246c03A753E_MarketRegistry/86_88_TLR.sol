pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TLR is ERC20Votes, Ownable {
    uint224 private immutable MAX_SUPPLY;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint224 _supplyCap, address tokenOwner)
        ERC20("Teller", "TLR")
        ERC20Permit("Teller")
    {
        require(_supplyCap > 0, "ERC20Capped: cap is 0");
        MAX_SUPPLY = _supplyCap;
        _transferOwnership(tokenOwner);
    }

    /**
     * @dev Max supply has been overridden to cap the token supply upon initialization of the contract
     * @dev See OpenZeppelin's implementation of ERC20Votes _mint() function
     */
    function _maxSupply() internal view override returns (uint224) {
        return MAX_SUPPLY;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}