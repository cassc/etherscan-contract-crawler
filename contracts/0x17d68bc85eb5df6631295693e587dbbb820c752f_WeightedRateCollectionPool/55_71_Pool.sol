// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./LoanReceipt.sol";
import "./LiquidityManager.sol";
import "./CollateralFilter.sol";
import "./InterestRateModel.sol";

import "./interfaces/IPool.sol";
import "./interfaces/ILiquidity.sol";
import "./interfaces/ICollateralWrapper.sol";
import "./interfaces/ICollateralLiquidator.sol";
import "./interfaces/ICollateralLiquidationReceiver.sol";

import "./integrations/DelegateCash/IDelegationRegistry.sol";

/**
 * @title Pool
 * @author MetaStreet Labs
 */
abstract contract Pool is
    ERC165,
    ReentrancyGuard,
    Multicall,
    CollateralFilter,
    InterestRateModel,
    IPool,
    ILiquidity,
    ICollateralLiquidationReceiver
{
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using LoanReceipt for LoanReceipt.LoanReceiptV1;
    using LiquidityManager for LiquidityManager.Liquidity;

    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Tick spacing basis points
     */
    uint256 public constant TICK_LIMIT_SPACING_BASIS_POINTS = LiquidityManager.TICK_LIMIT_SPACING_BASIS_POINTS;

    /**
     * @notice Borrower's split of liquidation proceed surplus in basis points
     */
    uint256 public constant BORROWER_SURPLUS_SPLIT_BASIS_POINTS = 9_500;

    /**
     * @notice Basis points scale
     */
    uint256 internal constant BASIS_POINTS_SCALE = 10_000;

    /**
     * @notice Borrow options tag size in bytes
     */
    uint256 internal constant BORROW_OPTIONS_TAG_SIZE = 2;

    /**
     * @notice Borrow options length size in bytes
     */
    uint256 internal constant BORROW_OPTIONS_LENGTH_SIZE = 2;

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid address
     */
    error InvalidAddress();

    /**
     * @notice Parameter out of bounds
     */
    error ParameterOutOfBounds();

    /**************************************************************************/
    /* Structures */
    /**************************************************************************/

    /**
     * @notice Deposit
     * @param shares Shares
     * @param redemptionPending Redemption shares pending
     * @param redemptionIndex Redemption queue index
     * @param redemptionTarget Redemption queue target
     */
    struct Deposit {
        uint128 shares;
        uint128 redemptionPending;
        uint128 redemptionIndex;
        uint128 redemptionTarget;
    }

    /**
     * @notice Loan status
     */
    enum LoanStatus {
        Uninitialized,
        Active,
        Repaid,
        Liquidated,
        CollateralLiquidated
    }

    /**
     * @notice Borrow function options
     */
    enum BorrowOptions {
        None,
        CollateralWrapperContext,
        CollateralFilterContext,
        DelegateCash
    }

    /**************************************************************************/
    /* Immutable State */
    /**************************************************************************/

    /**
     * @notice Collateral wrappers (max 3)
     */
    address internal immutable _collateralWrapper1;
    address internal immutable _collateralWrapper2;
    address internal immutable _collateralWrapper3;

    /**
     * @notice Collateral liquidator
     */
    ICollateralLiquidator internal immutable _collateralLiquidator;

    /**
     * @notice Delegation registry contract
     */
    IDelegationRegistry internal immutable _delegationRegistry;

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Currency token contract
     */
    IERC20 internal _currencyToken;

    /**
     * @notice Admin fee rate in basis points
     */
    uint32 internal _adminFeeRate;

    /**
     * @notice Durations
     */
    uint64[] internal _durations;

    /**
     * @notice Rates
     */
    uint64[] internal _rates;

    /**
     * @notice Admin
     */
    address private _admin;

    /**
     * @notice Total admin fee balance
     */
    uint256 internal _adminFeeBalance;

    /**
     * @notice Liquidity
     */
    LiquidityManager.Liquidity internal _liquidity;

    /**
     * @notice Mapping of account to tick to deposit
     */
    mapping(address => mapping(uint128 => Deposit)) internal _deposits;

    /**
     * @notice Mapping of loan receipt hash to loan status
     */
    mapping(bytes32 => LoanStatus) internal _loans;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice Pool constructor
     * @param collateralLiquidator_ Collateral liquidator
     * @param delegationRegistry_ Delegation registry contract
     * @param collateralWrappers_ Collateral wrappers
     */
    constructor(address collateralLiquidator_, address delegationRegistry_, address[] memory collateralWrappers_) {
        _collateralLiquidator = ICollateralLiquidator(collateralLiquidator_);

        _delegationRegistry = IDelegationRegistry(delegationRegistry_);

        if (collateralWrappers_.length > 3) revert ParameterOutOfBounds();
        _collateralWrapper1 = (collateralWrappers_.length > 0) ? collateralWrappers_[0] : address(0);
        _collateralWrapper2 = (collateralWrappers_.length > 1) ? collateralWrappers_[1] : address(0);
        _collateralWrapper3 = (collateralWrappers_.length > 2) ? collateralWrappers_[2] : address(0);
    }

    /**************************************************************************/
    /* Initializer */
    /**************************************************************************/

    /**
     * @notice Pool initializer
     * @dev Fee-on-transfer currency tokens are not supported
     * @param currencyToken_ Currency token contract
     * @param durations_ Duration tiers
     * @param rates_ Interest rate tiers
     */
    function _initialize(address currencyToken_, uint64[] memory durations_, uint64[] memory rates_) internal {
        if (IERC20Metadata(currencyToken_).decimals() != 18) revert ParameterOutOfBounds();

        _currencyToken = IERC20(currencyToken_);
        _admin = msg.sender;

        /* Assign durations */
        if (durations_.length > Tick.MAX_NUM_DURATIONS) revert ParameterOutOfBounds();
        for (uint256 i; i < durations_.length; i++) {
            /* Check duration is monotonic */
            if (i != 0 && durations_[i] <= durations_[i - 1]) revert ParameterOutOfBounds();
            _durations.push(durations_[i]);
        }

        /* Assign rates */
        if (rates_.length > Tick.MAX_NUM_RATES) revert ParameterOutOfBounds();
        for (uint256 i; i < rates_.length; i++) {
            /* Check rate is monotonic */
            if (i != 0 && rates_[i] <= rates_[i - 1]) revert ParameterOutOfBounds();
            _rates.push(rates_[i]);
        }

        /* Initialize liquidity */
        _liquidity.initialize();
    }

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @notice Get implementation name
     * @return Implementation name
     */
    function IMPLEMENTATION_NAME() external pure virtual returns (string memory);

    /**
     * @notice Get implementation version
     * @return Implementation version
     */
    function IMPLEMENTATION_VERSION() external pure returns (string memory) {
        return "1.3";
    }

    /**
     * @inheritdoc IPool
     */
    function currencyToken() external view returns (address) {
        return address(_currencyToken);
    }

    /**
     * @inheritdoc IPool
     */
    function durations() external view returns (uint64[] memory) {
        return _durations;
    }

    /**
     * @inheritdoc IPool
     */
    function rates() external view returns (uint64[] memory) {
        return _rates;
    }

    /**
     * @inheritdoc IPool
     */
    function admin() external view returns (address) {
        return _admin;
    }

    /**
     * @inheritdoc IPool
     */
    function adminFeeRate() external view returns (uint32) {
        return _adminFeeRate;
    }

    /**
     * @inheritdoc IPool
     */
    function collateralWrappers() external view returns (address[] memory) {
        address[] memory collateralWrappers_ = new address[](3);
        collateralWrappers_[0] = _collateralWrapper1;
        collateralWrappers_[1] = _collateralWrapper2;
        collateralWrappers_[2] = _collateralWrapper3;
        return collateralWrappers_;
    }

    /**
     * @inheritdoc IPool
     */
    function collateralLiquidator() external view returns (address) {
        return address(_collateralLiquidator);
    }

    /**
     * @inheritdoc IPool
     */
    function delegationRegistry() external view returns (address) {
        return address(_delegationRegistry);
    }

    /**
     * @notice Get deposit
     * @param account Account
     * @param tick Tick
     * @return Deposit information
     */
    function deposits(address account, uint128 tick) external view returns (Deposit memory) {
        return _deposits[account][tick];
    }

    /**
     * @notice Get loan status
     * @param receiptHash Loan receipt hash
     * @return Loan status
     */
    function loans(bytes32 receiptHash) external view returns (LoanStatus) {
        return _loans[receiptHash];
    }

    /**
     * @notice Get total admin fee balance
     * @return Total admin fee balance
     */
    function adminFeeBalance() external view returns (uint256) {
        return _adminFeeBalance;
    }

    /**************************************************************************/
    /* Loan Receipt External Helpers */
    /**************************************************************************/

    /**
     * @notice Decode loan receipt
     * @param loanReceipt Loan receipt
     * @return Decoded loan receipt
     */
    function decodeLoanReceipt(bytes calldata loanReceipt) external pure returns (LoanReceipt.LoanReceiptV1 memory) {
        return LoanReceipt.decode(loanReceipt);
    }

    /**************************************************************************/
    /* ILiquidity Getters */
    /**************************************************************************/

    /**
     * @inheritdoc ILiquidity
     */
    function liquidityNodes(uint128 startTick, uint128 endTick) external view returns (NodeInfo[] memory) {
        return _liquidity.liquidityNodes(startTick, endTick);
    }

    /**
     * @inheritdoc ILiquidity
     */
    function liquidityNode(uint128 tick) external view returns (NodeInfo memory) {
        return _liquidity.liquidityNode(tick);
    }

    /**************************************************************************/
    /* Helper Functions */
    /**************************************************************************/

    /**
     * @notice Helper function to extract specified option tag from options
     * data
     *
     * @dev Options are encoded as:
     *   2 byte uint16 tag
     *   2 byte uint16 length
     *   n byte bytes  data
     * The first matching tag is returned.
     *
     * @param options Encoded options
     * @param tag Tag to find
     * @return Options data
     */
    function _getOptionsData(bytes calldata options, uint16 tag) internal pure returns (bytes calldata) {
        uint256 offsetTag = 0;

        /* Scan the options for the tag */
        while (offsetTag < options.length) {
            /* Compute offsets with for tag length and data */
            uint256 offsetLength = offsetTag + BORROW_OPTIONS_TAG_SIZE;
            uint256 offsetData = offsetTag + BORROW_OPTIONS_TAG_SIZE + BORROW_OPTIONS_LENGTH_SIZE;

            /* The tag is in the first 2 bytes of each options item */
            uint16 currentTag = uint16(bytes2(options[offsetTag:offsetLength]));

            /* The length of the options data is in the second 2 bytes of each options item, after the tag */
            uint256 dataLength = uint16(bytes2(options[offsetLength:offsetData]));

            /* Return the offset and length if the tag is found */
            if (currentTag == tag) {
                return options[offsetData:offsetData + dataLength];
            }

            /* Increment to next options item */
            offsetTag = offsetData + dataLength;
        }

        /* Return empty slice if no tag is found */
        return options[0:0];
    }

    /**
     * @notice Helper function that returns underlying collateral in (address,
     * uint256[]) shape
     * @param collateralToken Collateral token, either underlying token or collateral wrapper
     * @param collateralTokenId Collateral token ID
     * @param collateralWrapperContext Collateral wrapper context
     * @return Underlying collateral token and token IDs
     */
    function _getUnderlyingCollateral(
        address collateralToken,
        uint256 collateralTokenId,
        bytes memory collateralWrapperContext
    ) internal view returns (address, uint256[] memory) {
        /* Enumerate bundle if collateral token is a collateral wrapper */
        if (
            collateralToken == _collateralWrapper1 ||
            collateralToken == _collateralWrapper2 ||
            collateralToken == _collateralWrapper3
        ) {
            return ICollateralWrapper(collateralToken).enumerate(collateralTokenId, collateralWrapperContext);
        }

        /* If single asset, convert to length one token ID array */
        uint256[] memory underlyingCollateralTokenIds = new uint256[](1);
        underlyingCollateralTokenIds[0] = collateralTokenId;

        return (collateralToken, underlyingCollateralTokenIds);
    }

    /**
     * @notice Helper function that calls delegate.cash registry to delegate
     * token
     * @param collateralToken Collateral token
     * @param collateralTokenId Collateral token ID
     * @param options Options data
     */
    function _optionDelegateCash(address collateralToken, uint256 collateralTokenId, bytes calldata options) internal {
        /* Find delegate.cash tagged data in options */
        bytes calldata delegateData = _getOptionsData(options, uint16(BorrowOptions.DelegateCash));

        if (delegateData.length != 0) {
            if (address(_delegationRegistry) == address(0) || delegateData.length != 20) revert InvalidBorrowOptions();

            /* Delegate token */
            _delegationRegistry.delegateForToken(
                address(uint160(bytes20(delegateData))),
                collateralToken,
                collateralTokenId,
                true
            );
        }
    }

    /**
     * @dev Helper function to revoke token delegate
     * @param collateralToken Contract address of token that delegation is being removed from
     * @param collateralTokenId Token id of token that delegation is being removed from
     */
    function _revokeDelegates(address collateralToken, uint256 collateralTokenId) internal {
        /* No operation if _delegationRegistry not set */
        if (address(_delegationRegistry) == address(0)) return;

        /* Get delegates for collateral token and id */
        address[] memory delegates = _delegationRegistry.getDelegatesForToken(
            address(this),
            collateralToken,
            collateralTokenId
        );

        for (uint256 i; i < delegates.length; i++) {
            /* Revoke by setting value to false */
            _delegationRegistry.delegateForToken(delegates[i], collateralToken, collateralTokenId, false);
        }
    }

    /**
     * @dev Helper function to quote a loan
     * @param principal Principal amount in currency tokens
     * @param duration Duration in seconds
     * @param collateralToken Collateral token address
     * @param collateralTokenIds List of collateral token ids
     * @param ticks Liquidity node ticks
     * @param collateralFilterContext Collateral filter context
     * @return Repayment amount in currency tokens, liquidity nodes, liquidity
     * node count
     */
    function _quote(
        uint256 principal,
        uint64 duration,
        address collateralToken,
        uint256[] memory collateralTokenIds,
        uint128[] calldata ticks,
        bytes calldata collateralFilterContext
    ) internal view returns (uint256, ILiquidity.NodeSource[] memory, uint16) {
        /* Verify collateral is supported */
        for (uint256 i; i < collateralTokenIds.length; i++) {
            if (!_collateralSupported(collateralToken, collateralTokenIds[i], i, collateralFilterContext))
                revert UnsupportedCollateral(i);
        }

        /* Cache durations */
        uint64[] memory durations_ = _durations;

        /* Lookup duration index */
        uint256 durationIndex;
        for (; durationIndex < durations_.length; durationIndex++) {
            if (duration <= durations_[durationIndex]) break;
        }

        /* Validate duration index */
        if (durationIndex == durations_.length) revert UnsupportedLoanDuration();

        /* Source liquidity nodes */
        (ILiquidity.NodeSource[] memory nodes, uint16 count) = _liquidity.source(
            principal,
            ticks,
            collateralTokenIds.length,
            durationIndex
        );

        /* Calculate repayment from principal, rate, and duration */
        uint256 repayment = (principal *
            (LiquidityManager.FIXED_POINT_SCALE + (_rate(principal, _rates, nodes, count) * duration))) /
            LiquidityManager.FIXED_POINT_SCALE;

        return (repayment, nodes, count);
    }

    /**
     * @dev Helper function to calculated prorated repayment
     * @param loanReceipt Decoded loan receipt
     * @return repayment amount in currency tokens
     * @return proration based on elapsed duration
     */
    function _prorateRepayment(
        LoanReceipt.LoanReceiptV1 memory loanReceipt
    ) internal view returns (uint256 repayment, uint256 proration) {
        /* Minimum of proration and 1.0 */
        proration = Math.min(
            ((block.timestamp - (loanReceipt.maturity - loanReceipt.duration)) * LiquidityManager.FIXED_POINT_SCALE) /
                loanReceipt.duration,
            LiquidityManager.FIXED_POINT_SCALE
        );

        /* Compute repayment using prorated interest */
        repayment =
            loanReceipt.principal +
            (((loanReceipt.repayment - loanReceipt.principal) * proration) / LiquidityManager.FIXED_POINT_SCALE);
    }

    /**
     * @dev Helper function to handle borrow accounting
     * @param principal Principal amount in currency tokens
     * @param duration Duration in seconds
     * @param collateralToken Collateral token address
     * @param collateralTokenId Collateral token ID
     * @param maxRepayment Maximum repayment amount in currency tokens
     * @param ticks Liquidity node ticks
     * @param collateralWrapperContext Collateral wrapper context data
     * @param collateralFilterContext Collateral filter context data
     * @return Repayment amount in currency tokens, encoded loan receipt, loan
     * receipt hash
     */
    function _borrow(
        uint256 principal,
        uint64 duration,
        address collateralToken,
        uint256 collateralTokenId,
        uint256 maxRepayment,
        uint128[] calldata ticks,
        bytes memory collateralWrapperContext,
        bytes calldata collateralFilterContext
    ) internal returns (uint256, bytes memory, bytes32) {
        /* Validate duration is non-zero */
        if (duration == 0) revert UnsupportedLoanDuration();

        /* Get underlying collateral */
        (address underlyingCollateralToken, uint256[] memory underlyingCollateralTokenIds) = _getUnderlyingCollateral(
            collateralToken,
            collateralTokenId,
            collateralWrapperContext
        );

        /* Quote repayment and liquidity nodes */
        (uint256 repayment, ILiquidity.NodeSource[] memory nodes, uint16 count) = _quote(
            principal,
            duration,
            underlyingCollateralToken,
            underlyingCollateralTokenIds,
            ticks,
            collateralFilterContext
        );

        /* Validate repayment */
        if (repayment > maxRepayment) revert RepaymentTooHigh();

        /* Compute total fee */
        uint256 totalFee = repayment - principal;

        /* Compute admin fee */
        uint256 adminFee = (_adminFeeRate * totalFee) / BASIS_POINTS_SCALE;

        /* Distribute interest */
        uint128[] memory interest = _distribute(principal, totalFee - adminFee, nodes, count);

        /* Build the loan receipt */
        LoanReceipt.LoanReceiptV1 memory receipt = LoanReceipt.LoanReceiptV1({
            version: 1,
            principal: principal,
            repayment: repayment,
            borrower: msg.sender,
            maturity: uint64(block.timestamp + duration),
            duration: duration,
            collateralToken: collateralToken,
            collateralTokenId: collateralTokenId,
            collateralWrapperContextLen: collateralWrapperContext.length.toUint16(),
            collateralWrapperContext: collateralWrapperContext,
            nodeReceipts: new LoanReceipt.NodeReceipt[](count)
        });

        /* Use liquidity nodes */
        for (uint256 i; i < count; i++) {
            /* Compute pending */
            uint128 pending = nodes[i].used + interest[i];

            /* Use node */
            _liquidity.use(nodes[i].tick, nodes[i].used, pending);

            /* Construct node receipt */
            receipt.nodeReceipts[i] = LoanReceipt.NodeReceipt({
                tick: nodes[i].tick,
                used: nodes[i].used,
                pending: pending
            });
        }

        /* Encode and hash the loan receipt */
        bytes memory encodedLoanReceipt = receipt.encode();
        bytes32 loanReceiptHash = LoanReceipt.hash(encodedLoanReceipt);

        /* Validate no loan receipt hash collision */
        if (_loans[loanReceiptHash] != LoanStatus.Uninitialized) revert InvalidLoanReceipt();

        /* Store loan status */
        _loans[loanReceiptHash] = LoanStatus.Active;

        return (repayment, encodedLoanReceipt, loanReceiptHash);
    }

    /**
     * @dev Helper function to handle repay accounting
     * @param encodedLoanReceipt Encoded loan receipt
     * @return Repayment amount in currency tokens, decoded loan receipt, loan
     * receipt hash
     */
    function _repay(
        bytes calldata encodedLoanReceipt
    ) internal returns (uint256, LoanReceipt.LoanReceiptV1 memory, bytes32) {
        /* Compute loan receipt hash */
        bytes32 loanReceiptHash = LoanReceipt.hash(encodedLoanReceipt);

        /* Validate loan receipt */
        if (_loans[loanReceiptHash] != LoanStatus.Active) revert InvalidLoanReceipt();

        /* Decode loan receipt */
        LoanReceipt.LoanReceiptV1 memory loanReceipt = LoanReceipt.decode(encodedLoanReceipt);

        /* Validate borrow and repay is not in same block */
        if (loanReceipt.maturity - loanReceipt.duration == block.timestamp) revert InvalidLoanReceipt();

        /* Validate caller is borrower */
        if (msg.sender != loanReceipt.borrower) revert InvalidCaller();

        /* Compute proration and repayment using prorated interest */
        (uint256 repayment, uint256 proration) = _prorateRepayment(loanReceipt);

        /* Restore liquidity nodes */
        uint128 totalPending;
        for (uint256 i; i < loanReceipt.nodeReceipts.length; i++) {
            /* Restore node */
            _liquidity.restore(
                loanReceipt.nodeReceipts[i].tick,
                loanReceipt.nodeReceipts[i].used,
                loanReceipt.nodeReceipts[i].pending,
                loanReceipt.nodeReceipts[i].used +
                    uint128(
                        ((loanReceipt.nodeReceipts[i].pending - loanReceipt.nodeReceipts[i].used) * proration) /
                            LiquidityManager.FIXED_POINT_SCALE
                    )
            );

            /* Accumulate pending */
            totalPending += loanReceipt.nodeReceipts[i].pending;
        }

        /* Update admin fee total balance with prorated admin fee */
        _adminFeeBalance += ((loanReceipt.repayment - totalPending) * proration) / LiquidityManager.FIXED_POINT_SCALE;

        /* Mark loan status repaid */
        _loans[loanReceiptHash] = LoanStatus.Repaid;

        return (repayment, loanReceipt, loanReceiptHash);
    }

    /**
     * @dev Helper function to handle deposit accounting
     * @param tick Tick
     * @param amount Amount
     * @param minShares Minimum shares
     * @return Deposit shares
     */
    function _deposit(uint128 tick, uint128 amount, uint128 minShares) internal returns (uint128) {
        /* Validate tick */
        Tick.validate(tick, 0, 0, _durations.length - 1, 0, _rates.length - 1);

        /* Deposit into liquidity node */
        uint128 shares = _liquidity.deposit(tick, amount);

        /* Validate shares received is sufficient */
        if (shares == 0 || shares < minShares) revert InsufficientShares();

        /* Add to deposit */
        _deposits[msg.sender][tick].shares += shares;

        return shares;
    }

    /**
     * @dev Helper function to handle redeem accounting
     * @param tick Tick
     * @param shares Shares
     */
    function _redeem(uint128 tick, uint128 shares) internal {
        /* Look up Deposit */
        Deposit storage dep = _deposits[msg.sender][tick];

        /* Validate shares */
        if (shares == 0 || shares > dep.shares) revert InsufficientShares();

        /* Validate redemption isn't pending */
        if (dep.redemptionPending != 0) revert InvalidRedemptionStatus();

        /* Redeem shares in tick with liquidity manager */
        (uint128 redemptionIndex, uint128 redemptionTarget) = _liquidity.redeem(tick, shares);

        /* Update deposit state */
        dep.redemptionPending = shares;
        dep.redemptionIndex = redemptionIndex;
        dep.redemptionTarget = redemptionTarget;
    }

    /**
     * @dev Helper function to handle withdraw accounting
     * @param tick Tick
     * @return Withdrawn shares and withdrawn amount
     */
    function _withdraw(uint128 tick) internal returns (uint128, uint128) {
        /* Look up Deposit */
        Deposit storage dep = _deposits[msg.sender][tick];

        /* If no redemption is pending */
        if (dep.redemptionPending == 0) revert InvalidRedemptionStatus();

        /* Look up redemption available */
        (uint128 shares, uint128 amount) = _liquidity.redemptionAvailable(
            tick,
            dep.redemptionPending,
            dep.redemptionIndex,
            dep.redemptionTarget
        );

        /* If the entire redemption is ready */
        if (shares == dep.redemptionPending) {
            dep.redemptionPending = 0;
            dep.redemptionIndex = 0;
            dep.redemptionTarget = 0;
        } else {
            dep.redemptionPending -= shares;
            dep.redemptionTarget += shares;
        }

        /* Decrement deposit shares */
        dep.shares -= shares;

        return (shares, amount);
    }

    /**************************************************************************/
    /* Lend API */
    /**************************************************************************/

    /**
     * @inheritdoc IPool
     */
    function quote(
        uint256 principal,
        uint64 duration,
        address collateralToken,
        uint256[] calldata collateralTokenIds,
        uint128[] calldata ticks,
        bytes calldata options
    ) external view returns (uint256) {
        /* Quote repayment */
        (uint256 repayment, , ) = _quote(
            principal,
            duration,
            collateralToken,
            collateralTokenIds,
            ticks,
            _getOptionsData(options, uint16(BorrowOptions.CollateralFilterContext))
        );

        return repayment;
    }

    /**
     * @inheritdoc IPool
     */
    function quoteRefinance(
        bytes calldata encodedLoanReceipt,
        uint256 principal,
        uint64 duration,
        uint128[] calldata ticks
    ) external view returns (int256, uint256) {
        /* Decode loan receipt */
        LoanReceipt.LoanReceiptV1 memory loanReceipt = LoanReceipt.decode(encodedLoanReceipt);

        /* Get underlying collateral */
        (address underlyingCollateralToken, uint256[] memory underlyingCollateralTokenIds) = _getUnderlyingCollateral(
            loanReceipt.collateralToken,
            loanReceipt.collateralTokenId,
            loanReceipt.collateralWrapperContext
        );

        /* Quote repayment */
        (uint256 newRepayment, , ) = _quote(
            principal,
            duration,
            underlyingCollateralToken,
            underlyingCollateralTokenIds,
            ticks,
            encodedLoanReceipt[0:0]
        );

        /* Compute repayment using prorated interest */
        (uint256 proratedRepayment, ) = _prorateRepayment(loanReceipt);

        return (int256(proratedRepayment) - int256(principal), newRepayment);
    }

    /**
     * @inheritdoc IPool
     */
    function borrow(
        uint256 principal,
        uint64 duration,
        address collateralToken,
        uint256 collateralTokenId,
        uint256 maxRepayment,
        uint128[] calldata ticks,
        bytes calldata options
    ) external nonReentrant returns (uint256) {
        /* Handle borrow accounting */
        (uint256 repayment, bytes memory encodedLoanReceipt, bytes32 loanReceiptHash) = _borrow(
            principal,
            duration,
            collateralToken,
            collateralTokenId,
            maxRepayment,
            ticks,
            _getOptionsData(options, uint16(BorrowOptions.CollateralWrapperContext)),
            _getOptionsData(options, uint16(BorrowOptions.CollateralFilterContext))
        );

        /* Handle delegate.cash option */
        _optionDelegateCash(collateralToken, collateralTokenId, options);

        /* Transfer collateral from borrower to pool */
        IERC721(collateralToken).transferFrom(msg.sender, address(this), collateralTokenId);

        /* Transfer principal from pool to borrower */
        _currencyToken.safeTransfer(msg.sender, principal);

        /* Emit LoanOriginated */
        emit LoanOriginated(loanReceiptHash, encodedLoanReceipt);

        return repayment;
    }

    /**
     * @inheritdoc IPool
     */
    function repay(bytes calldata encodedLoanReceipt) external nonReentrant returns (uint256) {
        /* Handle repay accounting */
        (uint256 repayment, LoanReceipt.LoanReceiptV1 memory loanReceipt, bytes32 loanReceiptHash) = _repay(
            encodedLoanReceipt
        );

        /* Revoke delegates */
        _revokeDelegates(loanReceipt.collateralToken, loanReceipt.collateralTokenId);

        /* Transfer repayment from borrower to pool */
        _currencyToken.safeTransferFrom(loanReceipt.borrower, address(this), repayment);

        /* Transfer collateral from pool to borrower */
        IERC721(loanReceipt.collateralToken).transferFrom(
            address(this),
            loanReceipt.borrower,
            loanReceipt.collateralTokenId
        );

        /* Emit Loan Repaid */
        emit LoanRepaid(loanReceiptHash, repayment);

        return repayment;
    }

    /**
     * @inheritdoc IPool
     */
    function refinance(
        bytes calldata encodedLoanReceipt,
        uint256 principal,
        uint64 duration,
        uint256 maxRepayment,
        uint128[] calldata ticks
    ) external nonReentrant returns (uint256) {
        /* Handle repay accounting */
        (uint256 repayment, LoanReceipt.LoanReceiptV1 memory loanReceipt, bytes32 loanReceiptHash) = _repay(
            encodedLoanReceipt
        );

        /* Handle borrow accounting */
        (uint256 newRepayment, bytes memory newEncodedLoanReceipt, bytes32 newLoanReceiptHash) = _borrow(
            principal,
            duration,
            loanReceipt.collateralToken,
            loanReceipt.collateralTokenId,
            maxRepayment,
            ticks,
            loanReceipt.collateralWrapperContext,
            encodedLoanReceipt[0:0]
        );

        /* Determine transfer direction */
        if (principal < repayment) {
            /* Transfer prorated repayment less principal from borrower to pool */
            _currencyToken.safeTransferFrom(loanReceipt.borrower, address(this), repayment - principal);
        } else {
            /* Transfer principal less prorated repayment from pool to borrower */
            _currencyToken.safeTransfer(msg.sender, principal - repayment);
        }

        /* Emit Loan Repaid */
        emit LoanRepaid(loanReceiptHash, repayment);

        /* Emit LoanOriginated */
        emit LoanOriginated(newLoanReceiptHash, newEncodedLoanReceipt);

        return newRepayment;
    }

    /**
     * @inheritdoc IPool
     */
    function liquidate(bytes calldata encodedLoanReceipt) external nonReentrant {
        /* Compute loan receipt hash */
        bytes32 loanReceiptHash = LoanReceipt.hash(encodedLoanReceipt);

        /* Validate loan status is active */
        if (_loans[loanReceiptHash] != LoanStatus.Active) revert InvalidLoanReceipt();

        /* Decode loan receipt */
        LoanReceipt.LoanReceiptV1 memory loanReceipt = LoanReceipt.decode(encodedLoanReceipt);

        /* Validate loan is expired */
        if (block.timestamp <= loanReceipt.maturity) revert LoanNotExpired();

        /* Approve collateral for transfer to _collateralLiquidator */
        IERC721(loanReceipt.collateralToken).approve(address(_collateralLiquidator), loanReceipt.collateralTokenId);

        /* Mark loan status liquidated */
        _loans[loanReceiptHash] = LoanStatus.Liquidated;

        /* Revoke delegates */
        _revokeDelegates(loanReceipt.collateralToken, loanReceipt.collateralTokenId);

        /* Start liquidation with collateral liquidator */
        _collateralLiquidator.liquidate(
            address(_currencyToken),
            loanReceipt.collateralToken,
            loanReceipt.collateralTokenId,
            loanReceipt.collateralWrapperContext,
            encodedLoanReceipt
        );

        /* Emit Loan Liquidated */
        emit LoanLiquidated(loanReceiptHash);
    }

    /**************************************************************************/
    /* Callbacks */
    /**************************************************************************/

    /**
     * @inheritdoc ICollateralLiquidationReceiver
     */
    function onCollateralLiquidated(bytes calldata encodedLoanReceipt, uint256 proceeds) external nonReentrant {
        /* Validate caller is collateral liquidator */
        if (msg.sender != address(_collateralLiquidator)) revert InvalidCaller();

        /* Compute loan receipt hash */
        bytes32 loanReceiptHash = LoanReceipt.hash(encodedLoanReceipt);

        /* Validate loan status is liquidated */
        if (_loans[loanReceiptHash] != LoanStatus.Liquidated) revert InvalidLoanReceipt();

        /* Decode loan receipt */
        LoanReceipt.LoanReceiptV1 memory loanReceipt = LoanReceipt.decode(encodedLoanReceipt);

        /* Compute borrower's share of liquidation surplus */
        uint256 borrowerSurplus = proceeds > loanReceipt.repayment
            ? Math.mulDiv(proceeds - loanReceipt.repayment, BORROWER_SURPLUS_SPLIT_BASIS_POINTS, BASIS_POINTS_SCALE)
            : 0;

        /* Compute remaining proceeds */
        uint128 proceedsRemaining = (proceeds - borrowerSurplus).toUint128();

        /* Restore liquidity nodes */
        for (uint256 i; i < loanReceipt.nodeReceipts.length; i++) {
            /* Restore node */
            uint128 restored = (i == loanReceipt.nodeReceipts.length - 1)
                ? proceedsRemaining
                : uint128(Math.min(loanReceipt.nodeReceipts[i].pending, proceedsRemaining));
            _liquidity.restore(
                loanReceipt.nodeReceipts[i].tick,
                loanReceipt.nodeReceipts[i].used,
                loanReceipt.nodeReceipts[i].pending,
                restored
            );

            /* Update proceeds remaining */
            proceedsRemaining -= restored;
        }

        /* Mark loan status collateral liquidated */
        _loans[loanReceiptHash] = LoanStatus.CollateralLiquidated;

        /* Transfer surplus to borrower */
        if (borrowerSurplus != 0) IERC20(_currencyToken).safeTransfer(loanReceipt.borrower, borrowerSurplus);

        /* Emit Collateral Liquidated */
        emit CollateralLiquidated(loanReceiptHash, proceeds, borrowerSurplus);
    }

    /**************************************************************************/
    /* Deposit API */
    /**************************************************************************/

    /**
     * @inheritdoc IPool
     */
    function deposit(uint128 tick, uint256 amount, uint256 minShares) external nonReentrant returns (uint256) {
        /* Handle deposit accounting and compute shares */
        uint128 shares = _deposit(tick, amount.toUint128(), minShares.toUint128());

        /* Transfer deposit amount */
        _currencyToken.safeTransferFrom(msg.sender, address(this), amount);

        /* Emit Deposited */
        emit Deposited(msg.sender, tick, amount, shares);

        return shares;
    }

    /**
     * @inheritdoc IPool
     */
    function redeem(uint128 tick, uint256 shares) external nonReentrant {
        /* Handle redeem accounting */
        _redeem(tick, shares.toUint128());

        /* Emit Redeemed event */
        emit Redeemed(msg.sender, tick, shares);
    }

    /**
     * @inheritdoc IPool
     */
    function redemptionAvailable(address account, uint128 tick) external view returns (uint256 shares, uint256 amount) {
        /* Look up Deposit */
        Deposit storage dep = _deposits[account][tick];

        /* If no redemption is pending */
        if (dep.redemptionPending == 0) return (0, 0);

        return _liquidity.redemptionAvailable(tick, dep.redemptionPending, dep.redemptionIndex, dep.redemptionTarget);
    }

    /**
     * @inheritdoc IPool
     */
    function withdraw(uint128 tick) external nonReentrant returns (uint256, uint256) {
        /* Handle withdraw accounting and compute both shares and amount */
        (uint128 shares, uint128 amount) = _withdraw(tick);

        /* Transfer withdrawal amount */
        _currencyToken.safeTransfer(msg.sender, amount);

        /* Emit Withdrawn */
        emit Withdrawn(msg.sender, tick, shares, amount);

        return (shares, amount);
    }

    /**
     * @inheritdoc IPool
     */
    function rebalance(
        uint128 srcTick,
        uint128 dstTick,
        uint256 minShares
    ) external nonReentrant returns (uint256, uint256, uint256) {
        /* Handle withdraw accounting and compute both shares and amount */
        (uint128 oldShares, uint128 amount) = _withdraw(srcTick);

        /* Handle deposit accounting and compute new shares */
        uint128 newShares = _deposit(dstTick, amount, minShares.toUint128());

        /* Emit Withdrawn */
        emit Withdrawn(msg.sender, srcTick, oldShares, amount);
        /* Emit Deposited */
        emit Deposited(msg.sender, dstTick, amount, newShares);

        return (oldShares, newShares, amount);
    }

    /**************************************************************************/
    /* Admin Fees API */
    /**************************************************************************/

    /**
     * @notice Set the admin fee rate
     *
     * Emits a {AdminFeeRateUpdated} event.
     *
     * @param rate Rate is the admin fee in basis points
     */
    function setAdminFeeRate(uint32 rate) external {
        if (msg.sender != _admin) revert InvalidCaller();
        if (rate == 0 || rate >= BASIS_POINTS_SCALE) revert ParameterOutOfBounds();
        _adminFeeRate = rate;
        emit AdminFeeRateUpdated(rate);
    }

    /**
     * @notice Withdraw admin fees
     *
     * Emits a {AdminFeesWithdrawn} event.
     *
     * @param recipient Recipient account
     * @param amount Amount to withdraw
     */
    function withdrawAdminFees(address recipient, uint256 amount) external nonReentrant {
        if (msg.sender != _admin) revert InvalidCaller();
        if (recipient == address(0)) revert InvalidAddress();
        if (amount > _adminFeeBalance) revert ParameterOutOfBounds();

        /* Update admin fees balance */
        _adminFeeBalance -= amount;

        /* Transfer cash from Pool to recipient */
        _currencyToken.safeTransfer(recipient, amount);

        emit AdminFeesWithdrawn(recipient, amount);
    }

    /******************************************************/
    /* ERC165 interface */
    /******************************************************/

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ICollateralLiquidationReceiver).interfaceId || super.supportsInterface(interfaceId);
    }
}