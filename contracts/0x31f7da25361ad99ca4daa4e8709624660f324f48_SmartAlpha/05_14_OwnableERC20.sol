// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A token that allows advanced privileges to its owner
/// @notice Allows the owner to mint, burn and transfer tokens without requiring explicit user approval
contract OwnableERC20 is ERC20, Ownable {
    uint8 private _dec;

    constructor(string memory name, string memory symbol, uint8 _decimals) ERC20(name, symbol) {
        _dec = _decimals;
    }


    /// @dev Returns the number of decimals used to get its user representation.
    /// For example, if `decimals` equals `2`, a balance of `505` tokens should
    /// be displayed to a user as `5,05` (`505 / 10 ** 2`).
    ///
    /// Tokens usually opt for a value of 18, imitating the relationship between
    /// Ether and Wei. This is the value {ERC20} uses, unless this function is
    /// overridden;
    ///
    /// NOTE: This information is only used for _display_ purposes: it in
    /// no way affects any of the arithmetic of the contract, including
    /// {IERC20-balanceOf} and {IERC20-transfer}.
    function decimals() public view override returns (uint8) {
        return _dec;
    }

    /// @notice Allow the owner of the contract to mint an amount of tokens to the specified user
    /// @dev Only callable by owner
    /// @dev Emits a Transfer from the 0 address
    /// @param user The address of the user to mint tokens for
    /// @param amount The amount of tokens to mint
    function mint(address user, uint256 amount) public onlyOwner {
        _mint(user, amount);
    }

    /// @notice Allow the owner of the contract to burn an amount of tokens from the specified user address
    /// @dev Only callable by owner
    /// @dev The user's balance must be at least equal to the amount specified
    /// @dev Emits a Transfer to the 0 address
    /// @param user The address of the user from which to burn tokens
    /// @param amount The amount of tokens to burn
    function burn(address user, uint256 amount) public onlyOwner {
        _burn(user, amount);
    }

    /// @notice Allow the owner of the contract to transfer an amount of tokens from sender to recipient
    /// @dev Only callable by owner
    /// @dev Acts just like transferFrom but without the allowance check
    /// @param sender The address of the account from which to transfer tokens
    /// @param recipient The address of the account to which to transfer tokens
    /// @param amount The amount of tokens to transfer
    /// @return bool (always true)
    function transferAsOwner(address sender, address recipient, uint256 amount) public onlyOwner returns (bool){
        _transfer(sender, recipient, amount);

        return true;
    }
}