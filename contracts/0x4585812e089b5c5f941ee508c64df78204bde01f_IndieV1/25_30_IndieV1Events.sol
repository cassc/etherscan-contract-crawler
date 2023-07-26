// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IndieV1Events {
    /* --------------------------- Ownership -------------------------- */

    /**
     * @dev Emitted when ownership is renounced
     */
    event OwnershipRenounced(address indexed previousOwner);

    /**
     * @dev Emitted when ownership is transferred
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* --------------------------- Address Change -------------------------- */

    /**
     * @dev Emitted when the treasury address changes
     */
    event TreasuryAddressChanged(address indexed previousAddress, address newAddress);

    /**
     * @dev Emitted when the withholding address changes
     */
    event WithholdingAddressChanged(address indexed previousAddress, address newAddress);

    /* --------------------------- Membership Claim -------------------------- */

    /**
     * @dev Emitted when tokens are claimed
     */
    event Claimed(address indexed recipient, uint256 amount);

    /* --------------------------- Member Status -------------------------- */

    /**
     * @dev Emitted when an indie member status changes to active
     */
    event MemberStatusActive(address indexed memberAddress);

    /**
     * @dev Emitted when an indie member status changes to inactive
     */
    event MemberStatusInactive(address indexed memberAddress);

    /**
     * @dev Emitted when an indie member status changes to resigned
     */
    event MemberStatusResigned(address indexed memberAddress);

    /**
     * @dev Emitted when an indie member status changes to terminated
     */
    event MemberStatusTerminated(address indexed memberAddress);

    /* --------------------------- Withholding -------------------------- */

    /**
     * @dev Emitted when the default withholding percentage changes
     */
    event DefaultWithholdingPercentageChanged(uint256 previousPercentage, uint256 percentage);

    /**
     * @dev Emitted when an indie member withholding percentage changes
     */
    event MemberWithholdingPercentageChanged(address indexed memberAddress, uint256 percentage);

    /* --------------------------- Seasonal Snapshot -------------------------- */

    /**
     * @dev Emitted when a seasonal USDC dividend total has been set
     */
    event SeasonalDividend(uint256 indexed seasonId, uint256 totalDividend, uint256 totalWithholding);

    /**
     * @dev Emitted when a seasonal USDC dividend has been assigned to an indie member
     */
    event SeasonalMemberDividend(
        uint256 indexed seasonId, address indexed memberAddress, uint256 netDividend, uint256 withholding
    );

    /* --------------------------- Dividends -------------------------- */

    /**
     * @dev Emitted when a seasonal USDC dividend is claimed by an indie member
     */
    event SeasonalMemberClaimedDividend(uint256 indexed seasonId, address indexed memberAddress, uint256 netDividend);

    /**
     * @dev Emitted when a terminated member has unclaimed dividends
     */
    event TerminatedMemberDividendsReturnedToTreasury(address indexed memberAddress, uint256 amount);

    /**
     * @dev Emitted when the membership merkle root changes
     */
    event MembershipMerkleRootChanged(bytes32 indexed previousMerkleRoot, bytes32 merkleRoot);

    /* --------------------------- Withdrawal -------------------------- */

    /**
     * @dev Emitted when ETH is withdrawn
     */
    event ETHWithdrawn(address indexed recipient, uint256 amount);

    /**
     * @dev Reverts when USDC is withdrawn
     */
    event USDCWithdrawn(address indexed recipient, uint256 amount);
}