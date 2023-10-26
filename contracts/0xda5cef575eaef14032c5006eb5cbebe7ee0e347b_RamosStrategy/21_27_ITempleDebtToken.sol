pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/ITempleDebtToken.sol)

import { IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ITempleElevatedAccess } from "contracts/interfaces/v2/access/ITempleElevatedAccess.sol";

interface ITempleDebtToken is IERC20, IERC20Metadata, ITempleElevatedAccess {
    error NonTransferrable();
    error CannotMintOrBurn(address caller);

    event BaseInterestRateSet(uint96 rate);
    event RiskPremiumInterestRateSet(address indexed debtor, uint96 rate);
    event AddedMinter(address indexed account);
    event RemovedMinter(address indexed account);
    event DebtorBalance(address indexed debtor, uint128 principal, uint128 baseInterest, uint128 riskPremiumInterest);

    /**
     * @notice Track the deployed version of this contract. 
     */
    function version() external view returns (string memory);

    /**
     * @notice The current (base rate) interest common for all users. This can be updated by governance
     * @dev 1e18 format, where 0.01e18 = 1%
     */
    function baseRate() external view returns (uint96);

    /**
     * @notice The last checkpoint time of the (base rate) principal and interest checkpoint
     */
    function baseCheckpointTime() external view returns (uint32);

    /**
     * @notice The (base rate) total principal and interest owed across all debtors as of the latest checkpoint
     */
    function baseCheckpoint() external view returns (uint128);

    /**
     * @notice The (base rate) total number of shares allocated out to users for internal book keeping
     */
    function baseShares() external view returns (uint128);

    /**
     * @notice The net amount of principal amount of debt minted across all users.
     */
    function totalPrincipal() external view returns (uint128);

    /**
     * @notice The latest estimate of the (risk premium) interest (no principal) owed.
     * @dev Indicative only. This total is only updated on a per strategy basis when that strategy gets 
     * checkpointed (on borrow/repay rate change).
     * So it is generally always going to be out of date as each strategy will accrue interest independently 
     * on different rates.
     */
    function estimatedTotalRiskPremiumInterest() external view returns (uint128);

    /// @dev byte packed into two slots.
    struct Debtor {
        /// @notice The current principal owed by this debtor
        uint128 principal;

        /// @notice The number of this shares this debtor is allocated of the base interest.
        uint128 baseShares;

        /// @notice The current (risk premium) interest rate specific to this debtor. This can be updated by governance
        /// @dev 1e18 format, where 0.01e18 = 1%
        uint96 rate;

        /// @notice The debtor's (risk premium only) interest (no principal or base interest) owed as of the last checkpoint
        uint128 checkpoint;

        /// @notice The last checkpoint time of this debtor's (risk premium) interest
        /// @dev uint32 => max time of Feb 7 2106
        uint32 checkpointTime;
    }

    /**
     * @notice Per address status of debt
     */
    function debtors(address account) external view returns (
        /// @notice The current principal owed by this debtor
        uint128 principal,

        /// @notice The number of this shares this debtor is allocated of the base interest.
        uint128 baseShares,

        /// @notice The current (risk premium) interest rate specific to this debtor. This can be updated by governance
        /// @dev 1e18 format, where 0.01e18 = 1%
        uint96 rate,

        /// @notice The debtor's (risk premium only) interest (no principal or base interest) owed as of the last checkpoint
        uint128 checkpoint,

        /// @notice The last checkpoint time of this debtor's (risk premium) interest
        uint32 checkpointTime
    );

    /// @notice A set of addresses which are approved to mint/burn
    function minters(address account) external view returns (bool);

    /**
     * @notice Governance can add an address which is able to mint or burn debt
     * positions on behalf of users.
     */
    function addMinter(address account) external;

    /**
     * @notice Governance can remove an address which is able to mint or burn debt
     * positions on behalf of users.
     */
    function removeMinter(address account) external;

    /**
     * @notice Governance can update the continuously compounding (base) interest rate of all debtors, from this block onwards.
     */
    function setBaseInterestRate(uint96 _rate) external;

    /**
     * @notice Governance can update the continuously compounding (risk premium) interest rate for a given debtor, from this block onwards
     */
    function setRiskPremiumInterestRate(address _debtor, uint96 _rate) external;

    /**
     * @notice Approved Minters can add a new debt position on behalf of a user.
     * @param _debtor The address of the debtor who is issued new debt
     * @param _mintAmount The notional amount of debt tokens to issue.
     */
    function mint(address _debtor, uint256 _mintAmount) external;

    /**
     * @notice Approved Minters can burn debt on behalf of a user.
     * @dev Interest is repaid in preference:
     *   1/ Firstly to the higher interest rate of (baseRate, debtor risk premium rate)
     *   2/ Any remaining of the repayment is then paid of the other interest amount.
     *   3/ Finally if there is still some repayment amount unallocated, 
     *      then the principal will be paid down. This is like a new debt is issued for the lower balance,
     *      where interest accrual starts fresh.
     * More debt than the user has cannot be burned - it is capped. The actual amount burned is returned
     * @param _debtor The address of the debtor
     * @param _burnAmount The notional amount of debt tokens to repay.
     */
    function burn(address _debtor, uint256 _burnAmount) external returns (uint256 burnedAmount);

    /**
     * @notice Approved Minters can burn the entire debt on behalf of a user.
     * @param _debtor The address of the debtor
     */
    function burnAll(address _debtor) external returns (uint256 burnedAmount);

    /**
     * @notice Checkpoint the base interest owed by all debtors up to this block.
     */
    function checkpointBaseInterest() external returns (uint256);

    /**
     * @notice Checkpoint a debtor's (risk premium) interest (no principal) owed up to this block.
     */
    function checkpointDebtorInterest(address debtor) external returns (uint256);

    /**
     * @notice Checkpoint multiple accounts (risk premium) interest (no principal) owed up to this block.
     * @dev Provided in case there needs to be block synchronisation on the total debt.
     */
    function checkpointDebtorsInterest(address[] calldata _debtors) external;

    struct DebtOwed {
        uint256 principal;
        uint256 baseInterest;
        uint256 riskPremiumInterest;
    }

    /**
     * @notice The current debt for a given user split out by
     * principal, base interest, risk premium (per debtor) interest
     */
    function currentDebtOf(address _debtor) external view returns (
        DebtOwed memory debtOwed
    );

    /**
     * @notice The current debt for a given set of users split out by
     * principal, base interest, risk premium (per debtor) interest
     */
    function currentDebtsOf(address[] calldata _debtors) external view returns (
        DebtOwed[] memory debtsOwed
    );

    /**
      * @notice The current total principal + total base interest, total (estimate) debtor specific risk premium interest owed by all debtors.
      * @dev Note the (total principal + total base interest) portion is up to date.
      * However the (debtor specific risk premium interest) portion is likely stale.
      * The `estimatedTotalDebtorInterest` is only updated when each debtor checkpoints, so it's going to be out of date.
      * For more up to date current totals, off-chain aggregation of balanceOf() will be required - eg via subgraph.
      */
    function currentTotalDebt() external view returns (
        DebtOwed memory debtOwed
    );

    /**
     * @notice Convert a (base interest) debt amount into proportional amount of shares
     */
    function baseDebtToShares(uint128 debt) external view returns (uint128);

    /**
     * @notice Convert a number of (base interest) shares into proportional amount of debt
     */
    function baseSharesToDebt(uint128 shares) external view returns (uint128);
}