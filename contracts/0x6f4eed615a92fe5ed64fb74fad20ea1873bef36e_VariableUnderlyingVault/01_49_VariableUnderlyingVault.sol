// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {ProductIdUtil} from "grappa/libraries/ProductIdUtil.sol";
import {TokenIdUtil} from "grappa/libraries/TokenIdUtil.sol";

// abstracts
import {CashOptionsVault} from "../mixins/options/CashOptionsVault.sol";
import {VariableUnderlyingVaultStorage} from "./VariableUnderlyingVaultStorage.sol";

// interfaces
import {IGrappa} from "grappa/interfaces/IGrappa.sol";

import "./errors.sol";
import "../../../config/types.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in VaultStorage.
 * VariableUnderlyingVault should not inherit from any other contract aside from OptionsVault, VaultStorage
 */
contract VariableUnderlyingVault is CashOptionsVault, VariableUnderlyingVaultStorage {
    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for Grappa (options protocol)
     */
    constructor(address _share, address _marginEngine) CashOptionsVault(_share, _marginEngine) {}

    /**
     * @notice Initializes the OptionsVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _auction is the address that settles the option contract
     */
    function initialize(InitParams calldata _initParams, address _auction) external initializer {
        __OptionsVault_init(_initParams, _auction);
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    function verifyOptions(uint256[] calldata _options) external view override {
        uint256 currentRoundExpiry = roundExpiry[vaultState.round];

        // initRounds set value to 1, so 0 or 1 are seed values
        if (currentRoundExpiry < 2) revert VUV_BadExpiry();

        uint8 marginEngineId = IGrappa(marginEngine.grappa()).engineIds(address(marginEngine));

        for (uint256 i; i < _options.length;) {
            (, uint40 productId, uint64 expiry,,) = TokenIdUtil.parseTokenId(_options[i]);

            // expirations need to match
            if (currentRoundExpiry != expiry) revert VUV_ExpiryMismatch();

            (, uint8 engineId,,, uint8 collateralId) = ProductIdUtil.parseProductId(productId);

            // must be the preset margin engine
            if (engineId != marginEngineId) revert VUV_MarginEngineMismatch();

            bool collExists = false;
            for (uint256 x; x < collaterals.length;) {
                if (collaterals[x].id == collateralId) collExists = true;

                unchecked {
                    ++x;
                }
            }

            // must be using a registered vault collateral
            if (!collExists) revert VUV_BadCollateral();

            unchecked {
                ++i;
            }
        }
    }
}