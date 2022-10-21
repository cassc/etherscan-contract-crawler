// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import { SignedMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SignedMathUpgradeable.sol";
import { SignedMathHelpers } from "../_utils/SignedMathHelpers.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IFeeStrategy } from "../_interfaces/IFeeStrategy.sol";
import { IPerpetualTranche } from "../_interfaces/IPerpetualTranche.sol";

/// @notice Expected perc value to be less than 100 with {PERC_DECIMALS}.
/// @param perc The percentage value.
error UnacceptablePercValue(int256 perc);

/**
 *  @title BasicFeeStrategy
 *
 *  @notice Basic fee strategy using fixed percentages. This strategy extracts NO protocol fees.
 *
 *  @dev IMPORTANT: If mint or burn fee is negative, the other must overcompensate in the positive direction.
 *       Otherwise, user could extract from the fee collector by constant mint/burn transactions.
 *
 */
contract BasicFeeStrategy is IFeeStrategy, OwnableUpgradeable {
    using SignedMathUpgradeable for int256;
    using SignedMathHelpers for int256;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;

    /// @dev {10 ** PERC_DECIMALS} is considered 1%
    uint8 public constant PERC_DECIMALS = 6;
    uint256 public constant UNIT_PERC = 10**PERC_DECIMALS;
    uint256 public constant HUNDRED_PERC = 100 * UNIT_PERC;

    /// @inheritdoc IFeeStrategy
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20Upgradeable public immutable override feeToken;

    /// @notice Fixed percentage of the mint amount to be used as fee.
    int256 public mintFeePerc;

    /// @notice Fixed percentage of the burn amount to be used as fee.
    int256 public burnFeePerc;

    /// @notice Fixed percentage of the rollover amount to be used as fee.
    int256 public rolloverFeePerc;

    // EVENTS

    /// @notice Event emitted when the mint fee percentage is updated.
    /// @param mintFeePerc Mint fee percentage.
    event UpdatedMintPerc(int256 mintFeePerc);

    /// @notice Event emitted when the burn fee percentage is updated.
    /// @param burnFeePerc Burn fee percentage.
    event UpdatedBurnPerc(int256 burnFeePerc);

    /// @notice Event emitted when the rollover fee percentage is updated.
    /// @param rolloverFeePerc Rollover fee percentage.
    event UpdatedRolloverPerc(int256 rolloverFeePerc);

    /// @notice Contract constructor.
    /// @param feeToken_ Address of the fee ERC-20 token contract.
    constructor(IERC20Upgradeable feeToken_) {
        feeToken = feeToken_;
    }

    /// @notice Contract initializer.
    /// @param mintFeePerc_ Mint fee percentage.
    /// @param burnFeePerc_ Burn fee percentage.
    /// @param rolloverFeePerc_ Rollover fee percentage.
    function init(
        int256 mintFeePerc_,
        int256 burnFeePerc_,
        int256 rolloverFeePerc_
    ) public initializer {
        __Ownable_init();
        updateMintFeePerc(mintFeePerc_);
        updateBurnFeePerc(burnFeePerc_);
        updateRolloverFeePerc(rolloverFeePerc_);
    }

    /// @notice Updates the mint fee percentage.
    /// @param mintFeePerc_ New mint fee percentage.
    function updateMintFeePerc(int256 mintFeePerc_) public onlyOwner {
        mintFeePerc = mintFeePerc_;
        emit UpdatedMintPerc(mintFeePerc_);
    }

    /// @notice Updates the burn fee percentage.
    /// @param burnFeePerc_ New burn fee percentage.
    function updateBurnFeePerc(int256 burnFeePerc_) public onlyOwner {
        burnFeePerc = burnFeePerc_;
        emit UpdatedBurnPerc(burnFeePerc_);
    }

    /// @notice Updates the rollover fee percentage.
    /// @param rolloverFeePerc_ New rollover fee percentage.
    function updateRolloverFeePerc(int256 rolloverFeePerc_) public onlyOwner {
        rolloverFeePerc = rolloverFeePerc_;
        emit UpdatedRolloverPerc(rolloverFeePerc_);
    }

    /// @inheritdoc IFeeStrategy
    function computeMintFees(uint256 mintAmt) external view override returns (int256, uint256) {
        uint256 absoluteFee = (mintFeePerc.abs() * mintAmt) / HUNDRED_PERC;
        return (mintFeePerc.sign() * absoluteFee.toInt256(), 0);
    }

    /// @inheritdoc IFeeStrategy
    function computeBurnFees(uint256 burnAmt) external view override returns (int256, uint256) {
        uint256 absoluteFee = (burnFeePerc.abs() * burnAmt) / HUNDRED_PERC;
        return (burnFeePerc.sign() * absoluteFee.toInt256(), 0);
    }

    /// @inheritdoc IFeeStrategy
    function computeRolloverFees(uint256 rolloverAmt) external view override returns (int256, uint256) {
        uint256 absoluteFee = (rolloverFeePerc.abs() * rolloverAmt) / HUNDRED_PERC;
        return (rolloverFeePerc.sign() * absoluteFee.toInt256(), 0);
    }
}