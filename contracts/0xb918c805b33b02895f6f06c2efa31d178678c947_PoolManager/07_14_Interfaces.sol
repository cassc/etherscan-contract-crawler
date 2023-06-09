// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20Like {

    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    function balanceOf(address account_) external view returns (uint256 balance_);

    function totalSupply() external view returns (uint256 totalSupply_);

}

interface IGlobalsLike {

    function bootstrapMint(address asset_) external view returns (uint256 bootstrapMint_);

    function governor() external view returns (address governor_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId_, address instance_) external view returns (bool isInstance_);

    function isPoolAsset(address asset_) external view returns (bool isPoolAsset_);

    function isPoolDelegate(address account_) external view returns (bool isPoolDelegate_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_)
        external view
        returns (bool isValid_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function maxCoverLiquidationPercent(address poolManager_) external view returns (uint256 maxCoverLiquidationPercent_);

    function migrationAdmin() external view returns (address migrationAdmin_);

    function minCoverAmount(address poolManager_) external view returns (uint256 minCoverAmount_);

    function ownedPoolManager(address poolDelegate_) external view returns (address poolManager_);

    function securityAdmin() external view returns (address securityAdmin_);

    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external;

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface ILoanManagerLike {

    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    function finishCollateralLiquidation(address loan_) external returns (uint256 remainingLosses_, uint256 serviceFee_);

    function triggerDefault(address loan_, address liquidatorFactory_)
        external
        returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

interface ILoanLike {

    function lender() external view returns (address lender_);

}

interface IMapleProxyFactoryLike {

    function mapleGlobals() external view returns (address mapleGlobals_);

}

interface IPoolDelegateCoverLike {

    function moveFunds(uint256 amount_, address recipient_) external;

}

interface IPoolLike is IERC20Like {

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    function previewMint(uint256 shares_) external view returns (uint256 assets_);

}

interface IPoolManagerLike {

    function addLoanManager(address loanManagerFactory_) external returns (address loanManager_);

    function canCall(bytes32 functionId_, address caller_, bytes memory data_)
        external view
        returns (bool canCall_, string memory errorMessage_);

    function completeConfiguration() external;

    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address escrow_);

    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);

    function maxMint(address receiver_) external view returns (uint256 maxShares_);

    function maxRedeem(address owner_) external view returns (uint256 maxShares_);

    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    function pool() external view returns (address pool_);

    function poolDelegateCover() external view returns (address poolDelegateCover_);

    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    function processRedeem(uint256 shares_, address owner_, address sender_)
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function processWithdraw(uint256 assets_, address owner_, address sender_)
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    function requestRedeem(uint256 shares_, address owner_, address sender_) external;

    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    function setDelegateManagementFeeRate(uint256 delegateManagementFeeRate_) external;

    function setLiquidityCap(uint256 liquidityCap_) external;

    function setWithdrawalManager(address withdrawalManager_) external;

    function totalAssets() external view returns (uint256 totalAssets_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

interface IWithdrawalManagerLike {

    function addShares(uint256 shares_, address owner_) external;

    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);

    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);

    function lockedShares(address owner_) external view returns (uint256 lockedShares_);

    function previewRedeem(address owner_, uint256 shares) external view returns (uint256 redeemableShares, uint256 resultingAssets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 redeemableAssets_, uint256 resultingShares_);

    function processExit(uint256 shares_, address account_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

}