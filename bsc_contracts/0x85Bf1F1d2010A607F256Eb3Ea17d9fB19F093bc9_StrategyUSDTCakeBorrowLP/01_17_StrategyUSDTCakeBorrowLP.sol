// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../tokens/ERC20.sol";
import "../utils/SafeERC20.sol";
import "../utils/SafeMath.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IPancakeFarm.sol";
import "../interfaces/IMasterChefV2.sol";
import "../interfaces/ICompoundProtocol.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "./StrategyBase.sol";

contract StrategyUSDTCakeBorrowLP is StrategyBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Deposit(address indexed wallet, uint wantAmount, uint lpAmount);
    event Withdraw(address indexed wallet, uint amount);
    event FeesPaid(uint256 cakeRepaid, uint256 strategistFeeCake, uint256 keeperFeeNative);
    event Harvest(uint amount);

    address public want;
    address public cakeLP;
    address public farmBooster;
    address public farmBoosterProxy;
    address public masterchef;
    uint256 public pid;
    uint256 public cakeLockDuration = 1 weeks;
    uint256 public cakeRepayBasis = 25;

    address constant public wrappedNative = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant public router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address constant public unitroller = address(0x29152a70BABc383e41fa20c52DB0643F4CD007e9);
    address constant public cToken = address(0x7ff9c8DC5522c4fDA763c6dbBff88935d07DDf96);
    address constant public cake = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    address constant public cakePool = address(0x45c54210128a065de780C4B0Df3d16664f7f859e);
    address constant public farmBoostFactory = address(0x2C36221bF724c60E9FEE3dd44e2da8017a8EF3BA);

    address[] public markets;
    address[] public wantToCakePath;
    address[] public cakeToWantPath;
    address[] public cakeToNativePath;
    
    uint256 public totalBorrowedAmount;

    constructor (
        address newWant,
        address newCakeLP,
        uint8 newPid, 
        address newManager,
        address newVault,
        address newStrategist
    ) StrategyBase(newManager, newVault, newStrategist) {
        want = newWant;
        cakeLP = newCakeLP;
        pid = newPid;
        address[] memory market = new address[](1);
        market[0] = cToken;
        markets = market;
        address[] memory path = new address[](2);
        path[0] = want;
        path[1] = cake;
        wantToCakePath = path;
        path[0] = cake;
        path[1] = want;
        cakeToWantPath = path;
        path[0] = cake;
        path[1] = wrappedNative;
        cakeToNativePath = path;
        ICompoundUnitroller(unitroller).enterMarkets(markets);
        IFarmBoosterProxyFactory(farmBoostFactory).createFarmBoosterProxy();
        farmBoosterProxy = IFarmBoosterProxyFactory(farmBoostFactory).proxyContract(address(this));
        farmBooster = IFarmBoosterProxyFactory(farmBoostFactory).Farm_Booster();
        masterchef = IFarmBoosterProxyFactory(farmBoostFactory).masterchefV2();
        IFarmBooster(farmBooster).activate(pid);
        _giveAllowances();
    }

    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal > 0) {
            uint256[] memory amountsOut = IUniswapV2Router01(router).getAmountsOut(wantBal, wantToCakePath);
            ICompoundToken(cToken).borrow(amountsOut[1]);
            totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
            IUniswapV2Router01(router).addLiquidity(want, cake, wantBal, amountsOut[1], 0, 0, address(this), block.timestamp);
            uint256 lpBal = IERC20(cakeLP).balanceOf(address(this));
            IFarmBoosterProxy(farmBoosterProxy).deposit(pid, lpBal);
            emit Deposit(tx.origin, wantBal, lpBal);
        }
    }

    function withdraw(uint256 shares) external whenNotPaused {
        require(msg.sender == vault, "not vault");
        uint256 cakeBalBefore = IERC20(cake).balanceOf(address(this));
        IFarmBoosterProxy(farmBoosterProxy).withdraw(pid, shares);
        uint256 lpBal = IERC20(cakeLP).balanceOf(address(this));
        IUniswapV2Router01(router).removeLiquidity(want, cake, lpBal, 0, 0, address(this), block.timestamp);
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        uint256 cakeBalAfter = IERC20(cake).balanceOf(address(this));
        uint256 cakeBalDelta = cakeBalAfter.sub(cakeBalBefore);
        _repayBorrow(cakeBalDelta);
        IERC20(want).safeTransfer(vault, wantBal);
        emit Withdraw(tx.origin, wantBal);
    }
    
    function harvest() external whenNotPaused {
        uint256 rewardAmount = IERC20(cake).balanceOf(address(this));
        if (rewardAmount > 0) {
            _payFees(rewardAmount); 
            _swapAddLiquidityAndBoost();
            emit Harvest(rewardAmount);
        }
    }

    function balanceOf() public view returns (uint256) {
        (uint256 amount,,) = IMasterChefV2(masterchef).userInfo(pid, address(farmBoosterProxy));
        return amount;
    }
    
    function repayBorrow(uint256 amount) public onlyManager {
        if (amount > totalBorrowedAmount) {
            amount = totalBorrowedAmount;
        }
        ICompoundToken(cToken).repayBorrow(amount);
        totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
    }
    
    function borrow(uint256 amount) external onlyManager {
        ICompoundToken(cToken).borrow(amount);
        totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
    }

    function setCakeLockDuration(uint256 time) external onlyManager {
        cakeLockDuration = time;
    }

    function setCakeRepayBasis(uint256 basis) external onlyManager {
        cakeRepayBasis = basis;
    }

    function lockCake(uint256 amount) external onlyManager {
        ICakePool(cakePool).deposit(amount, cakeLockDuration);
    }

    function retriveCake(uint256 amount) external onlyManager {
        ICakePool(cakePool).withdraw(amount);
    }

    function retriveLP(uint256 amount) external onlyManager {
        IFarmBoosterProxy(farmBoosterProxy).withdraw(pid, amount);
    }

    function removeLP(uint256 amount) external onlyManager {
        IUniswapV2Router01(router).removeLiquidity(want, cake, amount, 0, 0, address(this), block.timestamp);
    }

    function migrateToken(address token, address newContract) public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(newContract, balance);
    }

    function pause() public onlyManager {
        _pause();
        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();
        _giveAllowances();
    }

    function retireStrategy() external {
        require(msg.sender == vault, "Not vault");
        _panic();
    }

    function panic() public onlyManager {
        _panic();
    }

    function _panic() internal {
        pause();
        IFarmBoosterProxy(farmBoosterProxy).emergencyWithdraw(pid);
        uint256 lpBal = IERC20(cakeLP).balanceOf(address(this));
        IUniswapV2Router01(router).removeLiquidity(want, cake, lpBal, 0, 0, address(this), block.timestamp);
        uint256 cakeBal = IERC20(cake).balanceOf(address(this));
        uint256 borrowBal = ICompoundToken(cToken).borrowBalanceStored(address(this));
        if (cakeBal > borrowBal) {
            cakeBal = borrowBal;
        }
        _repayBorrow(cakeBal);
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal > 0) {
            IERC20(want).safeTransfer(vault, wantBal);
        }
    }

    function _repayBorrow(uint256 amount) internal {
        if (totalBorrowedAmount > 0) {
            if (amount > totalBorrowedAmount) {
                amount = totalBorrowedAmount;
            }
            ICompoundToken(cToken).repayBorrow(amount);
            totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
        }
    }

    function _payFees(uint256 amount) internal {
        uint256 strategistAmount = amount.mul(strategistFee).div(DIVISOR);
        IERC20(cake).safeTransfer(strategist, strategistAmount);
        uint256 repayAmount = amount.mul(cakeRepayBasis).div(DIVISOR);
        _repayBorrow(repayAmount);
        uint256 toNativeBal = amount.mul(keeperFee).div(DIVISOR);
        IUniswapV2Router01(router).swapExactTokensForTokens(
            toNativeBal,
            0,
            cakeToNativePath,
            address(this),
            block.timestamp
        );
        uint256 nativeBal = IERC20(wrappedNative).balanceOf(address(this));
        IERC20(wrappedNative).safeTransfer(tx.origin, nativeBal);
        emit FeesPaid(repayAmount, strategistAmount, nativeBal);
    }

    function _swapAddLiquidityAndBoost() internal {
        uint256 swapHalf = IERC20(cake).balanceOf(address(this)).div(2);
        IUniswapV2Router01(router).swapExactTokensForTokens(
            swapHalf,
            0,
            cakeToWantPath,
            address(this),
            block.timestamp
        );
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        uint256 cakeBal = IERC20(cake).balanceOf(address(this));
        IUniswapV2Router01(router).addLiquidity(want, cake, wantBal, cakeBal, 0, 0, address(this), block.timestamp);
        uint256 lpBal = IERC20(cakeLP).balanceOf(address(this));
        IFarmBoosterProxy(farmBoosterProxy).deposit(pid, lpBal);
    }

    function _giveAllowances() internal {
        IERC20(cake).safeApprove(cToken, type(uint256).max);
        IERC20(want).safeApprove(router, type(uint256).max);
        IERC20(cake).safeApprove(router, type(uint256).max);
        IERC20(cakeLP).safeApprove(farmBoosterProxy, type(uint256).max);
        IERC20(cakeLP).safeApprove(router, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(cake).safeApprove(cToken, 0);
        IERC20(want).safeApprove(router, 0);
        IERC20(cake).safeApprove(router, 0);
        IERC20(cakeLP).safeApprove(farmBoosterProxy, 0);
        IERC20(cakeLP).safeApprove(router, 0);
    }
}