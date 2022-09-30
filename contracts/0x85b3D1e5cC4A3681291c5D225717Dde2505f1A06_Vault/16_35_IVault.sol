// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ILoanPriceOracle.sol";
import "./INoteAdapter.sol";
import "./ILoanReceiver.sol";

/**
 * @title Interface to a Vault
 */
interface IVault is ILoanReceiver {
    /**************************************************************************/
    /* Enums */
    /**************************************************************************/

    /**
     * @notice Tranche identifier
     */
    enum TrancheId {
        Senior,
        Junior
    }

    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when currency is deposited
     * @param account Depositing account
     * @param trancheId Tranche
     * @param amount Amount of currency tokens
     * @param shares Amount of LP tokens minted
     */
    event Deposited(address indexed account, TrancheId indexed trancheId, uint256 amount, uint256 shares);

    /**
     * @notice Emitted when a note is purchased
     * @param account Selling account
     * @param noteToken Note token contract
     * @param noteTokenId Note token ID
     * @param loanId Loan ID
     * @param purchasePrice Purchase price in currency tokens
     * @param trancheContributions Tranche contributions in currency tokens
     */
    event NotePurchased(
        address indexed account,
        address indexed noteToken,
        uint256 noteTokenId,
        uint256 indexed loanId,
        uint256 purchasePrice,
        uint256[2] trancheContributions
    );

    /**
     * @notice Emitted when LP tokens are redeemed
     * @param account Redeeming account
     * @param trancheId Tranche
     * @param shares Amount of LP tokens burned
     * @param amount Amount of currency tokens
     */
    event Redeemed(address indexed account, TrancheId indexed trancheId, uint256 shares, uint256 amount);

    /**
     * @notice Emitted when redeemed currency tokens are withdrawn
     * @param account Withdrawing account
     * @param trancheId Tranche
     * @param amount Amount of currency tokens withdrawn
     */
    event Withdrawn(address indexed account, TrancheId indexed trancheId, uint256 amount);

    /**
     * @notice Emitted when liquidated loan collateral is withdrawn
     * @param noteToken Note token contract
     * @param loanId Loan ID
     * @param collateralToken Collateral token contract
     * @param collateralTokenId Collateral token ID
     * @param collateralLiquidator Collateral liquidator contract
     */
    event CollateralWithdrawn(
        address indexed noteToken,
        uint256 indexed loanId,
        address collateralToken,
        uint256 collateralTokenId,
        address collateralLiquidator
    );

    /**
     * @notice Emitted when loan is repaid
     * @param noteToken Note token contract
     * @param loanId Loan ID
     * @param adminFee Admin fee in currency tokens
     * @param trancheReturns Tranches returns in currency tokens
     */
    event LoanRepaid(address indexed noteToken, uint256 indexed loanId, uint256 adminFee, uint256[2] trancheReturns);

    /**
     * @notice Emitted when loan is liquidated
     * @param noteToken Note token contract
     * @param loanId Loan ID
     * @param trancheLosses Tranche losses in currency tokens
     */
    event LoanLiquidated(address indexed noteToken, uint256 indexed loanId, uint256[2] trancheLosses);

    /**
     * @notice Emitted when collateral is liquidated
     * @param noteToken Note token contract
     * @param loanId Loan ID
     * @param trancheReturns Tranches returns in currency tokens
     */
    event CollateralLiquidated(address indexed noteToken, uint256 indexed loanId, uint256[2] trancheReturns);

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @notice Get vault name
     * @return Vault name
     */
    function name() external view returns (string memory);

    /**
     * @notice Get currency token
     * @return Currency token contract
     */
    function currencyToken() external view returns (IERC20);

    /**
     * @notice Get LP token
     * @param trancheId Tranche
     * @return LP token contract
     */
    function lpToken(TrancheId trancheId) external view returns (IERC20);

    /**
     * @notice Get loan price oracle
     * @return Loan price oracle contract
     */
    function loanPriceOracle() external view returns (ILoanPriceOracle);

    /**
     * @notice Get note adapter contract
     * @param noteToken Note token contract
     * @return Note adapter contract
     */
    function noteAdapters(address noteToken) external view returns (INoteAdapter);

    /**
     * @notice Get list of supported note tokens
     * @return List of note token addresses
     */
    function supportedNoteTokens() external view returns (address[] memory);

    /**
     * @notice Get share price
     * @param trancheId Tranche
     * @return Share price in UD60x18
     */
    function sharePrice(TrancheId trancheId) external view returns (uint256);

    /**
     * @notice Get redemption share price
     * @param trancheId Tranche
     * @return Redemption share price in UD60x18
     */
    function redemptionSharePrice(TrancheId trancheId) external view returns (uint256);

    /**
     * @notice Get utilization
     * @return Utilization in UD60x18, between 0 to 1
     */
    function utilization() external view returns (uint256);

    /**
     * @notice Get utilization with added loan balanace
     * @param additionalLoanBalance Additional loan balance in currency tokens
     * @return Utilization in UD60x18, between 0 to 1
     */
    function utilization(uint256 additionalLoanBalance) external view returns (uint256);

    /**************************************************************************/
    /* User API */
    /**************************************************************************/

    /**
     * @notice Deposit currency into a tranche in exchange for LP tokens
     *
     * Emits a {Deposited} event.
     *
     * @param trancheId Tranche
     * @param amount Amount of currency tokens
     */
    function deposit(TrancheId trancheId, uint256 amount) external;

    /**
     * @notice Sell a note to the vault
     *
     * Emits a {NotePurchased} event.
     *
     * @param noteToken Note token contract
     * @param noteTokenId Note token ID
     * @param minPurchasePrice Minimum purchase price in currency tokens
     * @return Executed purchase price in currency tokens
     */
    function sellNote(
        address noteToken,
        uint256 noteTokenId,
        uint256 minPurchasePrice
    ) external returns (uint256);

    /**
     * @notice Sell a note to the vault and deposit its proceeds into one or
     * more tranches
     *
     * Emits {NotePurchased} and {Deposited} events.
     *
     * Note: the minimum purchase price is the sum of `amounts`.
     *
     * @param noteToken Note token contract
     * @param noteTokenId Note token ID
     * @param minPurchasePrice Minimum purchase price in currency tokens
     * @param allocation Allocation for each tranche as a percentage in UD60x18
     * @return Executed purchase price in currency tokens
     */
    function sellNoteAndDeposit(
        address noteToken,
        uint256 noteTokenId,
        uint256 minPurchasePrice,
        uint256[2] calldata allocation
    ) external returns (uint256);

    /**
     * @notice Redeem LP tokens in exchange for currency tokens. Currency
     * tokens can be withdrawn with the `withdraw()` method, once the
     * redemption is processed.
     *
     * Emits a {Redeemed} event.
     *
     * @param trancheId Tranche
     * @param shares Amount of LP tokens
     */
    function redeem(TrancheId trancheId, uint256 shares) external;

    /**
     * @notice Withdraw redeemed currency tokens
     *
     * Emits a {Withdrawn} event.
     *
     * @param trancheId Tranche
     * @param maxAmount Maximum amount of currency tokens to withdraw
     */
    function withdraw(TrancheId trancheId, uint256 maxAmount) external;

    /**************************************************************************/
    /* Collateral API */
    /**************************************************************************/

    /**
     * @notice Withdraw the collateral of a liquidated loan
     *
     * Emits a {CollateralWithdrawn} event.
     *
     * @param noteToken Note token contract
     * @param loanId Loan ID
     */
    function withdrawCollateral(address noteToken, uint256 loanId) external;

    /**************************************************************************/
    /* Callbacks */
    /**************************************************************************/

    /* See ILoanReceiver */

    /**
     * @notice Callback on collateral liquidated
     *
     * Emits a {CollateralLiquidated} event.
     *
     * @param noteToken Note token contract
     * @param loanId Loan ID
     * @param proceeds Proceeds from collateral liquidation in currency tokens
     */
    function onCollateralLiquidated(
        address noteToken,
        uint256 loanId,
        uint256 proceeds
    ) external;
}