// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {PaymentConduit} from "./PaymentConduit.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface PaymentConduitFactoryEvents {
    /**
     * @notice Emitted when a new `PaymentConduit` is deployed.
     */
    event PaymentConduitDeployed(
        address indexed target, string indexed description, address clone
    );
}

/**
 * @notice Utility library to work with a `PaymentConduitFactory`
 */
library PaymentConduitFactoryUtils {
    /**
     * @notice Computes the salt for the CREATE2 deployement including the clone
     * initialisation parameters.
     * @dev This guarantees that a clone at a given address was initialised with
     * the specified parameters.
     */
    function create2Salt(
        bytes32 salt,
        address payable target,
        string memory description
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(salt, target, description));
    }

    /**
     * @notice Predicts the deterministic PaymentConduit clone deployment
     * addresses.
     */
    function predictDeterministicAddress(
        PaymentConduitFactory factory,
        bytes32 salt,
        address payable target,
        string memory description
    ) internal view returns (address) {
        return Clones.predictDeterministicAddress(
            address(factory.implementation()),
            create2Salt(salt, target, description),
            address(factory)
        );
    }
}

/**
 * @notice Factory to deploy and keep track of ERC-1167 clones of
 * a `PaymentConduit`.
 */
contract PaymentConduitFactory is PaymentConduitFactoryEvents {
    using Clones for address;

    /**
     * @notice The primary instance of the PaymentConduit, delegated to by all
     * clones.
     */
    PaymentConduit public immutable implementation;

    /**
     * @notice Keeps track of all deployed conduits by target address.
     */
    mapping(address => PaymentConduit[]) internal _conduits;

    constructor() {
        implementation = new PaymentConduit();
    }

    /**
     * @notice Deploys a minimal proxy contract to a `PaymentConduit`.
     */
    function deploy(address payable target, string calldata description)
        external
        returns (PaymentConduit)
    {
        address clone = address(implementation).clone();
        return _postDeploy(clone, target, description);
    }

    /**
     * @notice Deploys a minimal proxy contract to a `PaymentConduit` at a
     * deterministic address.
     * @dev Use `Clones.predictDeterministicAddress` with the same salt and
     * initialisation parameters to predict the address before calling
     * deployDeterministic(). See OpenZeppelin's `proxy/Clones.sol` for details
     * and caveats, primarily that this will revert if a salt is reused.
     */
    function deployDeterministic(
        bytes32 salt,
        address payable target,
        string memory description
    ) external returns (PaymentConduit) {
        address clone = address(implementation).cloneDeterministic(
            PaymentConduitFactoryUtils.create2Salt(salt, target, description)
        );
        return _postDeploy(clone, target, description);
    }

    /**
     * @notice Calls initialize(target, description) on the proxy contract,
     * registers the clone and emits an event to log the new address.
     */
    function _postDeploy(
        address clone,
        address payable target,
        string memory description
    ) internal returns (PaymentConduit) {
        PaymentConduit conduit = PaymentConduit(payable(clone));
        conduit.initialize(target, description);
        _conduits[target].push(conduit);
        emit PaymentConduitDeployed(target, description, clone);
        return conduit;
    }

    /**
     * @notice Returns all conduits to a given target.
     */
    function conduits(address target)
        external
        view
        returns (PaymentConduit[] memory)
    {
        return _conduits[target];
    }

    /**
     * @notice Returns the conduit with given index to a given target.
     */
    function conduitAt(address target, uint256 idx)
        external
        view
        returns (PaymentConduit)
    {
        return _conduits[target][idx];
    }

    /**
     * @notice Calls the `forwardETH` method on a list of conduits.
     */
    function forwardETH(PaymentConduit[] calldata conduits_) external {
        for (uint256 i = 0; i < conduits_.length; ++i) {
            conduits_[i].forwardETH();
        }
    }

    /**
     * @notice Calls the `forwardERC20` method on a list of conduits.
     */
    function forwardERC20(IERC20 token, PaymentConduit[] calldata conduits_)
        external
    {
        for (uint256 i = 0; i < conduits_.length; ++i) {
            conduits_[i].forwardERC20(token);
        }
    }
}