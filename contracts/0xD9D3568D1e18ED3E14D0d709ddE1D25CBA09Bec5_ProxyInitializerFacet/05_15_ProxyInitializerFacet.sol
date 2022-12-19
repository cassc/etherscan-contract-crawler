//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IProxyInitializer} from "../../interfaces/IProxyInitializer.sol";
import {StorageQuorumGovernance} from "../../storage/StorageQuorumGovernance.sol";
import {LibState} from "../../libraries/LibState.sol";
import {StateEnum} from "../../structs/StateEnum.sol";
import {StorageOwnershipUnits} from "../../storage/StorageOwnershipUnits.sol";
import {LibEIP712} from "../../libraries/LibEIP712.sol";
import {StorageAnticFee} from "../../storage/StorageAnticFee.sol";
import {StorageFormingProposition} from "../../storage/StorageFormingProposition.sol";

/// @author Amit Molek
/// @dev Initializes the DominiumProxy storage.
contract ProxyInitializerFacet is IProxyInitializer {
    struct InitData {
        uint8 quorumPercentage;
        uint8 passRatePercentage;
        /// @dev Total ownership units. Must be the price of the target nft in wei
        uint256 totalOwnershipUnits;
        /// @dev Smallest ownership unit. Must be in wei
        uint256 smallestOwnershipUnit;
        /// @dev The hash of the forming proposition to be enacted
        bytes32 formingPropositionHash;
    }

    modifier initializer() {
        StateEnum state = LibState._state();
        require(
            state == StateEnum.UNINITIALIZED,
            "ProxyInitializerFacet: Initialized"
        );
        LibState._changeState(StateEnum.OPEN);
        _;
    }

    /// @notice Proxy's entry point
    function proxyInit(
        address anticFeeCollector,
        uint16 anticJoinFeePercentage,
        uint16 anticSellFeePercentage,
        bytes memory data
    ) public override initializer {
        require(
            anticFeeCollector != address(0),
            "ProxyInitializerFacet: Fee collector can't be zero address"
        );

        InitData memory initData = _decode(data);

        // EIP712's domain separator
        LibEIP712._initDomainSeparator();

        // Governance
        StorageQuorumGovernance._initStorage(
            initData.quorumPercentage,
            initData.passRatePercentage
        );

        // Ownership
        StorageOwnershipUnits._initStorage(
            initData.smallestOwnershipUnit,
            initData.totalOwnershipUnits
        );

        // Antic fee
        StorageAnticFee._initStorage(
            anticFeeCollector,
            anticJoinFeePercentage,
            anticSellFeePercentage
        );

        // Forming Proposition
        StorageFormingProposition._initStorage(initData.formingPropositionHash);
    }

    function initialized() external view override returns (bool) {
        return LibState._state() != StateEnum.UNINITIALIZED;
    }

    function encode(InitData memory initData)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(initData);
    }

    function _decode(bytes memory data)
        internal
        pure
        returns (InitData memory)
    {
        return abi.decode(data, (InitData));
    }
}