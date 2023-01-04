// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AllowList} from "./abstract/AllowList.sol";
import {Controllable} from "./abstract/Controllable.sol";

import {ITokenDeployer} from "./interfaces/ITokenDeployer.sol";
import {ITokens} from "./interfaces/ITokens.sol";
import {IControllable} from "./interfaces/IControllable.sol";

/// @title TokenDeployer - Deploys Emint155 tokens
/// @notice The only module authorized to deploy new Emint1155 tokens. Maintains
/// an allowlist of external contracts with permission to deploy.
contract TokenDeployer is ITokenDeployer, AllowList {
    string public constant NAME = "TokenDeployer";
    string public constant VERSION = "0.0.1";

    address public tokens;

    constructor(address _controller) AllowList(_controller) {}

    function deploy() external override onlyAllowed returns (address) {
        return ITokens(tokens).deploy();
    }

    function register(uint256 id, address token) external override onlyAllowed {
        ITokens(tokens).register(id, token);
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