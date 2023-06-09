// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { IMapleProxied }         from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { PoolManagerStorage } from "./proxy/PoolManagerStorage.sol";

import {
    IERC20Like,
    IGlobalsLike,
    ILoanLike,
    ILoanManagerLike,
    IPoolDelegateCoverLike,
    IPoolLike,
    IWithdrawalManagerLike
} from "./interfaces/Interfaces.sol";

import { IPoolManager } from "./interfaces/IPoolManager.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

   ██████╗  ██████╗  ██████╗ ██╗         ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
   ██╔══██╗██╔═══██╗██╔═══██╗██║         ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
   ██████╔╝██║   ██║██║   ██║██║         ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
   ██╔═══╝ ██║   ██║██║   ██║██║         ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
   ██║     ╚██████╔╝╚██████╔╝███████╗    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
   ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

*/

contract PoolManager is IPoolManager, MapleProxiedInternals, PoolManagerStorage {

    uint256 public constant HUNDRED_PERCENT = 100_0000;  // Four decimal precision.

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier nonReentrant() {
        require(_locked == 1, "PM:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    modifier onlyIfNotConfigured() {
        _revertIfConfigured();
        _;
    }

    modifier onlyPoolDelegateOrNotConfigured() {
        _revertIfConfiguredAndNotPoolDelegate();
        _;
    }

    modifier onlyPool() {
        _revertIfNotPool();
        _;
    }

    modifier onlyPoolDelegate() {
        _revertIfNotPoolDelegate();
        _;
    }

    modifier onlyPoolDelegateOrGovernor() {
        _revertIfNeitherPoolDelegateNorGovernor();
        _;
    }

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    /**************************************************************************************************************************************/
    /*** Migration Functions                                                                                                            ***/
    /**************************************************************************************************************************************/

    // NOTE: Can't add whenProtocolNotPaused modifier here, as globals won't be set until
    //       initializer.initialize() is called, and this function is what triggers that initialization.
    function migrate(address migrator_, bytes calldata arguments_) external override whenNotPaused {
        require(msg.sender == _factory(),        "PM:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "PM:M:FAILED");
        require(poolDelegateCover != address(0), "PM:M:DELEGATE_NOT_SET");
    }

    function setImplementation(address implementation_) external override whenNotPaused {
        require(msg.sender == _factory(), "PM:SI:NOT_FACTORY");
        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override whenNotPaused {
        IGlobalsLike globals_ = IGlobalsLike(globals());

        if (msg.sender == poolDelegate) {
            require(globals_.isValidScheduledCall(msg.sender, address(this), "PM:UPGRADE", msg.data), "PM:U:INVALID_SCHED_CALL");

            globals_.unscheduleCall(msg.sender, "PM:UPGRADE", msg.data);
        } else {
            require(msg.sender == globals_.securityAdmin(), "PM:U:NO_AUTH");
        }

        emit Upgraded(version_, arguments_);

        IMapleProxyFactory(_factory()).upgradeInstance(version_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** Initial Configuration Function                                                                                                 ***/
    /**************************************************************************************************************************************/

    // NOTE: This function is always called atomically during the deployment process so a DoS attack is not possible.
    function completeConfiguration() external override whenNotPaused onlyIfNotConfigured {
        configured = true;

        emit PoolConfigurationComplete();
    }

    /**************************************************************************************************************************************/
    /*** Ownership Transfer Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    function acceptPoolDelegate() external override whenNotPaused {
        require(msg.sender == pendingPoolDelegate, "PM:APD:NOT_PENDING_PD");

        IGlobalsLike(globals()).transferOwnedPoolManager(poolDelegate, msg.sender);

        emit PendingDelegateAccepted(poolDelegate, pendingPoolDelegate);

        poolDelegate        = pendingPoolDelegate;
        pendingPoolDelegate = address(0);
    }

    function setPendingPoolDelegate(address pendingPoolDelegate_) external override whenNotPaused onlyPoolDelegate {
        pendingPoolDelegate = pendingPoolDelegate_;

        emit PendingDelegateSet(poolDelegate, pendingPoolDelegate_);
    }

    /**************************************************************************************************************************************/
    /*** Globals Admin Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function setActive(bool active_) external override whenNotPaused {
        require(msg.sender == globals(), "PM:SA:NOT_GLOBALS");
        emit SetAsActive(active = active_);
    }

    /**************************************************************************************************************************************/
    /*** Pool Delegate Admin Functions                                                                                                  ***/
    /**************************************************************************************************************************************/

    function addLoanManager(address loanManagerFactory_)
        external override whenNotPaused onlyPoolDelegateOrNotConfigured returns (address loanManager_)
    {
        require(IGlobalsLike(globals()).isInstanceOf("LOAN_MANAGER_FACTORY", loanManagerFactory_), "PM:ALM:INVALID_FACTORY");

        // NOTE: If removing loan managers is allowed in the future, there will be a need to rethink salts here due to collisions.
        loanManager_ = IMapleProxyFactory(loanManagerFactory_).createInstance(
            abi.encode(address(this)),
            keccak256(abi.encode(address(this), loanManagerList.length))
        );

        isLoanManager[loanManager_] = true;

        loanManagerList.push(loanManager_);

        emit LoanManagerAdded(loanManager_);
    }

    function setAllowedLender(address lender_, bool isValid_) external override whenNotPaused onlyPoolDelegate {
        emit AllowedLenderSet(lender_, isValidLender[lender_] = isValid_);
    }

    function setDelegateManagementFeeRate(uint256 delegateManagementFeeRate_)
        external override whenNotPaused onlyPoolDelegateOrNotConfigured
    {
        require(delegateManagementFeeRate_ <= HUNDRED_PERCENT, "PM:SDMFR:OOB");

        emit DelegateManagementFeeRateSet(delegateManagementFeeRate = delegateManagementFeeRate_);
    }

    function setIsLoanManager(address loanManager_, bool isLoanManager_) external override whenNotPaused onlyPoolDelegate {
        emit IsLoanManagerSet(loanManager_, isLoanManager[loanManager_] = isLoanManager_);

        // Check LoanManager is in the list.
        // NOTE: The factory and instance check are not required as the mapping is being updated for a LoanManager that is in the list.
        for (uint256 i_; i_ < loanManagerList.length; ++i_) {
            if (loanManagerList[i_] == loanManager_) return;
        }

        revert("PM:SILM:INVALID_LM");
    }

    function setLiquidityCap(uint256 liquidityCap_) external override whenNotPaused onlyPoolDelegateOrNotConfigured {
        emit LiquidityCapSet(liquidityCap = liquidityCap_);
    }

    function setOpenToPublic() external override whenNotPaused onlyPoolDelegate {
        openToPublic = true;

        emit OpenToPublic();
    }

    function setWithdrawalManager(address withdrawalManager_) external override whenNotPaused onlyIfNotConfigured {
        address factory_ = IMapleProxied(withdrawalManager_).factory();

        require(IGlobalsLike(globals()).isInstanceOf("WITHDRAWAL_MANAGER_FACTORY", factory_), "PM:SWM:INVALID_FACTORY");
        require(IMapleProxyFactory(factory_).isInstance(withdrawalManager_),                  "PM:SWM:INVALID_INSTANCE");

        emit WithdrawalManagerSet(withdrawalManager = withdrawalManager_);
    }

    /**************************************************************************************************************************************/
    /*** Funding Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

    function requestFunds(address destination_, uint256 principal_) external override whenNotPaused nonReentrant {
        address asset_   = asset;
        address pool_    = pool;
        address factory_ = IMapleProxied(msg.sender).factory();

        IGlobalsLike globals_ = IGlobalsLike(globals());

        // NOTE: Do not need to check isInstance() as the LoanManager is added to the list on `addLoanManager()` or `configure()`.
        require(principal_ != 0,                                         "PM:RF:INVALID_PRINCIPAL");
        require(globals_.isInstanceOf("LOAN_MANAGER_FACTORY", factory_), "PM:RF:INVALID_FACTORY");
        require(IMapleProxyFactory(factory_).isInstance(msg.sender),     "PM:RF:INVALID_INSTANCE");
        require(isLoanManager[msg.sender],                               "PM:RF:NOT_LM");
        require(IERC20Like(pool_).totalSupply() != 0,                    "PM:RF:ZERO_SUPPLY");
        require(_hasSufficientCover(address(globals_), asset_),          "PM:RF:INSUFFICIENT_COVER");

        // Fetching locked liquidity needs to be done prior to transferring the tokens.
        uint256 lockedLiquidity_ = IWithdrawalManagerLike(withdrawalManager).lockedLiquidity();

        // Transfer the required principal.
        require(destination_ != address(0),                                        "PM:RF:INVALID_DESTINATION");
        require(ERC20Helper.transferFrom(asset_, pool_, destination_, principal_), "PM:RF:TRANSFER_FAIL");

        // The remaining liquidity in the pool must be greater or equal to the locked liquidity.
        require(IERC20Like(asset_).balanceOf(pool_) >= lockedLiquidity_, "PM:RF:LOCKED_LIQUIDITY");
    }

    /**************************************************************************************************************************************/
    /*** Loan Default Functions                                                                                                         ***/
    /**************************************************************************************************************************************/

    function finishCollateralLiquidation(address loan_) external override whenNotPaused nonReentrant onlyPoolDelegateOrGovernor {
        ( uint256 losses_, uint256 platformFees_ ) = ILoanManagerLike(_getLoanManager(loan_)).finishCollateralLiquidation(loan_);

        _handleCover(losses_, platformFees_);

        emit CollateralLiquidationFinished(loan_, losses_);
    }

    function triggerDefault(address loan_, address liquidatorFactory_)
        external override whenNotPaused nonReentrant onlyPoolDelegateOrGovernor
    {
        require(IGlobalsLike(globals()).isInstanceOf("LIQUIDATOR_FACTORY", liquidatorFactory_), "PM:TD:NOT_FACTORY");

        (
            bool    liquidationComplete_,
            uint256 losses_,
            uint256 platformFees_
        ) = ILoanManagerLike(_getLoanManager(loan_)).triggerDefault(loan_, liquidatorFactory_);

        if (!liquidationComplete_) {
            emit CollateralLiquidationTriggered(loan_);
            return;
        }

        _handleCover(losses_, platformFees_);

        emit CollateralLiquidationFinished(loan_, losses_);
    }

    /**************************************************************************************************************************************/
    /*** Pool Exit Functions                                                                                                            ***/
    /**************************************************************************************************************************************/

    function processRedeem(uint256 shares_, address owner_, address sender_)
        external override whenNotPaused nonReentrant onlyPool returns (uint256 redeemableShares_, uint256 resultingAssets_)
    {
        require(owner_ == sender_ || IPoolLike(pool).allowance(owner_, sender_) > 0, "PM:PR:NO_ALLOWANCE");

        ( redeemableShares_, resultingAssets_ ) = IWithdrawalManagerLike(withdrawalManager).processExit(shares_, owner_);
        emit RedeemProcessed(owner_, redeemableShares_, resultingAssets_);
    }

    function processWithdraw(uint256 assets_, address owner_, address sender_)
        external override whenNotPaused nonReentrant returns (uint256 redeemableShares_, uint256 resultingAssets_)
    {
        assets_; owner_; sender_; redeemableShares_; resultingAssets_;  // Silence compiler warnings
        require(false, "PM:PW:NOT_ENABLED");
    }

    function removeShares(uint256 shares_, address owner_)
        external override whenNotPaused nonReentrant onlyPool returns (uint256 sharesReturned_)
    {
        emit SharesRemoved(
            owner_,
            sharesReturned_ = IWithdrawalManagerLike(withdrawalManager).removeShares(shares_, owner_)
        );
    }

    function requestRedeem(uint256 shares_, address owner_, address sender_) external override whenNotPaused nonReentrant onlyPool {
        address pool_ = pool;

        require(ERC20Helper.approve(pool_, withdrawalManager, shares_), "PM:RR:APPROVE_FAIL");

        if (sender_ != owner_ && shares_ == 0) {
            require(IPoolLike(pool_).allowance(owner_, sender_) > 0, "PM:RR:NO_ALLOWANCE");
        }

        IWithdrawalManagerLike(withdrawalManager).addShares(shares_, owner_);

        emit RedeemRequested(owner_, shares_);
    }

    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_)
        external override whenNotPaused nonReentrant
    {
        shares_; assets_; owner_; sender_;  // Silence compiler warnings
        require(false, "PM:RW:NOT_ENABLED");
    }

    /**************************************************************************************************************************************/
    /*** Pool Delegate Cover Functions                                                                                                  ***/
    /**************************************************************************************************************************************/

    function depositCover(uint256 amount_) external override whenNotPaused {
        require(ERC20Helper.transferFrom(asset, msg.sender, poolDelegateCover, amount_), "PM:DC:TRANSFER_FAIL");
        emit CoverDeposited(amount_);
    }

    function withdrawCover(uint256 amount_, address recipient_) external override whenNotPaused onlyPoolDelegate {
        recipient_ = recipient_ == address(0) ? msg.sender : recipient_;

        IPoolDelegateCoverLike(poolDelegateCover).moveFunds(amount_, recipient_);

        require(
            IERC20Like(asset).balanceOf(poolDelegateCover) >= IGlobalsLike(globals()).minCoverAmount(address(this)),
            "PM:WC:BELOW_MIN"
        );

        emit CoverWithdrawn(amount_);
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function canCall(bytes32 functionId_, address, bytes memory data_)
        external view override returns (bool canCall_, string memory errorMessage_)
    {
        // NOTE: `caller_` param not named to avoid compiler warning.

        if (IGlobalsLike(globals()).isFunctionPaused(msg.sig)) return (false, "PM:CC:PAUSED");

        if (
            functionId_ == "P:redeem"          ||
            functionId_ == "P:withdraw"        ||
            functionId_ == "P:removeShares"    ||
            functionId_ == "P:requestRedeem"   ||
            functionId_ == "P:requestWithdraw"
        ) return (true, "");

        if (functionId_ == "P:deposit") {
            ( uint256 assets_, address receiver_ ) = abi.decode(data_, (uint256, address));
            return _canDeposit(assets_, receiver_, "P:D:");
        }

        if (functionId_ == "P:depositWithPermit") {
            ( uint256 assets_, address receiver_, , , , ) = abi.decode(data_, (uint256, address, uint256, uint8, bytes32, bytes32));
            return _canDeposit(assets_, receiver_, "P:DWP:");
        }

        if (functionId_ == "P:mint") {
            ( uint256 shares_, address receiver_ ) = abi.decode(data_, (uint256, address));
            return _canDeposit(IPoolLike(pool).previewMint(shares_), receiver_, "P:M:");
        }

        if (functionId_ == "P:mintWithPermit") {
            (
                uint256 shares_,
                address receiver_,
                ,
                ,
                ,
                ,
            ) = abi.decode(data_, (uint256, address, uint256, uint256, uint8, bytes32, bytes32));
            return _canDeposit(IPoolLike(pool).previewMint(shares_), receiver_, "P:MWP:");
        }

        if (functionId_ == "P:transfer") {
            ( address recipient_, ) = abi.decode(data_, (address, uint256));
            return _canTransfer(recipient_, "P:T:");
        }

        if (functionId_ == "P:transferFrom") {
            ( , address recipient_, ) = abi.decode(data_, (address, address, uint256));
            return _canTransfer(recipient_, "P:TF:");
        }

        return (false, "PM:CC:INVALID_FUNCTION_ID");
    }

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function governor() public view override returns (address governor_) {
        governor_ = IGlobalsLike(globals()).governor();
    }

    function hasSufficientCover() public view override returns (bool hasSufficientCover_) {
        hasSufficientCover_ = _hasSufficientCover(globals(), asset);
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function loanManagerListLength() external view override returns (uint256 loanManagerListLength_) {
        loanManagerListLength_ = loanManagerList.length;
    }

    function totalAssets() public view override returns (uint256 totalAssets_) {
        totalAssets_ = IERC20Like(asset).balanceOf(pool);

        uint256 length_ = loanManagerList.length;

        for (uint256 i_; i_ < length_;) {
            totalAssets_ += ILoanManagerLike(loanManagerList[i_]).assetsUnderManagement();
            unchecked { ++i_; }
        }
    }

    /**************************************************************************************************************************************/
    /*** LP Token View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function convertToExitShares(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = IPoolLike(pool).convertToExitShares(assets_);
    }

    function getEscrowParams(address, uint256 shares_) external view override returns (uint256 escrowShares_, address destination_) {
        // NOTE: `owner_` param not named to avoid compiler warning.
        ( escrowShares_, destination_) = (shares_, address(this));
    }

    function maxDeposit(address receiver_) external view virtual override returns (uint256 maxAssets_) {
        maxAssets_ = _getMaxAssets(receiver_, totalAssets());
    }

    function maxMint(address receiver_) external view virtual override returns (uint256 maxShares_) {
        uint256 totalAssets_ = totalAssets();
        uint256 maxAssets_   = _getMaxAssets(receiver_, totalAssets_);

        maxShares_ = IPoolLike(pool).previewDeposit(maxAssets_);
    }

    function maxRedeem(address owner_) external view virtual override returns (uint256 maxShares_) {
        uint256 lockedShares_ = IWithdrawalManagerLike(withdrawalManager).lockedShares(owner_);
        maxShares_            = IWithdrawalManagerLike(withdrawalManager).isInExitWindow(owner_) ? lockedShares_ : 0;
    }

    function maxWithdraw(address owner_) external view virtual override returns (uint256 maxAssets_) {
        owner_;          // Silence compiler warning
        maxAssets_ = 0;  // NOTE: always returns 0 as withdraw is not implemented
    }

    function previewRedeem(address owner_, uint256 shares_) external view virtual override returns (uint256 assets_) {
        ( , assets_ ) = IWithdrawalManagerLike(withdrawalManager).previewRedeem(owner_, shares_);
    }

    function previewWithdraw(address owner_, uint256 assets_) external view virtual override returns (uint256 shares_) {
        ( , shares_ ) = IWithdrawalManagerLike(withdrawalManager).previewWithdraw(owner_, assets_);
    }

    function unrealizedLosses() public view override returns (uint256 unrealizedLosses_) {
        uint256 length_ = loanManagerList.length;

        for (uint256 i_; i_ < length_;) {
            unrealizedLosses_ += ILoanManagerLike(loanManagerList[i_]).unrealizedLosses();
            unchecked { ++i_; }
        }

        // NOTE: Use minimum to prevent underflows in the case that `unrealizedLosses` includes late interest and `totalAssets` does not.
        unrealizedLosses_ = _min(unrealizedLosses_, totalAssets());
    }

    /**************************************************************************************************************************************/
    /*** Internal Helper Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    function _getLoanManager(address loan_) internal view returns (address loanManager_) {
        loanManager_ = ILoanLike(loan_).lender();

        require(isLoanManager[loanManager_], "PM:GLM:INVALID_LOAN_MANAGER");
    }

    function _handleCover(uint256 losses_, uint256 platformFees_) internal {
        address globals_ = globals();

        uint256 availableCover_ =
            IERC20Like(asset).balanceOf(poolDelegateCover) * IGlobalsLike(globals_).maxCoverLiquidationPercent(address(this)) /
            HUNDRED_PERCENT;

        uint256 toTreasury_ = _min(availableCover_,               platformFees_);
        uint256 toPool_     = _min(availableCover_ - toTreasury_, losses_);

        if (toTreasury_ != 0) {
            IPoolDelegateCoverLike(poolDelegateCover).moveFunds(toTreasury_, IGlobalsLike(globals_).mapleTreasury());
        }

        if (toPool_ != 0) {
            IPoolDelegateCoverLike(poolDelegateCover).moveFunds(toPool_, pool);
        }

        emit CoverLiquidated(toTreasury_, toPool_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _canDeposit(uint256 assets_, address receiver_, string memory errorPrefix_)
        internal view returns (bool canDeposit_, string memory errorMessage_)
    {
        if (!active)                                    return (false, _formatErrorMessage(errorPrefix_, "NOT_ACTIVE"));
        if (!openToPublic && !isValidLender[receiver_]) return (false, _formatErrorMessage(errorPrefix_, "LENDER_NOT_ALLOWED"));
        if (assets_ + totalAssets() > liquidityCap)     return (false, _formatErrorMessage(errorPrefix_, "DEPOSIT_GT_LIQ_CAP"));

        return (true, "");
    }

    function _canTransfer(address recipient_, string memory errorPrefix_)
        internal view returns (bool canTransfer_, string memory errorMessage_)
    {
        if (!openToPublic && !isValidLender[recipient_]) return (false, _formatErrorMessage(errorPrefix_, "RECIPIENT_NOT_ALLOWED"));

        return (true, "");
    }

    function _formatErrorMessage(string memory errorPrefix_, string memory partialError_)
        internal pure returns (string memory errorMessage_)
    {
        errorMessage_ = string(abi.encodePacked(errorPrefix_, partialError_));
    }

    function _getMaxAssets(address receiver_, uint256 totalAssets_) internal view returns (uint256 maxAssets_) {
        bool    depositAllowed_ = openToPublic || isValidLender[receiver_];
        uint256 liquidityCap_   = liquidityCap;
        maxAssets_              = liquidityCap_ > totalAssets_ && depositAllowed_ ? liquidityCap_ - totalAssets_ : 0;
    }

    function _hasSufficientCover(address globals_, address asset_) internal view returns (bool hasSufficientCover_) {
        hasSufficientCover_ = IERC20Like(asset_).balanceOf(poolDelegateCover) >= IGlobalsLike(globals_).minCoverAmount(address(this));
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 minimum_) {
        minimum_ = a_ < b_ ? a_ : b_;
    }

    function _revertIfConfigured() internal view {
        require(!configured, "PM:ALREADY_CONFIGURED");
    }

    function _revertIfConfiguredAndNotPoolDelegate() internal view {
        require(!configured || msg.sender == poolDelegate, "PM:NO_AUTH");
    }

    function _revertIfNotPool() internal view {
        require(msg.sender == pool, "PM:NOT_POOL");
    }

    function _revertIfNotPoolDelegate() internal view {
        require(msg.sender == poolDelegate, "PM:NOT_PD");
    }

    function _revertIfNeitherPoolDelegateNorGovernor() internal view {
        require(msg.sender == poolDelegate || msg.sender == governor(), "PM:NOT_PD_OR_GOV");
    }

    function _revertIfPaused() internal view {
        require(!IGlobalsLike(globals()).isFunctionPaused(msg.sig), "PM:PAUSED");
    }

}