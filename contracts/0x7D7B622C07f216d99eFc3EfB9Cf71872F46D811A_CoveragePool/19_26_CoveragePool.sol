// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IAssetPoolUpgrade.sol";
import "./interfaces/ICollateralToken.sol";
import "./AssetPool.sol";
import "./CoveragePoolConstants.sol";
import "./GovernanceUtils.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Coverage Pool
/// @notice A contract that manages a single asset pool. Handles approving and
///         unapproving of risk managers and allows them to seize funds from the
///         asset pool if they are approved.
/// @dev Coverage pool contract is owned by the governance. Coverage pool is the
///      owner of the asset pool contract.
contract CoveragePool is Ownable {
    AssetPool public immutable assetPool;
    ICollateralToken public immutable collateralToken;
    UnderwriterToken public immutable underwriterToken;

    bool public firstRiskManagerApproved = false;

    // Currently approved risk managers
    mapping(address => bool) public approvedRiskManagers;
    // Timestamps of risk managers whose approvals have been initiated
    mapping(address => uint256) public riskManagerApprovalTimestamps;

    event RiskManagerApprovalStarted(address riskManager, uint256 timestamp);
    event RiskManagerApprovalCompleted(address riskManager, uint256 timestamp);
    event RiskManagerUnapproved(address riskManager, uint256 timestamp);

    /// @notice Reverts if called by a risk manager that is not approved
    modifier onlyApprovedRiskManager() {
        require(approvedRiskManagers[msg.sender], "Risk manager not approved");
        _;
    }

    constructor(AssetPool _assetPool) {
        assetPool = _assetPool;
        collateralToken = _assetPool.collateralToken();
        underwriterToken = _assetPool.underwriterToken();
    }

    /// @notice Approves the first risk manager
    /// @dev Can be called only by the contract owner. Can be called only once.
    ///      Does not require any further calls to any functions.
    /// @param riskManager Risk manager that will be approved
    function approveFirstRiskManager(address riskManager) external onlyOwner {
        require(
            !firstRiskManagerApproved,
            "The first risk manager was approved"
        );
        approvedRiskManagers[riskManager] = true;
        firstRiskManagerApproved = true;
    }

    /// @notice Begins risk manager approval process.
    /// @dev Can be called only by the contract owner and only when the first
    ///      risk manager is already approved. For a risk manager to be
    ///      approved, a call to `finalizeRiskManagerApproval` must follow
    ///      (after a governance delay).
    /// @param riskManager Risk manager that will be approved
    function beginRiskManagerApproval(address riskManager) external onlyOwner {
        require(
            firstRiskManagerApproved,
            "The first risk manager is not yet approved; Please use "
            "approveFirstRiskManager instead"
        );

        require(
            !approvedRiskManagers[riskManager],
            "Risk manager already approved"
        );

        /* solhint-disable-next-line not-rely-on-time */
        riskManagerApprovalTimestamps[riskManager] = block.timestamp;
        /* solhint-disable-next-line not-rely-on-time */
        emit RiskManagerApprovalStarted(riskManager, block.timestamp);
    }

    /// @notice Finalizes risk manager approval process.
    /// @dev Can be called only by the contract owner. Must be preceded with a
    ///      call to beginRiskManagerApproval and a governance delay must elapse.
    /// @param riskManager Risk manager that will be approved
    function finalizeRiskManagerApproval(address riskManager)
        external
        onlyOwner
    {
        require(
            riskManagerApprovalTimestamps[riskManager] > 0,
            "Risk manager approval not initiated"
        );
        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp - riskManagerApprovalTimestamps[riskManager] >=
                assetPool.withdrawalGovernanceDelay(),
            "Risk manager governance delay has not elapsed"
        );
        approvedRiskManagers[riskManager] = true;
        /* solhint-disable-next-line not-rely-on-time */
        emit RiskManagerApprovalCompleted(riskManager, block.timestamp);
        delete riskManagerApprovalTimestamps[riskManager];
    }

    /// @notice Unapproves an already approved risk manager or cancels the
    ///         approval process of a risk manager (the latter happens if called
    ///         between `beginRiskManagerApproval` and `finalizeRiskManagerApproval`).
    ///         The change takes effect immediately.
    /// @dev Can be called only by the contract owner.
    /// @param riskManager Risk manager that will be unapproved
    function unapproveRiskManager(address riskManager) external onlyOwner {
        require(
            riskManagerApprovalTimestamps[riskManager] > 0 ||
                approvedRiskManagers[riskManager],
            "Risk manager is neither approved nor with a pending approval"
        );
        delete riskManagerApprovalTimestamps[riskManager];
        delete approvedRiskManagers[riskManager];
        /* solhint-disable-next-line not-rely-on-time */
        emit RiskManagerUnapproved(riskManager, block.timestamp);
    }

    /// @notice Approves upgradeability to the new asset pool.
    ///         Allows governance to set a new asset pool so the underwriters
    ///         can move their collateral tokens to a new asset pool without
    ///         having to wait for the withdrawal delay.
    /// @param _newAssetPool New asset pool
    function approveNewAssetPoolUpgrade(IAssetPoolUpgrade _newAssetPool)
        external
        onlyOwner
    {
        assetPool.approveNewAssetPoolUpgrade(_newAssetPool);
    }

    /// @notice Lets the governance to begin an update of withdrawal delay
    ///         parameter value. Withdrawal delay is the time it takes the
    ///         underwriter to withdraw their collateral and rewards from the
    ///         pool. This is the time that needs to pass between initiating and
    ///         completing the withdrawal. The change needs to be finalized with
    ///         a call to finalizeWithdrawalDelayUpdate after the required
    ///         governance delay passes. It is up to the governance to
    ///         decide what the withdrawal delay value should be but it should
    ///         be long enough so that the possibility of having free-riding
    ///         underwriters escaping from a potential coverage claim by
    ///         withdrawing their positions from the pool is negligible.
    /// @param newWithdrawalDelay The new value of withdrawal delay
    function beginWithdrawalDelayUpdate(uint256 newWithdrawalDelay)
        external
        onlyOwner
    {
        assetPool.beginWithdrawalDelayUpdate(newWithdrawalDelay);
    }

    /// @notice Lets the governance to finalize an update of withdrawal
    ///         delay parameter value. This call has to be preceded with
    ///         a call to beginWithdrawalDelayUpdate and the governance delay
    ///         has to pass.
    function finalizeWithdrawalDelayUpdate() external onlyOwner {
        assetPool.finalizeWithdrawalDelayUpdate();
    }

    /// @notice Lets the governance to begin an update of withdrawal timeout
    ///         parameter value. The withdrawal timeout is the time the
    ///         underwriter has - after the withdrawal delay passed - to
    ///         complete the withdrawal. The change needs to be finalized with
    ///         a call to finalizeWithdrawalTimeoutUpdate after the required
    ///         governance delay passes. It is up to the governance to
    ///         decide what the withdrawal timeout value should be but it should
    ///         be short enough so that the time of free-riding by being able to
    ///         immediately escape from the claim is minimal and long enough so
    ///         that honest underwriters have a possibility to finalize the
    ///         withdrawal. It is all about the right proportions with
    ///         a relation to withdrawal delay value.
    /// @param  newWithdrawalTimeout The new value of the withdrawal timeout
    function beginWithdrawalTimeoutUpdate(uint256 newWithdrawalTimeout)
        external
        onlyOwner
    {
        assetPool.beginWithdrawalTimeoutUpdate(newWithdrawalTimeout);
    }

    /// @notice Lets the governance to finalize an update of withdrawal
    ///         timeout parameter value. This call has to be preceded with
    ///         a call to beginWithdrawalTimeoutUpdate and the governance delay
    ///         has to pass.
    function finalizeWithdrawalTimeoutUpdate() external onlyOwner {
        assetPool.finalizeWithdrawalTimeoutUpdate();
    }

    /// @notice Seizes funds from the coverage pool and sends them to the
    ///         `recipient`.
    /// @dev `portionToSeize` value was multiplied by `FLOATING_POINT_DIVISOR`
    ///      for calculation precision purposes. Further calculations in this
    ///      function will need to take this divisor into account.
    /// @param recipient Address that will receive the pool's seized funds
    /// @param portionToSeize Portion of the pool to seize in the range (0, 1]
    ///        multiplied by `FLOATING_POINT_DIVISOR`
    function seizePortion(address recipient, uint256 portionToSeize)
        external
        onlyApprovedRiskManager
    {
        require(
            portionToSeize > 0 &&
                portionToSeize <= CoveragePoolConstants.FLOATING_POINT_DIVISOR,
            "Portion to seize is not within the range (0, 1]"
        );

        assetPool.claim(recipient, amountToSeize(portionToSeize));
    }

    /// @notice Seizes funds from the coverage pool and sends them to the
    ///         `recipient`.
    /// @param recipient Address that will receive the pool's seized funds
    /// @param amountToSeize Amount to be seized from the pool
    // slither-disable-next-line shadowing-local
    function seizeAmount(address recipient, uint256 amountToSeize)
        external
        onlyApprovedRiskManager
    {
        require(amountToSeize > 0, "Amount to seize must be >0");

        assetPool.claim(recipient, amountToSeize);
    }

    /// @notice Grants asset pool shares by minting a given amount of the
    ///         underwriter tokens for the recipient address. In result, the
    ///         recipient obtains part of the pool ownership without depositing
    ///         any collateral tokens. Shares are usually granted for notifiers
    ///         reporting about various contract state changes.
    /// @dev Can be called only by an approved risk manager.
    /// @param recipient Address of the underwriter tokens recipient
    /// @param covAmount Amount of the underwriter tokens which should be minted
    function grantAssetPoolShares(address recipient, uint256 covAmount)
        external
        onlyApprovedRiskManager
    {
        assetPool.grantShares(recipient, covAmount);
    }

    /// @notice Returns the time remaining until the risk manager approval
    ///         process can be finalized
    /// @param riskManager Risk manager in the process of approval
    /// @return Remaining time in seconds.
    function getRemainingRiskManagerApprovalTime(address riskManager)
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                riskManagerApprovalTimestamps[riskManager],
                assetPool.withdrawalGovernanceDelay()
            );
    }

    /// @notice Determine the prior number of DAO votes for the given coverage
    ///         pool underwriter.
    /// @param account The underwriter address to check
    /// @param blockNumber The block number to get the vote balance at
    /// @return The number of votes the underwriter had as of the given block
    function getPastVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96)
    {
        uint96 underwriterVotes = underwriterToken.getPastVotes(
            account,
            blockNumber
        );
        uint96 underwriterTokenSupply = underwriterToken.getPastTotalSupply(
            blockNumber
        );

        if (underwriterTokenSupply == 0) {
            return 0;
        }

        uint96 covPoolVotes = collateralToken.getPastVotes(
            address(assetPool),
            blockNumber
        );

        return
            uint96(
                (uint256(underwriterVotes) * covPoolVotes) /
                    underwriterTokenSupply
            );
    }

    /// @notice Calculates amount of tokens to be seized from the coverage pool.
    /// @param portionToSeize Portion of the pool to seize in the range (0, 1]
    ///        multiplied by FLOATING_POINT_DIVISOR
    function amountToSeize(uint256 portionToSeize)
        public
        view
        returns (uint256)
    {
        return
            (collateralToken.balanceOf(address(assetPool)) * portionToSeize) /
            CoveragePoolConstants.FLOATING_POINT_DIVISOR;
    }
}