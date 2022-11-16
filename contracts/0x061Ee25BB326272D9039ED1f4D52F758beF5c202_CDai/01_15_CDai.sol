// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/ISubStrategy.sol";
import "../../interfaces/IRouter.sol";
import "../../interfaces/IExchange.sol";
import "../../utils/TransferHelper.sol";
import "./interfaces/INotionalProxy.sol";
import "./interfaces/INusdc.sol";
import "./interfaces/ICurve.sol";

contract CDai is OwnableUpgradeable, ISubStrategy {
    using SafeMath for uint256;

    // Sub Strategy name
    string public constant poolName = "CDAI V3";

    // Controller address
    address public controller;

    // USDC token address
    address public usdc;

    // DAI token address
    address public dai;

    // USDC token Decimal
    uint256 public usdcDecimal;

    // DAI token Decimal
    uint256 public daiDecimal;

    // NoteToken Decimal
    uint256 public noteDecimal;

    // Notional Proxy address
    address public notionalProxy;

    // Slippages for deposit and withdraw
    uint256 public depositSlippage;
    uint256 public withdrawSlippage;

    // Constant magnifier
    uint256 public constant magnifier = 10000;

    // Harvest Gap
    uint256 public override harvestGap;

    // Latest Harvest
    uint256 public override latestHarvest;

    // NoteToken Address
    address public note;

    // nDAI address
    address public nDAI;

    // USDC Currency ID
    uint16 public currencyId;

    // Router address
    address public router;

    // Path index
    bytes32 public usdcDaiIndex;
    bytes32 public daiUSDCIndex;

    // Exchange Address
    address public exchange;

    // Max Deposit
    uint256 public override maxDeposit;
    uint256 public abstractSlippage;

    event OwnerDeposit(uint256 lpAmount);

    event EmergencyWithdraw(uint256 amount);

    event SetController(address controller);

    event SetDepositSlippage(uint256 depositSlippage);

    event SetWithdrawSlippage(uint256 withdrawSlippage);

    event SetAbstractSlippage(uint256 abstractSlippage);

    event SetHarvestGap(uint256 harvestGap);

    event SetMaxDeposit(uint256 maxDeposit);

    event SetSwapPath(address _exchange, address _router, bytes32 _usdcDaiIndex, bytes32 _daiUSDCIndex);

    function initialize(
        address _usdc,
        address _dai,
        address _controller,
        address _notionalProxy,
        address _note,
        address _ndai,
        uint16 _currencyId,
        address _exchange
    ) public initializer {
        __Ownable_init();
        usdc = _usdc;
        dai = _dai;
        controller = _controller;
        notionalProxy = _notionalProxy;
        note = _note;
        nDAI = _ndai;
        currencyId = _currencyId;
        exchange = _exchange;

        // Set Max Deposit as max uin256
        maxDeposit = type(uint256).max;

        usdcDecimal = 1e6;
        daiDecimal = 1e18;
        noteDecimal = 1e8;
    }

    /**
        Only controller can call
     */
    modifier onlyController() {
        require(controller == _msgSender(), "ONLY_CONTROLLER");
        _;
    }

    //////////////////////////////////////////
    //          VIEW FUNCTIONS              //
    //////////////////////////////////////////

    /**
        External view function of total USDC deposited in Covex Booster
     */
    function totalAssets(bool fetch) external view override returns (uint256) {
        return _totalAssets(fetch);
    }

    /**
        Internal view function of total USDC deposited
    */
    function _totalAssets(bool fetch) internal view returns (uint256) {
        uint256 nTokenBal = IERC20(nDAI).balanceOf(address(this));

        uint256 nTokenTotal = IERC20(nDAI).totalSupply();

        int256 underlyingDenominated = INusdc(nDAI).getPresentValueUnderlyingDenominated();

        if (underlyingDenominated < 0) return 0;
        else {
            uint256 daiBal = ((nTokenBal * uint256(underlyingDenominated)) * daiDecimal) / noteDecimal / nTokenTotal;

            if (daiBal == 0) return 0;

            // Get Curve Pool Info - pool address, token i, j index
            CurvePool memory curvePool = ICurveRouter(router).pools(daiUSDCIndex);
            address poolAddr = curvePool.pool;
            uint256 i = curvePool.i;
            uint256 j = curvePool.j;

            // Calculate withdraw amout of usdc - from Dai (i) to USDC(j)
            uint256 usdcBal = ICurvePool(poolAddr).get_dy(int128(uint128(i)), int128(uint128(j)), daiBal);
            daiBal = (daiBal * usdcDecimal) / daiDecimal;

            if (!fetch) {
                require(
                    usdcBal >= ((magnifier - abstractSlippage) * daiBal) / magnifier &&
                        usdcBal <= ((magnifier + abstractSlippage) * daiBal) / magnifier,
                    "SLIPPAGE_USDC_ERROR"
                );
            }
            return usdcBal;
        }
    }

    /**
        Deposit function of USDC
     */
    function deposit(uint256 _amount) external override onlyController returns (uint256) {
        uint256 deposited = _deposit(_amount);
        return deposited;
    }

    /**
        Deposit internal function
     */
    function _deposit(uint256 _amount) internal returns (uint256) {
        // Get Prev Deposit Amt
        uint256 prevAmt = _totalAssets(false);

        // Check Max Deposit
        require(prevAmt + _amount <= maxDeposit, "EXCEED_MAX_DEPOSIT");

        uint256 usdcAmt = IERC20(usdc).balanceOf(address(this));
        // Check whether transferred sufficient usdc from controller
        require(usdcAmt >= _amount, "INSUFFICIENT_USDC_TRANSFER");

        // Swap USDC to DAI
        // Approve fromToken to Exchange
        IERC20(usdc).approve(exchange, 0);
        IERC20(usdc).approve(exchange, usdcAmt);

        // Call Swap on exchange
        IExchange(exchange).swapExactTokenInput(usdc, dai, router, usdcDaiIndex, usdcAmt);

        uint256 daiAmt = IERC20(dai).balanceOf(address(this));

        // Make Balance Action
        BalanceAction[] memory actions = new BalanceAction[](1);
        actions[0] = BalanceAction({
            actionType: DepositActionType.DepositUnderlyingAndMintNToken,
            currencyId: currencyId,
            depositActionAmount: daiAmt,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: false,
            redeemToUnderlying: false
        });

        // Approve DAI to notional proxy
        IERC20(dai).approve(notionalProxy, 0);
        IERC20(dai).approve(notionalProxy, daiAmt);

        // Calls batch balance action
        INotionalProxy(notionalProxy).batchBalanceAction(address(this), actions);

        // Get new total assets amount
        uint256 newAmt = _totalAssets(false);

        // Deposited amt
        uint256 deposited = newAmt - prevAmt;
        uint256 minOutput = (_amount * (magnifier - depositSlippage)) / magnifier;

        require(deposited >= minOutput, "DEPOSIT_SLIPPAGE_TOO_BIG");

        return deposited;
    }

    /**
        Withdraw function of USDC
     */
    function withdraw(uint256 _amount) external override onlyController returns (uint256) {
        // Get Current Deposit Amt
        uint256 total = _totalAssets(false);
        uint256 totalLP = IERC20(nDAI).balanceOf(address(this));

        uint256 lpAmt = (totalLP * _amount) / total;

        // Withdraw nDAI
        _withdraw(lpAmt);

        // Swap DAI to USDC
        uint256 daiAmt = IERC20(dai).balanceOf(address(this));
        // Approve DAI to Exchange
        IERC20(dai).approve(exchange, 0);
        IERC20(dai).approve(exchange, daiAmt);

        // Call Swap on exchange
        IExchange(exchange).swapExactTokenInput(dai, usdc, router, daiUSDCIndex, daiAmt);

        // Transfer withdrawn USDC to controller
        uint256 asset = IERC20(usdc).balanceOf(address(this));

        // Deposited amt
        uint256 withdrawn = asset;
        uint256 minOutput = (_amount * (magnifier - withdrawSlippage)) / magnifier;

        require(withdrawn >= minOutput, "WITHDRAW_SLIPPAGE_TOO_BIG");

        // Transfer USDC to Controller
        TransferHelper.safeTransfer(usdc, controller, asset);

        return asset;
    }

    /**
        Withdraw internal function
     */
    function _withdraw(uint256 _amount) internal {
        // Make Balance Action
        BalanceAction[] memory actions = new BalanceAction[](1);
        actions[0] = BalanceAction({
            actionType: DepositActionType.RedeemNToken,
            currencyId: currencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true
        });

        // Calls batch balance action
        INotionalProxy(notionalProxy).batchBalanceAction(address(this), actions);

        // Deduct total LP Amount is not needed
    }

    /**
        Harvest reward token from convex booster
     */
    function harvest() external override onlyController {
        // Call incentive earning
        INotionalProxy(notionalProxy).nTokenClaimIncentives();

        // Transfer Reward tokens to controller
        uint256 noteBal = IERC20(note).balanceOf(address(this));

        TransferHelper.safeTransfer(note, controller, noteBal);

        // Update latest block timestamp
        latestHarvest = block.timestamp;
    }

    /**
        Emergency Withdraw LP token from convex booster and send to owner
     */
    function emergencyWithdraw() public onlyOwner {
        uint256 totalLP = IERC20(nDAI).balanceOf(address(this));
        // If totalLP is zero, return
        if (totalLP == 0) return;

        _withdraw(totalLP);
        // Transfer withdrawn USDC to controller
        uint256 asset = IERC20(dai).balanceOf(address(this));
        TransferHelper.safeTransfer(dai, owner(), asset);

        // Emit Event
        emit EmergencyWithdraw(totalLP);
    }

    /**
        Check withdrawable status of required amount
     */
    function withdrawable(uint256 _amount) external view override returns (uint256) {
        // Get Current Deposit Amt
        uint256 total = _totalAssets(false);

        // If requested amt is bigger than total asset, return false
        if (_amount > total) return total;
        // Todo Have to check withdrawable amount
        else return _amount;
    }

    /**
        Deposit by owner not issueing any ENF token
     */
    function ownerDeposit(uint256 _amount) public onlyOwner {
        // Transfer token from owner
        TransferHelper.safeTransferFrom(usdc, owner(), address(this), _amount);

        // Call deposit
        _deposit(_amount);

        emit OwnerDeposit(_amount);
    }

    //////////////////////////////////////////////////
    //               SET CONFIGURATION              //
    //////////////////////////////////////////////////

    /**
        Set Controller
     */
    function setController(address _controller) public onlyOwner {
        require(_controller != address(0), "INVALID_LP_TOKEN");
        controller = _controller;

        emit SetController(controller);
    }

    /**
        Set Deposit Slipage
     */
    function setDepositSlippage(uint256 _slippage) public onlyOwner {
        require(_slippage < magnifier, "INVALID_SLIPPAGE");

        depositSlippage = _slippage;

        emit SetDepositSlippage(depositSlippage);
    }

    /**
        Set Withdraw Slipage
     */
    function setWithdrawSlippage(uint256 _slippage) public onlyOwner {
        require(_slippage < magnifier, "INVALID_SLIPPAGE");

        withdrawSlippage = _slippage;

        emit SetWithdrawSlippage(withdrawSlippage);
    }

    /**
        Set Abstract Slipage
     */
    function setAbstractSlippage(uint256 _slippage) public onlyOwner {
        require(_slippage < magnifier, "INVALID_SLIPPAGE");

        abstractSlippage = _slippage;

        emit SetAbstractSlippage(abstractSlippage);
    }

    /**
        Set Harvest Gap
     */
    function setHarvestGap(uint256 _harvestGap) public onlyOwner {
        require(_harvestGap > 0, "INVALID_HARVEST_GAP");
        harvestGap = _harvestGap;

        emit SetHarvestGap(harvestGap);
    }

    /**
        Set Max Deposit
     */
    function setMaxDeposit(uint256 _maxDeposit) public onlyOwner {
        require(_maxDeposit > 0, "INVALID_MAX_DEPOSIT");
        maxDeposit = _maxDeposit;

        emit SetMaxDeposit(maxDeposit);
    }

    /**
        Set Swap Router
     */
    function setSwapPath(
        address _exchange,
        address _router,
        bytes32 _usdcDaiIndex,
        bytes32 _daiUSDCIndex
    ) public onlyOwner {
        require(_exchange != address(0) && _router != address(0) && _usdcDaiIndex != 0, "INVALID_ROUTER_ADDRESS");

        exchange = _exchange;
        router = _router;
        usdcDaiIndex = _usdcDaiIndex;
        daiUSDCIndex = _daiUSDCIndex;

        emit SetSwapPath(_exchange, _router, _usdcDaiIndex, _daiUSDCIndex);
    }
}