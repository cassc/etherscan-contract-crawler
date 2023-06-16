pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/ICrvDeposit.sol";
import "../interfaces/ICrvMinter.sol";
import "../interfaces/ICrvPool.sol";
import "../interfaces/IController.sol";
import "../interfaces/IUniswapRouter.sol";
import "./CrvLocker.sol";

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

contract StrategyHbtc is CrvLocker {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // TODO: change want according to wBTC/hBTC
    // HBTC 0x0316EB71485b0Ab14103307bf65a021042c6d380
    // WBTC 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    address constant public want = address(0x0316EB71485b0Ab14103307bf65a021042c6d380); // hBtc
    address constant public hBTCPool = address(0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F); // hBTC Pool
    address constant public hBTCGauge = address(0x4c18E409Dc8619bFb6a1cB56D114C3f592E0aE79); // hBTC gauge
    address constant public hCrv = address(0xb19059ebb43466C323583928285a49f558E572Fd); // hCrv
    address constant public bella = address(0xA91ac63D040dEB1b7A5E4d4134aD23eb0ba07e14);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public output = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV   
    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public crv_minter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address constant public wBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // wBTC (used to convert from crv to hCrv)

    // 0 = hBTC, 1 = wBTC in hBTC pool
    enum TokenIndexInHBTCPool {HBTC, WBTC}
    uint56 constant tokenIndexHBTCPool = uint56(TokenIndexInHBTCPool.HBTC); // TODO: change according to hBTC/wBTC
    uint56 constant tokenIndexWBTC = uint56(TokenIndexInHBTCPool.WBTC);

    address public governance;
    address public controller;

    uint256 public toWant = 92; // 20% manager fee + 80%*90%
    uint256 public toBella = 8;
    uint256 public manageFee = 22; //92%*22% = 20%

    uint256 public burnPercent = 50;
    uint256 public distributionPercent = 50;
    address public burnAddress = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // withdrawSome withdraw a bit more to compensate the imbalanced asset, 10000=1
    uint256 public withdrawCompensation = 30;

    address[] public swap2BellaRouting;
    address[] public swap2WBTCRouting;
    
    constructor(address _controller, address _governance) public CrvLocker(_governance) {
        governance = _governance;
        controller = _controller;
        swap2BellaRouting = [output, weth, bella];
        swap2WBTCRouting = [output, weth, wBTC];
        doApprove();
    }

    function doApprove () public {

        // crv -> want
        IERC20(crv).safeApprove(unirouter, 0);
        IERC20(crv).safeApprove(unirouter, uint(-1)); 

        // wBTC/hBTC -> hBTC Pool
        // IERC20(want).safeApprove(hBTCPool, 0); HTBC can not approve 0!!!
        IERC20(want).safeApprove(hBTCPool, uint(-1));

        // hCrv -> hBTC gauge
        IERC20(hCrv).safeApprove(hBTCGauge, 0);
        IERC20(hCrv).safeApprove(hBTCGauge, uint(-1));

        IERC20(wBTC).safeApprove(hBTCPool, 0);
        IERC20(wBTC).safeApprove(hBTCPool, uint(-1));        

    }
    
    function deposit() public {
        require((msg.sender == governance || 
            (msg.sender == tx.origin) ||
            (msg.sender == controller)),"!contract");

        /// wBTC/hBTC -> hBTC pool
        uint256[2] memory amounts = wrapCoinAmount(IERC20(want).balanceOf(address(this)), tokenIndexHBTCPool);
        ICrvPool2Coins(hBTCPool).add_liquidity(amounts, 0);

        /// hBTC pool -> gauge
        invest(hBTCGauge, IERC20(hCrv).balanceOf(address(this)));
    }

    /**
     * @dev Deposit XCurve into XCurve gauge
     */
    function invest(address gauge, uint256 amount) internal {

        ICrvDeposit(gauge).deposit(amount);

    }

    /**
     * @dev Get CRV rewards
     */
    function harvest(address gauge) public {
        require(msg.sender == tx.origin ,"!contract");

        ICrvMinter(crv_minter).mint(gauge);

        uint256 crvToWBTC = crv.balanceOf(address(this)).mul(toWant).div(100);

        if (crvToWBTC == 0)
            return;

        uint256 bWantBefore = IERC20(wBTC).balanceOf(address(this));

        IUniswapRouter(unirouter).swapExactTokensForTokens(
            crvToWBTC, 1, swap2WBTCRouting, address(this), block.timestamp
        );

        uint256 bWantAfter = IERC20(wBTC).balanceOf(address(this));

        uint256 fee = bWantAfter.sub(bWantBefore).mul(manageFee).div(100);
        IERC20(wBTC).safeTransfer(IController(controller).rewards(), fee);

        if (toBella != 0) {
            uint256 crvBalance = crv.balanceOf(address(this));
            IUniswapRouter(unirouter).swapExactTokensForTokens(
                crvBalance, 1, swap2BellaRouting, address(this), block.timestamp
            );
            splitBella();
        }

        depositWbtc();

    }

    /**
     * @dev wBTC -> hCrv -> hCrv gauge
     */
    function depositWbtc() internal {
        /// wBTC -> hCrv  Pool
        uint256[2] memory amounts = wrapCoinAmount(IERC20(wBTC).balanceOf(address(this)), tokenIndexWBTC);
        ICrvPool2Coins(hBTCPool).add_liquidity(amounts, 0);

        /// hCrv -> gauge
        invest(hBTCGauge, IERC20(hCrv).balanceOf(address(this)));
    }

    function splitBella() internal {
        uint bellaBalance = IERC20(bella).balanceOf(address(this));

        uint burn = bellaBalance.mul(burnPercent).div(100);
        uint distribution = bellaBalance.mul(distributionPercent).div(100);
        
        IERC20(bella).safeTransfer(IController(controller).belRewards(), distribution);
        IERC20(bella).safeTransfer(burnAddress, burn); 
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(address(_asset) != address(hCrv), "!hCrv");
        require(address(_asset) != address(want), "!want");
        require(address(_asset) != address(crv), "!crv");
        require(address(_asset) != address(wBTC), "!wBTC");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount);
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        balance = IERC20(want).balanceOf(address(this));
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }
    
    function _withdrawAll() internal {
        // withdraw hBTC pool crv from gauge
        uint256 amount = ICrvDeposit(hBTCGauge).balanceOf(address(this));
        _withdrawXCurve(hBTCGauge, amount);
        
        // exchange xcrv from pool to say dai 
        ICrvPool2Coins(hBTCPool).remove_liquidity_one_coin(amount, tokenIndexHBTCPool, 1);
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        // withdraw hBTC pool crv from gauge
        uint256 amount = _amount.mul(1e18).div(ICrvPool2Coins(hBTCPool).get_virtual_price())
            .mul(10000 + withdrawCompensation).div(10000);
        amount = _withdrawXCurve(hBTCGauge, amount);

        uint256 bBefore = IERC20(want).balanceOf(address(this));

        ICrvPool2Coins(hBTCPool).remove_liquidity_one_coin(amount, tokenIndexHBTCPool, 1);

        uint256 bAfter = IERC20(want).balanceOf(address(this));

        return bAfter.sub(bBefore);
    }

    /**
     * @dev Internal function to withdraw yCurve, handle the case when withdraw amount exceeds the buffer
     * @param gauge Gauge address (hBTC pool, busd, usdt)
     * @param amount Amount of yCurve to withdraw
     */
    function _withdrawXCurve(address gauge, uint256 amount) internal returns (uint256) {
        uint256 a = Math.min(ICrvDeposit(gauge).balanceOf(address(this)), amount);
        ICrvDeposit(gauge).withdraw(a);
        return a;
    }
    
    function balanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this))
                .add(balanceInPool());
    }

    function underlyingBalanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this))
                .add(underlyingBalanceInPool());
    }
    
    function balanceInPool() public view returns (uint256) {
        return ICrvDeposit(hBTCGauge).balanceOf(address(this)).mul(ICrvPool2Coins(hBTCPool).get_virtual_price()).div(1e18);
    }

    function underlyingBalanceInPool() public view returns (uint256) {
        uint balance = ICrvDeposit(hBTCGauge).balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        uint balanceVirtual = balance.mul(ICrvPool2Coins(hBTCPool).get_virtual_price()).div(1e18);
        uint balanceUnderlying = ICrvPool2Coins(hBTCPool).calc_withdraw_one_coin(balance, tokenIndexHBTCPool);
        return Math.min(balanceVirtual, balanceUnderlying);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function changeManageFee(uint256 newManageFee) external {
        require(msg.sender == governance, "!governance");
        require(newManageFee <= 100, "must less than 100%!");
        manageFee = newManageFee;
    }

    function changeBelWantRatio(uint256 newToBella, uint256 newToWant) external {
        require(msg.sender == governance, "!governance");
        require(newToBella.add(newToWant) == 100, "must divide all the pool");
        toBella = newToBella;
        toWant = newToWant;
    }

    function setDistributionAndBurnRatio(uint256 newDistributionPercent, uint256 newBurnPercent) external{
        require(msg.sender == governance, "!governance");
        require(newDistributionPercent.add(newBurnPercent) == 100, "must be 100% total");
        distributionPercent = newDistributionPercent;
        burnPercent = newBurnPercent;
    }

    function setBurnAddress(address _burnAddress) public{
        require(msg.sender == governance, "!governance");
        require(_burnAddress != address(0), "cannot send bella to 0 address");
        burnAddress = _burnAddress;
    }

    function setWithdrawCompensation(uint256 _withdrawCompensation) public {
        require(msg.sender == governance, "!governance");
        require(_withdrawCompensation <= 100, "too much compensation");
        withdrawCompensation = _withdrawCompensation;
    }

    /**
    * @dev Wraps the coin amount in the array for interacting with the Curve protocol
    */
    function wrapCoinAmount(uint256 amount, uint56 index) internal pure returns (uint256[2] memory) {
        uint256[2] memory amounts = [uint256(0), uint256(0)];
        amounts[index] = amount;
        return amounts;
    }

}