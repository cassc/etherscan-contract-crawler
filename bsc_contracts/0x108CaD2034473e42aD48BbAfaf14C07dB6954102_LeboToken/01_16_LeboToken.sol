// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
/// [Max Supply]             : 250.000.000 Token.
/// -----------------------------------------------------------------------------------------------------------
/// [Liquidity & Incentives] : 23%
/// [Foundation reserve]     : 21.2%
/// [Team & Advisors]        : 17.4% ➔ Unlock 1.45% more every 3 months.
/// [Marketing]              : 10%
/// -----------------------------------------------------------------------------------------------------------
/// [Token Sale]             : 28.4%
/// ●------------[Seed]      : 10.6% ➔ Unlock 2.65% every 6 months.
/// ●------------[IDO]       : 12.8% ➔ One wallet address can only buy upto 1000 tokens.
/// ●------------[Public]    : 5%
/// -----------------------------------------------------------------------------------------------------------
contract LeboToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
    uint256 internal cap_ = 250000000e18;

    constructor() ERC20("Lebo", "LEBO") ERC20Permit("Lebo") {}

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return cap_;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(_msgSender() != address(0), "BEP20: mint to the zero address");
        require(totalSupply() + amount <= cap(), "Cannot mint more than cap");
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual onlyOwner {
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
    function burnFrom(address account, uint256 amount)
        public
        virtual
        onlyOwner
    {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}