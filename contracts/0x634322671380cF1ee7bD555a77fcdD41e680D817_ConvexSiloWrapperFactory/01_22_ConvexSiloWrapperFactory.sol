// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12; // solhint-disable-line compiler-version

import "../../lib/Ping06.sol";
import "./ConvexSiloWrapper.sol";
import "../../interfaces/IConvexSiloWrapperFactory.sol";

/// @title ConvexSiloWrapperFactory
/// @notice Deploys ConvexSiloWrapper for Curve LP tokens
contract ConvexSiloWrapperFactory is IConvexSiloWrapperFactory {
    string public constant ERROR_INVALID_SILO_REPOSITORY = "InvalidSiloRepository";
    string public constant ERROR_WRAPPER_ALREADY_DEPLOYED = "WrapperAlreadyDeployed";
    bytes4 public constant SILO_REPOSITORY_PING_SELECTOR = bytes4(keccak256("siloRepositoryPing()"));

    // solhint-disable-next-line var-name-mixedcase
    ISiloRepository0612Like public immutable SILO_REPOSITORY;

    /// @inheritdoc IConvexSiloWrapperFactory
    mapping(uint256 => address) public override deployedWrappers;

    /// @inheritdoc IConvexSiloWrapperFactory
    mapping(address => bool) public override isWrapper;

    /// @dev New ConvexSiloWrapper is deployed with an address `convexSiloWrapper`. Underlying LP token
    ///     is for `curvePoolId` Curve pool.
    event ConvexSiloWrapperCreated(address indexed convexSiloWrapper, uint256 indexed curvePoolId);

    constructor(ISiloRepository0612Like _siloRepository) public {
        if (!Ping06.pong(address(_siloRepository), SILO_REPOSITORY_PING_SELECTOR)) {
            revert(ERROR_INVALID_SILO_REPOSITORY);
        }

        SILO_REPOSITORY = _siloRepository;
    }

    /// @inheritdoc IConvexSiloWrapperFactory
    function createConvexSiloWrapper(uint256 _poolId) external virtual override returns (address wrapper) {
        if (deployedWrappers[_poolId] != address(0)) revert(ERROR_WRAPPER_ALREADY_DEPLOYED);

        wrapper = address(new ConvexSiloWrapper(SILO_REPOSITORY));
        ConvexSiloWrapper(wrapper).initializeSiloWrapper(_poolId);
        deployedWrappers[_poolId] = wrapper;
        isWrapper[wrapper] = true;

        emit ConvexSiloWrapperCreated(wrapper, _poolId);
    }

    function convexSiloWrapperFactoryPing() external pure override returns (bytes4) {
        return this.convexSiloWrapperFactoryPing.selector;
    }
}