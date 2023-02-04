// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "solmate/src/tokens/ERC20.sol";
import "solmate/src/tokens/WETH.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./internal/interfaces/NotionalProxy.sol";
import "./internal/interfaces/IStrategyVault.sol";
import "./internal/interfaces/ITradingModule.sol";
import "./internal/Types.sol";
import "./internal/Constants.sol";

import "../../libraries/DataTypes.sol";
import "../../libraries/ErrorLib.sol";
import "../../libraries/ProxyLib.sol";
import "../../utils/Balanceless.sol";

import "./NotionalUtils.sol";

// solhint-disable not-rely-on-time, var-name-mixedcase
contract ContangoVault is IStrategyVault, AccessControlUpgradeable, UUPSUpgradeable, Balanceless {
    using NotionalUtils for uint256;
    using ProxyLib for PositionId;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    error CanNotSettleBeforeMaturity();
    error InsufficientBorrowedAmount(uint256 expected, uint256 borrowed);
    error InsufficientWithdrawAmount(uint256 expected, uint256 borrowed);
    error InvalidContangoProxy(address expected, address actual);
    error OnlyContango();
    error OnlyNotional();
    error OnlyVault();
    error Unsupported();

    struct EnterParams {
        // Contango position Id for proxy validation
        PositionId positionId;
        // Amount of underlying lending token to lend
        uint256 lendAmount;
        // Amount of lent fCash to be received from lending lendAmount
        uint256 fCashLendAmount;
        // Amount of underlying borrowing token to send to the receiver
        uint256 borrowAmount;
        // Address paying for the lending position
        address payer;
        // Address receiving the borrowed underlying
        address receiver;
    }

    struct ExitParams {
        // Contango position Id for proxy validation
        PositionId positionId;
        // Amount of underlying lending token to send to the receiver
        uint256 withdrawAmount;
        // Address paying for the borrowing unwind
        address payer;
        // Address receiving the lending unwind
        address receiver;
    }

    struct SettleParams {
        // Address paying for the borrowing unwind
        address payer;
        // Address receiving the lending unwind
        address receiver;
        // Amount of underlying borrowing token to pay back on post maturity redeem
        uint256 repaymentAmount;
        // Amount of underlying lending token to send to the receiver
        uint256 withdrawAmount;
    }

    uint8 private constant INTERNAL_TOKEN_DECIMALS = 8;

    /// @notice Hardcoded on the implementation contract during deployment
    NotionalProxy public immutable notional;
    ITradingModule public immutable tradingModule;
    address public immutable contango;
    bytes32 public immutable contangoProxyHash;

    // TODO alfredo - evaluate using storage to facilitate upgrades

    // Borrow Currency ID the vault is configured with
    uint16 public immutable borrowCurrencyId;
    // True if borrow the underlying is ETH
    bool public immutable borrowUnderlyingIsEth;
    // Address of the borrow underlying token
    ERC20 public immutable borrowUnderlyingToken;
    // Borrow underlying token precision, e.g. 1e18
    uint256 public immutable borrowTokenPrecision;

    // Lend Currency ID the vault is configured with
    uint16 public immutable lendCurrencyId;
    // True if the lend underlying is ETH
    bool public immutable lendUnderlyingIsEth;
    // Address of the lend underlying token
    ERC20 public immutable lendUnderlyingToken;
    // Lend underlying token precision, e.g. 1e18
    uint256 public immutable lendTokenPrecision;

    // Name of the vault (cannot make string immutable)
    string public name;

    constructor(
        NotionalProxy _notional,
        ITradingModule _tradingModule,
        address _contango,
        bytes32 _contangoProxyHash,
        string memory _name,
        address _weth,
        uint16 _lendCurrencyId,
        uint16 _borrowCurrencyId
    ) {
        notional = _notional;
        tradingModule = _tradingModule;
        contango = _contango;
        contangoProxyHash = _contangoProxyHash;
        name = _name;

        (borrowCurrencyId, borrowUnderlyingIsEth, borrowUnderlyingToken, borrowTokenPrecision) =
            _currencyIdConfiguration(_borrowCurrencyId, _weth);
        (lendCurrencyId, lendUnderlyingIsEth, lendUnderlyingToken, lendTokenPrecision) =
            _currencyIdConfiguration(_lendCurrencyId, _weth);
    }

    function initialize() external initializer {
        __AccessControl_init_unchained();
        __UUPSUpgradeable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Allow Notional to pull the lend underlying currency
        lendUnderlyingToken.approve(address(notional), type(uint256).max);
    }

    // ============================================== IStrategyVault functions ==============================================

    /// @notice All strategy vaults MUST implement 8 decimal precision
    function decimals() public pure override returns (uint8) {
        return INTERNAL_TOKEN_DECIMALS;
    }

    function strategy() external pure override returns (bytes4) {
        return bytes4(keccak256("ContangoVault"));
    }

    /// @notice Converts the amount of fCash the vault holds into underlying denomination for the borrow currency.
    /// @param strategyTokens each strategy token is equivalent to 1 unit of fCash
    /// @param maturity the maturity of the fCash
    /// @return underlyingValue the value of the lent fCash in terms of the borrowed currency
    function convertStrategyToUnderlying(
        address, // account
        uint256 strategyTokens,
        uint256 maturity
    ) public view override returns (int256 underlyingValue) {
        int256 pvInternal;
        if (maturity <= block.timestamp) {
            // After maturity, strategy tokens no longer have a present value
            pvInternal = strategyTokens.toInt256();
        } else {
            // This is the non-risk adjusted oracle price for fCash, present value is used in case
            // liquidation is required. The liquidator may need to exit the fCash position in order
            // to repay a flash loan.
            pvInternal = notional.getPresentfCashValue(
                lendCurrencyId, maturity, strategyTokens.toInt256(), block.timestamp, false
            );
        }

        (int256 rate, int256 rateDecimals) =
            tradingModule.getOraclePrice(address(lendUnderlyingToken), address(borrowUnderlyingToken));

        // Convert this back to the borrow currency, external precision
        // (pv (8 decimals) * borrowTokenPrecision * rate) / (rateDecimals * 8 decimals)
        underlyingValue = (pvInternal * int256(borrowTokenPrecision) * rate)
            / (rateDecimals * int256(Constants.INTERNAL_TOKEN_PRECISION));
    }

    // TODO alfredo - natspec
    function depositFromNotional(
        address account,
        uint256 depositUnderlyingExternal,
        uint256 maturity,
        bytes calldata data
    ) external payable override onlyNotional returns (uint256 lentFCashAmount) {
        if (maturity <= block.timestamp) {
            revert NotImplemented("deposit after maturity");
        }

        // 4. Take lending underlying from the payer and lend to get fCash
        EnterParams memory params = abi.decode(data, (EnterParams));

        if (depositUnderlyingExternal < params.borrowAmount) {
            revert InsufficientBorrowedAmount(params.borrowAmount, depositUnderlyingExternal);
        }

        // TODO alfredo - the assumption is that the account is guaranteed to be the msg.sender that called notional initially
        _validateAccount(params.positionId, account);

        if (params.lendAmount > 0) {
            lendUnderlyingToken.safeTransferFrom(params.payer, address(this), params.lendAmount);
            if (lendUnderlyingIsEth) {
                WETH(payable(address(lendUnderlyingToken))).withdraw(params.lendAmount);
            }

            // should only have one portfolio for the lending currency (or none if first time entering)
            // and balance always positive since it's always lending
            (,, PortfolioAsset[] memory portfolio) = notional.getAccount(address(this));
            int256 balanceBefore = portfolio.length == 0 ? int256(0) : portfolio[0].notional;

            // Now we lend the underlying amount
            BalanceActionWithTrades[] memory lendAction = new BalanceActionWithTrades[](1);
            lendAction[0] = NotionalUtils.encodeOpenLendAction({
                currencyId: lendCurrencyId,
                marketIndex: notional.getMarketIndex(maturity, block.timestamp),
                depositActionAmount: params.lendAmount,
                fCashLendAmount: params.fCashLendAmount.toUint88()
            });
            uint256 sendValue = lendUnderlyingIsEth ? params.lendAmount : 0;
            notional.batchBalanceAndTradeAction{value: sendValue}(address(this), lendAction);

            (,, portfolio) = notional.getAccount(address(this));
            lentFCashAmount = uint256(portfolio[0].notional - balanceBefore);
        }

        // 5. Transfer borrowed underlying to the receiver
        if (borrowUnderlyingIsEth) {
            WETH(payable(address(borrowUnderlyingToken))).deposit{value: params.borrowAmount}();
        }
        borrowUnderlyingToken.safeTransfer(params.receiver, params.borrowAmount);
    }

    // TODO alfredo - natspec
    function redeemFromNotional(
        address account,
        address, // receiver,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external override onlyNotional returns (uint256 transferToReceiver) {
        if (maturity > block.timestamp) {
            _redeemBeforeMaturity(account, strategyTokens, maturity, underlyingToRepayDebt, data);
        } else {
            _redeemAfterMaturity(account, strategyTokens, data);
        }

        // this is always 0 since we already transfer what we can/need on the steps above
        transferToReceiver = 0;
    }

    function _redeemBeforeMaturity(
        address account,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) private {
        ExitParams memory params = abi.decode(data, (ExitParams));

        // TODO alfredo - the assumption is that the account is guaranteed to be the msg.sender that called notional initially
        _validateAccount(params.positionId, account);

        // 4. Take borrowing underlying from the payer to pay for exiting the borrowing position
        if (!borrowUnderlyingIsEth) {
            borrowUnderlyingToken.safeTransferFrom(params.payer, address(notional), underlyingToRepayDebt);
        }

        if (strategyTokens > 0) {
            // 5. Borrow lending fCash to close lending position
            uint256 balanceBefore =
                lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));

            BalanceActionWithTrades[] memory closeLendingAction = new BalanceActionWithTrades[](1);
            closeLendingAction[0] = NotionalUtils.encodeCloseLendAction({
                currencyId: lendCurrencyId,
                marketIndex: notional.getMarketIndex(maturity, block.timestamp),
                fCashAmount: strategyTokens.toUint88()
            });
            notional.batchBalanceAndTradeAction(address(this), closeLendingAction);

            uint256 balanceAfter =
                lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));
            uint256 availableBalance = balanceAfter - balanceBefore;

            if (params.withdrawAmount > availableBalance) {
                revert InsufficientWithdrawAmount(params.withdrawAmount, availableBalance);
            }

            // 6. Transfer remaining lending underlying to the receiver
            if (lendUnderlyingIsEth) {
                WETH(payable(address(lendUnderlyingToken))).deposit{value: params.withdrawAmount}();
            }
            lendUnderlyingToken.safeTransfer(params.receiver, params.withdrawAmount);
        }
    }

    function _redeemAfterMaturity(address account, uint256 strategyTokens, bytes calldata data) private {
        // only vault can settle after maturity
        if (account != address(this)) {
            revert OnlyVault();
        }

        SettleParams memory params = abi.decode(data, (SettleParams));

        // take borrowing underlying from the payer to pay for exiting the full borrowing position
        if (borrowUnderlyingIsEth) {
            payable(address(notional)).safeTransferETH(params.repaymentAmount);
        } else {
            borrowUnderlyingToken.safeTransferFrom(params.payer, address(notional), params.repaymentAmount);
        }

        uint256 balanceBefore =
            lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));

        // withdraw proportional lending fCash to underlying
        (,,, AssetRateParameters memory ar) = notional.getCurrencyAndRates(lendCurrencyId);
        int256 withdrawAmount = strategyTokens.fromNotionalPrecision(lendTokenPrecision, false).toInt256();
        int256 ratePrecision = int256(10 ** ar.rateOracle.decimals());
        int256 withdrawAmountInternal = ((withdrawAmount * ratePrecision) / ar.rate) + 1; // buffer

        BalanceAction[] memory withdrawAction = new BalanceAction[](1);
        withdrawAction[0] = NotionalUtils.encodeWithdrawAction({
            currencyId: lendCurrencyId,
            withdrawAmountInternal: uint256(withdrawAmountInternal)
        });
        notional.batchBalanceAction(address(this), withdrawAction);

        uint256 balanceAfter =
            lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));
        uint256 availableBalance = balanceAfter - balanceBefore;

        if (params.withdrawAmount > availableBalance) {
            revert InsufficientWithdrawAmount(params.withdrawAmount, availableBalance);
        }

        // transfer received funds
        if (lendUnderlyingIsEth) {
            WETH(payable(address(lendUnderlyingToken))).deposit{value: params.withdrawAmount}();
        }
        lendUnderlyingToken.safeTransfer(params.receiver, params.withdrawAmount);
    }

    // TODO alfredo - natspec
    function settleAccount(address account, uint256 maturity, bytes calldata data) external payable onlyContango {
        if (maturity > block.timestamp) {
            revert CanNotSettleBeforeMaturity();
        }

        notional.redeemStrategyTokensToCash({
            maturity: maturity,
            strategyTokensToRedeem: notional.getVaultAccount(account, address(this)).vaultShares,
            vaultData: data
        });

        // If there are no more strategy tokens left, meaning all positions were delivered, then clean and fully settle the vault with Notional
        if (notional.getVaultState(address(this), maturity).totalStrategyTokens == 0) {
            // currency ids in ascending order
            (uint16 currencyId1, uint16 currencyId2) = borrowCurrencyId < lendCurrencyId
                ? (borrowCurrencyId, lendCurrencyId)
                : (lendCurrencyId, borrowCurrencyId);

            // withdraws any remaining balance (dust) on Notional
            BalanceAction[] memory withdrawalsAction = new BalanceAction[](2);
            withdrawalsAction[0] = NotionalUtils.encodeWithdrawAllAction(currencyId1);
            withdrawalsAction[1] = NotionalUtils.encodeWithdrawAllAction(currencyId2);
            notional.batchBalanceAction(address(this), withdrawalsAction);

            // fully settle vault
            notional.settleVault(address(this), maturity);
        }
    }

    function repaySecondaryBorrowCallback(
        address, // token,
        uint256, // underlyingRequired,
        bytes calldata // data
    ) external pure override returns (bytes memory) {
        revert Unsupported();
    }

    // ============================================== Admin functions ==============================================

    function collectBalance(address token, address payable to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _collectBalance(token, to, amount);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @notice reverts on fallback for informational purposes
    fallback() external payable {
        revert FunctionNotFound(msg.sig);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        // Allow ETH transfers to succeed
    }

    // ============================================== Private functions ==============================================

    function _currencyIdConfiguration(uint16 currencyId, address weth)
        private
        view
        returns (uint16 currencyId_, bool underlyingIsEth_, ERC20 underlyingToken_, uint256 tokenPrecision_)
    {
        currencyId_ = currencyId;
        address underlying = _getNotionalUnderlyingToken(currencyId);
        underlyingIsEth_ = underlying == address(0);
        underlyingToken_ = ERC20(underlyingIsEth_ ? weth : underlying);
        tokenPrecision_ = 10 ** underlyingToken_.decimals();
    }

    function _getNotionalUnderlyingToken(uint16 currencyId) private view returns (address) {
        (Token memory assetToken, Token memory underlyingToken) = notional.getCurrency(currencyId);

        return assetToken.tokenType == TokenType.NonMintable ? assetToken.tokenAddress : underlyingToken.tokenAddress;
    }

    function _validateAccount(PositionId positionId, address proxy) private view {
        address expectedProxy = positionId.computeProxyAddress(contango, contangoProxyHash);

        if (proxy != expectedProxy) {
            revert InvalidContangoProxy(expectedProxy, proxy);
        }
    }

    modifier onlyContango() {
        if (msg.sender != contango) {
            revert OnlyContango();
        }
        _;
    }

    modifier onlyNotional() {
        if (msg.sender != address(notional)) {
            revert OnlyNotional();
        }
        _;
    }
}