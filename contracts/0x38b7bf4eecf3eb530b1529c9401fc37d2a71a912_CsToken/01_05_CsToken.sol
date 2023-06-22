// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title CsToken
 * @author ClayStack
 * @notice Implementation ClayStack's synthetic ERC20 compliant token.
 */
contract CsToken is ERC20 {
    address public immutable clayMain;

    /// @notice Check if the clayMain contract is the msg.sender.
    modifier onlyClayMain() {
        require(msg.sender == clayMain, "Authentication failed");
        _;
    }

    /**
     * @dev Initializes the values for `name`, `symbol` and `clayMain`.
     * The default value of `decimals` is 18.
     *
     * @param name_ : Name of the token.
     * @param symbol_ : Symbol of the token.
     * @param clayMain_ : ClayMain address.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address clayMain_
    ) ERC20(name_, symbol_) {
        require(clayMain_ != address(0x0), "ClayMain address can not be zero address");
        clayMain = clayMain_;
    }

    /**
     * @dev Mints `_amount` tokens to `_to`, increasing the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * @notice only `clayMain` callable.
     *
     * Requirements:
     * - `_to` cannot be the zero address.
     *
     * @param _to : Address to which tokens will be minted.
     * @param _amount : Number of tokens to be minted.
     * @return : Boolean value indicating whether the operation succeeded.
     */
    function mint(address _to, uint256 _amount) external onlyClayMain returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    /**
     * @dev Burns `_amount` tokens from `_from`, reducing the total supply.
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * @notice only `clayMain` callable.
     *
     * Requirements:
     * - `_from` cannot be the zero address.
     * - `_from` must have at least `_amount` tokens.
     *
     * @param _from : Address from which tokens will be burned.
     * @param _amount : Number of tokens to be burned.
     * @return : Boolean value indicating whether the operation succeeded.
     */
    function burn(address _from, uint256 _amount) external onlyClayMain returns (bool) {
        _burn(_from, _amount);
        return true;
    }
}