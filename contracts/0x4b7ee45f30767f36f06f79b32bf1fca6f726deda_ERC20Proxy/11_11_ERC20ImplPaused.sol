// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./ERC20Store.sol";

/** @title  ERC20 compliant token intermediary contract holding core logic.
  *
  * @notice  This contract serves as an intermediary between the exposed ERC20
  * interface in ERC20Proxy and the store of balances in ERC20Store. This
  * contract contains core logic that the proxy can delegate to
  * and that the store is called by.
  *
  * @dev  This version of ERC20Impl is intended to revert all ERC20 functions
  * that are state mutating; only view functions remain operational. Upgrading
  * to this contract places the system into a read-only paused state.
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20ImplPaused {

    // MEMBERS

    /// @dev  The reference to the store.
    ERC20Store immutable public erc20Store;

    // CONSTRUCTOR
    constructor(
          address _erc20Store
    )
    {
        erc20Store = ERC20Store(_erc20Store);
    }

    // METHODS (ERC20 sub interface impl.)
    /// @notice  Core logic of the ERC20 `totalSupply` function.
    function totalSupply() external view returns (uint256) {
        return erc20Store.totalSupply();
    }

    /// @notice  Core logic of the ERC20 `balanceOf` function.
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return erc20Store.balances(_owner);
    }

    /// @notice  Core logic of the ERC20 `allowance` function.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return erc20Store.allowed(_owner, _spender);
    }
}