// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/ISubStrategy.sol";
import "../../interfaces/IController.sol";
import "../../utils/TransferHelper.sol";
import "./interfaces/INotionalProxy.sol";
import "./interfaces/INeth.sol";

contract CEth is OwnableUpgradeable, ISubStrategy {
    using SafeMath for uint256;

    // Sub Strategy name
    string public constant poolName = "CETH V3";

    // Controller address
    address public controller;

    // decimal
    uint256 public constant decimal = 1e18;

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

    // nETH address
    address public nETH;

    // ETH Currency ID
    uint16 public currencyId;

    // Max Deposit
    uint256 public override maxDeposit;

    event OwnerDeposit(uint256 lpAmount);

    event EmergencyWithdraw(uint256 amount);

    event SetController(address controller);

    event SetDepositSlippage(uint256 depositSlippage);

    event SetWithdrawSlippage(uint256 withdrawSlippage);

    event SetHarvestGap(uint256 harvestGap);

    event SetMaxDeposit(uint256 maxDeposit);

    function initialize(
        address _controller,
        address _notionalProxy,
        address _note,
        address _nETH,
        uint16 _currencyId
    ) public initializer {
        __Ownable_init();
        controller = _controller;
        notionalProxy = _notionalProxy;
        note = _note;
        nETH = _nETH;
        currencyId = _currencyId;

        // Set Max Deposit as max uin256
        maxDeposit = type(uint256).max;

        noteDecimal = 1e8;
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
        return _totalAssets();
    }

    /**
        Internal view function of total ETH deposited
    */
    function _totalAssets() internal view returns (uint256) {
        uint256 nTokenBal = IERC20(nETH).balanceOf(address(this));

        uint256 nTokenTotal = IERC20(nETH).totalSupply();

        int256 underlyingDenominated = INeth(nETH).getPresentValueUnderlyingDenominated();

        if (underlyingDenominated < 0) return 0;
        else return ((nTokenBal * uint256(underlyingDenominated)) * decimal) / noteDecimal / nTokenTotal;
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
        uint256 prevAmt = _totalAssets();
        console.log("Total: ", prevAmt);

        // Check Max Deposit
        require(prevAmt + _amount <= maxDeposit, "EXCEED_MAX_DEPOSIT");

        // Check whether transferred sufficient eth from controller
        require(address(this).balance >= _amount, "INSUFFICIENT_ETH_TRANSFER");

        // Make Balance Action
        BalanceAction[] memory actions = new BalanceAction[](1);
        actions[0] = BalanceAction({
            actionType: DepositActionType.DepositUnderlyingAndMintNToken,
            currencyId: currencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: false,
            redeemToUnderlying: false
        });

        // Calls batch balance action
        INotionalProxy(notionalProxy).batchBalanceAction{value: _amount}(address(this), actions);

        // Get new total assets amount
        uint256 newAmt = _totalAssets();
        console.log("New Amt: ", newAmt);
        // Deposited amt
        uint256 deposited = newAmt - prevAmt;
        uint256 minOutput = (_amount * (magnifier - depositSlippage)) / magnifier;

        require(deposited >= minOutput, "DEPOSIT_SLIPPAGE_TOO_BIG");

        return deposited;
    }

    /**
        Withdraw function of ETH
     */
    function withdraw(uint256 _amount) external override onlyController returns (uint256) {
        // Get Current Deposit Amt
        uint256 total = _totalAssets();
        uint256 totalLP = IERC20(nETH).balanceOf(address(this));
        uint256 lpAmt = (totalLP * _amount) / total;
        console.log("LP Amt: ", lpAmt);
        // Withdraw nETH
        _withdraw(lpAmt);
        // Transfer withdrawn ETH to controller
        uint256 asset = address(this).balance;
        console.log("ETH: ", asset);

        // Deposited amt
        uint256 withdrawn = asset;
        uint256 minOutput = (_amount * (magnifier - withdrawSlippage)) / magnifier;

        require(withdrawn >= minOutput, "WITHDRAW_SLIPPAGE_TOO_BIG");

        // Transfer ETH to Controller
        TransferHelper.safeTransferETH(controller, asset);

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
    }

    /**
        Harvest reward token from convex booster
     */
    function harvest() external override onlyController {
        // Call incentive earning
        INotionalProxy(notionalProxy).nTokenClaimIncentives();

        uint256 harvestFee = IController(controller).harvestFee();
        address vault = IController(controller).vault();
        address treasury = IController(controller).treasury();

        // Transfer Reward tokens to controller
        uint256 noteBal = IERC20(note).balanceOf(address(this));

        if (noteBal == 0) return;

        TransferHelper.safeTransfer(note, treasury, (noteBal * harvestFee) / magnifier);
        TransferHelper.safeTransfer(note, vault, (noteBal * (magnifier - harvestFee)) / magnifier);

        // Update latest block timestamp
        latestHarvest = block.timestamp;
    }

    /**
        Emergency Withdraw LP token from convex booster and send to owner
     */
    function emergencyWithdraw() public onlyOwner {
        uint256 totalLP = IERC20(nETH).balanceOf(address(this));
        // If totalLP is zero, return
        if (totalLP == 0) return;

        _withdraw(totalLP);
        // Transfer withdrawn ETH to controller
        uint256 asset = address(this).balance;
        TransferHelper.safeTransferETH(owner(), asset);

        // Emit Event
        emit EmergencyWithdraw(totalLP);
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
}