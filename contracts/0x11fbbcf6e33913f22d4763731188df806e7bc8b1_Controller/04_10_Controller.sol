// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";

import {IController} from "./interfaces/IController.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {IAllowList} from "./interfaces/IAllowList.sol";
import {IPausable} from "./interfaces/IPausable.sol";

/// @title Controller - System admin module
/// @notice This module has authority to pause and unpause contracts, update
/// contract dependencies, manage allowlists, and execute arbitrary calls.
contract Controller is IController, Ownable2Step {
    string public constant NAME = "Controller";
    string public constant VERSION = "0.0.1";

    mapping(address => bool) public pausers;

    modifier onlyPauser() {
        if (msg.sender != owner() && !pausers[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    /// @inheritdoc IController
    function setDependency(address _contract, bytes32 _name, address _dependency) external override onlyOwner {
        IControllable(_contract).setDependency(_name, _dependency);
    }

    /// @inheritdoc IController
    function allow(address _allowList, address _caller) external override onlyOwner {
        IAllowList(_allowList).allow(_caller);
    }

    /// @inheritdoc IController
    function deny(address _allowList, address _caller) external override onlyOwner {
        IAllowList(_allowList).deny(_caller);
    }

    /// @inheritdoc IController
    function allowPauser(address pauser) external override onlyOwner {
        pausers[pauser] = true;
        emit AllowPauser(pauser);
    }

    /// @inheritdoc IController
    function denyPauser(address pauser) external override onlyOwner {
        pausers[pauser] = false;
        emit DenyPauser(pauser);
    }

    /// @inheritdoc IController
    function pause(address _contract) external override onlyPauser {
        IPausable(_contract).pause();
    }

    /// @inheritdoc IController
    function unpause(address _contract) external override onlyPauser {
        IPausable(_contract).unpause();
    }

    /// @inheritdoc IController
    function exec(address receiver, bytes calldata data) external payable override onlyOwner returns (bytes memory) {
        (bool success, bytes memory returnData) = address(receiver).call{value: msg.value}(data);
        if (!success) revert ExecFailed(returnData);
        return returnData;
    }
}