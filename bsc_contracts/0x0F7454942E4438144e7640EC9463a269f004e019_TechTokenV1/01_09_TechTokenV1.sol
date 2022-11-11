// SPDX-License-Identifier: MIT
// NIFTSY protocol ERC20
pragma solidity 0.8.16;

import "ERC20.sol";
import "MinterRole.sol";
import "FeeRoyaltyModelV1_00.sol";


contract TechTokenV1 is ERC20, MinterRole, FeeRoyaltyModelV1_00 {
    constructor()
    ERC20("Virtual Envelop Transfer Fee Token", "vENVLP")
    MinterRole(msg.sender)
    { 
    }

    function mint(address _to, uint256 _value) external onlyMinter {
        _mint(_to, _value);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (msg.sender == wrapper) {
            // not for mint and burn
            if (from != address(0) && to != address(0)) {
                _mint(from, amount);
                // Next string was commented due overide `transferFrom` (see below)
                //_approve(from, wrapper, amount);
            }
        }
    }


    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * !!!!!!!!!!
     * ENVELOP NOTE: Does not update the allowance if the sender is wrapper
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public  override returns (bool) {
        address spender = _msgSender();
        if (spender != wrapper) {
            _spendAllowance(from, spender, amount);
        }
        _transfer(from, to, amount);
        return true;
    }
}