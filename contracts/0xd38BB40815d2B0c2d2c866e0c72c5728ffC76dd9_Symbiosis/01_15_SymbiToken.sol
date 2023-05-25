// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";

/**
 * @title Symbiosis
 *
 * @dev Symbiosis ERC20 token.
 */
contract Symbiosis is ERC20Burnable, ERC20VotesComp {
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _mint(_owner, 1e8 * 1e18);
    }

    /**
     * @dev Batch transfer.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - `recipients` cannot include the zero address.
     * - the caller must have a balance of at least sum of `amounts`.
     */
    function transferBatch(
        address[] memory recipients,
        uint256[] memory amounts
    ) external virtual returns (bool) {
        uint256 length = recipients.length;
        require(
            length == amounts.length,
            "Symbiosis: recipients and amounts length mismatch"
        );

        for (uint256 i = 0; i < length; i++) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }

        return true;
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Votes)
    {
        ERC20Votes._mint(account, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Votes)
    {
        ERC20Votes._burn(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        ERC20Votes._afterTokenTransfer(from, to, amount);
    }
}