// SPDX-License-Identifier: BUSL-1.1

// ███╗░░██╗██╗░░░██╗██╗░░██╗███████╗███╗░░░███╗
// ████╗░██║██║░░░██║██║░██╔╝██╔════╝████╗░████║
// ██╔██╗██║██║░░░██║█████═╝░█████╗░░██╔████╔██║
// ██║╚████║██║░░░██║██╔═██╗░██╔══╝░░██║╚██╔╝██║
// ██║░╚███║╚██████╔╝██║░╚██╗███████╗██║░╚═╝░██║
// ╚═╝░░╚══╝░╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝
// https://nukem.loans/
// https://twitter.com/NukemLoans
// https://t.me/nukemloans
// https://enabledefi.gitbook.io/nukemloans/

pragma solidity 0.8.20;

import "IERC20Metadata.sol";
import "IEnFi20.sol";
import "ERC20PermitImmutable.sol";
import "ERC20Immutable.sol";
import "AttributesLibrary.sol";

contract EnFi20Immutable is IEnFi20, ERC20PermitImmutable {
    using Attributes for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        uint256 _supply
    )
        ERC20Immutable(_name, _symbol, decimals_, _supply)
        ERC20PermitImmutable(_name)
    {}

    function recover(
        address account,
        address destination
    ) external virtual onlyRole(Role.RECOVER) returns (uint256 amount) {
        bool is_wallet_blocked = attributes[account].has(
            Attribute.BLOCK_TRANSFER |
                Attribute.BLOCK_MINT |
                Attribute.BLOCK_BURN
        );
        require(is_wallet_blocked, "#1C99CC4C");
        require(destination != address(0), "#1C99CC4D");
        amount = balanceOf(account);
        _decrementBalance(account, amount);
        _incrementBalance(destination, amount);
        return amount;
    }
}