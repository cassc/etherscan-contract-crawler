// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// Libs
import { AbstractVault } from "../AbstractVault.sol";

/**
 * @title   Abstract ERC-4626 vault that collects fees.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-27
 *
 * The following functions have to be implemented
 * - totalAssets()
 * - the token functions on `AbstractToken`.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - FeeAdminAbstractVault._initialize(_feeReceiver)
 */
abstract contract FeeAdminAbstractVault is AbstractVault {
    /// @notice Account that receives the performance fee as shares.
    address public feeReceiver;

    event FeeReceiverUpdated(address indexed feeReceiver);

    /**
     * @param _feeReceiver Account that receives the performance fee as shares.
     */
    function _initialize(address _feeReceiver) internal virtual override {
        feeReceiver = _feeReceiver;
    }

    /***************************************
                    Vault Admin
    ****************************************/

    /**
     * @notice Called by the protocol Governor to set the fee receiver address.
     * @param _feeReceiver Address that will receive the fees.
     */
    function setFeeReceiver(address _feeReceiver) external onlyGovernor {
        feeReceiver = _feeReceiver;

        emit FeeReceiverUpdated(feeReceiver);
    }
}