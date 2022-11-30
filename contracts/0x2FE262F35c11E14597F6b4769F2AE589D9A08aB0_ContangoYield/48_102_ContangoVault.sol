// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {NotionalProxy} from "./internal/interfaces/NotionalProxy.sol";
import {IStrategyVault} from "./internal/interfaces/IStrategyVault.sol";
import {ITradingModule} from "./internal/interfaces/ITradingModule.sol";
import {
    BalanceActionWithTrades,
    DepositActionType,
    PortfolioAsset,
    TradeActionType,
    Token,
    TokenType
} from "./internal/Types.sol";
import {Constants} from "./internal/Constants.sol";

import {IWETH9} from "../../dependencies/IWETH9.sol";
import {PositionId} from "../../libraries/DataTypes.sol";
import {NotImplemented, FunctionNotFound} from "../../libraries/ErrorLib.sol";
import {ProxyLib} from "../../libraries/ProxyLib.sol";
import {Balanceless} from "../../utils/Balanceless.sol";

// solhint-disable not-rely-on-time, var-name-mixedcase
contract ContangoVault is IStrategyVault, AccessControlUpgradeable, UUPSUpgradeable, Balanceless {
    using ProxyLib for PositionId;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    error InsufficientBorrowedAmount(uint256 expected, uint256 borrowed);
    error InsufficientWithdrawAmount(uint256 expected, uint256 borrowed);
    error InvalidContangoProxy(address expected, address actual);
    error NotNotional();
    error OnlyOwner();
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

    uint8 private constant INTERNAL_TOKEN_DECIMALS = 8;

    /// @notice Hardcoded on the implementation contract during deployment
    NotionalProxy public immutable notional;
    ITradingModule public immutable tradingModule;
    address public immutable contangoNotional;
    bytes32 public immutable contangoProxyHash;
    address public immutable owner;

    // TODO alfredo - evaluate using storage to facilitate upgrades

    // Borrow Currency ID the vault is configured with
    uint16 public immutable borrowCurrencyId;
    // True if borrow the underlying is ETH
    bool public immutable borrowUnderlyingIsEth;
    // Address of the borrow underlying token
    IERC20 public immutable borrowUnderlyingToken;

    // Lend Currency ID the vault is configured with
    uint16 public immutable lendCurrencyId;
    // True if the lend underlying is ETH
    bool public immutable lendUnderlyingIsEth;
    // Address of the lend underlying token
    IERC20 public immutable lendUnderlyingToken;

    // Name of the vault (cannot make string immutable)
    string public name;

    constructor(
        NotionalProxy _notional,
        ITradingModule _tradingModule,
        address _contangoNotional,
        bytes32 _contangoProxyHash,
        string memory _name,
        address _weth,
        uint16 _lendCurrencyId,
        uint16 _borrowCurrencyId
    ) {
        notional = _notional;
        tradingModule = _tradingModule;
        contangoNotional = _contangoNotional;
        contangoProxyHash = _contangoProxyHash;
        owner = msg.sender;
        name = _name;

        (borrowCurrencyId, borrowUnderlyingIsEth, borrowUnderlyingToken) =
            _currencyIdConfiguration(_borrowCurrencyId, _weth);
        (lendCurrencyId, lendUnderlyingIsEth, lendUnderlyingToken) = _currencyIdConfiguration(_lendCurrencyId, _weth);
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
        // TODO alfredo - store decimals
        int256 borrowTokenDecimals = int256(10 ** IERC20Metadata(address(borrowUnderlyingToken)).decimals());

        // Convert this back to the borrow currency, external precision
        // (pv (8 decimals) * borrowTokenDecimals * rate) / (rateDecimals * 8 decimals)
        underlyingValue =
            (pvInternal * borrowTokenDecimals * rate) / (rateDecimals * int256(Constants.INTERNAL_TOKEN_PRECISION));
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
                IWETH9(address(lendUnderlyingToken)).withdraw(params.lendAmount);
            }

            // should only have one portfolio for the lending currency (or none if first time entering)
            // and balance always positive since it's always lending
            (,, PortfolioAsset[] memory portfolio) = notional.getAccount(address(this));
            int256 balanceBefore = portfolio.length == 0 ? int256(0) : portfolio[0].notional;

            // Now we lend the underlying amount
            uint256 marketIndex = notional.getMarketIndex(maturity, block.timestamp);
            BalanceActionWithTrades[] memory lendAction = new BalanceActionWithTrades[](1);
            lendAction[0].currencyId = lendCurrencyId;
            lendAction[0].actionType = DepositActionType.DepositUnderlying;
            lendAction[0].depositActionAmount = params.lendAmount;
            lendAction[0].trades = new bytes32[](1);
            lendAction[0].trades[0] = bytes32(
                abi.encodePacked(uint8(TradeActionType.Lend), uint8(marketIndex), uint88(params.fCashLendAmount))
            );
            uint256 sendValue = lendUnderlyingIsEth ? params.lendAmount : 0;
            notional.batchBalanceAndTradeAction{value: sendValue}(address(this), lendAction);

            (,, portfolio) = notional.getAccount(address(this));
            lentFCashAmount = uint256(portfolio[0].notional - balanceBefore);
        }

        // 5. Transfer borrowed underlying to the receiver
        if (borrowUnderlyingIsEth) {
            IWETH9(address(borrowUnderlyingToken)).deposit{value: params.borrowAmount}();
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
        if (maturity <= block.timestamp) {
            revert NotImplemented("redeem after maturity");
        }

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

            uint256 marketIndex = notional.getMarketIndex(maturity, block.timestamp);
            BalanceActionWithTrades[] memory borrowAction = new BalanceActionWithTrades[](1);
            borrowAction[0].currencyId = lendCurrencyId;
            borrowAction[0].actionType = DepositActionType.None;
            borrowAction[0].withdrawEntireCashBalance = true;
            borrowAction[0].redeemToUnderlying = true;
            borrowAction[0].trades = new bytes32[](1);
            borrowAction[0].trades[0] =
                bytes32(abi.encodePacked(uint8(TradeActionType.Borrow), uint8(marketIndex), uint88(strategyTokens)));
            notional.batchBalanceAndTradeAction(address(this), borrowAction);

            uint256 balanceAfter =
                lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));
            uint256 availableBalance = balanceAfter - balanceBefore;

            if (params.withdrawAmount > availableBalance) {
                revert InsufficientWithdrawAmount(params.withdrawAmount, availableBalance);
            }

            // 6. Transfer remaining lending underlying to the receiver
            if (lendUnderlyingIsEth) {
                IWETH9(address(lendUnderlyingToken)).deposit{value: params.withdrawAmount}();
            }
            lendUnderlyingToken.transfer(params.receiver, params.withdrawAmount);
        }

        // this is always 0 since we already transfer what we can/need on the step above
        transferToReceiver = 0;
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
        returns (uint16 currencyId_, bool underlyingIsEth_, IERC20 underlyingToken_)
    {
        currencyId_ = currencyId;
        address underlying = _getNotionalUnderlyingToken(currencyId);
        underlyingIsEth_ = underlying == address(0);
        underlyingToken_ = IERC20(underlyingIsEth_ ? weth : underlying);
    }

    function _getNotionalUnderlyingToken(uint16 currencyId) private view returns (address) {
        (Token memory assetToken, Token memory underlyingToken) = notional.getCurrency(currencyId);

        return assetToken.tokenType == TokenType.NonMintable ? assetToken.tokenAddress : underlyingToken.tokenAddress;
    }

    function _validateAccount(PositionId positionId, address proxy) private view {
        address expectedProxy = positionId.computeProxyAddress(contangoNotional, contangoProxyHash);

        if (proxy != expectedProxy) {
            revert InvalidContangoProxy(expectedProxy, proxy);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    modifier onlyNotional() {
        if (msg.sender != address(notional)) {
            revert NotNotional();
        }
        _;
    }
}