// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/OperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IFairxyzOperatorFiltererUpgradeable.sol";

abstract contract FairxyzOperatorFiltererUpgradeable is
    Initializable,
    IFairxyzOperatorFiltererUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable REGISTRY_ADDRESS;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable DEFAULT_SUBSCRIPTION_ADDRESS;

    bool public operatorFilterDisabled;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address registry_, address defaultSubscription_) {
        REGISTRY_ADDRESS = registry_;
        DEFAULT_SUBSCRIPTION_ADDRESS = defaultSubscription_;
    }

    function __FairxyzOperatorFilterer_init(
        bool enabled
    ) internal onlyInitializing {
        __FairxyzOperatorFilterer_init_unchained(enabled);
    }

    function __FairxyzOperatorFilterer_init_unchained(
        bool enabled
    ) internal onlyInitializing {
        if (
            enabled &&
            REGISTRY_ADDRESS.code.length > 0 &&
            DEFAULT_SUBSCRIPTION_ADDRESS != address(0)
        ) {
            IOperatorFilterRegistry(REGISTRY_ADDRESS).registerAndSubscribe(
                address(this),
                DEFAULT_SUBSCRIPTION_ADDRESS
            );
        } else {
            operatorFilterDisabled = true;
        }
    }

    // * MODIFIERS * //

    /**
     * @dev Used to modify transfer functions to check the msg.sender is an allowed operator.
     * @dev Checks are bypassed if the filter is disabled or msg.sender owns the tokens.
     *
     * @param operator the address of the operator that transfer is being attempted by
     * @param from the address tokens are being transferred from
     */
    modifier onlyAllowedOperator(address operator, address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (REGISTRY_ADDRESS.code.length > 0 && !operatorFilterDisabled) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (operator != from) {
                // The OperatorFilterRegistry is responsible for checking if the operator is allowed
                // Reverts with AddressFiltered() if not.
                IOperatorFilterRegistry(REGISTRY_ADDRESS).isOperatorAllowed(
                    address(this),
                    operator
                );
            }
        }
        _;
    }

    /**
     * @dev Used to modify approval functions to check the operator is an allowed operator.
     * @dev Checks are bypassed if the filter is disabled.
     *
     * @param operator the address of the operator that approval is being attempted for
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (REGISTRY_ADDRESS.code.length > 0 && !operatorFilterDisabled) {
            // The OperatorFilterRegistry is responsible for checking if the operator is allowed
            // Reverts with AddressFiltered() if not.
            IOperatorFilterRegistry(REGISTRY_ADDRESS).isOperatorAllowed(
                address(this),
                operator
            );
        }
        _;
    }

    modifier onlyOperatorFilterAdmin() {
        if (!_isOperatorFilterAdmin(msg.sender)) {
            revert OnlyAdmin();
        }
        _;
    }

    // * ADMIN * //

    /**
     * @dev See {IFairxyzOperatorFiltererUpgradeable-toggleOperatorFilterDisabled}.
     */
    function toggleOperatorFilterDisabled()
        external
        virtual
        override
        onlyOperatorFilterAdmin
    {
        bool disabled = !operatorFilterDisabled;
        operatorFilterDisabled = disabled;
        emit OperatorFilterDisabled(disabled);
    }

    // * INTERNAL * //

    /**
     * @dev Inheriting contract is responsible for implementation
     */
    function _isOperatorFilterAdmin(
        address operator
    ) internal view virtual returns (bool);

    uint256[49] private __gap;
}