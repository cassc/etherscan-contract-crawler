// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../math/SaturatingMath.sol";
import {TierReport} from "./libraries/TierReport.sol";
import {ValueTier} from "./ValueTier.sol";
import "./ReadWriteTier.sol";

/// @param erc20_ The erc20 token contract to transfer balances
/// from/to during `setTier`.
/// @param tierValues_ 8 values corresponding to minimum erc20
/// balances for tiers ONE through EIGHT.
struct ERC20TransferTierConfig {
    IERC20 erc20;
    uint256[8] tierValues;
}

/// @title ERC20TransferTier
/// @notice `ERC20TransferTier` inherits from `ReadWriteTier`.
///
/// In addition to the standard accounting it requires that users transfer
/// erc20 tokens to achieve a tier.
///
/// Data is ignored, the only requirement is that the user has approved
/// sufficient balance to gain the next tier.
///
/// To avoid griefing attacks where accounts remove tiers from arbitrary third
/// parties, we `require(msg.sender == account_);` when a tier is removed.
/// When a tier is added the `msg.sender` is responsible for payment.
///
/// The 8 values for gainable tiers and erc20 contract must be set upon
/// construction and are immutable.
///
/// The `_afterSetTier` simply transfers the diff between the start/end tier
/// to/from the user as required.
///
/// If a user sends erc20 tokens directly to the contract without calling
/// `setTier` the FUNDS ARE LOST.
///
/// @dev The `ERC20TransferTier` takes ownership of an erc20 balance by
/// transferring erc20 token to itself. The `msg.sender` must pay the
/// difference on upgrade; the tiered address receives refunds on downgrade.
/// This allows users to "gift" tiers to each other.
/// As the transfer is a state changing event we can track historical block
/// times.
/// As the tiered address moves up/down tiers it sends/receives the value
/// difference between its current tier only.
///
/// The user is required to preapprove enough erc20 to cover the tier change or
/// they will fail and lose gas.
///
/// `ERC20TransferTier` is useful for:
/// - Claims that rely on historical holdings so the tiered address
///   cannot simply "flash claim"
/// - Token demand and lockup where liquidity (trading) is a secondary goal
/// - erc20 tokens without additonal restrictions on transfer
contract ERC20TransferTier is ReadWriteTier, ValueTier, Initializable {
    using SafeERC20 for IERC20;
    using SaturatingMath for uint256;

    /// Result of initialize.
    /// @param sender `msg.sender` of the initialize.
    /// @param erc20 erc20 to transfer.
    event Initialize(address sender, address erc20);

    /// The erc20 to transfer balances of.
    IERC20 internal erc20;

    /// @param config_ Constructor config.
    function initialize(ERC20TransferTierConfig memory config_)
        external
        initializer
    {
        initializeValueTier(config_.tierValues);
        erc20 = config_.erc20;
        emit Initialize(msg.sender, address(config_.erc20));
    }

    /// Transfers balances of erc20 from/to the tiered account according to the
    /// difference in values. Any failure to transfer in/out will rollback the
    /// tier change. The tiered account must ensure sufficient approvals before
    /// attempting to set a new tier.
    /// The `msg.sender` is responsible for paying the token cost of a tier
    /// increase.
    /// The tiered account is always the recipient of a refund on a tier
    /// decrease.
    /// @inheritdoc ReadWriteTier
    function _afterSetTier(
        address account_,
        uint256 startTier_,
        uint256 endTier_,
        bytes calldata
    ) internal override {
        // As _anyone_ can call `setTier` we require that `msg.sender` and
        // `account_` are the same if the end tier is not an improvement.
        // Anyone can increase anyone else's tier as the `msg.sender` is
        // responsible to pay the difference.
        if (endTier_ <= startTier_) {
            require(msg.sender == account_, "DELEGATED_TIER_LOSS");
        }

        uint256[8] memory tierValues_ = tierValues();

        // Handle the erc20 transfer.
        // Convert the start tier to an erc20 amount.
        uint256 startValue_ = tierToValue(tierValues_, startTier_);
        // Convert the end tier to an erc20 amount.
        uint256 endValue_ = tierToValue(tierValues_, endTier_);

        unchecked {
            // Short circuit if the values are the same for both tiers.
            if (endValue_ == startValue_) {
                return;
            }
            if (endValue_ > startValue_) {
                // Going up, take ownership of erc20 from the `msg.sender`.
                erc20.safeTransferFrom(
                    msg.sender,
                    address(this),
                    endValue_ - startValue_
                );
            } else {
                // Going down, process a refund for the tiered account.
                // Guaranteed to be `msg.sender` for a tier loss (see above) and
                // using `msg.sender` is cheaper gas than using `account_`.
                erc20.safeTransfer(msg.sender, startValue_ - endValue_);
            }
        }
    }
}