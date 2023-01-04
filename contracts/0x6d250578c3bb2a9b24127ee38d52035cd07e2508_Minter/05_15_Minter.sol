// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AllowList} from "./abstract/AllowList.sol";
import {Controllable} from "./abstract/Controllable.sol";

import {IMinter} from "./interfaces/IMinter.sol";
import {ITokens} from "./interfaces/ITokens.sol";
import {IControllable} from "./interfaces/IControllable.sol";

/// @title Minter - Mints tokens
/// @notice The only module authorized to directly mint tokens. Maintains an
/// allowlist of external contracts with permission to mint.
contract Minter is IMinter, AllowList {
    string public constant NAME = "Minter";
    string public constant VERSION = "0.0.1";

    address public tokens;

    constructor(address _controller) AllowList(_controller) {}

    /// @inheritdoc IMinter
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external override onlyAllowed {
        ITokens(tokens).mint(to, id, amount, data);
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "tokens") _setTokens(_contract);
        else revert InvalidDependency(_name);
    }

    function _setTokens(address _tokens) internal {
        emit SetTokens(tokens, _tokens);
        tokens = _tokens;
    }
}