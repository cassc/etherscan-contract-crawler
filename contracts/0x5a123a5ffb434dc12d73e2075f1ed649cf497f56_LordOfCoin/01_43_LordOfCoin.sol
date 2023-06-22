// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IWETH.sol";
import './interfaces/IERC20Snapshot.sol';
import './interfaces/ITreasury.sol';
import './interfaces/IVault.sol';
import './interfaces/IMasset.sol';
import './interfaces/IDvd.sol';
import './interfaces/ISDvd.sol';
import './interfaces/IPool.sol';
import './interfaces/IBPool.sol';
import './utils/MathUtils.sol';

/// @title Lord of Coin
/// @notice Lord of Coin finds the money, for you - to spend it.
/// @author Lord Nami
// Special thanks to TRIB as inspiration.
// Special thanks to Lord Nami mods @AspieJames, @defimoon, @tectumor, @downsin, @ghost, @LordFes, @converge, @cryptycreepy, @cryptpower, @jonsnow
// and everyone else who support this project by spreading the words on social media.
contract LordOfCoin is ReentrancyGuard {
    using SafeMath for uint256;
    using MathUtils for uint256;
    using SafeERC20 for IERC20;

    event Bought(address indexed sender, address indexed recipient, uint256 musdAmount, uint256 dvdReceived);
    event Sold(address indexed sender, address indexed recipient, uint256 dvdAmount, uint256 musdReceived);
    event SoldToETH(address indexed sender, address indexed recipient, uint256 dvdAmount, uint256 ethReceived);

    event DividendClaimed(address indexed recipient, uint256 musdReceived);
    event DividendClaimedETH(address indexed recipient, uint256 ethReceived);
    event Received(address indexed from, uint256 amount);

    /// @notice Applied to every buy or sale of DVD.
    /// @dev Tax denominator
    uint256 public constant CURVE_TAX_DENOMINATOR = 10;

    /// @notice Applied to every buy of DVD before bonding curve tax.
    /// @dev Tax denominator
    uint256 public constant BUY_TAX_DENOMINATOR = 20;

    /// @notice Applied to every sale of DVD after bonding curve tax.
    /// @dev Tax denominator
    uint256 public constant SELL_TAX_DENOMINATOR = 10;

    /// @notice The slope of the bonding curve.
    uint256 public constant DIVIDER = 1000000; // 1 / multiplier 0.000001 (so that we don't deal with decimals)

    /// @notice Address in which DVD are sent to be burned.
    /// These DVD can't be redeemed by the reserve.
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev WETH token address
    address weth;

    /// @dev Balancer pool WETH-MUSD
    address balancerPool;

    /// @dev mUSD token mStable address.
    address musd;

    /// @notice Dvd token instance.
    address public dvd;

    /// @notice SDvd token instance.
    address public sdvd;

    /// @notice Pair address for SDVD-ETH on uniswap
    address public sdvdEthPairAddress;

    /// @notice SDVD-ETH farming pool.
    address public sdvdEthPool;

    /// @notice DVD farming pool.
    address public dvdPool;

    /// @notice Dev treasury.
    address public devTreasury;

    /// @notice Pool treasury.
    address public poolTreasury;

    /// @notice Trading treasury.
    address public tradingTreasury;

    /// @notice Total dividend earned since the contract deployment.
    uint256 public totalDividendClaimed;

    /// @notice Total reserve value that backs all DVD in circulation.
    /// @dev Area below the bonding curve.
    uint256 public totalReserve;

    /// @notice Interface for integration with mStable.
    address public vault;

    /// @notice Current state of the application.
    /// Either already open (true) or not yet (false).
    bool public isMarketOpen = false;

    /// @notice Market will be open on this timestamp
    uint256 public marketOpenTime;

    /// @notice Current snapshot id
    /// Can be thought as week index, since snapshot is increased per week
    uint256 public snapshotId;

    /// @notice Snapshot timestamp.
    uint256 public snapshotTime;

    /// @notice Snapshot duration.
    uint256 public SNAPSHOT_DURATION = 1 weeks;

    /// @dev Total profits on each snapshot id.
    mapping(uint256 => uint256) private _totalProfitSnapshots;

    /// @dev Dividend paying SDVD supply on each snapshot id.
    mapping(uint256 => uint256) private _dividendPayingSDVDSupplySnapshots;

    /// @dev Flag to determine if account has claim their dividend on each snapshot id.
    mapping(address => mapping(uint256 => bool)) private _isDividendClaimedSnapshots;

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    constructor(
        address _vault,
        address _uniswapRouter,
        address _balancerPool,
        address _dvd,
        address _sdvd,
        address _sdvdEthPool,
        address _dvdPool,
        address _devTreasury,
        address _poolTreasury,
        address _tradingTreasury,
        uint256 _marketOpenTime
    ) public {
        // Set vault
        vault = _vault;
        // mUSD instance
        musd = IVault(vault).musd();
        // Approve vault to manage mUSD in this contract
        _approveMax(musd, vault);

        // Set uniswap router
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        // Set balancer pool
        balancerPool = _balancerPool;

        // Set weth address
        weth = uniswapRouter.WETH();

        // Approve balancer pool to manage mUSD in this contract
        _approveMax(musd, balancerPool);
        // Approve balancer pool to manage WETH in this contract
        _approveMax(weth, balancerPool);
        // Approve self to spend mUSD in this contract (used to buy from ETH / sell to ETH)
        _approveMax(musd, address(this));

        dvd = _dvd;
        sdvd = _sdvd;
        sdvdEthPool = _sdvdEthPool;
        dvdPool = _dvdPool;
        devTreasury = _devTreasury;
        poolTreasury = _poolTreasury;
        tradingTreasury = _tradingTreasury;

        // Create SDVD ETH pair
        sdvdEthPairAddress = IUniswapV2Factory(uniswapRouter.factory()).createPair(sdvd, weth);

        // Set open time
        marketOpenTime = _marketOpenTime;
        // Set initial snapshot timestamp
        snapshotTime = _marketOpenTime;
    }

    /* ========== Modifier ========== */

    modifier marketOpen() {
        require(isMarketOpen, 'Market not open');
        _;
    }

    modifier onlyTradingTreasury() {
        require(msg.sender == tradingTreasury, 'Only treasury');
        _;
    }

    /* ========== Trading Treasury Only ========== */

    /// @notice Deposit trading profit to vault
    function depositTradingProfit(uint256 amount) external onlyTradingTreasury {
        // Deposit mUSD to vault
        IVault(vault).deposit(amount);
    }

    /* ========== Mutative ========== */

    /// @notice Exchanges mUSD to DVD.
    /// @dev mUSD to be exchanged needs to be approved first.
    /// @param musdAmount mUSD amount to be exchanged.
    function buy(uint256 musdAmount) external nonReentrant returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _buy(msg.sender, msg.sender, musdAmount);
    }

    /// @notice Exchanges mUSD to DVD.
    /// @dev mUSD to be exchanged needs to be approved first.
    /// @param recipient Recipient of DVD token.
    /// @param musdAmount mUSD amount to be exchanged.
    function buyTo(address recipient, uint256 musdAmount) external nonReentrant returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _buy(msg.sender, recipient, musdAmount);
    }

    /// @notice Exchanges ETH to DVD.
    function buyFromETH() payable external nonReentrant returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _buy(address(this), msg.sender, _swapETHToMUSD(address(this), msg.value));
    }

    /// @notice Exchanges DVD to mUSD.
    /// @param dvdAmount DVD amount to be exchanged.
    function sell(uint256 dvdAmount) external nonReentrant marketOpen returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _sell(msg.sender, msg.sender, dvdAmount);
    }

    /// @notice Exchanges DVD to mUSD.
    /// @param recipient Recipient of mUSD.
    /// @param dvdAmount DVD amount to be exchanged.
    function sellTo(address recipient, uint256 dvdAmount) external nonReentrant marketOpen returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _sell(msg.sender, recipient, dvdAmount);
    }

    /// @notice Exchanges DVD to ETH.
    /// @param dvdAmount DVD amount to be exchanged.
    function sellToETH(uint256 dvdAmount) external nonReentrant marketOpen returns (uint256 returnedETH, uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        // Sell DVD and receive mUSD in this contract
        (returnedMUSD, marketTax, curveTax, taxedDVD) = _sell(msg.sender, address(this), dvdAmount);
        // Swap received mUSD dividend for ether and send it back to sender
        returnedETH = _swapMUSDToETH(msg.sender, returnedMUSD);

        emit SoldToETH(msg.sender, msg.sender, dvdAmount, returnedETH);
    }

    /// @notice Claim dividend in mUSD.
    function claimDividend() external nonReentrant marketOpen returns (uint256 dividend) {
        return _claimDividend(msg.sender, msg.sender);
    }

    /// @notice Claim dividend in mUSD.
    /// @param recipient Recipient of mUSD.
    function claimDividendTo(address recipient) external nonReentrant marketOpen returns (uint256 dividend) {
        return _claimDividend(msg.sender, recipient);
    }

    /// @notice Claim dividend in ETH.
    function claimDividendETH() external nonReentrant marketOpen returns (uint256 dividend, uint256 receivedETH) {
        // Claim dividend to this contract
        dividend = _claimDividend(msg.sender, address(this));
        // Swap received mUSD dividend for ether and send it back to sender
        receivedETH = _swapMUSDToETH(msg.sender, dividend);

        emit DividendClaimedETH(msg.sender, receivedETH);
    }

    /// @notice Check if we need to create new snapshot.
    function checkSnapshot() public {
        if (isMarketOpen) {
            // If time has passed for 1 week since last snapshot
            // and market is open
            if (snapshotTime.add(SNAPSHOT_DURATION) <= block.timestamp) {
                // Update snapshot timestamp
                snapshotTime = block.timestamp;
                // Take new snapshot
                snapshotId = ISDvd(sdvd).snapshot();
                // Save the interest
                _totalProfitSnapshots[snapshotId] = totalProfit();
                // Save dividend paying supply
                _dividendPayingSDVDSupplySnapshots[snapshotId] = dividendPayingSDVDSupply();
            }
            // If something wrong / there is no interest, lets try again.
            if (snapshotId > 0 && _totalProfitSnapshots[snapshotId] == 0) {
                _totalProfitSnapshots[snapshotId] = totalProfit();
            }
        }
    }

    /// @notice Release treasury.
    function releaseTreasury() public {
        if (isMarketOpen) {
            ITreasury(devTreasury).release();
            ITreasury(poolTreasury).release();
            ITreasury(tradingTreasury).release();
        }
    }

    /* ========== View ========== */

    /// @notice Get claimable dividend for address.
    /// @param account Account address.
    /// @return dividend Dividend in mUSD.
    function claimableDividend(address account) public view returns (uint256 dividend) {
        // If there is no snapshot or already claimed
        if (snapshotId == 0 || isDividendClaimedAt(account, snapshotId)) {
            return 0;
        }

        // Get sdvd balance at snapshot
        uint256 sdvdBalance = IERC20Snapshot(sdvd).balanceOfAt(account, snapshotId);
        if (sdvdBalance == 0) {
            return 0;
        }

        // Get dividend in mUSD based on SDVD balance
        dividend = sdvdBalance
        .mul(claimableProfitAt(snapshotId))
        .div(dividendPayingSDVDSupplyAt(snapshotId));
    }

    /// @notice Total mUSD that is now forever locked in the protocol.
    function totalLockedReserve() external view returns (uint256) {
        return _calculateReserveFromSupply(dvdBurnedAmount());
    }

    /// @notice Total claimable profit.
    /// @return Total claimable profit in mUSD.
    function claimableProfit() public view returns (uint256) {
        return totalProfit().div(2);
    }

    /// @notice Total claimable profit in snapshot.
    /// @return Total claimable profit in mUSD.
    function claimableProfitAt(uint256 _snapshotId) public view returns (uint256) {
        return totalProfitAt(_snapshotId).div(2);
    }

    /// @notice Total profit.
    /// @return Total profit in MUSD.
    function totalProfit() public view returns (uint256) {
        uint256 vaultBalance = IVault(vault).getBalance();
        // Sometimes mStable returns a value lower than the
        // deposit because their exchange rate gets updated after the deposit.
        if (vaultBalance < totalReserve) {
            vaultBalance = totalReserve;
        }
        return vaultBalance.sub(totalReserve);
    }

    /// @notice Total profit in snapshot.
    /// @param _snapshotId Snapshot id.
    /// @return Total profit in MUSD.
    function totalProfitAt(uint256 _snapshotId) public view returns (uint256) {
        return _totalProfitSnapshots[_snapshotId];
    }

    /// @notice Check if dividend already claimed by account.
    /// @return Is dividend claimed.
    function isDividendClaimedAt(address account, uint256 _snapshotId) public view returns (bool) {
        return _isDividendClaimedSnapshots[account][_snapshotId];
    }

    /// @notice Total supply of DVD. This includes burned DVD.
    /// @return Total supply of DVD in wei.
    function dvdTotalSupply() public view returns (uint256) {
        return IERC20(dvd).totalSupply();
    }

    /// @notice Total DVD that have been burned.
    /// @dev These DVD are still in circulation therefore they
    /// are still considered on the bonding curve formula.
    /// @return Total burned DVD in wei.
    function dvdBurnedAmount() public view returns (uint256) {
        return IERC20(dvd).balanceOf(BURN_ADDRESS);
    }

    /// @notice DVD price in wei according to the bonding curve formula.
    /// @return Current DVD price in wei.
    function dvdPrice() external view returns (uint256) {
        // price = supply * multiplier
        return dvdTotalSupply().roundedDiv(DIVIDER);
    }

    /// @notice DVD price floor in wei according to the bonding curve formula.
    /// @return Current DVD price floor in wei.
    function dvdPriceFloor() external view returns (uint256) {
        return dvdBurnedAmount().roundedDiv(DIVIDER);
    }

    /// @notice Total supply of Dividend-paying SDVD.
    /// @return Total supply of SDVD in wei.
    function dividendPayingSDVDSupply() public view returns (uint256) {
        // Get total supply
        return IERC20(sdvd).totalSupply()
        // Get sdvd in uniswap pair balance
        .sub(IERC20(sdvd).balanceOf(sdvdEthPairAddress))
        // Get sdvd in SDVD-ETH pool
        .sub(IERC20(sdvd).balanceOf(sdvdEthPool))
        // Get sdvd in DVD pool
        .sub(IERC20(sdvd).balanceOf(dvdPool))
        // Get sdvd in pool treasury
        .sub(IERC20(sdvd).balanceOf(poolTreasury))
        // Get sdvd in dev treasury
        .sub(IERC20(sdvd).balanceOf(devTreasury))
        // Get sdvd in trading treasury
        .sub(IERC20(sdvd).balanceOf(tradingTreasury));
    }

    /// @notice Total supply of Dividend-paying SDVD in snapshot.
    /// @return Total supply of SDVD in wei.
    function dividendPayingSDVDSupplyAt(uint256 _snapshotId) public view returns (uint256) {
        return _dividendPayingSDVDSupplySnapshots[_snapshotId];
    }

    /// @notice Calculates the amount of DVD in exchange for reserve after applying bonding curve tax.
    /// @param reserveAmount Reserve value in wei to use in the conversion.
    /// @return Token amount in wei after the 10% tax has been applied.
    function reserveToDVDTaxed(uint256 reserveAmount) external view returns (uint256) {
        if (reserveAmount == 0) {
            return 0;
        }
        uint256 tax = reserveAmount.div(CURVE_TAX_DENOMINATOR);
        uint256 totalDVD = reserveToDVD(reserveAmount);
        uint256 taxedDVD = reserveToDVD(tax);
        return totalDVD.sub(taxedDVD);
    }

    /// @notice Calculates the amount of reserve in exchange for DVD after applying bonding curve tax.
    /// @param tokenAmount Token value in wei to use in the conversion.
    /// @return Reserve amount in wei after the 10% tax has been applied.
    function dvdToReserveTaxed(uint256 tokenAmount) external view returns (uint256) {
        if (tokenAmount == 0) {
            return 0;
        }
        uint256 reserveAmount = dvdToReserve(tokenAmount);
        uint256 tax = reserveAmount.div(CURVE_TAX_DENOMINATOR);
        return reserveAmount.sub(tax);
    }

    /// @notice Calculates the amount of DVD in exchange for reserve.
    /// @param reserveAmount Reserve value in wei to use in the conversion.
    /// @return Token amount in wei.
    function reserveToDVD(uint256 reserveAmount) public view returns (uint256) {
        return _calculateReserveToDVD(reserveAmount, totalReserve, dvdTotalSupply());
    }

    /// @notice Calculates the amount of reserve in exchange for DVD.
    /// @param tokenAmount Token value in wei to use in the conversion.
    /// @return Reserve amount in wei.
    function dvdToReserve(uint256 tokenAmount) public view returns (uint256) {
        return _calculateDVDToReserve(tokenAmount, dvdTotalSupply(), totalReserve);
    }

    /* ========== Internal ========== */

    /// @notice Check if market can be opened
    function _checkOpenMarket() internal {
        require(marketOpenTime <= block.timestamp, 'Market not open');
        if (!isMarketOpen) {
            // Set flag
            isMarketOpen = true;
        }
    }

    /// @notice Exchanges mUSD to DVD.
    /// @dev mUSD to be exchanged needs to be approved first.
    /// @param sender Address that has mUSD token.
    /// @param recipient Address that will receive DVD token.
    /// @param musdAmount mUSD amount to be exchanged.
    function _buy(address sender, address recipient, uint256 musdAmount) internal returns (uint256 returnedDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        _checkOpenMarket();
        checkSnapshot();
        releaseTreasury();

        require(musdAmount > 0, 'Cannot buy 0');

        // Tax to be included as profit
        marketTax = musdAmount.div(BUY_TAX_DENOMINATOR);
        // Get amount after market tax
        uint256 inAmount = musdAmount.sub(marketTax);

        // Calculate bonding curve tax in mUSD
        curveTax = inAmount.div(CURVE_TAX_DENOMINATOR);

        // Convert mUSD amount to DVD amount
        uint256 totalDVD = reserveToDVD(inAmount);
        // Convert tax to DVD amount
        taxedDVD = reserveToDVD(curveTax);
        // Calculate DVD for recipient
        returnedDVD = totalDVD.sub(taxedDVD);

        // Transfer mUSD from sender to this contract
        IERC20(musd).safeTransferFrom(sender, address(this), musdAmount);

        // Deposit mUSD to vault
        IVault(vault).deposit(musdAmount);
        // Increase mUSD total reserve
        totalReserve = totalReserve.add(inAmount);

        // Send taxed DVD to burn address
        IDvd(dvd).mint(BURN_ADDRESS, taxedDVD);
        // Increase recipient DVD balance
        IDvd(dvd).mint(recipient, returnedDVD);
        // Increase user DVD Shareholder point
        IDvd(dvd).increaseShareholderPoint(recipient, returnedDVD);

        emit Bought(sender, recipient, musdAmount, returnedDVD);
    }

    /// @notice Exchanges DVD to mUSD.
    /// @param sender Address that has DVD token.
    /// @param recipient Address that will receive mUSD token.
    /// @param dvdAmount DVD amount to be exchanged.
    function _sell(address sender, address recipient, uint256 dvdAmount) internal returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        checkSnapshot();
        releaseTreasury();

        require(dvdAmount <= IERC20(dvd).balanceOf(sender), 'Insufficient balance');
        require(dvdAmount > 0, 'Cannot sell 0');
        require(IDvd(dvd).shareholderPointOf(sender) >= dvdAmount, 'Insufficient shareholder points');

        // Convert number of DVD amount that user want to sell to mUSD amount
        uint256 reserveAmount = dvdToReserve(dvdAmount);
        // Calculate tax in mUSD
        curveTax = reserveAmount.div(CURVE_TAX_DENOMINATOR);
        // Make sure fee is enough
        require(curveTax >= 1, 'Insufficient tax');

        // Get net amount
        uint256 net = reserveAmount.sub(curveTax);

        // Calculate taxed DVD
        taxedDVD = _calculateReserveToDVD(
            curveTax,
            totalReserve.sub(reserveAmount),
            dvdTotalSupply().sub(dvdAmount)
        );

        // Tax to be included as profit
        marketTax = net.div(SELL_TAX_DENOMINATOR);
        // Get musd amount for recipient
        returnedMUSD = net.sub(marketTax);

        // Decrease total reserve
        totalReserve = totalReserve.sub(net);

        // Reduce user DVD balance
        IDvd(dvd).burn(sender, dvdAmount);
        // Send taxed DVD to burn address
        IDvd(dvd).mint(BURN_ADDRESS, taxedDVD);
        // Decrease sender DVD Shareholder point
        IDvd(dvd).decreaseShareholderPoint(sender, dvdAmount);

        // Redeem mUSD from vault
        IVault(vault).redeem(returnedMUSD);
        // Send mUSD to recipient
        IERC20(musd).safeTransfer(recipient, returnedMUSD);

        emit Sold(sender, recipient, dvdAmount, returnedMUSD);
    }

    /// @notice Claim dividend in mUSD.
    /// @param sender Address that has SDVD token.
    /// @param recipient Address that will receive mUSD dividend.
    function _claimDividend(address sender, address recipient) internal returns (uint256 dividend) {
        checkSnapshot();
        releaseTreasury();

        // Get dividend in mUSD based on SDVD balance
        dividend = claimableDividend(sender);
        require(dividend > 0, 'No dividend');

        // Set dividend as claimed
        _isDividendClaimedSnapshots[sender][snapshotId] = true;

        // Redeem mUSD from vault
        IVault(vault).redeem(dividend);
        // Send dividend mUSD to user
        IERC20(musd).safeTransfer(recipient, dividend);

        emit DividendClaimed(recipient, dividend);
    }

    /// @notice Swap ETH to mUSD in this contract.
    /// @param amount ETH amount.
    /// @return musdAmount returned mUSD amount.
    function _swapETHToMUSD(address recipient, uint256 amount) internal returns (uint256 musdAmount) {
        // Convert ETH to WETH
        IWETH(weth).deposit{ value: amount }();
        // Swap WETH to mUSD
        (musdAmount,) = IBPool(balancerPool).swapExactAmountIn(weth, amount, musd, 0, uint256(-1));
        // Send mUSD
        if (recipient != address(this)) {
            IERC20(musd).safeTransfer(recipient, musdAmount);
        }
    }

    /// @notice Swap mUSD to ETH in this contract.
    /// @param amount mUSD Amount.
    /// @return ethAmount returned ETH amount.
    function _swapMUSDToETH(address recipient, uint256 amount) internal returns (uint256 ethAmount) {
        // Swap mUSD to WETH
        (ethAmount,) = IBPool(balancerPool).swapExactAmountIn(musd, amount, weth, 0, uint256(-1));
        // Convert WETH to ETH
        IWETH(weth).withdraw(ethAmount);
        // Send ETH
        if (recipient != address(this)) {
            payable(recipient).transfer(ethAmount);
        }
    }

    /// @notice Approve maximum value to spender
    function _approveMax(address tkn, address spender) internal {
        uint256 max = uint256(- 1);
        IERC20(tkn).safeApprove(spender, max);
    }

    /**
     * Supply (s), reserve (r) and token price (p) are in a relationship defined by the bonding curve:
     *      p = m * s
     * The reserve equals to the area below the bonding curve
     *      r = s^2 / 2
     * The formula for the supply becomes
     *      s = sqrt(2 * r / m)
     *
     * In solidity computations, we are using divider instead of multiplier (because its an integer).
     * All values are decimals with 18 decimals (represented as uints), which needs to be compensated for in
     * multiplications and divisions
     */

    /// @notice Computes the increased supply given an amount of reserve.
    /// @param _reserveDelta The amount of reserve in wei to be used in the calculation.
    /// @param _totalReserve The current reserve state to be used in the calculation.
    /// @param _supply The current supply state to be used in the calculation.
    /// @return _supplyDelta token amount in wei.
    function _calculateReserveToDVD(
        uint256 _reserveDelta,
        uint256 _totalReserve,
        uint256 _supply
    ) internal pure returns (uint256 _supplyDelta) {
        uint256 _reserve = _totalReserve;
        uint256 _newReserve = _reserve.add(_reserveDelta);
        // s = sqrt(2 * r / m)
        uint256 _newSupply = MathUtils.sqrt(
            _newReserve
            .mul(2)
            .mul(DIVIDER) // inverse the operation (Divider instead of multiplier)
            .mul(1e18) // compensation for the squared unit
        );

        _supplyDelta = _newSupply.sub(_supply);
    }

    /// @notice Computes the decrease in reserve given an amount of DVD.
    /// @param _supplyDelta The amount of DVD in wei to be used in the calculation.
    /// @param _supply The current supply state to be used in the calculation.
    /// @param _totalReserve The current reserve state to be used in the calculation.
    /// @return _reserveDelta Reserve amount in wei.
    function _calculateDVDToReserve(
        uint256 _supplyDelta,
        uint256 _supply,
        uint256 _totalReserve
    ) internal pure returns (uint256 _reserveDelta) {
        require(_supplyDelta <= _supply, 'Token amount must be less than the supply');

        uint256 _newSupply = _supply.sub(_supplyDelta);
        uint256 _newReserve = _calculateReserveFromSupply(_newSupply);
        _reserveDelta = _totalReserve.sub(_newReserve);
    }

    /// @notice Calculates reserve given a specific supply.
    /// @param _supply The token supply in wei to be used in the calculation.
    /// @return _reserve Reserve amount in wei.
    function _calculateReserveFromSupply(uint256 _supply) internal pure returns (uint256 _reserve) {
        // r = s^2 * m / 2
        _reserve = _supply
        .mul(_supply)
        .div(DIVIDER) // inverse the operation (Divider instead of multiplier)
        .div(2)
        .roundedDiv(1e18);
        // correction of the squared unit
    }
}