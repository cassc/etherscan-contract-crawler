// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/ValidatorLibrary.sol";

import "./interfaces/IOrdererV2.sol";
import "./interfaces/IOrderingExecutor.sol";
import "./interfaces/IIndexRegistry.sol";

/// @title Phuture job
/// @notice Contains signature verification and order execution logic
contract OrderingExecutor is IOrderingExecutor, Pausable {
    using ERC165Checker for address;
    using Counters for Counters.Counter;
    using ValidatorLibrary for ValidatorLibrary.Sign;

    /// @notice Validator role
    bytes32 internal immutable VALIDATOR_ROLE;
    /// @notice Order executor role
    bytes32 internal immutable ORDER_EXECUTOR_ROLE;
    /// @notice Role allows configure ordering related data/components
    bytes32 internal immutable ORDERING_MANAGER_ROLE;

    /// @notice Nonce
    Counters.Counter internal _nonce;

    /// @inheritdoc IOrderingExecutor
    address public immutable override registry;

    /// @inheritdoc IOrderingExecutor
    uint256 public override minAmountOfSigners = 1;

    /// @notice Checks if msg.sender has the given role's permission
    modifier onlyRole(bytes32 role) {
        require(IAccessControl(registry).hasRole(role, msg.sender), "OrderingExecutor: FORBIDDEN");
        _;
    }

    constructor(address _registry) {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "OrderingExecutor: INTERFACE");

        VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
        ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
        ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

        registry = _registry;
    }

    /// @inheritdoc IOrderingExecutor
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_minAmountOfSigners != 0, "OrderingExecutor: INVALID");

        minAmountOfSigners = _minAmountOfSigners;
    }

    /// @inheritdoc IOrderingExecutor
    function pause() external override onlyRole(ORDERING_MANAGER_ROLE) {
        _pause();
    }

    /// @inheritdoc IOrderingExecutor
    function unpause() external override onlyRole(ORDERING_MANAGER_ROLE) {
        _unpause();
    }

    /// @inheritdoc IOrderingExecutor
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info)
        external
        override
    {
        require(
            !paused() || IAccessControl(registry).hasRole(ORDER_EXECUTOR_ROLE, msg.sender),
            "OrderingExecutor: PAUSED"
        );

        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.internalSwap.selector, _info));
        orderer.internalSwap(_info);
    }

    /// @inheritdoc IOrderingExecutor
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info)
        external
        override
    {
        require(
            !paused() || IAccessControl(registry).hasRole(ORDER_EXECUTOR_ROLE, msg.sender),
            "OrderingExecutor: PAUSED"
        );

        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.externalSwap.selector, _info));
        orderer.externalSwap(_info);
    }

    /// @inheritdoc IOrderingExecutor
    function nonce() external view override returns (uint256) {
        return _nonce.current();
    }

    /// @notice Verifies that list of signatures provided by validator have signed given `_data` object
    /// @param _signs List of signatures
    /// @param _data Data object to verify signature
    function _validate(ValidatorLibrary.Sign[] calldata _signs, bytes memory _data) internal {
        uint signsCount = _signs.length;
        require(signsCount >= minAmountOfSigners, "OrderingExecutor: !ENOUGH_SIGNERS");

        address lastAddress = address(0);
        for (uint i; i < signsCount; ) {
            address signer = _signs[i].signer;
            require(uint160(signer) > uint160(lastAddress), "OrderingExecutor: UNSORTED");
            require(
                _signs[i].verify(_data, _useNonce()) && IAccessControl(registry).hasRole(VALIDATOR_ROLE, signer),
                string.concat("OrderingExecutor: SIGN ", Strings.toHexString(uint160(signer), 20))
            );

            lastAddress = signer;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Return the current value of nonce and increment
    /// @return current Current nonce of signer
    function _useNonce() internal virtual returns (uint256 current) {
        current = _nonce.current();
        _nonce.increment();
    }
}