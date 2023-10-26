// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IArcadeToken.sol";

import { AT_AlreadySent, AT_ZeroAddress, AT_TokenAlreadySet } from "../errors/Token.sol";

/**
 * @title Arcade Token Distributor
 * @author Non-Fungible Technologies, Inc.
 *
 * A contract that is responsible for distributing Arcade Tokens (ARCD). Each recipient address
 * is provided at the time of the distribution function call. Once each distribution function has
 * been called, the corresponding flag is set to true and the function cannot be called again. Once
 * all of the flags are set to true, the Arcade Token Distributor contract is no longer needed
 * and should not hold any tokens.
 */
contract ArcadeTokenDistributor is Ownable {
    using SafeERC20 for IArcadeToken;

    // ============================================= STATE =============================================

    /// @notice The Arcade Token contract to be used in token distribution.
    IArcadeToken public arcadeToken;

    /// @notice 25.499484% of initial distribution is for the governance treasury
    uint256 public constant governanceTreasuryAmount = 25_499_484 ether;
    /// @notice A flag to indicate if the governance treasury has already been transferred to
    bool public governanceTreasurySent;

    /// @notice 10% of initial distribution is for the foundation treasury
    uint256 public constant foundationTreasuryAmount = 10_000_000 ether;
    /// @notice A flag to indicate if the foundation treasury has already been transferred to
    bool public foundationTreasurySent;

    /// @notice 1.081284% of initial distribution is for the token development partner
    uint256 public constant devPartnerAmount = 1_081_284 ether;
    /// @notice A flag to indicate if the token development partner has already been transferred to.
    bool public devPartnerSent;

    /// @notice 9% of initial distribution is for the community rewards pool
    uint256 public constant communityRewardsAmount = 9_000_000 ether;
    /// @notice A flag to indicate if the community rewards pool has already been transferred to
    bool public communityRewardsSent;

    /// @notice 6% of initial distribution is for the community airdrop contract
    uint256 public constant communityAirdropAmount = 6_000_000 ether;
    /// @notice A flag to indicate if the community airdrop contract has already been transferred to
    bool public communityAirdropSent;

    /// @notice 15.54647% of initial distribution is for the Arcade team vesting
    uint256 public constant vestingTeamAmount = 15_546_470 ether;
    /// @notice A flag to indicate if the Arcade team vesting have already been transferred to
    bool public vestingTeamSent;

    /// @notice 33.872762% of initial distribution is for Arcade's launch partner vesting
    uint256 public constant vestingPartnerAmount = 32_872_762 ether;
    /// @notice A flag to indicate if Arcade's launch partner vesting has already been transferred to
    bool public vestingPartnerSent;

    // ============================================ EVENTS ==============================================

    /// @notice Emitted when Arcade Tokens are distributed to any recipient address
    event Distribute(address token, address recipient, uint256 amount);

    // ======================================== DISTRIBUTION OPS ========================================

    /**
     * @notice Transfers a predetermined amount of Arcade Tokens to the governance treasury.
     *
     * @param _governanceTreasury                The address of the Arcade governance treasury.
     */
    function toGovernanceTreasury(address _governanceTreasury) external onlyOwner whenTokenSet {
        if (governanceTreasurySent) revert AT_AlreadySent();
        if (_governanceTreasury == address(0)) revert AT_ZeroAddress("govTreasury");

        governanceTreasurySent = true;

        arcadeToken.safeTransfer(_governanceTreasury, governanceTreasuryAmount);

        emit Distribute(address(arcadeToken), _governanceTreasury, governanceTreasuryAmount);
    }

    /**
     * @notice Transfers a predetermined amount of Arcade Tokens to the foundation treasury.
     *
     * @param _foundationTreasury      The address of the foundation treasury.
     */
    function toFoundationTreasury(address _foundationTreasury) external onlyOwner whenTokenSet {
        if (foundationTreasurySent) revert AT_AlreadySent();
        if (_foundationTreasury == address(0)) revert AT_ZeroAddress("foundationTreasury");

        foundationTreasurySent = true;

        arcadeToken.safeTransfer(_foundationTreasury, foundationTreasuryAmount);

        emit Distribute(address(arcadeToken), _foundationTreasury, foundationTreasuryAmount);
    }

    /**
     * @notice Transfers a predetermined amount of Arcade Tokens to token's development partner.
     *
     * @param _devPartner              The address of the token's development partner.
     */
    function toDevPartner(address _devPartner) external onlyOwner whenTokenSet {
        if (devPartnerSent) revert AT_AlreadySent();
        if (_devPartner == address(0)) revert AT_ZeroAddress("devPartner");

        devPartnerSent = true;

        arcadeToken.safeTransfer(_devPartner, devPartnerAmount);

        emit Distribute(address(arcadeToken), _devPartner, devPartnerAmount);
    }

    /**
     * @notice Transfers a predetermined amount of Arcade Tokens to the community rewards pool.
     *
     * @param _communityRewards        The address of the community rewards pool.
     */
    function toCommunityRewards(address _communityRewards) external onlyOwner whenTokenSet {
        if (communityRewardsSent) revert AT_AlreadySent();
        if (_communityRewards == address(0)) revert AT_ZeroAddress("communityRewards");

        communityRewardsSent = true;

        arcadeToken.safeTransfer(_communityRewards, communityRewardsAmount);

        emit Distribute(address(arcadeToken), _communityRewards, communityRewardsAmount);
    }

    /**
     * @notice Transfers a predetermined amount of Arcade Tokens to the community airdrop contract.
     *
     * @param _communityAirdrop        The address of the community airdrop contract.
     */
    function toCommunityAirdrop(address _communityAirdrop) external onlyOwner whenTokenSet {
        if (communityAirdropSent) revert AT_AlreadySent();
        if (_communityAirdrop == address(0)) revert AT_ZeroAddress("communityAirdrop");

        communityAirdropSent = true;

        arcadeToken.safeTransfer(_communityAirdrop, communityAirdropAmount);

        emit Distribute(address(arcadeToken), _communityAirdrop, communityAirdropAmount);
    }

    /**
     * @notice Transfers a predetermined amount of Arcade Tokens to a recipient address
     *         which is responsible for distributing Arcade Tokens to the Arcade team.
     *
     * @param _vestingTeam             Address responsible for distributing vesting rewards.
     */
    function toTeamVesting(address _vestingTeam) external onlyOwner whenTokenSet {
        if (vestingTeamSent) revert AT_AlreadySent();
        if (_vestingTeam == address(0)) revert AT_ZeroAddress("vestingTeam");

        vestingTeamSent = true;

        arcadeToken.safeTransfer(_vestingTeam, vestingTeamAmount);

        emit Distribute(address(arcadeToken), _vestingTeam, vestingTeamAmount);
    }

    /**
     * @notice Transfers a predetermined amount of Arcade Tokens to a recipient address
     *         which is responsible for distributing Arcade Tokens to our Launch Partners.
     *
     * @param _vestingPartner          Address responsible for distributing vesting rewards.
     */
    function toPartnerVesting(address _vestingPartner) external onlyOwner whenTokenSet {
        if (vestingPartnerSent) revert AT_AlreadySent();
        if (_vestingPartner == address(0)) revert AT_ZeroAddress("vestingPartner");

        vestingPartnerSent = true;

        arcadeToken.safeTransfer(_vestingPartner, vestingPartnerAmount);

        emit Distribute(address(arcadeToken), _vestingPartner, vestingPartnerAmount);
    }

    // ============================================ ADMIN OPS ===========================================

    /**
     * @notice Sets the Arcade Token contract address, to be used in token distribution. The token
     *         contract address can only be set once.
     *
     * @param _arcadeToken             The Arcade Token contract.
     */
    function setToken(IArcadeToken _arcadeToken) external onlyOwner {
        if (address(_arcadeToken) == address(0)) revert AT_ZeroAddress("arcadeToken");
        if (address(arcadeToken) != address(0)) revert AT_TokenAlreadySet();

        arcadeToken = _arcadeToken;
    }

    // ============================================ HELPERS ============================================

    /** @notice Check to ensure that the Arcade Token contract address has been set
     *          before calling a withdraw function.
     */
    modifier whenTokenSet() {
        if (address(arcadeToken) == address(0)) revert AT_ZeroAddress("arcadeToken");
        _;
    }
}