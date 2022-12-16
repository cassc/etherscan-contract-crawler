// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Burnable} from "./../interfaces/IERC20Burnable.sol";
import {ERC20Storage} from "./../libraries/ERC20Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Burnable (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC20 (Fungible Token Standard).
abstract contract ERC20BurnableBase is Context, IERC20Burnable {
    using ERC20Storage for ERC20Storage.Layout;

    /// @inheritdoc IERC20Burnable
    function burn(uint256 value) external virtual override returns (bool) {
        ERC20Storage.layout().burn(_msgSender(), value);
        return true;
    }

    /// @inheritdoc IERC20Burnable
    function burnFrom(address from, uint256 value) external virtual override returns (bool) {
        ERC20Storage.layout().burnFrom(_msgSender(), from, value);
        return true;
    }

    /// @inheritdoc IERC20Burnable
    function batchBurnFrom(address[] calldata owners, uint256[] calldata values) external virtual override returns (bool) {
        ERC20Storage.layout().batchBurnFrom(_msgSender(), owners, values);
        return true;
    }
}