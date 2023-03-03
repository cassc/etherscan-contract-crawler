// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "./interfaces/IVault.sol";
import "./LPToken.sol";

/**
 * @title Storage for Vault, V1
 */
abstract contract VaultStorageV1 {
    /**************************************************************************/
    /* Structures */
    /**************************************************************************/

    /**
     * @notice Tranche state
     * @param realizedValue Realized value
     * @param pendingRedemptions Pending redemptions
     * @param redemptionQueue Current redemption queue (tail)
     * @param processedRedemptionQueue Processed redemption queue (head)
     * @param pendingReturns Mapping of time bucket to pending returns
     */
    struct Tranche {
        uint256 realizedValue;
        uint256 pendingRedemptions;
        uint256 redemptionQueue;
        uint256 processedRedemptionQueue;
        mapping(uint256 => uint256) pendingReturns;
    }

    /**
     * @notice Loan status
     */
    enum LoanStatus {
        Uninitialized,
        Active,
        Liquidated,
        Complete
    }

    /**
     * @notice Loan state
     * @param status Loan status
     * @param maturityTimeBucket Maturity time bucket
     * @param collateralToken Collateral token contract
     * @param collateralTokenId Collateral token ID
     * @param purchasePrice Purchase price in currency tokens
     * @param repayment Repayment in currency tokens
     * @param seniorTrancheReturn Senior tranche return in currency tokens
     */
    struct Loan {
        LoanStatus status;
        uint64 maturityTimeBucket;
        IERC721 collateralToken;
        uint256 collateralTokenId;
        uint256 purchasePrice;
        uint256 repayment;
        uint256 seniorTrancheReturn;
    }

    /**************************************************************************/
    /* Properties and Linked Contracts */
    /**************************************************************************/

    string internal _name;
    IERC20 internal _currencyToken;
    ILoanPriceOracle internal _loanPriceOracle;
    mapping(address => INoteAdapter) internal _noteAdapters;
    EnumerableSet.AddressSet internal _noteTokens;
    LPToken internal _seniorLPToken;
    LPToken internal _juniorLPToken;

    /**************************************************************************/
    /* Parameters */
    /**************************************************************************/

    /**
     * @dev Senior tranche rate in UD60x18 amount per second
     */
    uint256 internal _seniorTrancheRate;

    /**
     * @dev Admin fee rate in UD60x18 fraction of interest
     */
    uint256 internal _adminFeeRate;

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    Tranche internal _seniorTranche;
    Tranche internal _juniorTranche;
    uint256 internal _totalCashBalance;
    /* _totalLoanBalance is computed at runtime */
    uint256 internal _totalAdminFeeBalance;
    uint256 internal _totalWithdrawalBalance;

    /**
     * @dev Mapping of note token contract to loan ID to loan
     */
    mapping(address => mapping(uint256 => Loan)) internal _loans;

    /**
     * @dev Mapping of maturity time bucket to note token contract to list of loan IDs
     */
    mapping(uint256 => mapping(address => uint256[])) internal _pendingLoans;
}

/**
 * @title Storage for Vault, aggregated
 */
abstract contract VaultStorage is VaultStorageV1 {

}

/**
 * @title Vault
 */
contract Vault is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    VaultStorage,
    ERC721Holder,
    ERC165,
    Multicall,
    KeeperCompatibleInterface,
    IVault
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.5";

    /**
     * @notice Time bucket duration in seconds
     */
    uint256 public constant TIME_BUCKET_DURATION = 7 days;

    /**
     * @notice Number of share price proration buckets
     */
    uint256 public constant SHARE_PRICE_PRORATION_BUCKETS = 14;

    /**
     * @notice Total share price proration window in seconds
     */
    uint256 public constant TOTAL_SHARE_PRICE_PRORATION_DURATION = TIME_BUCKET_DURATION * SHARE_PRICE_PRORATION_BUCKETS;

    /**
     * @notice One in UD60x18
     */
    uint256 private constant ONE_UD60X18 = 1e18;

    /**************************************************************************/
    /* Access Control Roles */
    /**************************************************************************/

    /**
     * @notice Note seller role
     */
    bytes32 public constant NOTE_SELLER_ROLE = keccak256("NOTE_SELLER");

    /**
     * @notice Collateral liquidator role
     */
    bytes32 public constant COLLATERAL_LIQUIDATOR_ROLE = keccak256("COLLATERAL_LIQUIDATOR");

    /**
     * @notice Emergency administrator role
     */
    bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN");

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid address (e.g. zero address)
     */
    error InvalidAddress();

    /**
     * @notice Parameter out of bounds
     */
    error ParameterOutOfBounds();

    /**
     * @notice Unsupported token decimals
     */
    error UnsupportedTokenDecimals();

    /**
     * @notice Unsupported note token
     */
    error UnsupportedNoteToken();

    /**
     * @notice Unsupported note parameters
     */
    error UnsupportedNoteParameters();

    /**
     * @notice Insolvent tranche
     */
    error InsolventTranche(TrancheId trancheId);

    /**
     * @notice Purchase price too low
     */
    error PurchasePriceTooLow();

    /**
     * @notice Purchase price too high
     */
    error PurchasePriceTooHigh();

    /**
     * @notice Insufficient cash available
     */
    error InsufficientCashAvailable();

    /**
     * @notice Interest rate too low
     */
    error InterestRateTooLow();

    /**
     * @notice Invalid loan status
     */
    error InvalidLoanStatus();

    /**
     * @notice Loan not repaid
     */
    error LoanNotRepaid();

    /**
     * @notice Loan not expired
     */
    error LoanNotExpired();

    /**
     * @notice Call failed
     */
    error CallFailed();

    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when senior tranche rate is updated
     * @param rate New senior tranche rate in UD60x18 amount per second
     */
    event SeniorTrancheRateUpdated(uint256 rate);

    /**
     * @notice Emitted when admin fee rate is updated
     * @param rate New admin fee rate in UD60x18 fraction of interest
     */
    event AdminFeeRateUpdated(uint256 rate);

    /**
     * @notice Emitted when loan price oracle contract is updated
     * @param loanPriceOracle New loan price oracle contract
     */
    event LoanPriceOracleUpdated(address loanPriceOracle);

    /**
     * @notice Emitted when note adapter is updated
     * @param noteToken Note token contract
     * @param noteAdapter Note adapter contract
     */
    event NoteAdapterUpdated(address indexed noteToken, address noteAdapter);

    /**
     * @notice Emitted when note seller approval is updated
     * @param enabled Note seller approval enabled
     */
    event NoteSellerApprovalUpdated(bool enabled);

    /**
     * @notice Emitted when admin fees are withdrawn
     * @param account Recipient account
     * @param amount Amount of currency tokens withdrawn
     */
    event AdminFeesWithdrawn(address indexed account, uint256 amount);

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice Vault constructor (for implementation)
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() initializer {}

    /**
     * @notice Vault constructor (for proxy)
     * @param name_ Vault name
     * @param currencyToken_ Currency token contract
     * @param loanPriceOracle_ Loan price oracle contract
     * @param seniorLPToken_ Senior LP token contract
     * @param juniorLPToken_ Junior LP token contract
     */
    function initialize(
        string memory name_,
        IERC20 currencyToken_,
        ILoanPriceOracle loanPriceOracle_,
        LPToken seniorLPToken_,
        LPToken juniorLPToken_
    ) external initializer {
        if (address(currencyToken_) == address(0)) revert InvalidAddress();
        if (address(loanPriceOracle_) == address(0)) revert InvalidAddress();
        if (address(seniorLPToken_) == address(0)) revert InvalidAddress();
        if (address(juniorLPToken_) == address(0)) revert InvalidAddress();

        if (IERC20Metadata(address(currencyToken_)).decimals() != 18) revert UnsupportedTokenDecimals();

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _name = name_;
        _currencyToken = currencyToken_;
        _loanPriceOracle = loanPriceOracle_;
        _seniorLPToken = seniorLPToken_;
        _juniorLPToken = juniorLPToken_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EMERGENCY_ADMIN_ROLE, msg.sender);
    }

    /**************************************************************************/
    /* Interface Getters (defined in IVault) */
    /**************************************************************************/

    /**
     * @inheritdoc IVault
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @inheritdoc IVault
     */
    function currencyToken() external view returns (IERC20) {
        return _currencyToken;
    }

    /**
     * @inheritdoc IVault
     */
    function lpToken(TrancheId trancheId) external view returns (IERC20) {
        return IERC20(address(_lpToken(trancheId)));
    }

    /**
     * @inheritdoc IVault
     */
    function loanPriceOracle() external view returns (ILoanPriceOracle) {
        return _loanPriceOracle;
    }

    /**
     * @inheritdoc IVault
     */
    function noteAdapters(address noteToken) external view returns (INoteAdapter) {
        return _noteAdapters[noteToken];
    }

    /**
     * @inheritdoc IVault
     */
    function supportedNoteTokens() external view returns (address[] memory) {
        return _noteTokens.values();
    }

    /**
     * @inheritdoc IVault
     */
    function sharePrice(TrancheId trancheId) external view returns (uint256) {
        return _computeSharePrice(trancheId);
    }

    /**
     * @inheritdoc IVault
     */
    function redemptionSharePrice(TrancheId trancheId) external view returns (uint256) {
        return _computeRedemptionSharePrice(trancheId);
    }

    /**
     * @inheritdoc IVault
     */
    function utilization() external view returns (uint256) {
        return _computeUtilization(0);
    }

    /**
     * @inheritdoc IVault
     */
    function utilization(uint256 additionalLoanBalance) external view returns (uint256) {
        return _computeUtilization(additionalLoanBalance);
    }

    /**************************************************************************/
    /* Additional Getters */
    /**************************************************************************/

    /**
     * @notice Get tranche state
     * @param trancheId Tranche
     * @return realizedValue Realized value
     * @return estimatedValue Estimated value
     * @return pendingRedemptions Pending redemptions
     * @return redemptionQueue Current redemption queue
     * @return processedRedemptionQueue Processed redemption queue
     * @return depositSharePrice Deposit share price in UD60x18
     * @return redemptionSharePrice_ Redemption share price in UD60x18
     */
    function trancheState(
        TrancheId trancheId
    )
        external
        view
        returns (
            uint256 realizedValue,
            uint256 estimatedValue,
            uint256 pendingRedemptions,
            uint256 redemptionQueue,
            uint256 processedRedemptionQueue,
            uint256 depositSharePrice,
            uint256 redemptionSharePrice_
        )
    {
        Tranche storage tranche = _trancheState(trancheId);
        return (
            tranche.realizedValue,
            _computeEstimatedValue(trancheId),
            tranche.pendingRedemptions,
            tranche.redemptionQueue,
            tranche.processedRedemptionQueue,
            _computeSharePrice(trancheId),
            _computeRedemptionSharePrice(trancheId)
        );
    }

    /**
     * @notice Get vault balance state
     * @return totalCashBalance Total cash balance
     * @return totalLoanBalance Total loan balance
     * @return totalAdminFeeBalance Total admin fee balance
     * @return totalWithdrawalBalance Total withdrawal balance
     */
    function balanceState()
        external
        view
        returns (
            uint256 totalCashBalance,
            uint256 totalLoanBalance,
            uint256 totalAdminFeeBalance,
            uint256 totalWithdrawalBalance
        )
    {
        return (_totalCashBalance, _totalLoanBalance(), _totalAdminFeeBalance, _totalWithdrawalBalance);
    }

    /**
     * @notice Get Loan state
     * @param noteToken Note token contract
     * @param loanId Loan ID
     * @return Loan state
     */
    function loanState(address noteToken, uint256 loanId) external view returns (Loan memory) {
        return _loans[noteToken][loanId];
    }

    /**
     * @notice Get Pending Loans
     * @param timeBucket Time bucket
     * @param noteToken Note token contract
     * @return Loan IDs
     */
    function pendingLoans(uint64 timeBucket, address noteToken) external view returns (uint256[] memory) {
        return _pendingLoans[uint256(timeBucket)][noteToken];
    }

    /**
     * @notice Get senior tranche rate
     * @return Senior tranche rate in UD60x18 amount per second
     */
    function seniorTrancheRate() external view returns (uint256) {
        return _seniorTrancheRate;
    }

    /**
     * @notice Get admin fee rate
     * @return Admin fee rate in UD60x18 fraction of interest
     */
    function adminFeeRate() external view returns (uint256) {
        return _adminFeeRate;
    }

    /**************************************************************************/
    /* Internal Helper Functions */
    /**************************************************************************/

    /**
     * @dev Get LP token contract
     */
    function _lpToken(TrancheId trancheId) internal view returns (LPToken) {
        return (trancheId == TrancheId.Senior) ? _seniorLPToken : _juniorLPToken;
    }

    /**
     * @dev Get tranche state
     */
    function _trancheState(TrancheId trancheId) internal view returns (Tranche storage) {
        return (trancheId == TrancheId.Senior) ? _seniorTranche : _juniorTranche;
    }

    /**
     * @dev Get the total loan balance, computed indirectly from tranche
     * realized values and cash balances
     * @return Total loan balance in UD60x18
     */
    function _totalLoanBalance() internal view returns (uint256) {
        return _seniorTranche.realizedValue + _juniorTranche.realizedValue - _totalCashBalance;
    }

    /**
     * @dev Get and validate the note adapter for a note token
     */
    function _getNoteAdapter(address noteToken) internal view returns (INoteAdapter) {
        INoteAdapter noteAdapter = _noteAdapters[noteToken];

        /* Validate note token is supported */
        if (noteAdapter == INoteAdapter(address(0x0))) revert UnsupportedNoteToken();

        return noteAdapter;
    }

    /**
     * @dev Convert Unix timestamp to time bucket
     */
    function _timestampToTimeBucket(uint256 timestamp) internal pure returns (uint256) {
        return timestamp / TIME_BUCKET_DURATION;
    }

    /**
     * @dev Convert time bucket to Unix timestamp
     */
    function _timeBucketToTimestamp(uint256 timeBucket) internal pure returns (uint256) {
        return timeBucket * TIME_BUCKET_DURATION;
    }

    /**
     * @dev Compute solvent value of the tranche
     * @param trancheId tranche
     * @return Solvent value in currency tokens
     */
    function _computeSolventValue(TrancheId trancheId) internal view returns (uint256) {
        Tranche storage tranche = _trancheState(trancheId);
        return
            tranche.realizedValue > tranche.pendingRedemptions ? tranche.realizedValue - tranche.pendingRedemptions : 0;
    }

    /**
     * @dev Compute estimated value of the tranche, including prorated pending
     * returns
     * @param trancheId tranche
     * @return Estimated value in currency tokens
     */
    function _computeEstimatedValue(TrancheId trancheId) internal view returns (uint256) {
        Tranche storage tranche = _trancheState(trancheId);

        /* Get the current time bucket */
        uint256 currentTimeBucket = _timestampToTimeBucket(block.timestamp);

        /* Compute elapsed time into current time bucket and convert to UD60x18 */
        uint256 elapsedTimeIntoBucket = PRBMathUD60x18.fromUint(
            block.timestamp - _timeBucketToTimestamp(currentTimeBucket)
        );

        /* Sum the prorated returns from pending returns in each time bucket */
        uint256 proratedReturns;
        for (uint256 i; i < SHARE_PRICE_PRORATION_BUCKETS; ++i) {
            /* Prorated Returns[i] = ((Elapsed Time + W * (N - 1 - i)) / (W * N)) * Pending Returns[i]  */
            proratedReturns += PRBMathUD60x18.div(
                PRBMathUD60x18.mul(
                    elapsedTimeIntoBucket +
                        PRBMathUD60x18.fromUint(TIME_BUCKET_DURATION * (SHARE_PRICE_PRORATION_BUCKETS - 1 - i)),
                    tranche.pendingReturns[currentTimeBucket + i]
                ),
                PRBMathUD60x18.fromUint(TOTAL_SHARE_PRICE_PRORATION_DURATION)
            );
        }

        /* Return the realized value plus prorated returns */
        return _computeSolventValue(trancheId) + proratedReturns;
    }

    /**
     * @dev Check if a tranche is solvent
     * @param trancheId tranche
     * @return Tranche is solvent
     */
    function _isSolvent(TrancheId trancheId) internal view returns (bool) {
        Tranche storage tranche = _trancheState(trancheId);
        return tranche.realizedValue > tranche.pendingRedemptions || _lpToken(trancheId).totalSupply() == 0;
    }

    /**
     * @dev Compute share price of tranche including prorated pending returns
     * @param trancheId tranche
     * @return Share price in UD60x18
     */
    function _computeSharePrice(TrancheId trancheId) internal view returns (uint256) {
        uint256 totalSupply = _lpToken(trancheId).totalSupply();
        if (totalSupply == 0) {
            return ONE_UD60X18;
        }
        return PRBMathUD60x18.div(_computeEstimatedValue(trancheId), totalSupply);
    }

    /**
     * @dev Compute redemption share price of tranche
     * @param trancheId tranche
     * @return Redemption share price in UD60x18
     */
    function _computeRedemptionSharePrice(TrancheId trancheId) internal view returns (uint256) {
        uint256 totalSupply = _lpToken(trancheId).totalSupply();
        if (totalSupply == 0) {
            return ONE_UD60X18;
        }
        return PRBMathUD60x18.div(_computeSolventValue(trancheId), totalSupply);
    }

    /**
     * @dev Compute utilization
     * @param additionalLoanBalance Additional loan balance in currency tokens
     * @return Utilization in UD60x18, between 0 and 1
     */
    function _computeUtilization(uint256 additionalLoanBalance) internal view returns (uint256) {
        uint256 totalLoanBalance = _totalLoanBalance();
        uint256 totalBalance = _totalCashBalance + totalLoanBalance;
        return (totalBalance == 0) ? 0 : PRBMathUD60x18.div(totalLoanBalance + additionalLoanBalance, totalBalance);
    }

    /**
     * @dev Process redemptions for tranche
     * @param tranche Tranche
     * @param proceeds Proceeds in currency tokens
     */
    function _processRedemptions(Tranche storage tranche, uint256 proceeds) internal returns (uint256) {
        /* Compute maximum redemption possible */
        uint256 redemptionAmount = Math.min(tranche.realizedValue, Math.min(tranche.pendingRedemptions, proceeds));

        /* Update tranche redemption state */
        tranche.pendingRedemptions -= redemptionAmount;
        tranche.processedRedemptionQueue += redemptionAmount;
        tranche.realizedValue -= redemptionAmount;

        /* Add redemption to withdrawal balance */
        _totalWithdrawalBalance += redemptionAmount;

        /* Return amount of proceeds leftover */
        return proceeds - redemptionAmount;
    }

    /**
     * @dev Process new proceeds by applying them to redemptions and undeployed
     * cash
     * @param proceeds Proceeds in currency tokens
     */
    function _processProceeds(uint256 proceeds) internal {
        /* Process senior redemptions */
        proceeds = _processRedemptions(_seniorTranche, proceeds);
        /* Process junior redemptions */
        proceeds = _processRedemptions(_juniorTranche, proceeds);
        /* Update undeployed cash balance */
        _totalCashBalance += proceeds;
    }

    /**
     * @dev Update tranche state with currency deposit and mint LP tokens to
     * depositer
     * @param trancheId tranche
     * @param amount Amount of currency tokens
     */
    function _deposit(TrancheId trancheId, uint256 amount) internal {
        /* Check tranche is solvent */
        if (!_isSolvent(trancheId)) revert InsolventTranche(trancheId);

        /* Compute current share price */
        uint256 currentSharePrice = _computeSharePrice(trancheId);

        /* Compute number of shares to mint from current tranche share price */
        uint256 shares = PRBMathUD60x18.div(amount, currentSharePrice);

        /* Increase realized value of tranche */
        _trancheState(trancheId).realizedValue += amount;

        /* Process new proceeds */
        _processProceeds(amount);

        /* Mint LP tokens to user */
        _lpToken(trancheId).mint(msg.sender, shares);

        emit Deposited(msg.sender, trancheId, amount, shares);
    }

    /**
     * @dev Calculate purchase price of a loan
     * @param loanInfo Loan info
     */
    function _priceLoan(
        INoteAdapter.LoanInfo memory loanInfo,
        INoteAdapter.AssetInfo[] memory collateralAssets
    ) internal view returns (uint256) {
        uint256 purchasePrice = 0;

        /* Calculate principal and repayment per asset */
        uint256 collateralCount = PRBMathUD60x18.fromUint(collateralAssets.length);
        uint256 principalPerAsset = PRBMathUD60x18.div(loanInfo.principal, collateralCount);
        uint256 repaymentPerAsset = PRBMathUD60x18.div(loanInfo.repayment, collateralCount);

        /* For each collateral asset */
        for (uint256 i; i < collateralAssets.length; ++i) {
            purchasePrice += _loanPriceOracle.priceLoan(
                collateralAssets[i].token,
                collateralAssets[i].tokenId,
                principalPerAsset,
                repaymentPerAsset,
                loanInfo.duration,
                loanInfo.maturity,
                _computeUtilization(purchasePrice)
            );
        }

        return purchasePrice;
    }

    /**
     * @dev Calculate purchase price of note and update tranche state with note
     * purchase
     * @param noteToken Note token contract
     * @param noteTokenId Note token ID
     * @param minPurchasePrice Minimum purchase price in currency tokens
     */
    function _sellNote(address noteToken, uint256 noteTokenId, uint256 minPurchasePrice) internal returns (uint256) {
        /* Lookup note adapter */
        INoteAdapter noteAdapter = _getNoteAdapter(noteToken);

        /* Check if loan parameters are supported */
        if (!noteAdapter.isSupported(noteTokenId, address(_currencyToken))) revert UnsupportedNoteParameters();

        /* Get loan info */
        INoteAdapter.LoanInfo memory loanInfo = noteAdapter.getLoanInfo(noteTokenId);

        /* Compute loan purchase price */
        uint256 purchasePrice = _priceLoan(loanInfo, noteAdapter.getLoanAssets(noteTokenId));

        /* Validate purchase price */
        if (purchasePrice < minPurchasePrice) revert PurchasePriceTooLow();

        /* Validate repayment */
        if (purchasePrice >= loanInfo.repayment) revert PurchasePriceTooHigh();

        /* Validate cash available */
        if (purchasePrice > _totalCashBalance) revert InsufficientCashAvailable();

        /* Calculate senior tranche contribution based on realized value proportion */
        /* Senior Tranche Contribution = (D_s * Purchase Price) / (D_s + D_j) */
        uint256 seniorTrancheContribution = PRBMathUD60x18.div(
            PRBMathUD60x18.mul(_seniorTranche.realizedValue, purchasePrice),
            _seniorTranche.realizedValue + _juniorTranche.realizedValue
        );

        /* Calculate senior tranche return */
        /* Senior Tranche Return = Senior Tranche Contribution * r * t */
        uint256 seniorTrancheReturn = PRBMathUD60x18.mul(
            seniorTrancheContribution,
            PRBMathUD60x18.mul(_seniorTrancheRate, PRBMathUD60x18.fromUint(loanInfo.maturity - block.timestamp))
        );

        /* Validate senior tranche return */
        if (loanInfo.repayment - purchasePrice < seniorTrancheReturn) revert InterestRateTooLow();

        /* Calculate junior tranche return */
        /* Junior Tranche Return = Repayment - Purchase Price - Senior Tranche Return */
        uint256 juniorTrancheReturn = loanInfo.repayment - purchasePrice - seniorTrancheReturn;

        /* Compute loan maturity time bucket */
        uint256 maturityTimeBucket = _timestampToTimeBucket(loanInfo.maturity);

        /* Schedule pending tranche returns */
        _seniorTranche.pendingReturns[maturityTimeBucket] += seniorTrancheReturn;
        _juniorTranche.pendingReturns[maturityTimeBucket] += juniorTrancheReturn;

        /* Update total cash balance */
        _totalCashBalance -= purchasePrice;

        /* Store loan state */
        Loan storage loan = _loans[noteToken][loanInfo.loanId];
        loan.status = LoanStatus.Active;
        loan.maturityTimeBucket = uint64(maturityTimeBucket);
        loan.collateralToken = IERC721(loanInfo.collateralToken);
        loan.collateralTokenId = loanInfo.collateralTokenId;
        loan.purchasePrice = purchasePrice;
        loan.repayment = loanInfo.repayment;
        loan.seniorTrancheReturn = seniorTrancheReturn;

        /* Add loan to pending loan ids */
        _pendingLoans[maturityTimeBucket][noteToken].push(loanInfo.loanId);

        emit NotePurchased(
            msg.sender,
            noteToken,
            noteTokenId,
            loanInfo.loanId,
            purchasePrice,
            [seniorTrancheContribution, purchasePrice - seniorTrancheContribution]
        );

        return purchasePrice;
    }

    /**
     * @dev Check if caller is a note seller. Only applies if note seller
     * approval is enabled.
     */
    modifier onlyNoteSeller() {
        if (StorageSlot.getBooleanSlot(NOTE_SELLER_ROLE).value) _checkRole(NOTE_SELLER_ROLE, _msgSender());
        _;
    }

    /**************************************************************************/
    /* User API */
    /**************************************************************************/

    /**
     * @inheritdoc IVault
     */
    function deposit(TrancheId trancheId, uint256 amount) external whenNotPaused nonReentrant {
        /* Validate amount */
        if (amount == 0) revert ParameterOutOfBounds();

        /* Deposit into tranche */
        _deposit(trancheId, amount);

        /* Transfer cash from user to vault */
        _currencyToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @inheritdoc IVault
     */
    function priceNote(address noteToken, uint256 noteTokenId) external view returns (uint256) {
        /* Lookup note adapter */
        INoteAdapter noteAdapter = _getNoteAdapter(noteToken);

        /* Check if loan parameters are supported */
        if (!noteAdapter.isSupported(noteTokenId, address(_currencyToken))) revert UnsupportedNoteParameters();

        /* Get loan info */
        INoteAdapter.LoanInfo memory loanInfo = noteAdapter.getLoanInfo(noteTokenId);

        /* Compute loan purchase price */
        return _priceLoan(loanInfo, noteAdapter.getLoanAssets(noteTokenId));
    }

    /**
     * @inheritdoc IVault
     */
    function sellNote(
        address noteToken,
        uint256 noteTokenId,
        uint256 minPurchasePrice
    ) external whenNotPaused nonReentrant onlyNoteSeller returns (uint256) {
        /* Purchase the note */
        uint256 purchasePrice = _sellNote(noteToken, noteTokenId, minPurchasePrice);

        /* Transfer promissory note from user to vault */
        IERC721(noteToken).safeTransferFrom(msg.sender, address(this), noteTokenId);

        /* Transfer cash from vault to user */
        _currencyToken.safeTransfer(msg.sender, purchasePrice);

        return purchasePrice;
    }

    /**
     * @inheritdoc IVault
     */
    function sellNoteAndDeposit(
        address noteToken,
        uint256 noteTokenId,
        uint256 minPurchasePrice,
        uint256[2] calldata allocation
    ) external whenNotPaused nonReentrant onlyNoteSeller returns (uint256) {
        /* Check allocations sum to one */
        if (allocation[0] + allocation[1] != ONE_UD60X18) revert ParameterOutOfBounds();

        /* Purchase the note */
        uint256 purchasePrice = _sellNote(noteToken, noteTokenId, minPurchasePrice);

        /* Calculate split of sale proceeds */
        uint256 seniorTrancheAmount = PRBMathUD60x18.mul(allocation[0], purchasePrice);
        uint256 juniorTrancheAmount = purchasePrice - seniorTrancheAmount;

        /* Deposit sale proceeds in tranches */
        if (seniorTrancheAmount != 0) _deposit(TrancheId.Senior, seniorTrancheAmount);
        if (juniorTrancheAmount != 0) _deposit(TrancheId.Junior, juniorTrancheAmount);

        /* Transfer promissory note from user to vault */
        IERC721(noteToken).safeTransferFrom(msg.sender, address(this), noteTokenId);

        return purchasePrice;
    }

    /**
     * @inheritdoc IVault
     */
    function redeem(TrancheId trancheId, uint256 shares) external whenNotPaused nonReentrant {
        /* Validate shares */
        if (shares == 0) revert ParameterOutOfBounds();

        Tranche storage tranche = _trancheState(trancheId);

        /* Check tranche is solvent */
        if (!_isSolvent(trancheId)) revert InsolventTranche(trancheId);

        /* Compute current redemption share price */
        uint256 currentRedemptionSharePrice = _computeRedemptionSharePrice(trancheId);

        /* Compute redemption amount */
        uint256 redemptionAmount = PRBMathUD60x18.mul(shares, currentRedemptionSharePrice);

        /* Schedule redemption with user's token state and burn LP tokens */
        _lpToken(trancheId).redeem(msg.sender, shares, redemptionAmount, tranche.redemptionQueue);

        /* Schedule redemption in tranche */
        tranche.pendingRedemptions += redemptionAmount;
        tranche.redemptionQueue += redemptionAmount;

        /* Process redemptions from undeployed cash */
        uint256 immediateRedemptionAmount = Math.min(redemptionAmount, _totalCashBalance);
        _totalCashBalance -= immediateRedemptionAmount;
        _processProceeds(immediateRedemptionAmount);

        emit Redeemed(msg.sender, trancheId, shares, redemptionAmount);
    }

    /**
     * @inheritdoc IVault
     */
    function withdraw(TrancheId trancheId, uint256 maxAmount) external whenNotPaused nonReentrant {
        Tranche storage tranche = _trancheState(trancheId);

        /* Calculate amount available to withdraw */
        uint256 amount = Math.min(
            _lpToken(trancheId).redemptionAvailable(msg.sender, tranche.processedRedemptionQueue),
            maxAmount
        );

        if (amount != 0) {
            /* Update user's token state with redemption */
            _lpToken(trancheId).withdraw(msg.sender, amount, tranche.processedRedemptionQueue);

            /* Decrease total withdrawal balance */
            _totalWithdrawalBalance -= amount;

            /* Transfer cash from vault to user */
            _currencyToken.safeTransfer(msg.sender, amount);
        }

        emit Withdrawn(msg.sender, trancheId, amount);
    }

    /**************************************************************************/
    /* Collateral API */
    /**************************************************************************/

    /**
     * @inheritdoc IVault
     */
    function withdrawCollateral(
        address noteToken,
        uint256 loanId
    ) external nonReentrant onlyRole(COLLATERAL_LIQUIDATOR_ROLE) {
        /* Lookup note adapter */
        INoteAdapter noteAdapter = _getNoteAdapter(noteToken);

        /* Lookup loan state */
        Loan storage loan = _loans[noteToken][loanId];

        /* Validate loan is liquidated */
        if (loan.status != LoanStatus.Liquidated) revert InvalidLoanStatus();

        /* Get unwrap target and calldata */
        (address target, bytes memory data) = noteAdapter.getUnwrapCalldata(loanId);

        /* Call unwrap if required */
        if (target != address(0x0)) {
            (bool success, ) = target.call(data);
            if (!success) revert CallFailed();
        }

        /* Transfer collateral to liquidator */
        loan.collateralToken.safeTransferFrom(address(this), msg.sender, loan.collateralTokenId);

        emit CollateralWithdrawn(noteToken, loanId, address(loan.collateralToken), loan.collateralTokenId, msg.sender);
    }

    /**************************************************************************/
    /* Callbacks */
    /**************************************************************************/

    /**
     * @inheritdoc ILoanReceiver
     */
    function onLoanRepaid(address noteToken, uint256 loanId) public nonReentrant {
        /* Lookup note adapter */
        INoteAdapter noteAdapter = _getNoteAdapter(noteToken);

        /* Lookup loan state */
        Loan storage loan = _loans[noteToken][loanId];

        /* Validate loan is active */
        if (loan.status != LoanStatus.Active) revert InvalidLoanStatus();

        /* Validate loan was repaid */
        if (!noteAdapter.isRepaid(loanId)) revert LoanNotRepaid();

        /* Calculate tranche returns */
        uint256 seniorTrancheReturn = loan.seniorTrancheReturn;
        uint256 juniorTrancheReturn = loan.repayment - loan.purchasePrice - seniorTrancheReturn;

        /* Unschedule pending returns */
        _seniorTranche.pendingReturns[loan.maturityTimeBucket] -= seniorTrancheReturn;
        _juniorTranche.pendingReturns[loan.maturityTimeBucket] -= juniorTrancheReturn;

        /* Calculate and apply admin fee */
        seniorTrancheReturn -= PRBMathUD60x18.mul(_adminFeeRate, seniorTrancheReturn);
        juniorTrancheReturn -= PRBMathUD60x18.mul(_adminFeeRate, juniorTrancheReturn);
        uint256 adminFee = loan.repayment - loan.purchasePrice - seniorTrancheReturn - juniorTrancheReturn;

        /* Increase admin fee balance */
        _totalAdminFeeBalance += adminFee;

        /* Increase tranche realized values */
        _seniorTranche.realizedValue += seniorTrancheReturn;
        _juniorTranche.realizedValue += juniorTrancheReturn;

        /* Process new proceeds */
        _processProceeds(loan.repayment - adminFee);

        /* Mark loan complete */
        loan.status = LoanStatus.Complete;

        emit LoanRepaid(noteToken, loanId, adminFee, [seniorTrancheReturn, juniorTrancheReturn]);
    }

    /**
     * @inheritdoc ILoanReceiver
     */
    function onLoanExpired(address noteToken, uint256 loanId) public nonReentrant {
        /* Lookup note adapter */
        INoteAdapter noteAdapter = _getNoteAdapter(noteToken);

        /* Lookup loan state */
        Loan storage loan = _loans[noteToken][loanId];

        /* Validate loan is active */
        if (loan.status != LoanStatus.Active) revert InvalidLoanStatus();

        /* Validate loan is not repaid and expired */
        if (noteAdapter.isRepaid(loanId) || !noteAdapter.isExpired(loanId)) revert LoanNotExpired();

        /* Calculate tranche returns */
        uint256 seniorTrancheReturn = loan.seniorTrancheReturn;
        uint256 juniorTrancheReturn = loan.repayment - loan.purchasePrice - seniorTrancheReturn;

        /* Unschedule pending returns */
        _seniorTranche.pendingReturns[loan.maturityTimeBucket] -= seniorTrancheReturn;
        _juniorTranche.pendingReturns[loan.maturityTimeBucket] -= juniorTrancheReturn;

        /* Compute tranche losses */
        uint256 juniorTrancheLoss = Math.min(loan.purchasePrice, _juniorTranche.realizedValue);
        uint256 seniorTrancheLoss = loan.purchasePrice - juniorTrancheLoss;

        /* Decrease tranche realized values */
        _seniorTranche.realizedValue -= seniorTrancheLoss;
        _juniorTranche.realizedValue -= juniorTrancheLoss;

        /* Update senior tranche return for collateral liquidation */
        loan.seniorTrancheReturn += seniorTrancheLoss;

        /* Mark loan liquidated in loan state */
        loan.status = LoanStatus.Liquidated;

        /* Get liquidate target and calldata */
        (address target, bytes memory data) = noteAdapter.getLiquidateCalldata(loanId);
        if (target == address(0x0)) revert InvalidAddress();

        /* Call liquidate on lending platform */
        (bool success, ) = target.call(data);
        if (!success) revert CallFailed();

        emit LoanLiquidated(noteToken, loanId, [seniorTrancheLoss, juniorTrancheLoss]);
    }

    /**
     * @inheritdoc IVault
     */
    function onCollateralLiquidated(
        address noteToken,
        uint256 loanId,
        uint256 proceeds
    ) external nonReentrant onlyRole(COLLATERAL_LIQUIDATOR_ROLE) {
        /* Lookup loan state */
        Loan storage loan = _loans[noteToken][loanId];

        /* Validate loan is liquidated */
        if (loan.status != LoanStatus.Liquidated) revert InvalidLoanStatus();

        /* Compute tranche repayments */
        uint256 seniorTrancheRepayment = Math.min(proceeds, loan.seniorTrancheReturn);
        uint256 juniorTrancheRepayment = proceeds - seniorTrancheRepayment;

        /* Increase tranche realized values */
        _seniorTranche.realizedValue += seniorTrancheRepayment;
        _juniorTranche.realizedValue += juniorTrancheRepayment;

        /* Process proceeds */
        _processProceeds(proceeds);

        /* Mark loan complete */
        loan.status = LoanStatus.Complete;

        /* Transfer cash from liquidator to vault */
        _currencyToken.safeTransferFrom(msg.sender, address(this), proceeds);

        emit CollateralLiquidated(noteToken, loanId, [seniorTrancheRepayment, juniorTrancheRepayment]);
    }

    /**************************************************************************/
    /* Keeper Integration */
    /**************************************************************************/

    /**
     * @inheritdoc KeeperCompatibleInterface
     */
    function checkUpkeep(bytes calldata) external view returns (bool, bytes memory) {
        /* Compute current time bucket */
        uint256 currentTimeBucket = _timestampToTimeBucket(block.timestamp);

        /* For each note token */
        uint256 numNoteTokens = _noteTokens.length();
        for (uint256 i; i < numNoteTokens; ++i) {
            /* Get note token */
            address noteToken = _noteTokens.at(i);

            /* Lookup note adapter */
            INoteAdapter noteAdapter = _getNoteAdapter(noteToken);

            /* Check previous, current, and future time buckets */
            for (
                uint256 timeBucket = currentTimeBucket - 1;
                timeBucket < currentTimeBucket + SHARE_PRICE_PRORATION_BUCKETS;
                timeBucket++
            ) {
                /* For each loan ID */
                uint256 numLoans = _pendingLoans[timeBucket][noteToken].length;
                for (uint256 j; j < numLoans; ++j) {
                    /* Get loan ID */
                    uint256 loanId = _pendingLoans[timeBucket][noteToken][j];

                    /* Lookup loan state */
                    Loan memory loan = _loans[noteToken][loanId];

                    /* Make sure loan is active */
                    if (loan.status != LoanStatus.Active) {
                        continue;
                    } else if (noteAdapter.isRepaid(loanId)) {
                        /* Call onLoanRepaid() */
                        return (true, abi.encode(uint8(0), noteToken, loanId));
                    } else if (noteAdapter.isExpired(loanId)) {
                        /* Call onLoanExpired() */
                        return (true, abi.encode(uint8(1), noteToken, loanId));
                    }
                }
            }
        }

        return (false, "");
    }

    /**
     * @inheritdoc KeeperCompatibleInterface
     */
    function performUpkeep(bytes calldata performData) external {
        (uint8 code, address noteToken, uint256 loanId) = abi.decode(performData, (uint8, address, uint256));

        /* Call appropriate callback based on code */
        if (code == 0) {
            onLoanRepaid(noteToken, loanId);
        } else if (code == 1) {
            onLoanExpired(noteToken, loanId);
        } else {
            revert ParameterOutOfBounds();
        }
    }

    /**************************************************************************/
    /* Setters */
    /**************************************************************************/

    /**
     * @notice Set the senior tranche rate
     *
     * Emits a {SeniorTrancheRateUpdated} event.
     *
     * @param rate Rate in UD60x18 amount per second
     */
    function setSeniorTrancheRate(uint256 rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (rate == 0 || rate >= ONE_UD60X18) revert ParameterOutOfBounds();
        _seniorTrancheRate = rate;
        emit SeniorTrancheRateUpdated(rate);
    }

    /**
     * @notice Set the admin fee rate
     *
     * Emits a {AdminFeeRateUpdated} event.
     *
     * @param rate Rate in UD60x18 fraction of interest
     */
    function setAdminFeeRate(uint256 rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (rate == 0 || rate >= ONE_UD60X18) revert ParameterOutOfBounds();
        _adminFeeRate = rate;
        emit AdminFeeRateUpdated(rate);
    }

    /**
     * @notice Set the loan price oracle contract
     *
     * Emits a {LoanPriceOracleUpdated} event.
     *
     * @param loanPriceOracle_ Loan price oracle contract
     */
    function setLoanPriceOracle(address loanPriceOracle_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (loanPriceOracle_ == address(0)) revert InvalidAddress();
        _loanPriceOracle = ILoanPriceOracle(loanPriceOracle_);
        emit LoanPriceOracleUpdated(loanPriceOracle_);
    }

    /**
     * @notice Set note adapter contract
     *
     * Emits a {NoteAdapterUpdated} event.
     *
     * @param noteToken Note token contract
     * @param noteAdapter Note adapter contract
     */
    function setNoteAdapter(address noteToken, address noteAdapter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (noteToken == address(0)) revert InvalidAddress();
        _noteAdapters[noteToken] = INoteAdapter(noteAdapter);
        if (noteAdapter != address(0)) {
            _noteTokens.add(noteToken);
        } else {
            _noteTokens.remove(noteToken);
        }
        emit NoteAdapterUpdated(noteToken, noteAdapter);
    }

    /**
     * @notice Set note seller approval
     *
     * Emits a {NoteSellerApprovalUpdated} event.
     *
     * @param enabled Note seller approval enabled
     */
    function setNoteSellerApproval(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        StorageSlot.getBooleanSlot(NOTE_SELLER_ROLE).value = enabled;
        emit NoteSellerApprovalUpdated(enabled);
    }

    /**
     * @notice Pause contract
     */
    function pause() external onlyRole(EMERGENCY_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyRole(EMERGENCY_ADMIN_ROLE) {
        _unpause();
    }

    /**************************************************************************/
    /* Admin Fees API */
    /**************************************************************************/

    /**
     * @notice Withdraw admin fees
     *
     * Emits a {AdminFeesWithdrawn} event.
     *
     * @param recipient Recipient account
     * @param amount Amount to withdraw
     */
    function withdrawAdminFees(address recipient, uint256 amount) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        if (recipient == address(0)) revert InvalidAddress();
        if (amount > _totalAdminFeeBalance) revert ParameterOutOfBounds();

        /* Update admin fees balance */
        _totalAdminFeeBalance -= amount;

        /* Transfer cash from vault to recipient */
        _currencyToken.safeTransfer(recipient, amount);

        emit AdminFeesWithdrawn(recipient, amount);
    }

    /******************************************************/
    /* ERC165 interface */
    /******************************************************/

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable, ERC165) returns (bool) {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(ILoanReceiver).interfaceId ||
            interfaceId == type(KeeperCompatibleInterface).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}