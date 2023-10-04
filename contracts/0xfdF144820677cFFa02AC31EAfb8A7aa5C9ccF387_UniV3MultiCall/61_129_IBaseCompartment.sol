// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IBaseCompartment {
    event Staked(uint256 gaugeIndex, address liqGaugeAddr, uint256 amount);

    event Delegated(address delegator, address delegatee);

    event UpdatedApprovedStaker(address staker, bool approvalState);

    event UpdatedApprovedDelegator(address delegator, bool approvalState);

    /**
     * @notice function to initialize collateral compartment
     * @dev factory creates clone and then initializes implementation contract
     * @param vaultAddr address of vault
     * @param loanId index of the loan
     */
    function initialize(address vaultAddr, uint256 loanId) external;

    /**
     * @notice function to transfer some amount of collateral to borrower on repay
     * @dev this function can only be called by vault and tranfers proportional amount
     * of compartment collTokenBalance to borrower address. This needs use a proportion
     * and not the amount to account for possible changes due to rewards accruing
     * @param repayAmount amount of loan token to be repaid
     * @param repayAmountLeft amount of loan token still outstanding
     * @param reclaimCollAmount amount of collateral token to be reclaimed
     * @param borrowerAddr address of borrower receiving transfer
     * @param collTokenAddr address of collateral token being transferred
     * @param callbackAddr address to send collateral to instead of borrower if using callback
     */
    function transferCollFromCompartment(
        uint256 repayAmount,
        uint256 repayAmountLeft,
        uint128 reclaimCollAmount,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr
    ) external;

    /**
     * @notice function to unlock all collateral left in compartment
     * @dev this function can only be called by vault and returns all collateral to vault
     * @param collTokenAddr pass in collToken addr to avoid callback reads gas cost
     */
    function unlockCollToVault(address collTokenAddr) external;

    /**
     * @notice function returns the potentially reclaimable collateral token balance
     * @param collTokenAddr address of collateral token for which reclaimable balance is being retrieved
     * @dev depending on compartment implementation this could be simple balanceOf or eg staked balance call
     */
    function getReclaimableBalance(
        address collTokenAddr
    ) external view returns (uint256 reclaimableBalance);
}