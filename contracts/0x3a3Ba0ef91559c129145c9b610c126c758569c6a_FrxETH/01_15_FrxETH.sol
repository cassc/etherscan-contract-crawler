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
import "./interfaces/ICurveFrx.sol";
import "./interfaces/IFrxMinter.sol";
import "./interfaces/ISfrx.sol";

contract FrxETH is OwnableUpgradeable, ISubStrategy {
    using SafeMath for uint256;

    // Sub Strategy name
    string public constant poolName = "CETH V3";

    // Controller address
    address public controller;

    // Curve Pool address
    address public curveFrx;

    // FrxEth token
    address public frxEth;

    // Weth address
    address public weth;

    // Frx Minter
    address public frxMinter;

    // sFrx address
    address public sFrx;

    // decimal
    uint256 public constant decimal = 1e18;

    // Slippage for Frx-ETH
    uint256 public slippage;

    // Slippages for deposit and withdraw
    uint256 public depositSlippage;
    uint256 public withdrawSlippage;

    // Constant magnifier
    uint256 public constant magnifier = 10000;

    // Harvest Gap
    uint256 public override harvestGap;

    // Latest Harvest
    uint256 public override latestHarvest;

    // Max Deposit
    uint256 public override maxDeposit;

    // Swap router
    address[] public swapFromRouters;
    address[] public swapToRouters;

    // Swap indexes
    bytes32[] public swapFromIndexes;
    bytes32[] public swapToIndexes;

    // Exchange address
    address public exchange;

    // Last Earn Price
    uint256 public lastEarnPrice;

    event OwnerDeposit(uint256 lpAmount);

    event EmergencyWithdraw(uint256 amount);

    event SetController(address controller);

    event SetDepositSlippage(uint256 depositSlippage);

    event SetWithdrawSlippage(uint256 withdrawSlippage);

    event SetHarvestGap(uint256 harvestGap);

    event SetMaxDeposit(uint256 maxDeposit);

    event SetExchange(address exchange);

    function initialize(
        address _controller,
        address _curveFrx,
        address _frxEth,
        address _sFrx,
        address _frxMinter,
        address _weth
    ) public initializer {
        __Ownable_init();
        controller = _controller;
        curveFrx = _curveFrx;

        frxEth = _frxEth;
        weth = _weth;
        frxMinter = _frxMinter;
        sFrx = _sFrx;

        // Set Max Deposit as max uin256
        maxDeposit = type(uint256).max;

        slippage = 100;
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
        External view function of total ETH deposited in Covex Booster
     */
    function totalAssets(bool fetch) external view override returns (uint256) {
        return _totalAssets(fetch);
    }

    /**
        Internal view function of total ETH deposited
    */
    function _totalAssets(bool fetch) internal view returns (uint256) {
        uint256 totalSupply = ISfrx(sFrx).totalSupply();
        uint256 sFrxTotal = ISfrx(sFrx).totalAssets();
        uint256 sFrxBal = IERC20(sFrx).balanceOf(address(this));

        uint256 frxBal = (sFrxBal * sFrxTotal) / totalSupply;

        if (frxBal == 0) return 0;

        uint256 ethBal = ICurveFrx(curveFrx).get_dy(1, 0, frxBal);

        if (!fetch) {
            require(
                ethBal < ((magnifier + slippage) * frxBal) / magnifier &&
                    ethBal > ((magnifier - slippage) * frxBal) / magnifier,
                "SLIPPAGE_TOO_BIG"
            );
        }
        return ethBal;
    }

    /**
        Deposit function of ETH
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

        // Check whether transferred sufficient eth from controller
        require(address(this).balance >= _amount, "INSUFFICIENT_ETH_TRANSFER");

        // Swap ETH to FrxETH
        uint256 curveExpect = ICurveFrx(curveFrx).get_dy(0, 1, _amount);
        if (curveExpect <= _amount) {
            IFrxMinter(frxMinter).submit{value: _amount}();
        } else {
            _swap(swapFromRouters, swapFromIndexes);
        }

        // Get FrxEth amount
        uint256 frxBal = IERC20(frxEth).balanceOf(address(this));

        IERC20(frxEth).approve(sFrx, 0);
        IERC20(frxEth).approve(sFrx, frxBal);

        // Stake Frx
        ISfrx(sFrx).deposit(frxBal, address(this));

        // Get new total assets amount
        uint256 newAmt = _totalAssets(false);
        // Deposited amt
        uint256 deposited = newAmt - prevAmt;
        uint256 minOutput = (_amount * (magnifier - depositSlippage)) / magnifier;

        require(deposited >= minOutput, "DEPOSIT_SLIPPAGE_TOO_BIG");

        if (lastEarnPrice == 0) lastEarnPrice = (ISfrx(sFrx).totalAssets() * 1e18) / ISfrx(sFrx).totalSupply();

        return deposited;
    }

    function getBalance(address token, address account) internal view returns (uint256) {
        // Asset is zero address when it is ether
        if (address(token) == address(0) || address(token) == address(weth)) return address(account).balance;
        else return IERC20(token).balanceOf(account);
    }

    function _swap(address[] memory _swapRouters, bytes32[] memory _swapIndexes) internal {
        require(exchange != address(0), "EXCHANGE_NOT_SET");

        // Swap fromToken to toToken for deposit
        for (uint256 i = 0; i < _swapIndexes.length; i++) {
            // If index of path is not registered, revert it
            require(_swapIndexes[i] != 0, "NON_REGISTERED_PATH");

            // Get fromToken Address
            address fromToken = IRouter(_swapRouters[i]).pathFrom(_swapIndexes[i]);
            // Get toToken Address
            address toToken = IRouter(_swapRouters[i]).pathTo(_swapIndexes[i]);

            uint256 amount = getBalance(address(fromToken), address(this));

            if (amount == 0) continue;

            if (fromToken == weth) {
                IExchange(exchange).swapExactETHInput{value: amount}(toToken, _swapRouters[i], _swapIndexes[i], amount);
            } else {
                // Approve fromToken to Exchange
                IERC20(fromToken).approve(exchange, 0);
                IERC20(fromToken).approve(exchange, amount);

                // Call Swap on exchange
                IExchange(exchange).swapExactTokenInput(fromToken, toToken, _swapRouters[i], _swapIndexes[i], amount);
            }
        }
    }

    /**
        Withdraw function of ETH
     */
    function withdraw(uint256 _amount) external override onlyController returns (uint256) {
        uint256 total = _totalAssets(false);
        uint256 sFrxAmt = IERC20(sFrx).balanceOf(address(this));
        uint256 sFrxToWithdraw = (sFrxAmt * _amount) / total;

        uint256 asset = _withdraw(sFrxToWithdraw);

        uint256 minOutput = (_amount * (magnifier - withdrawSlippage)) / magnifier;

        require(asset >= minOutput, "WITHDRAW_SLIPPAGE_TOO_BIG");

        // Transfer ETH to Controller
        TransferHelper.safeTransferETH(controller, asset);

        return asset;
    }

    function _withdraw(uint256 amount) internal returns (uint256 asset) {
        // Redeem Frx from sFrx
        ISfrx(sFrx).redeem(amount, address(this), address(this));

        // Swap Frx to ETH
        _swap(swapToRouters, swapToIndexes);

        asset = address(this).balance;
    }

    /**
        Harvest reward token from convex booster
     */
    function harvest() external override onlyController {
        uint256 currentPrice = (ISfrx(sFrx).totalAssets() * 1e18) / ISfrx(sFrx).totalSupply();
        require(currentPrice > lastEarnPrice, "PRICE_DUMPED");

        uint256 sFrxBal = IERC20(sFrx).balanceOf(address(this));
        uint256 redeemAmt = ((currentPrice - lastEarnPrice) * sFrxBal) / 1e18;

        uint256 asset = _withdraw(redeemAmt);
        TransferHelper.safeTransferETH(controller, asset);
        latestHarvest = block.timestamp;

        currentPrice = (ISfrx(sFrx).totalAssets() * 1e18) / ISfrx(sFrx).totalSupply();

        lastEarnPrice = currentPrice;
    }

    /**
        Emergency Withdraw LP token and send to owner
     */
    function emergencyWithdraw() public onlyOwner {
        uint256 sFrxAmt = IERC20(sFrx).balanceOf(address(this));

        if (sFrxAmt == 0) return;

        ISfrx(sFrx).redeem(sFrxAmt, address(this), address(this));

        uint256 frxAmt = IERC20(frxEth).balanceOf(address(this));

        TransferHelper.safeTransfer(frxEth, owner(), frxAmt);

        emit EmergencyWithdraw(sFrxAmt);
    }

    /**
        Check withdrawable status of required amount
     */
    function withdrawable(uint256 _amount) external view override returns (uint256) {
        // Withdraw from SFRX is 1:1, so withrawable amt is only dependant on Curve slippage
        uint256 total = _totalAssets(false);
        if (_amount > total) return total;
        else {
            uint256 out = ICurveFrx(curveFrx).get_dy(1, 0, _amount);
            return out;
        }
    }

    /**
        Deposit by owner not issueing any ENF token
     */
    function ownerDeposit(uint256 _amount) public payable onlyOwner {
        require(_amount == msg.value, "INSUFFICIENT_ETH");
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
        Set exchange address
     */
    function setExchange(address _exchange) public onlyOwner {
        require(_exchange != address(0), "ZERO_ADDRESS");
        exchange = _exchange;

        emit SetExchange(exchange);
    }

    /**
        Set path
     */
    function setSwapPath(
        address[] memory _swapFromRouters,
        address[] memory _swapToRouters,
        bytes32[] memory _swapFromIndexes,
        bytes32[] memory _swapToIndexes
    ) public onlyOwner {
        require(
            _swapFromRouters.length == _swapFromIndexes.length && _swapToRouters.length == _swapToIndexes.length,
            "MISMATCHING_LENGTH"
        );

        swapFromRouters = _swapFromRouters;
        swapFromIndexes = _swapFromIndexes;

        swapToRouters = _swapToRouters;
        swapToIndexes = _swapToIndexes;
    }
}