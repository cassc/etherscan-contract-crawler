pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/ICrvDeposit.sol";
import "../interfaces/ICrvMinter.sol";
import "../interfaces/ICrvPoolUnderlying.sol";
import "../interfaces/ICrvPoolZap.sol";
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

contract StrategyBusd is CrvLocker {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public want = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53); // busd
    address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7); // usdt
    address constant public busdPool = address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27); // bCrv swap
    address constant public busdPoolZap = address(0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB); // bCrv swap zap
    address constant public bCrvGauge = address(0x69Fb7c45726cfE2baDeE8317005d3F94bE838840); // bCrv gauge
    address constant public bCrv = address(0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B); // bCrv
    address constant public bella = address(0xA91ac63D040dEB1b7A5E4d4134aD23eb0ba07e14);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public output = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV   
    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public crv_minter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    enum TokenIndexInbusdPool {DAI, USDC, USDT, BUSD}
    uint56 constant tokenIndexBusd = uint56(TokenIndexInbusdPool.BUSD);
    uint56 constant tokenIndexUsdt = uint56(TokenIndexInbusdPool.USDT);

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
    address[] public swap2UsdtRouting;
    
    constructor(address _controller, address _governance) public CrvLocker(_governance) {
        governance = _governance;
        controller = _controller;
        swap2BellaRouting = [output, weth, bella];
        swap2UsdtRouting = [output, weth, usdt];
        doApprove();
    }

    function doApprove () public {

        // crv -> want
        IERC20(crv).safeApprove(unirouter, 0);
        IERC20(crv).safeApprove(unirouter, uint(-1)); 

        // busd -> bCrv zap
        IERC20(want).safeApprove(busdPoolZap, 0);
        IERC20(want).safeApprove(busdPoolZap, uint(-1));

        // usdt -> bCrv zap
        IERC20(usdt).safeApprove(busdPoolZap, 0);
        IERC20(usdt).safeApprove(busdPoolZap, uint(-1));

        // bCrv -> bCrv gauge
        IERC20(bCrv).safeApprove(bCrvGauge, 0);
        IERC20(bCrv).safeApprove(bCrvGauge, uint(-1));

    }
    
    function deposit() public {
        require((msg.sender == governance || 
            (msg.sender == tx.origin) ||
            (msg.sender == controller)),"!contract");

        /// busd -> bCrv Pool
        uint256[4] memory amounts = wrapCoinAmount(IERC20(want).balanceOf(address(this)), tokenIndexBusd);
        ICrvPoolZap(busdPoolZap).add_liquidity(amounts, 0);

        /// bCrv -> gauge
        invest(bCrvGauge, IERC20(bCrv).balanceOf(address(this)));
    }

    /**
     * @dev Get CRV rewards
     */
    function harvest(address gauge) public {
        require(msg.sender == tx.origin ,"!contract");

        ICrvMinter(crv_minter).mint(gauge);

        uint256 crvToWant = crv.balanceOf(address(this)).mul(toWant).div(100);

        if (crvToWant == 0)
            return;

        uint256 bUsdtBefore = IERC20(usdt).balanceOf(address(this));

        IUniswapRouter(unirouter).swapExactTokensForTokens(
            crvToWant, 1, swap2UsdtRouting, address(this), block.timestamp
        );

        uint256 bUsdtAfter = IERC20(usdt).balanceOf(address(this));

        uint256 fee = bUsdtAfter.sub(bUsdtBefore).mul(manageFee).div(100);
        IERC20(usdt).safeTransfer(IController(controller).rewards(), fee);

        if (toBella != 0) {
            uint256 crvBalance = crv.balanceOf(address(this));
            IUniswapRouter(unirouter).swapExactTokensForTokens(
                crvBalance, 1, swap2BellaRouting, address(this), block.timestamp
            );
            splitBella();
        }

        depositUsdt();

    }

    /**
     * @dev usdt -> bCrv -> bCrv gauge
     */
    function depositUsdt() internal {
        /// usdt -> bCrv Pool
        uint256[4] memory amounts = wrapCoinAmount(IERC20(usdt).balanceOf(address(this)), tokenIndexUsdt);
        ICrvPoolZap(busdPoolZap).add_liquidity(amounts, 0);

        /// bCrv -> gauge
        invest(bCrvGauge, IERC20(bCrv).balanceOf(address(this)));
    }

    /**
     * @dev Deposit XCurve into XCurve gauge
     */
    function invest(address gauge, uint256 amount) internal {

        ICrvDeposit(gauge).deposit(amount);

    }

    /**
     * @dev Distribute bella to burn address and reward address
     */
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
        require(address(_asset) != address(bCrv), "!bCrv");
        require(address(_asset) != address(want), "!want");
        require(address(_asset) != address(crv), "!crv");
        require(address(_asset) != address(usdt), "!usdt");
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
        // withdraw 3pool crv from gauge
        uint256 amount = ICrvDeposit(bCrvGauge).balanceOf(address(this));
        _withdrawXCurve(bCrvGauge, amount);
        
        // exchange xcrv from pool to say dai 
        ICrvPoolZap(busdPoolZap).remove_liquidity_one_coin(amount, tokenIndexBusd, 1);
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        // withdraw 3pool crv from gauge
        uint256 amount = _amount.mul(1e18).div(ICrvPoolUnderlying(busdPool).get_virtual_price())
            .mul(10000 + withdrawCompensation).div(10000);
        amount = _withdrawXCurve(bCrvGauge, amount);

        uint256 bBefore = IERC20(want).balanceOf(address(this));

        ICrvPoolZap(busdPoolZap).remove_liquidity_one_coin(amount, tokenIndexBusd, 1);

        uint256 bAfter = IERC20(want).balanceOf(address(this));

        return bAfter.sub(bBefore);
    }

    /**
     * @dev Internal function to withdraw yCurve, handle the case when withdraw amount exceeds the buffer
     * @param gauge Gauge address (3pool, busd, usdt)
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
        return ICrvDeposit(bCrvGauge).balanceOf(address(this)).mul(ICrvPoolUnderlying(busdPool).get_virtual_price()).div(1e18);
    }

    function underlyingBalanceInPool() public view returns (uint256) {
        uint balance = ICrvDeposit(bCrvGauge).balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        uint balanceVirtual = balance.mul(ICrvPoolUnderlying(busdPool).get_virtual_price()).div(1e18);
        uint balanceUnderlying = ICrvPoolZap(busdPoolZap).calc_withdraw_one_coin(balance, tokenIndexBusd);
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
    function wrapCoinAmount(uint256 amount, uint56 index) internal pure returns (uint256[4] memory) {
        uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
        amounts[index] = amount;
        return amounts;
    }
}