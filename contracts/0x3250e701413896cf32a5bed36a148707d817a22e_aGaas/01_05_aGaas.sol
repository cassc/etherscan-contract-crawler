// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.7.5;

import "../libs/ERC20.sol";
import "../libs/SafeMath.sol";

contract aGaas is ERC20 {

    using SafeMath for uint256;
	
    constructor() ERC20("Congruent DAO Presale Token", "aGaas", 9) {
		_mint(msg.sender, 6500 * 10**9);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}