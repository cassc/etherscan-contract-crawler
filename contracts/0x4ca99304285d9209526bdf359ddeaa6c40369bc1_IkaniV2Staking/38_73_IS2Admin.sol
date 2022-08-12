// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IERC721Upgradeable } from "../../../deps/oz_cu_4_7_2/IERC721Upgradeable.sol";
import { SafeCastUpgradeable } from "../../../deps/oz_cu_4_7_2/SafeCastUpgradeable.sol";

import { IIkaniERC20 } from "../../../erc20/interfaces/IIkaniERC20.sol";
import { IS2Core } from "./IS2Core.sol";
import { IS2Roles } from "./IS2Roles.sol";

/**
 * @title IS2Admin
 * @author Cyborg Labs, LLC
 *
 *  Role-restricted functions.
 */
abstract contract IS2Admin is
    IS2Core,
    IS2Roles
{
    using SafeCastUpgradeable for uint256;

    //---------------- External Functions ----------------//

    function pause()
        external
        onlyRole(PAUSER_ROLE)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole(UNPAUSER_ROLE)
    {
        _unpause();
    }

    function setBaseRate(
        uint32 baseRate
    )
        external
        onlyRole(BASE_RATE_CONTROLLER_ROLE)
    {
        _setBaseRate(baseRate);
    }

    function adminUnstake(
        address owner,
        uint256[] calldata tokenIds,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external
        onlyRole(UNSTAKE_CONTROLLER_ROLE)
        whenNotPaused
    {
        // Verify owner.
        _requireSameOwnerAndAuthorized(owner, tokenIds, true);

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Unstake the tokens.
        context = _unstake(context, owner, tokenIds);

        // Update storage for the account.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] += rewardsDiff;

        emit AdminUnstaked(owner, tokenIds, receipt, receiptData);
    }

    function adminClaimRewards(
        address owner
    )
        external
        onlyRole(CLAIM_CONTROLLER_ROLE)
        whenNotPaused
    {
        _claimRewards(owner, owner);
    }

    function adminClaimRewardsAndBurnWithPermit(
        address owner,
        uint256 burnAmount,
        bytes32 burnReceipt,
        bytes calldata burnReceiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s

    )
        external
        onlyRole(CLAIM_CONTROLLER_ROLE)
        onlyRole(BURN_CONTROLLER_ROLE)
        whenNotPaused
    {
        _claimRewards(owner, owner);
        _burnErc20(owner, burnAmount, burnReceipt, burnReceiptData, deadline, v, r, s);
    }

    //---------------- Internal Functions ----------------//

    function _setBaseRate(
        uint32 baseRate
    )
        internal
    {
        // The base rate at index zero is always zero.
        // The first configured base rate is at index one.
        unchecked {
            _RATE_CHANGES_[++_NUM_RATE_CHANGES_] = RateChange({
                baseRate: baseRate,
                timestamp: block.timestamp.toUint32()
            });
        }

        emit SetBaseRate(baseRate);
    }
}