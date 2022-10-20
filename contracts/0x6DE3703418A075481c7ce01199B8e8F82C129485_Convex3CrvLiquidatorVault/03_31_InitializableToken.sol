// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { InitializableTokenDetails } from "./InitializableTokenDetails.sol";

/**
 * @title  Basic token with name, symbol and decimals that is initializable.
 * @author mStable
 * @dev    Implementing contracts must call InitializableToken._initialize
 * in their initialize function.
 */
abstract contract InitializableToken is ERC20, InitializableTokenDetails {
    /// @dev The name and symbol set by the constructor is not used.
    /// The `_initialize` is used to set the name and symbol as the token can be proxied.
    constructor() ERC20("name", "symbol") {}

    /**
     * @notice Initialization function for implementing contract
     * @param _name Name of token.
     * @param _symbol Symbol of token.
     * @param _decimals Decimals places of token. eg 18
     */
    function _initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal virtual override {
        InitializableTokenDetails._initialize(_name, _symbol, _decimals);
    }

    /// @return name_ The `name` of the token.
    function name() public view override(ERC20, InitializableTokenDetails) returns (string memory name_) {
        name_ = InitializableTokenDetails.name();
    }

    /// @return symbol_ The symbol of the token, usually a shorter version of the name.
    function symbol()
        public
        view
        override(ERC20, InitializableTokenDetails)
        returns (string memory symbol_)
    {
        symbol_ = InitializableTokenDetails.symbol();
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() public view override(ERC20, InitializableTokenDetails) returns (uint8 decimals_) {
        decimals_ = InitializableTokenDetails.decimals();
    }
}