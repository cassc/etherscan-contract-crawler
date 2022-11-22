// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title  Token name, symbol and decimals are initializable.
 * @author mStable
 * @dev Optional functions from the ERC20 standard.
 * Converted from openzeppelin/contracts/token/ERC20/ERC20Detailed.sol
 */
abstract contract InitializableTokenDetails {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(
        string memory nameArg,
        string memory symbolArg,
        uint8 decimalsArg
    ) internal virtual {
        _name = nameArg;
        _symbol = symbolArg;
        _decimals = decimalsArg;
    }

    /// @return name_ The `name` of the token.
    function name() public view virtual returns (string memory name_) {
        name_ = _name;
    }

    /// @return symbol_ The symbol of the token, usually a shorter version of the name.
    function symbol() public view virtual returns (string memory symbol_) {
        symbol_ = _symbol;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8 decimals_) {
        decimals_ = _decimals;
    }
}