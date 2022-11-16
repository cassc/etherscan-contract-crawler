// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/ISubStrategy.sol";
import "../../utils/TransferHelper.sol";
import "./interfaces/ICurvePoolAave.sol";
import "./interfaces/IConvexBooster.sol";
import "./interfaces/IConvexReward.sol";
import "./interfaces/IPrice.sol";

contract Aave is OwnableUpgradeable, ISubStrategy {
    using SafeMath for uint256;

    // Sub Strategy name
    string public constant poolName = "AAVE V3";

    // Curve Pool Address
    address public curvePool;

    // Curve LP token address
    address public lpToken;

    // Controller address
    address public controller;

    // USDC token address
    address public usdc;

    // Convex Booster address
    address public convex;

    // Pool Id of convex
    uint256 public pId;

    // Slippages for deposit and withdraw
    uint256 public depositSlippage;
    uint256 public withdrawSlippage;

    // Constant magnifier
    uint256 public constant magnifier = 10000;

    // Total LP token deposit to convex booster
    uint256 public totalLP;

    // USDC token id for withdraw in curve pool
    int128 public constant tokenId = 1;

    // Harvest Gap
    uint256 public override harvestGap;

    // Latest Harvest
    uint256 public override latestHarvest;

    // Reward Token list
    address[] public rewardTokens;

    // Max Deposit
    uint256 public override maxDeposit;

    uint256 public constant virtualPriceMag = 1e30;

    event OwnerDeposit(uint256 lpAmount);

    event EmergencyWithdraw(uint256 amount);

    event SetController(address controller);

    event SetDepositSlippage(uint256 depositSlippage);

    event SetWithdrawSlippage(uint256 withdrawSlippage);

    event SetPoolId(uint256 pId);

    event SetLPToken(address lpToken);

    event SetCurvePool(address curvePool);

    event SetHarvestGap(uint256 harvestGap);

    event SetMaxDeposit(uint256 maxDeposit);

    event AddRewardToken(address rewardToken);

    event RemoveRewardToken(address rewardToken);

    function initialize(
        address _curvePool,
        address _lpToken,
        address _controller,
        address _usdc,
        address _convex,
        uint256 _pId
    ) public initializer {
        __Ownable_init();
        curvePool = _curvePool;
        lpToken = _lpToken;
        controller = _controller;
        usdc = _usdc;
        convex = _convex;
        pId = _pId;

        // Set Max Deposit as max uin256
        maxDeposit = type(uint256).max;
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
        return _totalAssets();
    }

    function getVirtualPrice() public view returns (uint256) {
        return IPrice(curvePool).get_virtual_price();
    }

    /**
        Internal view function of total USDC deposited
    */
    function _totalAssets() internal view returns (uint256) {
        if (totalLP == 0) return 0;
        // uint256 assets = ICurvePoolAave(curvePool).calc_withdraw_one_coin(totalLP, tokenId);
        uint256 assets = (totalLP * IPrice(curvePool).get_virtual_price()) / virtualPriceMag;
        return assets;
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
        uint256 prevAmt = _totalAssets();

        // Check Max Deposit
        require(prevAmt + _amount <= maxDeposit, "EXCEED_MAX_DEPOSIT");

        // Check whether transferred sufficient usdc from controller
        require(IERC20(usdc).balanceOf(address(this)) >= _amount, "INSUFFICIENT_USDC_TRANSFER");

        // Approve USDC to curve pool
        IERC20(usdc).approve(curvePool, 0);
        IERC20(usdc).approve(curvePool, _amount);

        // Calculate LP output expect to avoid front running
        // uint256[3] memory amounts = [0, _amount, 0];
        // uint256 expectOutput = ICurvePoolAave(curvePool).calc_token_amount(amounts, true);

        // AAVE LP does not support virtual price
        uint256 expectOutput = (_amount * virtualPriceMag) / IPrice(curvePool).get_virtual_price();

        // Calculate Minimum output considering slippage
        uint256 minOutput = (expectOutput * (magnifier - depositSlippage)) / magnifier;

        // Add liquidity to Curve pool
        uint256[3] memory amounts = [0, _amount, 0];
        ICurvePoolAave(curvePool).add_liquidity(amounts, minOutput, true);

        // Get LP token amount output
        uint256 lpAmt = IERC20(lpToken).balanceOf(address(this));

        // Increase LP token total amt
        totalLP += lpAmt;

        // Approve LP token to Convex
        IERC20(lpToken).approve(convex, lpAmt);

        // Deposit to Convex Booster
        IConvexBooster(convex).depositAll(pId, true);

        // Get new total assets amount
        uint256 newAmt = _totalAssets();
        return newAmt - prevAmt;
    }

    /**
        Withdraw function of USDC
     */
    function withdraw(uint256 _amount) external override onlyController returns (uint256) {
        // Get Current Deposit Amt
        uint256 total = _totalAssets();
        uint256 lpAmt = (totalLP * _amount) / total;

        // Get Reward pool address
        (, , , address crvRewards, , ) = IConvexBooster(convex).poolInfo(pId);

        uint256 lpBefore = IERC20(lpToken).balanceOf(address(this));

        // Withdraw Reward
        IConvexReward(crvRewards).withdraw(lpAmt, false);

        // Withdraw from Convex Pool
        IConvexBooster(convex).withdraw(pId, lpAmt);

        // Get LP Token Amt
        uint256 lpWithdrawn = IERC20(lpToken).balanceOf(address(this)) - lpBefore;

        // See if LP withdrawn as requested amount
        require(lpWithdrawn >= lpAmt, "LP_WITHDRAWN_NOT_MATCH");
        totalLP -= lpAmt;

        // Calculate Minimum output
        // uint256 minAmt = ICurvePoolAave(curvePool).calc_withdraw_one_coin(lpWithdrawn, tokenId);
        uint256 minAmt = (lpWithdrawn * IPrice(curvePool).get_virtual_price()) / virtualPriceMag;
        minAmt = (minAmt * (magnifier - withdrawSlippage)) / magnifier;

        // Approve LP token to Curve
        IERC20(lpToken).approve(curvePool, lpWithdrawn);

        // Withdraw USDC from Curve Pool
        ICurvePoolAave(curvePool).remove_liquidity_one_coin(lpWithdrawn, tokenId, minAmt, true);

        // Transfer withdrawn USDC to controller
        uint256 asset = IERC20(usdc).balanceOf(address(this));
        TransferHelper.safeTransfer(usdc, controller, asset);

        return asset;
    }

    /**
        Harvest reward token from convex booster
     */
    function harvest() external override onlyController {
        // Get CRV reward pool
        (, , , address crvRewards, , ) = IConvexBooster(convex).poolInfo(pId);
        IConvexReward(crvRewards).getReward(address(this), true);

        // Transfer Reward tokens to controller
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 balance = IERC20(rewardTokens[i]).balanceOf(address(this));
            require(balance > 0, "ZERO_HARVEST_ON_CONVEX_AAVE");
            TransferHelper.safeTransfer(rewardTokens[i], controller, balance);
        }

        // Update latest block timestamp
        latestHarvest = block.timestamp;
    }

    /**
        Emergency Withdraw LP token from convex booster and send to owner
     */
    function emergencyWithdraw() public onlyOwner {
        // Get Reward pool address
        (, , , address crvRewards, , ) = IConvexBooster(convex).poolInfo(pId);

        // If totalLP is zero, return
        if (totalLP == 0) return;

        // Withdraw Reward
        IConvexReward(crvRewards).withdrawAllAndUnwrap(false);

        // Get LP Token Amt
        uint256 lpWithdrawn = IERC20(lpToken).balanceOf(address(this));

        // Decrease total amount by withdrawn
        totalLP -= lpWithdrawn;

        // Transfer LP token to owner
        TransferHelper.safeTransfer(lpToken, owner(), lpWithdrawn);

        // Emit Event
        emit EmergencyWithdraw(lpWithdrawn);
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

    /**
        Check withdrawable status of required amount
     */
    function withdrawable(uint256 _amount) external view override returns (uint256) {
        // Get Current Deposit Amt
        uint256 total = _totalAssets();

        if (total == 0) return 0;

        // If requested amt is bigger than total asset, try to withdraw total
        if (_amount > total) _amount = total;

        uint256 lpAmt = (totalLP * _amount) / total;
        uint256 expectedOutput = ICurvePoolAave(curvePool).calc_withdraw_one_coin(lpAmt, tokenId);

        // If expected output is
        if (expectedOutput >= (_amount * (magnifier - withdrawSlippage)) / magnifier) return _amount;
        else return 0;
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
        Set Pool Id
     */
    function setPoolId(uint256 _pId) public onlyOwner {
        require(_pId < IConvexBooster(convex).poolLength(), "INVALID_POOL_ID");
        pId = _pId;

        emit SetPoolId(pId);
    }

    /**
        Set LP Token
     */
    function setLPToken(address _lpToken) public onlyOwner {
        require(_lpToken != address(0), "INVALID_LP_TOKEN");
        lpToken = _lpToken;

        emit SetLPToken(lpToken);
    }

    /**
        Set Curve pool
     */
    function setCurvePool(address _curvePool) public onlyOwner {
        require(_curvePool != address(0), "INVALID_LP_TOKEN");
        curvePool = _curvePool;

        emit SetCurvePool(curvePool);
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
    }

    // Add reward token to list
    function addRewardToken(address _token) public onlyOwner {
        require(_token != address(0), "ZERO_ADDRESS");

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            require(rewardTokens[i] != _token, "DUPLICATE_REWARD_TOKEN");
        }
        rewardTokens.push(_token);

        emit AddRewardToken(_token);
    }

    // Remove reward token from list
    function removeRewardToken(address _token) public onlyOwner {
        require(_token != address(0), "ZERO_ADDRESS");

        bool succeed;

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i] == _token) {
                rewardTokens[i] = rewardTokens[rewardTokens.length - 1];
                rewardTokens.pop();

                succeed = true;
                break;
            }
        }

        require(succeed, "REMOVE_REWARD_TOKEN_FAIL");

        emit RemoveRewardToken(_token);
    }
}