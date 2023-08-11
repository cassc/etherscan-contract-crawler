// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IETHLeverage.sol";
import "./interfaces/IFlashloanReceiver.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IAave.sol";
import "../interfaces/ISubStrategy.sol";
import "../interfaces/IVault.sol";
import "../utils/TransferHelper.sol";

contract ETHStrategy is Ownable, ISubStrategy, IETHLeverage {
    using SafeMath for uint256;

    // Sub Strategy name
    string public constant poolName = "ETHStrategy V0.9";

    // Controller address
    address public controller;

    // Vault address
    address public vault;

    // Constant magnifier
    uint256 public constant magnifier = 10000;

    // Harvest Gap
    uint256 public override harvestGap;

    // Latest Harvest
    uint256 public override latestHarvest;

    // Exchange Address
    address public exchange;

    // Flashloan receiver
    address public receiver;

    // Fee collector
    address public feePool;

    // WETH Address
    address public weth;

    // STETH Address
    address public stETH;

    // ASTETH Address
    address public astETH;

    // aave address
    address public aave;

    // Slippages for deposit and withdraw
    uint256 public depositSlippage;
    uint256 public withdrawSlippage;

    // Max Deposit
    uint256 public override maxDeposit;

    // Last Earn Block
    uint256 public lastEarnBlock;

    // Last Earn Total
    uint256 public lastTotal;

    // Block rate
    uint256 public blockRate;

    // Max Loan Ratio
    uint256 public mlr;

    enum SrategyState {
        Normal,
        Deposit,
        Withdraw,
        EmergencyWithdraw
    }

    SrategyState private curState;

    event SetController(address controller);

    event SetVault(address vault);

    event SetExchange(address exchange);

    event SetFeePool(address feePool);

    event SetDepositSlippage(uint256 depositSlippage);

    event SetWithdrawSlippage(uint256 withdrawSlippage);

    event SetHarvestGap(uint256 harvestGap);

    event SetMaxDeposit(uint256 maxDeposit);

    event SetFlashloanReceiver(address receiver);

    event SetMLR(uint256 oldMlr, uint256 newMlr);

    event SetBlockRate(uint256 oldRate, uint256 newRate);

    event LTVUpdate(
        uint256 oldDebt,
        uint256 oldCollateral,
        uint256 newDebt,
        uint256 newCollateral
    );

    constructor(
        address _weth,
        address _stETH,
        address _astETH,
        uint256 _mlr,
        address _aave,
        address _controller,
        address _vault,
        address _feePool
    ) {
        mlr = _mlr;
        weth = _weth;
        stETH = _stETH;
        astETH = _astETH;
        aave = _aave;

        controller = _controller;
        vault = _vault;
        feePool = _feePool;

        // Block Rate
        blockRate = 4756468797;

        // Set Max Deposit as max uin256
        maxDeposit = type(uint256).max;
    }

    receive() external payable {}

    /**
        Only controller can call
     */
    modifier onlyController() {
        require(controller == _msgSender(), "NOT_CONTROLLER");
        _;
    }

    /**
        Only Flashloan receiver can call
     */
    modifier onlyReceiver() {
        require(receiver == _msgSender(), "NOT_FLASHLOAN_RECEIVER");
        _;
    }

    modifier onDeposit() {
        require(curState == SrategyState.Normal, "REENTERANCY");
        curState = SrategyState.Deposit;
        _;
        curState = SrategyState.Normal;
    }

    modifier onWithdraw() {
        require(curState == SrategyState.Normal, "REENTERANCY");
        curState = SrategyState.Withdraw;
        _;
        curState = SrategyState.Normal;
    }

    modifier onEmergencyWithdraw() {
        require(curState == SrategyState.Normal, "REENTERANCY");
        curState = SrategyState.EmergencyWithdraw;
        _;
        curState = SrategyState.Normal;
    }

    //////////////////////////////////////////
    //           Flash loan Fallback        //
    //////////////////////////////////////////

    /**
        External Function for Callback when to flash loan
     */
    function loanFallback(
        uint256 loanAmt,
        uint256 feeAmt
    ) external override onlyReceiver {
        require(curState != SrategyState.Normal, "NORMAL_STATE_CANT_CALL_THIS");
        require(
            IERC20(weth).balanceOf(address(this)) >= loanAmt,
            "INSUFFICIENT_TRANSFERED"
        );

        if (curState == SrategyState.Deposit) {
            // Withdraw ETH from WETH
            IWeth(weth).withdraw(loanAmt);
            uint256 ethBal = address(this).balance;
            // Transfer ETH to Exchange
            TransferHelper.safeTransferETH(exchange, ethBal);
            // Swap ETH to STETH
            IExchange(exchange).swapStETH(ethBal);

            // Deposit STETH to AAVE
            uint256 stETHBal = IERC20(stETH).balanceOf(address(this));
            IERC20(stETH).approve(aave, 0);
            IERC20(stETH).approve(aave, stETHBal);

            IAave(aave).deposit(stETH, stETHBal, address(this), 0);
            if (getCollateral() == 0) {
                IAave(aave).setUserUseReserveAsCollateral(stETH, true);
            }
            // Repay flash loan
            uint256 repay = loanAmt + feeAmt;
            IAave(aave).borrow(weth, repay, 2, 0, address(this));

            TransferHelper.safeTransfer(weth, receiver, repay);
        } else if (curState == SrategyState.Withdraw) {
            // Withdraw ETH from WETH
            uint256 stETHAmt = (loanAmt *
                IERC20(astETH).balanceOf(address(this))) / getDebt();
            // Approve WETH to AAVE
            IERC20(weth).approve(aave, 0);
            IERC20(weth).approve(aave, loanAmt);

            // Repay WETH to aave
            IAave(aave).repay(weth, loanAmt, 2, address(this));
            IAave(aave).withdraw(stETH, stETHAmt, address(this));

            // Swap STETH to ETH
            TransferHelper.safeTransfer(stETH, exchange, stETHAmt);
            IExchange(exchange).swapETH(stETHAmt);
            // Deposit WETH
            TransferHelper.safeTransferETH(weth, (loanAmt + feeAmt));
            // Repay Weth to receiver
            TransferHelper.safeTransfer(weth, receiver, loanAmt + feeAmt);
        } else if (curState == SrategyState.EmergencyWithdraw) {
            // Withdraw ETH from WETH
            uint256 stETHAmt = (loanAmt *
                IERC20(astETH).balanceOf(address(this))) / getDebt();

            // Approve WETH to AAVE
            IERC20(weth).approve(aave, 0);
            IERC20(weth).approve(aave, loanAmt);

            // Repay WETH to aave
            IAave(aave).repay(weth, loanAmt, 2, address(this));
            IAave(aave).withdraw(stETH, stETHAmt, address(this));

            // Swap STETH to repay flashloan
            IERC20(stETH).approve(exchange, 0);
            IERC20(stETH).approve(exchange, stETHAmt);

            IExchange(exchange).swapExactETH(stETHAmt, loanAmt + feeAmt);
            // Deposit WETH
            TransferHelper.safeTransferETH(weth, (loanAmt + feeAmt));
            // Repay Weth to receiver
            TransferHelper.safeTransfer(weth, receiver, loanAmt + feeAmt);
        } else {
            revert("NOT_A_SS_STATE");
        }
    }

    //////////////////////////////////////////
    //          VIEW FUNCTIONS              //
    //////////////////////////////////////////

    /**
        External view function of total USDC deposited in Covex Booster
     */
    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    /**
        Internal view function of total USDC deposited
    */
    function _totalAssets() internal view returns (uint256) {
        return getCollateral() - getDebt();
    }

    /**
        Deposit function of USDC
     */
    function deposit(
        uint256 _amount
    ) external override onlyController onDeposit returns (uint256) {
        // Harvest Reward First
        _harvest();

        uint256 deposited = _deposit(_amount);
        return deposited;
    }

    /**
        Deposit internal function
     */
    function _deposit(uint256 _amount) internal returns (uint256) {
        // Get Prev Deposit Amt
        uint256 prevAmt = _totalAssets();

        // Check Max Deposit
        require(prevAmt + _amount <= maxDeposit, "EXCEED_MAX_DEPOSIT");

        uint256 ethAmt = address(this).balance;
        require(ethAmt >= _amount, "INSUFFICIENT_ETH_TRANSFER");

        // Calculate Flashloan Fee - in terms of 1e4
        uint256 fee = IFlashloanReceiver(receiver).getFee();
        uint256 feeParam = fee + magnifier;
        uint256 loanAmt = (_amount * mlr) / (feeParam - mlr);
        // uint256 feeAmt = (loanAmt * fee) / magnifier;

        // Execute flash loan
        IFlashloanReceiver(receiver).flashLoan(weth, loanAmt);

        // Get new total assets amount
        uint256 newAmt = _totalAssets();

        // Deposited amt
        uint256 deposited = newAmt - prevAmt;
        uint256 minOutput = (_amount * (magnifier - depositSlippage)) /
            magnifier;

        require(deposited >= minOutput, "DEPOSIT_SLIPPAGE_TOO_BIG");

        return deposited;
    }

    /**
        Withdraw function of USDC
     */
    function withdraw(
        uint256 _amount
    ) external override onlyController onWithdraw returns (uint256) {
        // Harvest Reward First
        _harvest();

        // Get Prev Deposit Amt
        uint256 prevAmt = _totalAssets();
        require(_amount <= prevAmt, "INSUFFICIENT_ASSET");

        uint256 loanAmt = (getDebt() * _amount) / _totalAssets();
        IFlashloanReceiver(receiver).flashLoan(weth, loanAmt);

        uint256 toSend = address(this).balance;
        TransferHelper.safeTransferETH(controller, toSend);

        return toSend;
    }

    /**
        Harvest reward token from convex booster
     */
    function harvest() external onlyOwner {
        _harvest();
    }

    /**
        Internal Harvest Function
     */
    function _harvest() internal {
        if (_totalAssets() == 0) {
            lastEarnBlock = block.number;
            return;
        }

        uint256 collapsed = block.number - lastEarnBlock;

        // If collapsed is zero, return
        if (collapsed <= harvestGap) return;

        uint256 a = (lastTotal * blockRate * collapsed) / 1e18;
        uint256 b = (_totalAssets() * blockRate * collapsed) / 1e18;
        uint256 stFee;
        if (a <= b) {
            stFee = (a + b) / 2;
        } else {
            stFee = b;
        }

        uint256 feePoolBal = IERC20(vault).balanceOf(feePool);
        uint256 totalEF = IERC20(vault).totalSupply();

        if (totalEF == 0) return;

        stFee = stFee - ((stFee * feePoolBal) / (totalEF));

        uint256 mintAmt = (stFee * totalEF) / (_totalAssets() - stFee);

        // Mint EF token to fee pool
        IVault(vault).mint(mintAmt, feePool);

        lastEarnBlock = block.number;
        lastTotal = _totalAssets();
    }

    /**
        Raise LTV
     */
    function raiseLTV(uint256 lt) public onlyOwner {
        uint256 e = getDebt();
        uint256 st = getCollateral();

        require(e * magnifier < st * mlr, "NO_NEED_TO_RAISE");

        uint256 x = (st * mlr - (e * magnifier)) / (magnifier - mlr);
        uint256 y = (st * lt) / magnifier - e - 1;

        if (x > y) {
            x = y;
        }

        IAave(aave).borrow(weth, x, 2, 0, address(this));
        uint256 wethAmt = IERC20(weth).balanceOf(address(this));
        IWeth(weth).withdraw(wethAmt);

        // Transfer ETH to Exchange
        TransferHelper.safeTransferETH(exchange, wethAmt);
        // Swap ETH to STETH
        IExchange(exchange).swapStETH(wethAmt);

        // Deposit STETH to AAVE
        uint256 stETHBal = IERC20(stETH).balanceOf(address(this));
        IERC20(stETH).approve(aave, 0);
        IERC20(stETH).approve(aave, stETHBal);

        IAave(aave).deposit(stETH, stETHBal, address(this), 0);

        emit LTVUpdate(e, st, getDebt(), getCollateral());
    }

    /**
        Reduce LTV
     */
    function reduceLTV() public onlyOwner onWithdraw {
        uint256 e = getDebt();
        uint256 st = getCollateral();

        require(e * magnifier > st * mlr, "NO_NEED_TO_REDUCE");

        uint256 x = (e * magnifier - st * mlr) / (magnifier - mlr);

        uint256 loanAmt = (x * getDebt()) / getCollateral();

        IFlashloanReceiver(receiver).flashLoan(weth, loanAmt);

        uint256 toSend = address(this).balance;
        TransferHelper.safeTransferETH(weth, toSend);

        uint256 wethBal = IERC20(weth).balanceOf(address(this));
        // Approve WETH to AAVE
        IERC20(weth).approve(aave, 0);
        IERC20(weth).approve(aave, wethBal);

        // Repay WETH to aave
        IAave(aave).repay(weth, wethBal, 2, address(this));
    }



    /**
        Check withdrawable status of required amount
     */
    function withdrawable(
        uint256 _amount
    ) external view override returns (uint256) {
        // Get Current Deposit Amt
        uint256 total = _totalAssets();

        // If requested amt is bigger than total asset, return false
        if (_amount > total) return total;
        // Todo Have to check withdrawable amount
        else return _amount;
    }



    function getCollateral() public view returns (uint256) {
        (uint256 c, , , , , ) = IAave(aave).getUserAccountData(address(this));
        return c;
    }

    function getDebt() public view returns (uint256) {
        //decimal 18
        (, uint256 d, , , , ) = IAave(aave).getUserAccountData(address(this));
        return d;
    }

    //////////////////////////////////////////////////
    //               SET CONFIGURATION              //
    //////////////////////////////////////////////////

    /**
        Set Controller
     */
    function setController(address _controller) public onlyOwner {
        require(_controller != address(0), "INVALID_ADDRESS");
        controller = _controller;

        emit SetController(controller);
    }

    /**
        Set Vault
     */
    function setVault(address _vault) public onlyOwner {
        require(_vault != address(0), "INVALID_ADDRESS");
        vault = _vault;

        emit SetVault(vault);
    }

    /**
        Set Fee Pool
     */
    function setFeePool(address _feePool) public onlyOwner {
        require(_feePool != address(0), "INVALID_ADDRESS");
        feePool = _feePool;

        emit SetController(feePool);
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
        Set Flashloan Receiver
     */
    function setFlashLoanReceiver(address _receiver) public onlyOwner {
        require(_receiver != address(0), "INVALID_RECEIVER_ADDRESS");
        receiver = _receiver;

        emit SetFlashloanReceiver(receiver);
    }

    /**
        Set Exchange
     */
    function setExchange(address _exchange) public onlyOwner {
        require(_exchange != address(0), "INVALID_ADDRESS");
        exchange = _exchange;

        emit SetExchange(exchange);
    }

    /**
        Set Block Rate
     */
    function setBlockRate(uint256 _rate) public onlyOwner {
        require(_rate > 0, "INVALID_RATE");

        uint256 oldRate = blockRate;
        blockRate = _rate;

        emit SetBlockRate(oldRate, _rate);
    }

    /**
        Set MLR
     */
    function setMLR(uint256 _mlr) public onlyOwner {
        require(_mlr > 0 && _mlr < magnifier, "INVALID_RATE");

        uint256 oldMlr = mlr;
        mlr = _mlr;

        emit SetMLR(oldMlr, _mlr);
    }
}