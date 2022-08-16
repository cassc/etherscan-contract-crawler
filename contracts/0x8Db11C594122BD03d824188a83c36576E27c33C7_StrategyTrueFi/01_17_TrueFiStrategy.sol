//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ITrueFi.sol";
import "./interfaces/ITrueMultiFarm.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IPancakeRouter02.sol";
import "../../interfaces/IOracle.sol";
import "../../refs/CoreRef.sol";

contract StrategyTrueFi is IStrategy, ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public override lastEarnBlock;

    address public override uniRouterAddress;

    address public constant TRU = 0x4C19596f5aAfF459fA38B0f7eD92F11AE6543784;

    address public lendingPool;
    address public override wantAddress;
    uint8 internal wantDecimals;
    address public  multifarm;

    address[] public override earnedToWantPath;
    address public oracle;
    uint256 internal swapSlippage;

    constructor(
        address _core,
        address _lendingPool,
        address _multifarm,
        address _wantAddress,
        uint8 _wantDecimals,
        address _uniRouterAddress,
        address[] memory _earnedToWantPath,
        address _oracle,
        uint256 _swapSlippage
    ) public CoreRef(_core) {
        lendingPool = _lendingPool;
        multifarm = _multifarm;
        wantAddress = _wantAddress;
        wantDecimals = _wantDecimals;
        earnedToWantPath = _earnedToWantPath;
        uniRouterAddress = _uniRouterAddress;
        oracle = _oracle;
        swapSlippage = _swapSlippage;

        IERC20(TRU).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(_wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(_wantAddress).safeApprove(_lendingPool, uint256(-1));
        IERC20(_lendingPool).safeApprove(_multifarm, uint256(-1));
    }

    function deposit(uint256 _wantAmt) public override nonReentrant whenNotPaused {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);
        _deposit(wantLockedInHere());
    }

    function _deposit(uint256 _wantAmt) internal {
        ITrueFi(lendingPool).join(_wantAmt);
        uint256 lendingBal = IERC20(lendingPool).balanceOf(address(this));
        ITrueMultiFarm(multifarm).stake(IERC20(lendingPool), lendingBal);
    }

    function earn() public override whenNotPaused onlyTimelock {

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(lendingPool);
        ITrueMultiFarm(multifarm).claim(tokens);

        uint256 earnedAmt = IERC20(TRU).balanceOf(address(this));
        if (TRU != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _deposit(earnedAmt);
        }

        lastEarnBlock = block.number;
    }

    function withdraw() public override onlyMultistrategy nonReentrant {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(lendingPool);
        ITrueMultiFarm(multifarm).exit(tokens);
        ITrueFi(lendingPool).liquidExit(tfTokenLockedInHere());

        uint256 earnedAmt = IERC20(TRU).balanceOf(address(this));
        if (TRU != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        uint256 balance = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, balance);
    }

    function _pause() internal override {
        super._pause();
        IERC20(TRU).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(lendingPool, 0);
        IERC20(lendingPool).safeApprove(multifarm, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(TRU).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(lendingPool, uint256(-1));
        IERC20(lendingPool).safeApprove(multifarm, uint256(-1));
    }

    function wantLockedInHere() public view override returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }
    function tfTokenLockedInHere() public view returns(uint256) {
        return IERC20(lendingPool).balanceOf(address(this));
    }

    function calculateMinReturn(uint256 _amount) external view returns (uint256 minReturn) {
        minReturn = _calculateMinReturn(_amount);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint8 resDecimals = IOracle(oracle).getResponseDecimals(TRU);
        uint8 truDecimals = IOracle(oracle).getBaseDecimals(TRU);
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(TRU);  
        uint256 scaled = IOracle(oracle).scalePrice(oraclePrice, resDecimals, wantDecimals);
        uint256 total = scaled.mul(amount).div(uint256(10 ** uint256(truDecimals)));
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setOracle(address _oracle) public onlyGovernor {
        oracle = _oracle;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != TRU, "!safe");
        require(_token != wantAddress, "!safe");
        require(_token != lendingPool, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() public override {}
}