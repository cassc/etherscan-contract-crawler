// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features-interfaces/IERC20BurnFeature.sol";

/**
 * @dev ERC20 token with a burn feature
 */
abstract contract ERC20BurnFeature is ERC20Base, IERC20BurnFeature {

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public override virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public override virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}