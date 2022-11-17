// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "SafeERC20.sol";
import "Initializable.sol";
import "ERC20.sol";
import "UUPSUpgradeable.sol";
import {BoringOwnable} from "BoringOwnable.sol";
import {EIP1271Wallet} from "EIP1271Wallet.sol";
import {TradeHandler} from "TradeHandler.sol";
import {IVault, IAsset} from "IVault.sol";
import {NotionalTreasuryAction} from "NotionalTreasuryAction.sol";
import {WETH9} from "WETH9.sol";
import {ITradingModule, Trade} from "ITradingModule.sol";
import "IExchangeV3.sol";
import "IStakedNote.sol";
import "BalancerUtils.sol";

contract TreasuryManager is
    EIP1271Wallet,
    BoringOwnable,
    Initializable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    using TradeHandler for Trade;

    /// @notice precision used to limit the amount of NOTE price impact (1e8 = 100%)
    uint256 internal constant NOTE_PURCHASE_LIMIT_PRECISION = 1e8;

    NotionalTreasuryAction public immutable NOTIONAL;
    IERC20 public immutable NOTE;
    IVault public immutable BALANCER_VAULT;
    ERC20 public immutable BALANCER_POOL_TOKEN;
    IStakedNote public immutable sNOTE;
    bytes32 public immutable NOTE_ETH_POOL_ID;
    address public immutable ASSET_PROXY;
    IExchangeV3 public immutable EXCHANGE;
    ITradingModule public immutable TRADING_MODULE;
    uint32 public constant MAXIMUM_COOL_DOWN_PERIOD_SECONDS = 30 days;
    
    /// @notice From IPriceOracle.getLargestSafeQueryWindow
    uint32 public constant MAX_ORACLE_WINDOW_SIZE = 122400;

    /// @notice Balancer token indexes
    /// Balancer requires token addresses to be sorted BAL#102
    uint256 public immutable WETH_INDEX;
    uint256 public immutable NOTE_INDEX;

    address public manager;

    /// @notice This limit determines the maximum price impact (% increase from current oracle price)
    /// from joining the BPT pool with WETH
    uint256 public notePurchaseLimit;

    /// @notice Number of seconds that need to pass before another investWETHAndNOTE can be called
    uint32 public coolDownTimeInSeconds;
    uint32 public lastInvestTimestamp;

    /// @notice Window for time weighted oracle price
    uint32 public priceOracleWindowInSeconds;

    event ManagementTransferred(address prevManager, address newManager);
    event AssetsHarvested(uint16[] currencies, uint256[] amounts);
    event COMPHarvested(address[] ctokens, uint256 amount);
    event NOTEPurchaseLimitUpdated(uint256 purchaseLimit);
    event OrderCancelled(
        uint8 orderStatus,
        bytes32 orderHash,
        uint256 orderTakerAssetFilledAmount
    );
    event TradeExecuted(
        address indexed sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        uint256 buyAmount
    );

    /// @notice Emitted when cool down time is updated
    event InvestmentCoolDownUpdated(uint256 newCoolDownTimeSeconds);
    event AssetsInvested(uint256 wethAmount, uint256 noteAmount);

    /// @notice Emitted when price oracle window is updated
    event PriceOracleWindowUpdated(uint256 _priceOracleWindowInSeconds);

    /// @dev Restricted methods for the treasury manager
    modifier onlyManager() {
        require(msg.sender == manager, "Unauthorized");
        _;
    }

    constructor(
        NotionalTreasuryAction _notional,
        WETH9 _weth,
        IVault _balancerVault,
        bytes32 _noteETHPoolId,
        IERC20 _note,
        IStakedNote _sNOTE,
        address _assetProxy,
        IExchangeV3 _exchange,
        uint256 _wethIndex,
        uint256 _noteIndex,
        ITradingModule _tradingModule
    ) EIP1271Wallet(_weth) initializer {
        // Balancer will revert if pool is not found
        // prettier-ignore
        (address poolAddress, /* */) = _balancerVault.getPool(_noteETHPoolId);

        WETH_INDEX = _wethIndex;
        NOTE_INDEX = _noteIndex;

        NOTIONAL = NotionalTreasuryAction(_notional);
        sNOTE = _sNOTE;
        NOTE = _note;
        BALANCER_VAULT = _balancerVault;
        NOTE_ETH_POOL_ID = _noteETHPoolId;
        ASSET_PROXY = _assetProxy;
        BALANCER_POOL_TOKEN = ERC20(poolAddress);
        EXCHANGE = _exchange;
        TRADING_MODULE = _tradingModule;
    }

    function initialize(
        address _owner,
        address _manager,
        uint32 _coolDownTimeInSeconds
    ) external initializer {
        owner = _owner;
        manager = _manager;
        coolDownTimeInSeconds = _coolDownTimeInSeconds;
        emit OwnershipTransferred(address(0), _owner);
        emit ManagementTransferred(address(0), _manager);
    }

    function approveToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeApprove(ASSET_PROXY, 0);
        IERC20(token).safeApprove(ASSET_PROXY, amount);
    }

    function approveBalancer() external onlyOwner {
        NOTE.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        IERC20(address(WETH)).safeApprove(
            address(BALANCER_VAULT),
            type(uint256).max
        );
    }

    function setPriceOracle(address tokenAddress, address oracleAddress)
        external
        onlyOwner
    {
        /// @dev oracleAddress validated inside _setPriceOracle
        _setPriceOracle(tokenAddress, oracleAddress);
    }

    function setSlippageLimit(address tokenAddress, uint256 slippageLimit)
        external
        onlyOwner
    {
        /// @dev slippageLimit validated inside _setSlippageLimit
        _setSlippageLimit(tokenAddress, slippageLimit);
    }

    function setNOTEPurchaseLimit(uint256 purchaseLimit) external onlyOwner {
        require(
            purchaseLimit <= NOTE_PURCHASE_LIMIT_PRECISION,
            "purchase limit is too high"
        );
        notePurchaseLimit = purchaseLimit;
        emit NOTEPurchaseLimitUpdated(purchaseLimit);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        if (amount == type(uint256).max)
            amount = IERC20(token).balanceOf(address(this));
        if (amount > 0) IERC20(token).safeTransfer(msg.sender, amount);
    }

    function wrapToWETH() external onlyManager {
        WETH.deposit{value: address(this).balance}();
    }

    function setManager(address newManager) external onlyOwner {
        emit ManagementTransferred(manager, newManager);
        manager = newManager;
    }

    function claimBAL() external onlyManager {
        sNOTE.claimBAL();
    }
    
    /// @notice cancelOrder needs to be proxied because 0x expects makerAddress to be address(this)
    /// @param order 0x order object
    function cancelOrder(IExchangeV3.Order calldata order)
        external
        onlyManager
    {
        IExchangeV3.OrderInfo memory info = EXCHANGE.getOrderInfo(order);
        EXCHANGE.cancelOrder(order);
        emit OrderCancelled(
            info.orderStatus,
            info.orderHash,
            info.orderTakerAssetFilledAmount
        );
    }

    /*** Manager Functionality  ***/

    /// @dev Will need to add a this method as a separate action behind the notional proxy
    function harvestAssetsFromNotional(uint16[] calldata currencies)
        external
        onlyManager
    {
        uint256[] memory amountsTransferred = NOTIONAL
            .transferReserveToTreasury(currencies);
        emit AssetsHarvested(currencies, amountsTransferred);
    }

    function harvestCOMPFromNotional(address[] calldata ctokens)
        external
        onlyManager
    {
        uint256 amountTransferred = NOTIONAL.claimCOMPAndTransfer(ctokens);
        emit COMPHarvested(ctokens, amountTransferred);
    }

    /// @notice Updates the required cooldown time to invest
    function setCoolDownTime(uint32 _coolDownTimeInSeconds) external onlyOwner {
        require(_coolDownTimeInSeconds <= MAXIMUM_COOL_DOWN_PERIOD_SECONDS);
        coolDownTimeInSeconds = _coolDownTimeInSeconds;
        emit InvestmentCoolDownUpdated(_coolDownTimeInSeconds);
    }

    /// @notice Updates the price oracle window
    function setPriceOracleWindow(uint32 _priceOracleWindowInSeconds)
        external
        onlyOwner
    {
        require(_priceOracleWindowInSeconds <= MAX_ORACLE_WINDOW_SIZE);
        priceOracleWindowInSeconds = _priceOracleWindowInSeconds;
        emit PriceOracleWindowUpdated(_priceOracleWindowInSeconds);
    }

    function executeTrade(Trade calldata trade, uint8 dexId) 
        external onlyManager returns (uint256 amountSold, uint256 amountBought) {
        require(trade.sellToken != address(WETH));
        require(trade.buyToken == address(WETH));

        (amountSold, amountBought) = trade._executeTrade(dexId, TRADING_MODULE);
        emit TradeExecuted(trade.sellToken, trade.buyToken, amountSold, amountBought);
    }

    /// @notice Allows treasury manager to invest WETH and NOTE into the Balancer pool
    /// @param wethAmount amount of WETH to transfer into the Balancer pool
    /// @param noteAmount amount of NOTE to transfer into the Balancer pool
    /// @param minBPT slippage parameter to prevent front running
    function investWETHAndNOTE(
        uint256 wethAmount,
        uint256 noteAmount,
        uint256 minBPT
    ) external onlyManager {
        uint32 blockTime = _safe32(block.timestamp);
        require(
            lastInvestTimestamp + coolDownTimeInSeconds < blockTime,
            "Investment Cooldown"
        );
        lastInvestTimestamp = blockTime;

        IAsset[] memory assets = new IAsset[](2);
        assets[WETH_INDEX] = IAsset(address(WETH));
        assets[NOTE_INDEX] = IAsset(address(NOTE));
        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[WETH_INDEX] = wethAmount;
        maxAmountsIn[NOTE_INDEX] = noteAmount;

        // Gets the balancer time weighted average price denominated in ETH
        uint256 noteOraclePrice = BalancerUtils.getTimeWeightedOraclePrice(
            address(BALANCER_POOL_TOKEN),
            IPriceOracle.Variable.PAIR_PRICE,
            uint256(priceOracleWindowInSeconds)
        );

        BALANCER_VAULT.joinPool(
            NOTE_ETH_POOL_ID,
            address(this),
            address(sNOTE), // sNOTE will receive the BPT
            IVault.JoinPoolRequest(
                assets,
                maxAmountsIn,
                abi.encode(
                    IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                    maxAmountsIn,
                    minBPT // Apply minBPT to prevent front running
                ),
                false // Don't use internal balances
            )
        );

        // Make sure the donated BPT is staked
        sNOTE.stakeAll();

        uint256 noteSpotPrice = _getNOTESpotPrice();

        // Calculate the max spot price based on the purchase limit
        uint256 maxPrice = noteOraclePrice +
            (noteOraclePrice * notePurchaseLimit) /
            NOTE_PURCHASE_LIMIT_PRECISION;

        require(noteSpotPrice <= maxPrice, "price impact is too high");

        emit AssetsInvested(wethAmount, noteAmount);
    }

    function _getNOTESpotPrice() public view returns (uint256) {
        // prettier-ignore
        (
            /* address[] memory tokens */,
            uint256[] memory balances,
            /* uint256 lastChangeBlock */
        ) = BALANCER_VAULT.getPoolTokens(NOTE_ETH_POOL_ID);

        // increase NOTE precision to 1e18
        uint256 noteBal = balances[NOTE_INDEX] * 1e10;

        // We need to multiply the numerator by 1e18 to preserve enough
        // precision for the division
        // NOTEWeight = 0.8
        // ETHWeight = 0.2
        // SpotPrice = (ETHBalance / 0.2 * 1e18) / (NOTEBalance / 0.8)
        // SpotPrice = (ETHBalance * 5 * 1e18) / (NOTEBalance * 1.25)
        // SpotPrice = (ETHBalance * 5 * 1e18) / (NOTEBalance * 125 / 100)

        return (balances[WETH_INDEX] * 5 * 1e18) / ((noteBal * 125) / 100);
    }

    function isValidSignature(bytes calldata data, bytes calldata signature)
        external
        view
        returns (bytes4)
    {
        return _isValidSignature(data, signature, manager);
    }

    function _safe32(uint256 x) internal pure returns (uint32) {
        require(x <= type(uint32).max);
        return uint32(x);
    }

    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal override onlyOwner {}
}