// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IWeth.sol";
import "./interfaces/IAave.sol";
import "./interfaces/IAavePriceOracle.sol";
import "./interfaces/IEthLeverage.sol";
import "./interfaces/IUniswapV3Router.sol";
import "../interfaces/ISubStrategy.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IRouter.sol";
import "../utils/TransferHelper.sol";

contract WBTCBorrowETH is OwnableUpgradeable, ISubStrategy {
    using SafeMath for uint256;

    // Sub Strategy name
    string public constant poolName = "WBTC_Borrow_ETH V3";

    // Controller address
    address public controller;

    // Vault address
    address public vault;

    // ETH Leverage address
    address public ethLeverage;

    // UniV3 Router address
    address public univ3Router;

    // UniV3 Fee
    uint24 public univ3Fee;

    // Price oracle address
    address public priceOracle;

    // Constant magnifier
    uint256 public constant magnifier = 10000;

    // Harvest Gap
    uint256 public override harvestGap;

    // Latest Harvest
    uint256 public override latestHarvest;

    // WETH Address
    address public weth;

    // AWBTC Address
    address public awbtc;

    // WBTC Address
    address public wbtc;

    // aave address
    address public aave;

    // Slippages for deposit and withdraw
    uint256 public depositSlippage;

    uint256 public withdrawSlippage;

    uint256 public leverageSlippage;

    uint256 public swapSlippage;

    // Max Deposit
    uint256 public override maxDeposit;

    // Last Earn Block
    uint256 public lastEarnBlock;

    // Max Loan Ratio
    uint256 public mlr;

    // WBTC decimal
    uint256 public constant wbtcDecimal = 1e8;

    // ETH decimal
    uint256 public constant ethDecimal = 1e18;

    // Fee Ratio
    uint256 public feeRatio;

    // Fee Collector
    address public feePool;

    event OwnerDeposit(uint256 lpAmount);

    event EmergencyWithdraw(uint256 amount);

    event SetController(address controller);

    event SetVault(address vault);

    event SetSwapInfo(address router, uint24 fee);

    event SetDepositSlippage(uint256 depositSlippage);

    event SetWithdrawSlippage(uint256 withdrawSlippage);

    event SetSwapSlippage(uint256 swapSlippage);

    event SetLeverageSlippage(uint256 leverageSlippage);

    event SetHarvestGap(uint256 harvestGap);

    event SetMaxDeposit(uint256 maxDeposit);

    event SetMLR(uint256 oldMlr, uint256 newMlr);

    event LTVUpdate(uint256 oldDebt, uint256 oldCollateral, uint256 newDebt, uint256 newCollateral);

    function initialize(
        address _wbtc,
        address _awbtc,
        address _weth,
        uint256 _mlr,
        address _aave,
        address _vault,
        address _controller,
        address _priceOracle,
        address _ethLeverage,
        address _feePool,
        uint256 _feeRatio
    ) public initializer {
        __Ownable_init();

        mlr = _mlr;
        wbtc = _wbtc;
        awbtc = _awbtc;
        weth = _weth;
        aave = _aave;

        vault = _vault;
        controller = _controller;
        priceOracle = _priceOracle;
        ethLeverage = _ethLeverage;

        feePool = _feePool;
        feeRatio = _feeRatio;

        // Set Max Deposit as max uin256
        maxDeposit = type(uint256).max;

        leverageSlippage = 100;

        swapSlippage = 200;
    }

    receive() external payable {}

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
        External view function of total WBTC deposited in Covex Booster
     */
    function totalAssets(bool fetch) external view override returns (uint256) {
        return _totalAssets();
    }

    /**
        Internal view function of total WBTC deposited
    */
    function _totalAssets() internal view returns (uint256) {
        uint256 ethBal = getCollateral() - getDebt() + _totalETH();
        uint256 price = IAavePriceOracle(priceOracle).getAssetPrice(wbtc);

        return (ethBal * 1e8) / price;
    }

    /**
        Internal view function of total WBTC collateralized
    */
    function _collateralInWBTC() internal view returns (uint256) {
        uint256 price = IAavePriceOracle(priceOracle).getAssetPrice(wbtc);

        return (getCollateral() * 1e8) / price;
    }

    /**
        Internal view function of total ETH assets
     */
    function _totalETH() internal view returns (uint256) {
        uint256 lpBal = IERC20(ethLeverage).balanceOf(address(this));
        uint256 totalETH = IEthLeverage(ethLeverage).convertToAssets(lpBal);

        return totalETH;
    }

    /**
        Deposit function of WBTC
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
        uint256 prevAmt = _totalAssets();

        // Check Max Deposit
        require(prevAmt + _amount <= maxDeposit, "EXCEED_MAX_DEPOSIT");

        uint256 wbtcAmt = IERC20(wbtc).balanceOf(address(this));
        require(wbtcAmt >= _amount, "INSUFFICIENT_ETH_TRANSFER");

        // Get WBTC Collateral
        uint256 wbtcCol = getCollateral();

        // Deposit WBTC
        IERC20(wbtc).approve(aave, 0);
        IERC20(wbtc).approve(aave, _amount);
        IAave(aave).deposit(wbtc, _amount, address(this), 0);

        if (getCollateral() == 0) {
            IAave(aave).setUserUseReserveAsCollateral(wbtc, true);
        }

        // Calculate ETH amount to borrow
        uint256 ethToBorrow;
        uint256 price = IAavePriceOracle(priceOracle).getAssetPrice(wbtc);
        if (wbtcCol == 0) {
            ethToBorrow = (price * mlr * wbtcAmt) / magnifier / wbtcDecimal;
        } else {
            uint256 ethDebt = getDebt();
            ethToBorrow = (ethDebt * wbtcAmt * price) / wbtcCol / wbtcDecimal;
        }

        // Borrow ETH from AAVE
        IAave(aave).borrow(weth, ethToBorrow, 2, 0, address(this));

        uint256 ethAmt = IERC20(weth).balanceOf(address(this));
        IWeth(weth).withdraw(ethAmt);

        // Deposit to ETH Leverage SS
        IEthLeverage(ethLeverage).deposit{value: ethAmt}(ethAmt, address(this));

        // Get new total assets amount
        uint256 newAmt = _totalAssets();

        // Deposited amt
        uint256 deposited = newAmt - prevAmt;
        uint256 minOutput = (_amount * (magnifier - depositSlippage)) / magnifier;

        require(deposited >= minOutput, "DEPOSIT_SLIPPAGE_TOO_BIG");

        return deposited;
    }

    /**
        Withdraw function of WBTC
     */
    function withdraw(uint256 _amount) external override onlyController returns (uint256) {
        uint256 withdrawn = _withdraw(_amount);
        return withdrawn;
    }

    function _withdraw(uint256 _amount) internal returns (uint256) {
        // Get Prev Deposit Amt
        uint256 prevAmt = _totalAssets();
        require(_amount <= prevAmt, "INSUFFICIENT_ASSET");

        // Calculate how much eth to be withdrawn from Leverage SS
        uint256 ethWithdraw = (_totalETH() * _amount) / prevAmt;

        uint256 ethBefore = address(this).balance;

        // Withdraw ETH from ETH Leverage
        IEthLeverage(ethLeverage).withdraw(ethWithdraw, address(this));

        uint256 ethWithdrawn = address(this).balance - ethBefore;

        // Withdraw WBTC from AAVE
        uint256 ethDebt = (getDebt() * _amount) / _collateralInWBTC();

        uint256 wbtcToWithdraw;
        if (ethWithdrawn >= ethDebt) {
            wbtcToWithdraw = _amount;
            _swapExactInput(weth, wbtc, ethWithdrawn - ethDebt);
        } else {
            // Calculate how much WBTC to withdraw to compensate extra ETH
            uint256 price = IAavePriceOracle(priceOracle).getAssetPrice(wbtc);
            uint256 wbtcToSwap = ((((ethDebt - ethWithdrawn) * 1e8) / price) * (magnifier + swapSlippage)) / magnifier;
            require((wbtcToSwap * magnifier) / _amount < withdrawSlippage, "WITHDRAW_SLIPPAGE_EXCEED");

            // Withdraw WBTC
            uint256 amtBefore = IERC20(wbtc).balanceOf(address(this));
            IAave(aave).withdraw(wbtc, wbtcToSwap, address(this));
            uint256 wbtcAmt = IERC20(wbtc).balanceOf(address(this)) - amtBefore;

            // Swap WBTC to ETH
            _swapExactOutput(wbtc, weth, ethDebt - ethWithdrawn, wbtcAmt);

            wbtcToWithdraw = _amount - wbtcToSwap;

            // Check ETH is enough
            uint256 ethBal = address(this).balance;
            require(ethBal >= ethDebt, "INSUFFICIENT_ETH_SWAPPED");

            if (ethBal > ethDebt) _swapExactInput(weth, wbtc, ethBal - ethDebt);
        }

        // Deposit WETH
        TransferHelper.safeTransferETH(weth, ethDebt);
        // Approve WETH
        IERC20(weth).approve(aave, 0);
        IERC20(weth).approve(aave, ethDebt);

        // Repay ETH to AAVE
        IAave(aave).repay(weth, ethDebt, 2, address(this));

        IAave(aave).withdraw(wbtc, wbtcToWithdraw, address(this));

        uint256 withdrawn = IERC20(wbtc).balanceOf(address(this));

        uint256 minOutput = (_amount * (magnifier - withdrawSlippage)) / magnifier;

        require(withdrawn >= minOutput, "WITHDRAW_SLIPPAGE_TOO_BIG");

        TransferHelper.safeTransferToken(wbtc, controller, withdrawn);

        return withdrawn;
    }

    function _swapExactInput(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(univ3Router != address(0), "ROUTER_NOT_SET");

        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
            tokenIn: _from,
            tokenOut: _to,
            fee: univ3Fee,
            recipient: address(this),
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 output;

        // If fromToken is weth, no need to approve
        if (_from != weth) {
            // Approve token
            IERC20(_from).approve(univ3Router, 0);
            IERC20(_from).approve(univ3Router, _amount);
            output = IUniswapV3Router(univ3Router).exactInputSingle(params);
        } else {
            output = IUniswapV3Router(univ3Router).exactInputSingle{value: _amount}(params);
        }

        if (_to == weth) {
            uint256 wad = IERC20(weth).balanceOf(address(this));
            IWeth(weth).withdraw(wad);
        }
    }

    function _swapExactOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _amountInMax
    ) internal {
        require(univ3Router != address(0), "ROUTER_NOT_SET");

        IUniswapV3Router.ExactOutputSingleParams memory params = IUniswapV3Router.ExactOutputSingleParams({
            tokenIn: _from,
            tokenOut: _to,
            fee: univ3Fee,
            recipient: address(this),
            amountOut: _amountOut,
            amountInMaximum: _amountInMax,
            sqrtPriceLimitX96: 0
        });
        uint256 output;

        // If fromToken is weth, no need to approve
        if (_from != weth) {
            // Approve token
            IERC20(_from).approve(univ3Router, 0);
            IERC20(_from).approve(univ3Router, _amountInMax);
            output = IUniswapV3Router(univ3Router).exactOutputSingle(params);
        } else {
            output = IUniswapV3Router(univ3Router).exactOutputSingle{value: _amountInMax}(params);
        }

        if (_to == weth) {
            uint256 wad = IERC20(weth).balanceOf(address(this));
            IWeth(weth).withdraw(wad);
        }
    }

    function getBalance(address _asset, address _account) internal view returns (uint256) {
        if (address(_asset) == address(0) || address(_asset) == weth) return address(_account).balance;
        else return IERC20(_asset).balanceOf(_account);
    }

    /**
        Harvest reward
     */
    function harvest() external override onlyOwner {
        // Get ETH Debt
        uint256 ethDebt = getDebt();
        // // For testing
        // uint256 ethDebt = 0;
        // Get ETH Current balance
        uint256 ethAsset = _totalETH();

        require(ethAsset > ethDebt, "NOTHING_TO_HARVEST");
        uint256 feeAmt = ((ethAsset - ethDebt) * feeRatio) / magnifier;

        uint256 feePoolBal = IERC20(vault).balanceOf(feePool);
        uint256 totalEF = IERC20(vault).totalSupply();

        if (totalEF == 0) return;

        feeAmt = feeAmt - ((feeAmt * feePoolBal) / (totalEF));

        uint256 mintAmt = (feeAmt * totalEF) / (ethAsset - feeAmt);
        // Mint EF token to fee pool
        IVault(vault).mint(mintAmt, feePool);
    }

    /**
        Raise LTV
     */
    function raiseLTV() public onlyOwner {
        uint256 e = getDebt();
        uint256 st = getCollateral();

        require(e * magnifier < st * mlr, "NO_NEED_TO_RAISE");

        uint256 x = (st * mlr) / magnifier - e;

        IAave(aave).borrow(weth, x, 2, 0, address(this));
        uint256 wethAmt = IERC20(weth).balanceOf(address(this));
        IWeth(weth).withdraw(wethAmt);

        IEthLeverage(ethLeverage).deposit{value: wethAmt}(wethAmt, address(this));

        // Deposit ETH to ETH Leverage

        emit LTVUpdate(e, st, getDebt(), getCollateral());
    }

    /**
        Reduce LTV
     */
    function reduceLTV() public onlyOwner {
        uint256 e = getDebt();
        uint256 st = getCollateral();

        require(e * magnifier > st * mlr, "NO_NEED_TO_REDUCE");

        uint256 x = (e - (mlr * st) / magnifier);
        uint256 toWithdraw = (x * magnifier) / (magnifier - leverageSlippage);

        // Withdraw ETH from Leverage
        IEthLeverage(ethLeverage).withdraw(toWithdraw, address(this));
        uint256 ethBal = address(this).balance;
        require(ethBal >= x, "ETH withdrawn not enough");

        // Deposit exceed ETH
        IEthLeverage(ethLeverage).deposit{value: ethBal - x}(ethBal - x, address(this));

        TransferHelper.safeTransferETH(weth, x);

        // Approve WETH to AAVE
        IERC20(weth).approve(aave, 0);
        IERC20(weth).approve(aave, x);

        // Repay WETH to aave
        IAave(aave).repay(weth, x, 2, address(this));
    }

    /**
        Emergency Withdraw 
     */
    function emergencyWithdraw() public onlyOwner {
        uint256 total = _collateralInWBTC();
        if (total == 0) return;

        IEthLeverage(ethLeverage).withdraw(_totalETH(), address(this));
        uint256 ethWithdrawn = address(this).balance;

        // Repay ETH
        uint256 totalDebt = getDebt();

        if (totalDebt == 0) {
            TransferHelper.safeTransferETH(owner(), ethWithdrawn);
            return;
        }

        uint256 ethToRepay;
        if (ethWithdrawn >= totalDebt) {
            ethToRepay = totalDebt;
            _swapExactInput(weth, wbtc, ethWithdrawn - ethToRepay);
        } else {
            ethToRepay = ethWithdrawn;
        }

        // Deposit WETH
        TransferHelper.safeTransferETH(weth, ethToRepay);
        // Approve WETH
        IERC20(weth).approve(aave, 0);
        IERC20(weth).approve(aave, ethToRepay);

        // Repay ETH to AAVE
        IAave(aave).repay(weth, ethToRepay, 2, address(this));

        // Withdraw WBTC
        uint256 amount = (total * ethToRepay) / totalDebt;

        IAave(aave).withdraw(wbtc, amount, address(this));

        uint256 wbtcAmt = IERC20(wbtc).balanceOf(address(this));
        TransferHelper.safeTransfer(wbtc, owner(), wbtcAmt);

        emit EmergencyWithdraw(total);
    }

    /**
        Check withdrawable status of required amount
     */
    function withdrawable(uint256 _amount) external view override returns (uint256) {
        // Get Current Deposit Amt
        uint256 total = _totalAssets();

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
        TransferHelper.safeTransferFrom(wbtc, owner(), address(this), _amount);

        _deposit(_amount);

        emit OwnerDeposit(_amount);
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
        Set Swap Slipage
     */
    function setSwapSlippage(uint256 _slippage) public onlyOwner {
        require(_slippage < magnifier, "INVALID_SLIPPAGE");

        swapSlippage = _slippage;

        emit SetSwapSlippage(swapSlippage);
    }

    /**
        Set Leverage Withdraw Slipage
     */
    function setLeverageSlippage(uint256 _slippage) public onlyOwner {
        require(_slippage < magnifier, "INVALID_SLIPPAGE");

        swapSlippage = _slippage;

        emit SetSwapSlippage(swapSlippage);
    }

    /**
        Set Swap Info
     */
    function setSwapInfo(address _univ3Router, uint24 _univ3Fee) public onlyOwner {
        require(_univ3Router != address(0), "INVALID_ADDRESS");

        univ3Router = _univ3Router;
        univ3Fee = _univ3Fee;

        emit SetSwapInfo(univ3Router, univ3Fee);
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
        Set MLR
     */
    function setMLR(uint256 _mlr) public onlyOwner {
        require(_mlr > 0 && _mlr < magnifier, "INVALID_RATE");

        uint256 oldMlr = mlr;
        mlr = _mlr;

        emit SetMLR(oldMlr, _mlr);
    }
}