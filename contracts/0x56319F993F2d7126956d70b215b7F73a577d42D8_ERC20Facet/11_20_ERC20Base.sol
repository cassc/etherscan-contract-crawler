// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "./../interfaces/IERC20.sol";
import {IERC20Allowance} from "./../interfaces/IERC20Allowance.sol";
import {ERC20Storage} from "./../libraries/ERC20Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC20 Fungible Token Standard (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
abstract contract ERC20Base is Context, IERC20, IERC20Allowance {
    using ERC20Storage for ERC20Storage.Layout;

    /// @inheritdoc IERC20
    function approve(address spender, uint256 value) external virtual override returns (bool result) {
        ERC20Storage.layout().approve(_msgSender(), spender, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value) external virtual override returns (bool result) {
        ERC20Storage.layout().transfer(_msgSender(), to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 value) external virtual override returns (bool result) {
        ERC20Storage.layout().transferFrom(_msgSender(), from, to, value);
        return true;
    }

    /// @inheritdoc IERC20Allowance
    function increaseAllowance(address spender, uint256 addedValue) external virtual override returns (bool result) {
        ERC20Storage.layout().increaseAllowance(_msgSender(), spender, addedValue);
        return true;
    }

    /// @inheritdoc IERC20Allowance
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual override returns (bool result) {
        ERC20Storage.layout().decreaseAllowance(_msgSender(), spender, subtractedValue);
        return true;
    }

    /// @inheritdoc IERC20
    function totalSupply() external view override returns (uint256 supply) {
        return ERC20Storage.layout().totalSupply();
    }

    /// @inheritdoc IERC20
    function balanceOf(address owner) external view override returns (uint256 balance) {
        return ERC20Storage.layout().balanceOf(owner);
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual override returns (uint256 value) {
        return ERC20Storage.layout().allowance(owner, spender);
    }
}