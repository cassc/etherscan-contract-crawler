// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IToken} from "./tokens/interfaces/IToken.sol";
import {IFixedPriceToken} from "./tokens/interfaces/IFixedPriceToken.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Observability, IObservability} from "./observability/Observability.sol";
import {TokenProxy} from "./TokenProxy.sol";
import {ITokenFactory} from "./interfaces/ITokenFactory.sol";

contract TokenFactory is Ownable2Step, ITokenFactory {
    /// @notice mapping of all tokens created by this factory
    mapping(address => bool) public isToken;

    /// @notice mapping of all deployed implementations
    mapping(address => bool) private deployments;

    /// @notice mapping of all upgrades
    /// @notice previousImplementation => newImplementation => isValid
    mapping(address => mapping(address => bool)) private upgrades;

    /// @notice Observability contract for data processing.
    address public immutable o11y;

    constructor() {
        o11y = address(new Observability());
    }

    /// @notice Creates a new token contract with the given implementation and data
    function create(
        address tokenImpl,
        bytes calldata data
    ) external returns (address clone) {
        clone = address(new TokenProxy(tokenImpl, ""));
        isToken[clone] = true;

        if (!deployments[tokenImpl]) revert NotDeployed(tokenImpl);
        IObservability(o11y).emitCloneDeployed(msg.sender, clone);

        // Initialize clone.
        IFixedPriceToken(clone).initialize(msg.sender, data);
    }

    /// @notice checks if an implementation is valid
    function isValidDeployment(address impl) external view returns (bool) {
        return deployments[impl];
    }

    /// @notice registers a new implementation
    function registerDeployment(address impl) external onlyOwner {
        deployments[impl] = true;
        IObservability(o11y).emitDeploymentTargetRegistererd(impl);
    }

    /// @notice unregisters an implementation
    function unregisterDeployment(address impl) external onlyOwner {
        delete deployments[impl];
        IObservability(o11y).emitDeploymentTargetUnregistered(impl);
    }

    /// @notice checks if an upgrade is valid
    function isValidUpgrade(
        address prevImpl,
        address newImpl
    ) external view returns (bool) {
        return upgrades[prevImpl][newImpl];
    }

    /// @notice registers a new upgrade
    function registerUpgrade(
        address prevImpl,
        address newImpl
    ) external onlyOwner {
        upgrades[prevImpl][newImpl] = true;

        IObservability(o11y).emitUpgradeRegistered(prevImpl, newImpl);
    }

    /// @notice unregisters an upgrade
    function unregisterUpgrade(
        address prevImpl,
        address newImpl
    ) external onlyOwner {
        delete upgrades[prevImpl][newImpl];

        IObservability(o11y).emitUpgradeUnregistered(prevImpl, newImpl);
    }
}