// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./erc20/ERC20Lockable.sol";
import "./erc20/ERC20Burnable.sol";
import "./erc20/ERC20Mintable.sol";
import "./library/Pausable.sol";
import "./library/Freezable.sol";

contract ROG is ERC20Lockable, ERC20Burnable, ERC20Mintable, Freezable {
    string private constant _name = "ROGIN.AI";
    string private constant _symbol = "ROG";
    uint8 private constant _decimals = 18;
    uint256 private constant _initial_supply = 2_000_000_000;

    constructor() Ownable() {
        _cap = 3_000_000_000 * (10**uint256(_decimals));
        _mint(msg.sender, _initial_supply * (10**uint256(_decimals)));
    }

    function transfer(address to, uint256 amount)
        external
        override
        whenNotFrozen(msg.sender)
        whenNotPaused
        checkLock(msg.sender, amount)
        returns (bool success)
    {
        require(
            to != address(0),
            "ROG/transfer : Should not send to zero address"
        );
        _transfer(msg.sender, to, amount);
        success = true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        override
        whenNotFrozen(from)
        whenNotPaused
        checkLock(from, amount)
        returns (bool success)
    {
        require(
            to != address(0),
            "ROG/transferFrom : Should not send to zero address"
        );
        _transfer(from, to, amount);
        _approve(from, msg.sender, _allowances[from][msg.sender] - amount);
        success = true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool success)
    {
        require(
            spender != address(0),
            "ROG/approve : Should not approve zero address"
        );
        _approve(msg.sender, spender, amount);
        success = true;
    }

    function name() external pure override returns (string memory tokenName) {
        tokenName = _name;
    }

    function symbol()
        external
        pure
        override
        returns (string memory tokenSymbol)
    {
        tokenSymbol = _symbol;
    }

    function decimals() external pure override returns (uint8 tokenDecimals) {
        tokenDecimals = _decimals;
    }
}