//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IClearPool.sol";
import "../../refs/CoreRef.sol";
import "./TWAP.sol";

contract StrategyClearpool is ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public lastEarnBlock;

    ISwapRouter public swapRouter;
    address public uniPool; 
    address public constant CPOOL = 0x66761Fa41377003622aEE3c7675Fc7b5c1C2FaC5;

    address public lendingPool;
    address public poolFactory;
    address public wantAddress;

    bytes public earnedToWantPathWithFees;
    uint256 internal swapSlippage;
    uint32 internal twapDuration;

    constructor(
        address _core,
        address _lendingPool, 
        address _poolFactory, 
        address _wantAddress,
        address _swapRouter,
        address _uniPool,
        bytes memory _earnedToWantPathWithFees,
        uint256 _swapSlippage,
        uint32 _twapDuration
    ) public CoreRef(_core) {
        lendingPool = _lendingPool;
        poolFactory = _poolFactory;
        wantAddress = _wantAddress;
        swapRouter = ISwapRouter(_swapRouter);
        uniPool = _uniPool;
        earnedToWantPathWithFees = _earnedToWantPathWithFees;
        swapSlippage = _swapSlippage;
        twapDuration = _twapDuration;

        IERC20(CPOOL).safeApprove(address(swapRouter), uint256(-1));
        IERC20(_wantAddress).safeApprove(address(swapRouter), uint256(-1));
        IERC20(_wantAddress).safeApprove(_lendingPool, uint256(-1));
        IERC20(_lendingPool).safeApprove(_poolFactory, uint256(-1));
    }

    function deposit(uint256 _wantAmt) public nonReentrant whenNotPaused {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);
        _deposit(wantLockedInHere());
    }

    function _deposit(uint256 _wantAmt) internal {
        IClearPool(lendingPool).provide(_wantAmt);
    }

    function withdraw() public onlyMultistrategy nonReentrant {
        address[] memory pools = new address[](1);
        pools[0] = address(lendingPool);
        IClearPoolFactory(poolFactory).withdrawReward(pools);
        IClearPool(lendingPool).redeem(cpTokenLockedInHere());

        uint256 earnedAmt = IERC20(CPOOL).balanceOf(address(this));

        // Swap CPOOL if the balance is positive
        if (earnedAmt > 0) {
            uint256 minReturn = _calculateMinReturn(earnedAmt);
            swap(earnedAmt, minReturn);
            
        }
        uint256 balance = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, balance);
    }


    function earn() public whenNotPaused onlyTimelock {

        address[] memory pools = new address[](1);
        pools[0] = address(lendingPool);
        IClearPoolFactory(poolFactory).withdrawReward(pools);
        uint256 earnedAmt = IERC20(CPOOL).balanceOf(address(this));
        // Swap CPOOL if the balance is positive
        if (earnedAmt > 0) {
            uint256 minReturn = _calculateMinReturn(earnedAmt);
            swap(earnedAmt, minReturn);
            
        }
        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _deposit(earnedAmt);
        }
        lastEarnBlock = block.number;
    }

    function swap(uint256 amountIn, uint256 amountOutMin) internal returns(uint256 amountOut) {
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: earnedToWantPathWithFees,
                recipient: address(this),
                deadline: now.add(600),
                amountIn: amountIn,
                amountOutMinimum: amountOutMin
            });
        amountOut = swapRouter.exactInput(params);

    }

    function _pause() override internal {
        super._pause();
        IERC20(CPOOL).safeApprove(address(swapRouter), 0);
        IERC20(wantAddress).safeApprove(address(swapRouter), 0);
        IERC20(wantAddress).safeApprove(lendingPool, 0);
        IERC20(lendingPool).safeApprove(poolFactory, 0);
    }

    function _unpause() override internal {
        super._unpause();
        IERC20(CPOOL).safeApprove(address(swapRouter), uint256(-1));
        IERC20(wantAddress).safeApprove(address(swapRouter), uint256(-1));
        IERC20(wantAddress).safeApprove(lendingPool, uint256(-1));
        IERC20(lendingPool).safeApprove(poolFactory, uint256(-1));
    }

    function wantLockedInHere() public view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }
    function cpTokenLockedInHere() public view returns(uint256) {
        return IERC20(lendingPool).balanceOf(address(this));
    }

    function calculateMinReturn(uint256 _amount) external view returns (uint256 minReturn) {
        minReturn = _calculateMinReturn(_amount);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint128 amt128 = uint128(amount);
        (int24 arithmeticMeanTick, ) =  OracleLibrary.consult(uniPool, twapDuration);
        uint256 quoteAmount = OracleLibrary.getQuoteAtTick(arithmeticMeanTick, amt128, CPOOL, wantAddress);
        minReturn = quoteAmount.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setLendingPool(address _lendingPool) public onlyGovernor {
        require(_lendingPool != address(0), "Zero address");
        lendingPool = _lendingPool;
        IERC20(wantAddress).safeApprove(lendingPool, uint256(-1));
        IERC20(lendingPool).safeApprove(poolFactory, uint256(-1));
    }

    function setTwapDuration (uint32 _twapDuration) public onlyGovernor {
        twapDuration = _twapDuration;
    }

    function setEarnedToWantPathWithFees (bytes memory _earnedToWantPathWithFees) public onlyGovernor {
        earnedToWantPathWithFees = _earnedToWantPathWithFees;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyGovernor {
        require(_token != wantAddress, "!safe");
        require(_token != lendingPool, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }
    function updateStrategy() public  {}
}