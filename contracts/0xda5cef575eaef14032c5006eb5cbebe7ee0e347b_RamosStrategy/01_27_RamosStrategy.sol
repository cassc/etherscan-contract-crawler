pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (v2/strategies/RamosStrategy.sol)

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IRamos } from "contracts/interfaces/amo/IRamos.sol";
import { IBalancerVault } from "contracts/interfaces/external/balancer/IBalancerVault.sol";
import { IRamosTokenVault } from "contracts/interfaces/amo/helpers/IRamosTokenVault.sol";
import { IRamosTokenVault } from "contracts/interfaces/amo/helpers/IRamosTokenVault.sol";
import { AbstractStrategy } from "contracts/v2/strategies/AbstractStrategy.sol";
import { ITempleERC20Token } from "contracts/interfaces/core/ITempleERC20Token.sol";
import { ITempleCircuitBreakerProxy } from "contracts/interfaces/v2/circuitBreaker/ITempleCircuitBreakerProxy.sol";

/**
 * @title Ramos Strategy
 * @notice Executors can add/remove proportional liquidity into Ramos via the strategy
 * It also serves as the 'token vault' - Ramos will call into this strategy
 * to obtain Temple and QuoteToken (eg DAI)
 */
contract RamosStrategy  is AbstractStrategy, IRamosTokenVault {
    using SafeERC20 for IERC20;
    using SafeERC20 for ITempleERC20Token;
    
    string private constant VERSION = "1.0.1";

    /**
     * @notice The RAMOS contract used to manage the TPI
     */
    IRamos public immutable ramos;

    /**
     * @notice The Temple token, one side of the Balancer LP used by Ramos
     */
    ITempleERC20Token public immutable templeToken;

    /**
     * @notice The Quote token - eg DAI, one side of the Balancer LP used by Ramos
     */
    IERC20 public immutable quoteToken;

    /**
     * @notice New withdrawals of tokens from TRV are checked against a circuit breaker
     * to ensure no more than a cap is withdrawn in a given period
     */
    ITempleCircuitBreakerProxy public immutable circuitBreakerProxy;

    event AddLiquidity(uint256 quoteTokenAmount, uint256 protocolTokenAmount, uint256 bptTokensStaked);
    event RemoveLiquidity(uint256 quoteTokenAmount, uint256 protocolTokenAmount, uint256 bptIn);
    event BorrowToken(address indexed token, uint256 amount);
    event RepayToken(address indexed token, uint256 amount);

    constructor(
        address _initialRescuer,
        address _initialExecutor,
        string memory _strategyName,
        address _treasuryReservesVault,
        address _ramos,
        address _templeToken,
        address _quoteToken,
        address _circuitBreakerProxy
    ) AbstractStrategy(_initialRescuer, _initialExecutor, _strategyName, _treasuryReservesVault) {
        ramos = IRamos(_ramos);
        templeToken = ITempleERC20Token(_templeToken);
        quoteToken = IERC20(_quoteToken);
        circuitBreakerProxy = ITempleCircuitBreakerProxy(_circuitBreakerProxy);
        _updateTrvApprovals(address(0), _treasuryReservesVault);
    }

    /**
     * @notice A hook where strategies can optionally update approvals when the trv is updated
     */
    function _updateTrvApprovals(address oldTrv, address newTrv) internal override {
        _setMaxAllowance(quoteToken, oldTrv, newTrv);
        _setMaxAllowance(templeToken, oldTrv, newTrv);
    }

    /**
     * The version of this particular strategy
     */
    function strategyVersion() external override pure returns (string memory) {
        return VERSION;
    }

    /**
     * @notice Send `protocolToken` to recipient
     * @param amount The requested amount to borrow
     * @param recipient The recipient to send the `protocolToken` tokens to
     */
    function borrowProtocolToken(uint256 amount, address recipient) external onlyElevatedAccess {
        circuitBreakerProxy.preCheck(
            address(templeToken), 
            msg.sender, 
            amount
        );
        emit BorrowToken(address(templeToken), amount);
        treasuryReservesVault.borrow(templeToken, amount, recipient);
    }

    /**
     * @notice Send `quoteToken` to recipient
     * @param amount The requested amount to borrow
     * @param recipient The recipient to send the `quoteToken` tokens to
     */
    function borrowQuoteToken(uint256 amount, address recipient) external onlyElevatedAccess {
        circuitBreakerProxy.preCheck(
            address(quoteToken), 
            msg.sender, 
            amount
        );
        emit BorrowToken(address(quoteToken), amount);
        treasuryReservesVault.borrow(quoteToken, amount, recipient);
    }

    /**
     * @notice Pull `protocolToken` from the caller
     * @param amount The requested amount to repay
     */
    function repayProtocolToken(uint256 amount) external onlyElevatedAccess {
        emit RepayToken(address(templeToken), amount);
        templeToken.safeTransferFrom(msg.sender, address(this), amount);
        treasuryReservesVault.repay(templeToken, amount, address(this));
    }

    /**
     * @notice Pull `quoteToken` from the caller
     * @param amount The requested amount to repay
     */
    function repayQuoteToken(uint256 amount) external onlyElevatedAccess {
        emit RepayToken(address(quoteToken), amount);
        quoteToken.safeTransferFrom(msg.sender, address(this), amount);
        treasuryReservesVault.repay(quoteToken, amount, address(this));
    }

    /**
     * @notice The latest checkpoint of each asset balance this strategy holds, and the current debt.
     * This will be used to report equity performance: `sum(asset value in STABLE) - debt`
     * The conversion of each asset price into the stable token (eg DAI) will be done off-chain
     *
     * @dev The asset value may be stale at any point in time, depending on the strategy. 
     * It may optionally implement `checkpointAssetBalances()` in order to update those balances.
     */
    function latestAssetBalances() public override view returns (
        AssetBalance[] memory assetBalances
    ) {
        // get RAMOS's quote token balance
        (, uint256 templeTokenBalance, uint256 quoteTokenBalance) = ramos.positions();

        assetBalances = new AssetBalance[](2);
        assetBalances[0] = AssetBalance({
            asset: address(quoteToken),
            balance: quoteTokenBalance
        });
        assetBalances[1] = AssetBalance({
            asset: address(templeToken),
            balance: templeTokenBalance
        });
    }

    /**
     * @notice Get the quote used to add liquidity proportionally
     * @dev Since this is not the view function, this should be called with `callStatic`
     */
    function proportionalAddLiquidityQuote(
        uint256 _quoteTokenAmount,
        uint256 _slippageBps
    ) external returns (
        uint256 templeAmount,
        uint256 expectedBptAmount,
        uint256 minBptAmount,
        IBalancerVault.JoinPoolRequest memory requestData
    ) {
        return ramos.poolHelper().proportionalAddLiquidityQuote(_quoteTokenAmount, _slippageBps);
    }

    /**
     * @notice Add liquidity
     * This is a wrapper function for Ramos::addLiquidity
     */
    function addLiquidity(IBalancerVault.JoinPoolRequest calldata _requestData) external onlyElevatedAccess {
        (
            uint256 quoteTokenAmount,
            uint256 protocolTokenAmount,
            uint256 bptTokensStaked
        ) = ramos.addLiquidity(_requestData);
        emit AddLiquidity(quoteTokenAmount, protocolTokenAmount, bptTokensStaked);
    }

    /// @notice Get the quote used to remove liquidity
    /// @dev Since this is not the view function, this should be called with `callStatic`
    function proportionalRemoveLiquidityQuote(
        uint256 _bptAmount,
        uint256 _slippageBps
    ) public returns (
        uint256 expectedTempleAmount,
        uint256 expectedQuoteTokenAmount,
        uint256 minTempleAmount,
        uint256 minQuoteTokenAmount,
        IBalancerVault.ExitPoolRequest memory requestData
    ) {
        return ramos.poolHelper().proportionalRemoveLiquidityQuote(_bptAmount, _slippageBps);
    }

    /**
     * @notice Remove liquidity
     * This is a wrapper function for Ramos:removeLiquidity.
     */
    function removeLiquidity(IBalancerVault.ExitPoolRequest calldata _requestData, uint256 _bptAmount) external onlyElevatedAccess {
        (
            uint256 quoteTokenAmount, 
            uint256 protocolTokenAmount
        ) = ramos.removeLiquidity(_requestData, _bptAmount);
        emit RemoveLiquidity(quoteTokenAmount, protocolTokenAmount, _bptAmount);
    }

    struct PopulateShutdownParams {
        uint256 slippageBps;
    }

    struct ShutdownParams {
        IBalancerVault.ExitPoolRequest requestData;
        uint256 bptAmount;
    }

    /**
     * @notice Populate data to automatically shutdown.
     * This gets a quote to unstake all BPT and liquidate proportionally into stables & temple.
     * @param populateParamsData abi encoded data of struct `PopulateShutdownParams`
     * @return shutdownData abi encoded data of struct `ShutdownParams`
     */
    function populateShutdownData(
        bytes calldata populateParamsData
    ) external virtual override returns (
        bytes memory shutdownData
    ) {
        (PopulateShutdownParams memory populateParams) = abi.decode(populateParamsData, (PopulateShutdownParams));
        ShutdownParams memory shutdownParams;

        (shutdownParams.bptAmount,,) = ramos.positions();
        (,,,,shutdownParams.requestData) = proportionalRemoveLiquidityQuote(shutdownParams.bptAmount, populateParams.slippageBps);
        shutdownData = abi.encode(shutdownParams);
    }

    /**
     * @notice Shutdown the strategy.
     * First unstake all BPT and liquidate into temple & stables, and then repay to the TRV.
     * @param shutdownData abi encoded data of struct `PopulateShutdownParams`
     */
    function _doShutdown(bytes calldata shutdownData) internal virtual override {
        (ShutdownParams memory params) = abi.decode(shutdownData, (ShutdownParams));
        ramos.removeLiquidity(params.requestData, params.bptAmount);

        uint256 stableBalance = quoteToken.balanceOf(address(this));
        if (stableBalance > 0) {
            treasuryReservesVault.repay(quoteToken, stableBalance, address(this));
        }

        uint256 templeBalance = templeToken.balanceOf(address(this));
        if (templeBalance > 0) {
            treasuryReservesVault.repay(templeToken, templeBalance, address(this));
        }
    }
}