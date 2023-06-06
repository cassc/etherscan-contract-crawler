// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title CrowdfundWithEditionsStorage
 * @author MirrorXYZ
 */
contract CrowdfundWithEditionsStorage {
    /**
     * @notice The two states that this contract can exist in.
     * "FUNDING" allows contributors to add funds.
     */
    enum Status {
        FUNDING,
        TRADING
    }

    // ============ Constants ============

    /// @notice The factor by which ETH contributions will multiply into crowdfund tokens.
    uint16 internal constant TOKEN_SCALE = 1000;

    // ============ Reentrancy ============

    /// @notice Reentrancy constants.
    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    /// @notice Current reentrancy status -- used by the modifier.
    uint256 internal reentrancy_status;

    /// @notice The operator has a special role to change contract status.
    address payable public operator;

    /// @notice Receives the funds when calling withdraw. Operator can configure.
    address payable public fundingRecipient;

    /// @notice Treasury configuration.
    address public treasuryConfig;

    /// @notice We add a hard cap to prevent raising more funds than deemed reasonable.
    uint256 public fundingCap;

    /// @notice Fee percentage that the crowdfund pays to the treasury.
    uint256 public feePercentage;

    /// @notice The operator takes some equity in the tokens, represented by this percent.
    uint256 public operatorPercent;

    // ============ Mutable Storage ============

    /// @notice Represents the current state of the campaign.
    Status public status;

    // ============ Tiered Campaigns ============

    /// @notice Address of the editions contract to purchase from.
    address public editions;
}