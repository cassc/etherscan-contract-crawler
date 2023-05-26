// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "../utils/Context.sol";
import "../ERC20/ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) virtual public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) virtual public returns (bool) {
        _burnFrom(account, amount);
        return true;
    }
}