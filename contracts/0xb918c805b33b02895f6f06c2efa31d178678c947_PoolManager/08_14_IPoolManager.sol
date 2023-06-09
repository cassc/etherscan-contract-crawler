// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { IPoolManagerStorage } from "./IPoolManagerStorage.sol";

interface IPoolManager is IMapleProxied, IPoolManagerStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when a new allowed lender is called.
     *  @param lender_ The address of the new lender.
     *  @param isValid_ Whether the new lender is valid.
     */
    event AllowedLenderSet(address indexed lender_, bool isValid_);

    /**
     *  @dev   Emitted when a collateral liquidations is finished.
     *  @param loan_             The address of the loan.
     *  @param unrealizedLosses_ The amount of unrealized losses.
     */
    event CollateralLiquidationFinished(address indexed loan_, uint256 unrealizedLosses_);

    /**
     *  @dev   Emitted when a collateral liquidations is triggered.
     *  @param loan_ The address of the loan.
     */
    event CollateralLiquidationTriggered(address indexed loan_);

    /**
     *  @dev   Emitted when cover is deposited.
     *  @param amount_ The amount of cover deposited.
     */
    event CoverDeposited(uint256 amount_);

    /**
     *  @dev   Emitted when cover is liquidated in the case of a loan defaulting.
     *  @param toTreasury_ The amount of cover sent to the Treasury.
     *  @param toPool_     The amount of cover sent to the Pool.
     */
    event CoverLiquidated(uint256 toTreasury_, uint256 toPool_);

    /**
     *  @dev   Emitted when cover is withdrawn.
     *  @param amount_ The amount of cover withdrawn.
     */
    event CoverWithdrawn(uint256 amount_);

    /**
     *  @dev   Emitted when a new management fee rate is set.
     *  @param managementFeeRate_ The amount of management fee rate.
     */
    event DelegateManagementFeeRateSet(uint256 managementFeeRate_);

    /**
     *  @dev   Emitted when a loan manager is set as valid.
     *  @param loanManager_   The address of the loan manager.
     *  @param isLoanManager_ Whether the loan manager is valid.
     */
    event IsLoanManagerSet(address indexed loanManager_, bool isLoanManager_);

    /**
     *  @dev   Emitted when a new liquidity cap is set.
     *  @param liquidityCap_ The value of liquidity cap.
     */
    event LiquidityCapSet(uint256 liquidityCap_);

    /**
     *  @dev   Emitted when a new loan manager is added.
     *  @param loanManager_ The address of the new loan manager.
     */
    event LoanManagerAdded(address indexed loanManager_);

    /**
     *  @dev Emitted when a pool is open to public.
     */
    event OpenToPublic();

    /**
     *  @dev   Emitted when the pending pool delegate accepts the ownership transfer.
     *  @param previousDelegate_ The address of the previous delegate.
     *  @param newDelegate_      The address of the new delegate.
     */
    event PendingDelegateAccepted(address indexed previousDelegate_, address indexed newDelegate_);

    /**
     *  @dev   Emitted when the pending pool delegate is set.
     *  @param previousDelegate_ The address of the previous delegate.
     *  @param newDelegate_      The address of the new delegate.
     */
    event PendingDelegateSet(address indexed previousDelegate_, address indexed newDelegate_);

    /**
     *  @dev Emitted when the pool configuration is marked as complete.
     */
    event PoolConfigurationComplete();

    /**
     *  @dev   Emitted when a redemption of shares from the pool is processed.
     *  @param owner_            The owner of the shares.
     *  @param redeemableShares_ The amount of redeemable shares.
     *  @param resultingAssets_  The amount of assets redeemed.
     */
    event RedeemProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev   Emitted when a redemption of shares from the pool is requested.
     *  @param owner_  The owner of the shares.
     *  @param shares_ The amount of redeemable shares.
     */
    event RedeemRequested(address indexed owner_, uint256 shares_);

    /**
     *  @dev   Emitted when a pool is sets to be active or inactive.
     *  @param active_ Whether the pool is active.
     */
    event SetAsActive(bool active_);

    /**
     *  @dev   Emitted when shares are removed from the pool.
     *  @param owner_  The address of the owner of the shares.
     *  @param shares_ The amount of shares removed.
     */
    event SharesRemoved(address indexed owner_, uint256 shares_);

    /**
     *  @dev   Emitted when the withdrawal manager is set.
     *  @param withdrawalManager_ The address of the withdrawal manager.
     */
    event WithdrawalManagerSet(address indexed withdrawalManager_);

    /**
     *  @dev   Emitted when withdrawal of assets from the pool is processed.
     *  @param owner_            The owner of the assets.
     *  @param redeemableShares_ The amount of redeemable shares.
     *  @param resultingAssets_  The amount of assets redeemed.
     */
    event WithdrawalProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);

    /**************************************************************************************************************************************/
    /*** Ownership Transfer Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev Accepts the role of pool delegate.
     */
    function acceptPoolDelegate() external;

    /**
     *  @dev   Sets an address as the pending pool delegate.
     *  @param pendingPoolDelegate_ The address of the new pool delegate.
     */
    function setPendingPoolDelegate(address pendingPoolDelegate_) external;

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Adds a new loan manager.
     *  @param  loanManagerFactory_ The address of the loan manager factory to use.
     *  @return loanManager_        The address of the new loan manager.
     */
    function addLoanManager(address loanManagerFactory_) external returns (address loanManager_);

    /**
     *  @dev Complete the configuration.
     */
    function completeConfiguration() external;

    /**
     *  @dev   Sets a the pool to be active or inactive.
     *  @param active_ Whether the pool is active.
     */
    function setActive(bool active_) external;

    /**
     *  @dev   Sets a new lender as valid or not.
     *  @param lender_  The address of the new lender.
     *  @param isValid_ Whether the new lender is valid.
     */
    function setAllowedLender(address lender_, bool isValid_) external;

    /**
     *  @dev   Sets the value for the delegate management fee rate.
     *  @param delegateManagementFeeRate_ The value for the delegate management fee rate.
     */
    function setDelegateManagementFeeRate(uint256 delegateManagementFeeRate_) external;

    /**
     *  @dev   Sets if the loanManager is valid in the isLoanManager mapping.
     *  @param loanManager_   The address of the loanManager
     *  @param isLoanManager_ Whether the loanManager is valid.
     */
    function setIsLoanManager(address loanManager_, bool isLoanManager_) external;

    /**
     *  @dev   Sets the value for liquidity cap.
     *  @param liquidityCap_ The value for liquidity cap.
     */
    function setLiquidityCap(uint256 liquidityCap_) external;

    /**
     *  @dev Sets pool open to public depositors.
     */
    function setOpenToPublic() external;

    /**
     *  @dev   Sets the address of the withdrawal manager.
     *  @param withdrawalManager_ The address of the withdrawal manager.
     */
    function setWithdrawalManager(address withdrawalManager_) external;

    /**************************************************************************************************************************************/
    /*** Funding Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   LoanManager can request funds from the pool via the poolManager.
     *  @param destination_ The address to send the funds to.
     *  @param principal_   The principal amount to fund the loan with.
     */
    function requestFunds(address destination_, uint256 principal_) external;

    /**************************************************************************************************************************************/
    /*** Liquidation Functions                                                                                                          ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Finishes the collateral liquidation
     *  @param loan_ Loan that had its collateral liquidated.
     */
    function finishCollateralLiquidation(address loan_) external;

    /**
     *  @dev   Triggers the default of a loan.
     *  @param loan_              Loan to trigger the default.
     *  @param liquidatorFactory_ Factory used to deploy the liquidator.
     */
    function triggerDefault(address loan_, address liquidatorFactory_) external;

    /**************************************************************************************************************************************/
    /*** Exit Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Processes a redemptions of shares for assets from the pool.
     *  @param  shares_           The amount of shares to redeem.
     *  @param  owner_            The address of the owner of the shares.
     *  @param  sender_           The address of the sender of the redeem call.
     *  @return redeemableShares_ The amount of shares redeemed.
     *  @return resultingAssets_  The amount of assets withdrawn.
     */
    function processRedeem(uint256 shares_, address owner_, address sender_)
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev    Processes a redemptions of shares for assets from the pool.
     *  @param  assets_           The amount of assets to withdraw.
     *  @param  owner_            The address of the owner of the shares.
     *  @param  sender_           The address of the sender of the withdraw call.
     *  @return redeemableShares_ The amount of shares redeemed.
     *  @return resultingAssets_  The amount of assets withdrawn.
     */
    function processWithdraw(uint256 assets_, address owner_, address sender_)
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev    Requests a redemption of shares from the pool.
     *  @param  shares_         The amount of shares to redeem.
     *  @param  owner_          The address of the owner of the shares.
     *  @return sharesReturned_ The amount of shares withdrawn.
     */
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /**
     *  @dev   Requests a redemption of shares from the pool.
     *  @param shares_ The amount of shares to redeem.
     *  @param owner_  The address of the owner of the shares.
     *  @param sender_ The address of the sender of the shares.
     */
    function requestRedeem(uint256 shares_, address owner_, address sender_) external;

    /**
     *  @dev   Requests a withdrawal of assets from the pool.
     *  @param shares_ The amount of shares to redeem.
     *  @param assets_ The amount of assets to withdraw.
     *  @param owner_  The address of the owner of the shares.
     *  @param sender_ The address of the sender of the shares.
     */
     function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    /**************************************************************************************************************************************/
    /*** Cover Functions                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Deposits cover into the pool.
     *  @param amount_ The amount of cover to deposit.
     */
    function depositCover(uint256 amount_) external;

    /**
     *  @dev   Withdraws cover from the pool.
     *  @param amount_    The amount of cover to withdraw.
     *  @param recipient_ The address of the recipient.
     */
    function withdrawCover(uint256 amount_, address recipient_) external;

    /**************************************************************************************************************************************/
    /*** LP Token View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the amount of exit shares for the input amount.
     *  @param  amount_  Address of the account.
     *  @return shares_  Amount of shares able to be exited.
     */
    function convertToExitShares(uint256 amount_) external view returns (uint256 shares_);

    /**
     *  @dev    Gets the information of escrowed shares.
     *  @param  owner_        The address of the owner of the shares.
     *  @param  shares_       The amount of shares to get the information of.
     *  @return escrowShares_ The amount of escrowed shares.
     *  @return destination_  The address of the destination.
     */
    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address destination_);

    /**
     *  @dev   Gets the amount of assets that can be deposited.
     *  @param receiver_  The address to check the deposit for.
     *  @param maxAssets_ The maximum amount assets to deposit.
     */
    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);

    /**
     *  @dev   Gets the amount of shares that can be minted.
     *  @param receiver_  The address to check the mint for.
     *  @param maxShares_ The maximum amount shares to mint.
     */
    function maxMint(address receiver_) external view returns (uint256 maxShares_);

    /**
     *  @dev   Gets the amount of shares that can be redeemed.
     *  @param owner_     The address to check the redemption for.
     *  @param maxShares_ The maximum amount shares to redeem.
     */
    function maxRedeem(address owner_) external view returns (uint256 maxShares_);

    /**
     *  @dev   Gets the amount of assets that can be withdrawn.
     *  @param owner_     The address to check the withdraw for.
     *  @param maxAssets_ The maximum amount assets to withdraw.
     */
    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    /**
     *  @dev    Gets the amount of shares that can be redeemed.
     *  @param  owner_   The address to check the redemption for.
     *  @param  shares_  The amount of requested shares to redeem.
     *  @return assets_  The amount of assets that will be returned for `shares_`.
     */
    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Gets the amount of assets that can be redeemed.
     *  @param  owner_   The address to check the redemption for.
     *  @param  assets_  The amount of requested shares to redeem.
     *  @return shares_  The amount of assets that will be returned for `assets_`.
     */
    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Checks if a scheduled call can be executed.
     *  @param  functionId_   The function to check.
     *  @param  caller_       The address of the caller.
     *  @param  data_         The data of the call.
     *  @return canCall_      True if the call can be executed, false otherwise.
     *  @return errorMessage_ The error message if the call cannot be executed.
     */
    function canCall(bytes32 functionId_, address caller_, bytes memory data_)
        external view
        returns (bool canCall_, string memory errorMessage_);

    /**
     *  @dev    Gets the address of the globals.
     *  @return globals_ The address of the globals.
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev    Gets the address of the governor.
     *  @return governor_ The address of the governor.
     */
    function governor() external view returns (address governor_);

    /**
     *  @dev    Returns if pool has sufficient cover.
     *  @return hasSufficientCover_ True if pool has sufficient cover.
     */
    function hasSufficientCover() external view returns (bool hasSufficientCover_);

    /**
     *  @dev    Returns the length of the `loanManagerList`.
     *  @return loanManagerListLength_ The length of the `loanManagerList`.
     */
    function loanManagerListLength() external view returns (uint256 loanManagerListLength_);

    /**
     *  @dev    Returns the amount of total assets.
     *  @return totalAssets_ Amount of of total assets.
     */
    function totalAssets() external view returns (uint256 totalAssets_);

    /**
     *  @dev    Returns the amount unrealized losses.
     *  @return unrealizedLosses_ Amount of unrealized losses.
     */
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}