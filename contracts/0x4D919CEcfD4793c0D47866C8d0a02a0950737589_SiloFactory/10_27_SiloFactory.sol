// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./Silo.sol";
import "./interfaces/ISiloFactory.sol";

/// @title SiloFactory
/// @notice Silo Factory has one job, deploy Silo implementation
/// @dev Silo Factory is registered within SiloRepository contract and it's given a version. Each version
/// is different Silo Factory that deploys different Silo implementation. Many Factory contracts can be
/// registered with the Repository contract.
/// @custom:security-contact [email protected]
contract SiloFactory is ISiloFactory {
    address public siloRepository;

    event InitSiloRepository();

    error OnlyRepository();
    error RepositoryAlreadySet();

    /// @inheritdoc ISiloFactory
    function initRepository(address _repository) external {
        // We don't perform a ping to the repository because this is meant to be called in its constructor
        if (siloRepository != address(0)) revert RepositoryAlreadySet();

        siloRepository = _repository;
        emit InitSiloRepository();
    }

    /// @inheritdoc ISiloFactory
    function createSilo(address _siloAsset, uint128 _version, bytes memory) external override returns (address silo) {
        // Only allow silo repository
        if (msg.sender != siloRepository) revert OnlyRepository();

        silo = address(new Silo(ISiloRepository(msg.sender), _siloAsset, _version));
        emit NewSiloCreated(silo, _siloAsset, _version);
    }

    function siloFactoryPing() external pure override returns (bytes4) {
        return this.siloFactoryPing.selector;
    }
}