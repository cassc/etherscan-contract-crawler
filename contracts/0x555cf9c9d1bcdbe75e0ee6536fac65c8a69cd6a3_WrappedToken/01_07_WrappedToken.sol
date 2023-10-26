// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract WrappedToken is ERC20Burnable, Ownable {
    uint8 private _decimal;
    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimal_
    ) public ERC20(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * ============================================================================
     * code for mapping token
     * ============================================================================
     */

    /****************************************************************************
     **
     ** MODIFIERS
     **
     ****************************************************************************/
    modifier onlyMeaningfulValue(uint256 value) {
        require(value > 0, "Value is null");
        _;
    }

    /****************************************************************************
     **
     ** MANIPULATIONS of mapping token
     **
     ****************************************************************************/

    function mint(address account_, uint256 value_)
        external
        onlyOwner
        onlyMeaningfulValue(value_)
    {
        _mint(account_, value_);
    }

    /// @notice Burn token
    /// @dev Burn token
    /// @param account_ Address of whose token will be burnt
    /// @param value_ Amount of token to be burnt
    function burn(address account_, uint256 value_)
        external
        onlyOwner
        onlyMeaningfulValue(value_)
    {
        _burn(account_, value_);
    }

    /// @notice update token name, symbol
    /// @dev update token name, symbol
    /// @param name_ token new name
    /// @param symbol_ token new symbol
    function update(string memory name_, string memory symbol_)
        external
        onlyOwner
    {
        _name = name_;
        _symbol = symbol_;
    }

    function transferOwner(address newOwner_) public onlyOwner {
        Ownable.transferOwnership(newOwner_);
    }

    function _beforeTokenTransfer(address /*from*/, address to, uint256 /*amount*/) internal override { 
        require(to != address(this), "to address incorrect");
    }
}