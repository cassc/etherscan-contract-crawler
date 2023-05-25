// contracts/Box.sol
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Extension of {ERC20Capped} that enables update of name and symbol.
 */
contract GovernanceToken is ERC20Capped, Ownable {
    string private _name;
    string private _symbol;

    event NameSet(string indexed oldName, string indexed newName);
    event SymbolSet(string indexed oldSymbol, string indexed newSymbol);

    /**
     * @dev Sets the value of the `name`, `symbol` and `cap`. The value of the latter is immutable.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_
    )
    ERC20(name_, symbol_)
    ERC20Capped(cap_)
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {ERC20-decimals}.
     */
    function decimals()
    public
    pure
    override
    returns (uint8)
    {
        return 15;
    }

    /**
     * @dev See {ERC20-name}.
     */
    function name()
    public
    view
    override
    returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Sets the value of `name`
     */
    function setName(string memory newName)
    public
    onlyOwner
    {
        emit NameSet(_name, newName);
        _name = newName;
    }

    /**
     * @dev See {ERC20-symbol}.
     */
    function symbol()
    public
    view
    override
    returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Sets the value of `symbol`
     */
    function setSymbol(string memory newSymbol)
    public
    onlyOwner
    {
        emit SymbolSet(_symbol, newSymbol);
        _symbol = newSymbol;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function mint(address account, uint256 amount)
    public
    onlyOwner
    {
        super._mint(account, amount);
    }
}