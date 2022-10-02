// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "./Owned.sol";
import "./TokensRecoverable.sol";

contract MFTERC20 is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    Owned,
    TokensRecoverable
{
    /**
     * @dev Sets the values for {name} and {symbol} and mint the tokens to the address set.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor()
        ERC20("Diamond", "DMA")
        Owned(0x0aB68BaC7902418f6D4892D4Bc8c772D04Ea5526)
    {
        _mint(0x0aB68BaC7902418f6D4892D4Bc8c772D04Ea5526, 50000000000 ether);
    }

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example in our contract, only Owner can call it.
     *
     */
    function snapshot() public onlyOwner {
        _snapshot();
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
    ) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}