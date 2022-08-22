//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "../refs/CoreRefUpgradeable.sol";
import "../interfaces/IAlpaca.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyAlpacaFarm.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyManagerAlpacaFarm.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeswapV2Worker02.sol";
import "../interfaces/IOracle.sol";

import "../library/Math.sol";

contract StrategyAlpacaFarmUpgradeable is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    CoreRefUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using WTFMath for uint256;

    address public wantAddress;
    address public farmTokenAddress;
    address public strategyManager;
    address public alpacaAddress;
    address public uniRouterAddress;
    address public vaultAddress;
    address public worker;
    address public strategyAddAllBaseToken;
    address public strategyLiquidate;
    address[] public earnedToWantPath;
    address public oracle;
    uint256 public swapSlippage;
    uint256 public vaultPositionId;

    function init(
        address _core,
        address _wantAddress,
        address _farmTokenAddress,
        address _strategyManager,
        address _alpacaAddress,
        address _uniRouterAddress,
        address _vaultAddress,
        address _worker,
        address _strategyAddAllBaseToken,
        address _strategyLiquidate,
        address[] memory _earnedToWantPath,
        address _oracle,
        uint256 _swapSlippage
    ) public initializer {
        // Init
        CoreRefUpgradeable.initialize(_core);
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        wantAddress = _wantAddress;
        farmTokenAddress = _farmTokenAddress;
        strategyManager = _strategyManager;
        alpacaAddress = _alpacaAddress;

        uniRouterAddress = _uniRouterAddress;
        vaultAddress = _vaultAddress;
        worker = _worker;
        strategyAddAllBaseToken = _strategyAddAllBaseToken;
        strategyLiquidate = _strategyLiquidate;
        earnedToWantPath = _earnedToWantPath;
        oracle = _oracle;
        swapSlippage = _swapSlippage;
        IERC20Upgradeable(alpacaAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20Upgradeable(wantAddress).safeApprove(strategyManager, uint256(-1));
    }

    function calculateMinLP(uint256 _amountWant) external view returns (uint256 minLP) {
        address[] memory path = new address[](2);
        path[0] = wantAddress; // want
        path[1] = farmTokenAddress; // farming token
        (uint256 rWant, uint256 rFarm) = _getPairReserves(path[0], path[1]);
        /* 
           find how many baseToken need to be converted to farmingToken
           Constants come from
           2-f = 2-0.0025 = 19975
           4(1-f) = 4*9975*10000 = 399000000, where f = 0.0025 and 10,000 is a way to avoid floating point
           19975^2 = 399000625
           9975*2 = 19950
        */
        uint256 amountIn = WTFMath.sqrt(rWant.mul(_amountWant.mul(399000000).add(rWant.mul(399000625)))).sub(
            rWant.mul(19975)
        ) / 19950;

        require(amountIn <= _amountWant, "StrategyAlpacaFarmUpgradeable:: Not enough tokens");
        uint256 amountOut = IPancakeRouter02(uniRouterAddress).getAmountsOut(amountIn, path)[1];
        uint256 amountWantInvest = _amountWant.sub(amountIn);
        uint256 totalSupply = _getLPTotalSupply(path[0], path[1]);
        minLP = MathUpgradeable.min(amountWantInvest.mul(totalSupply) / rWant, amountOut.mul(totalSupply) / rFarm);
    }

    function _getPairReserves(address token0, address token1) internal view returns (uint256 rWant, uint256 rFarm) {
        address factory = IPancakeRouter02(uniRouterAddress).factory();
        IPancakePair lptoken = IPancakePair(IPancakeV2Factory(factory).getPair(token0, token1));
        (uint256 r0, uint256 r1, ) = lptoken.getReserves();
        rWant = lptoken.token0() == wantAddress ? r0 : r1;
        rFarm = lptoken.token1() == farmTokenAddress ? r1 : r0;
    }

    function _getLPTotalSupply(address token0, address token1) internal view returns (uint256 totalSupply) {
        address factory = IPancakeRouter02(uniRouterAddress).factory();
        totalSupply = IPancakePair(IPancakeV2Factory(factory).getPair(token0, token1)).totalSupply();
    }

    function deposit(uint256 _wantAmt, uint256 _minLPAmount) external nonReentrant whenNotPaused {
        require(_wantAmt > 0, "StrategyAlpacaFarmUpgradeable:: Invalid amount");
        IERC20Upgradeable(wantAddress).safeTransferFrom(msg.sender, address(this), _wantAmt);
        _deposit(_wantAmt, _minLPAmount);
    }

    function _deposit(uint256 _wantAmt, uint256 _minLPAmount) internal {
        bytes memory ext = abi.encode(uint256(_minLPAmount));
        bytes memory data = abi.encode(strategyAddAllBaseToken, ext);
        vaultPositionId = IStrategyManagerAlpacaFarm(strategyManager).deposit(
            vaultAddress,
            vaultPositionId,
            worker,
            wantAddress,
            _wantAmt,
            data
        );
    }

    function calculateMinBaseToken() external view returns (uint256 minBaseToken) {
        minBaseToken = IWorker(worker).health(vaultPositionId);
    }

    function _liquidate(uint256 minBaseToken) internal {
        bytes memory ext = abi.encode(uint256(minBaseToken));
        bytes memory data = abi.encode(strategyLiquidate, ext);
        IStrategyManagerAlpacaFarm(strategyManager).withdraw(wantAddress, vaultAddress, vaultPositionId, worker, data);
    }

    function withdraw(uint256 minBaseToken) public onlyMultistrategy nonReentrant {
        _liquidate(minBaseToken);
        uint256 earnedAmt = IERC20Upgradeable(alpacaAddress).balanceOf(address(this));
        if (earnedAmt != 0) {
            uint256 minReturn = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturn,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }
        uint256 balanceWant = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        IERC20Upgradeable(wantAddress).transfer(msg.sender, balanceWant);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(alpacaAddress);
        uint256 total = amount.mul(oraclePrice).div(1e18);
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function _pause() internal override {
        super._pause();
        IERC20Upgradeable(alpacaAddress).safeApprove(uniRouterAddress, 0);
        IERC20Upgradeable(wantAddress).safeApprove(strategyManager, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20Upgradeable(alpacaAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20Upgradeable(wantAddress).safeApprove(strategyManager, uint256(-1));
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setOracle(address _oracle) public onlyGovernor {
        oracle = _oracle;
    }

    function wantLockedInHere() public view returns (uint256) {
        return IERC20Upgradeable(wantAddress).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyTimelock {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    receive() external payable {}

    function updateStrategy() public {}
}