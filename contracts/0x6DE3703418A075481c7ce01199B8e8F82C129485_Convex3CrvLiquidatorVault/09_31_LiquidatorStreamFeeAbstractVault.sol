// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Libs
import { LiquidatorAbstractVault } from "./LiquidatorStreamAbstractVault.sol";
import { LiquidatorStreamAbstractVault, StreamData } from "./LiquidatorStreamAbstractVault.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { FeeAdminAbstractVault } from "../fee/FeeAdminAbstractVault.sol";

/**
 * @notice   Abstract ERC-4626 vault that streams increases in the vault's assets per share
 * by minting and then burning shares over a period of time.
 * This vault charges a performance fee on the donated assets by senting a percentage of the streamed shares
 * to a fee receiver.
 *
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-08
 *
 * The following functions have to be implemented
 * - collectRewards()
 * - totalAssets()
 * - the token functions on `AbstractToken`.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 *   - LiquidatorStreamAbstractVault(_streamDuration)
 * - VaultManagerRole._initialize(_vaultManager)
 * - LiquidatorAbstractVault._initialize(_rewardTokens)
 * - LiquidatorStreamFeeAbstractVault._initialize(_feeReceiver, _donationFee)
 */
abstract contract LiquidatorStreamFeeAbstractVault is LiquidatorStreamAbstractVault {
    /// @notice Scale of the `donationFee`. 100% = 1000000, 1% = 10000, 0.01% = 100.
    uint256 public constant FEE_SCALE = 1e6;

    /// @notice Account that receives the donation fee as shares.
    address public feeReceiver;
    /// @notice Donation fee scaled to `FEE_SCALE`.
    uint32 public donationFee;

    event FeeReceiverUpdated(address indexed feeReceiver);
    event DonationFeeUpdated(uint32 donationFee);

    /**
     * @param _feeReceiver Account that receives the performance fee as shares.
     * @param _donationFee Donation fee scaled to `FEE_SCALE`.
     */
    function _initialize(address _feeReceiver, uint256 _donationFee) internal virtual {
        feeReceiver = _feeReceiver;
        donationFee = SafeCast.toUint32(_donationFee);
    }

    /**
     * @dev Collects a performance fee in the form of shares from the donated tokens.
     * @return streamShares_ The number of shares to be minted and then burnt over a period of time.
     * @return streamAssets_ The number of assets allocated to the streaming of shares.
     */
    function _beforeStreamShare(uint256 newShares, uint256 newAssets)
        internal
        virtual
        override
        returns (uint256 streamShares_, uint256 streamAssets_)
    {
        // Charge a fee
        uint256 feeShares = (newShares * donationFee) / FEE_SCALE;
        uint256 feeAssets = (newAssets * donationFee) / FEE_SCALE;
        streamShares_ = newShares - feeShares;
        streamAssets_ = newAssets - feeAssets;

        // Mint new shares to the fee receiver. These shares will not be burnt over time.
        _mint(feeReceiver, feeShares);

        emit Deposit(msg.sender, feeReceiver, feeAssets, feeShares);
    }

    /***************************************
                    Vault Admin
    ****************************************/

    /**
     * @notice  Called by the protocol `Governor` to set a new donation fee
     * @param _donationFee Donation fee scaled to 6 decimal places. 1% = 10000, 0.01% = 100
     */
    function setDonationFee(uint32 _donationFee) external onlyGovernor {
        require(_donationFee <= FEE_SCALE, "Invalid fee");

        donationFee = _donationFee;

        emit DonationFeeUpdated(_donationFee);
    }

    /**
     * @notice Called by the protocol `Governor` to set the fee receiver address.
     * @param _feeReceiver Address that will receive the fees.
     */
    function setFeeReceiver(address _feeReceiver) external onlyGovernor {
        feeReceiver = _feeReceiver;

        emit FeeReceiverUpdated(feeReceiver);
    }
}