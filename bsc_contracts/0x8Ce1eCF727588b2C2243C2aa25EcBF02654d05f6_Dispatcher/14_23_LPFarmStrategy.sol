//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

import '../interface/IStrategy.sol';
import '../interface/IPancakePair.sol';
import '../interface/IPancakeRouter.sol';
import '../interface/IPancakeFarm.sol';
import '../interface/IPuppetOfDispatcher.sol';
/**
 * pancakeswapLP farm strategy
 */
contract LPFarmStrategy is  ReentrancyGuard, Context, IStrategy, IPuppetOfDispatcher, Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Harvest(uint256 token0Amount, uint256 token1Amount, uint256  farmRewardAmount);
    event Sweep(address token, address recipient, uint256 amount);
    event SetOperator(address indexed user, bool allow );

    address public  lptoken;
    address public  router;
    address public  farm ;
    address public  farmRewardToken ;
    uint256 public swapLimit = 1e3;
    uint256 public poolId = 0;
    address public dispatcher;
    mapping(address => bool) public operators;

    modifier onlyDispatcher() {
        require(_msgSender() == dispatcher, "LPFarmStrategy:sender is not dispatcher");
        _;
    }
    modifier onlyOperator() {
        require(operators[_msgSender()], "LPFarmStrategy: sender is not operator");
        _;
    }
    constructor(address _lptoken, address _farmRewardToken,  address _router, address _farm, address _dispatcher) {
        lptoken = _lptoken;
        router = _router;
        farm = _farm;
        farmRewardToken = _farmRewardToken;
        dispatcher = _dispatcher;
        operators[msg.sender] = true;
        operators[dispatcher] = true;
    }

    // Call initApprove before calling
    function withdrawToDispatcher(uint256 leaveAmount) external override onlyDispatcher  {
        require(leaveAmount > 0, "LPFarmStrategy: leaveAmount is zero");
        IPancakeFarm pancakeFarm = IPancakeFarm(farm);
        pancakeFarm.withdraw(poolId, leaveAmount);
        IPancakePair pair = IPancakePair(lptoken);
        IPancakeRouter(router).removeLiquidity(pair.token0(), pair.token1(), leaveAmount, 0, 0, dispatcher, block.timestamp.add(300));
        harvest();
    }

    function harvest() public override onlyDispatcher{
        IPancakeFarm pancakeFarm = IPancakeFarm(farm);
        (uint256 amount,) = pancakeFarm.userInfo(poolId, address(this));
        if (amount > 0) {
            IPancakeFarm(farm).withdraw(poolId, 0);
        }
        uint256 balance = IERC20(farmRewardToken).balanceOf(address(this));
        IPancakePair pair = IPancakePair(lptoken);
        if(balance > 0 && farmRewardToken != pair.token0() &&  pair.token1() != farmRewardToken) {
            address[] memory path = new address[](2);
            path[0] = farmRewardToken;
            path[1] = pair.token0();
            IPancakeRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(balance, 0 ,path, address(this), block.timestamp.add(300));
        }
        uint256 balanceA = IERC20(pair.token0()).balanceOf(address(this));
        if(balanceA > 0) {
            IERC20(pair.token0()).safeTransfer(dispatcher, balanceA);
        }
        uint256 balanceB = IERC20(pair.token1()).balanceOf(address(this));
        if(balanceB > 0) {
            IERC20(pair.token1()).safeTransfer(dispatcher, balanceB);
        }
        emit Harvest(balanceA, balanceB, balance);
    }

    // Call initApprove before calling
    function executeStrategy() external override onlyDispatcher nonReentrant{
        IPancakePair pair = IPancakePair(lptoken);
        uint256 balanceA =  IERC20(pair.token0()).balanceOf(address(this));
        uint256 balanceB =  IERC20(pair.token1()).balanceOf(address(this));
        require(balanceA > 0 || balanceB > 0, "LPFarmStrategy: balanceA and balanceB are zero");
        (uint256 reserveA, uint256 reserveB) = getReserves(lptoken);
        uint256 timesOfA = reserveB.mul(balanceB).div(reserveA); //
        if(balanceA > timesOfA.add(swapLimit)) {
            address[] memory path = new address[](2);
            path[0] = pair.token0();
            path[1] = pair.token1();
            uint256 amountAOptimal =0;
            if ( balanceB > 0 ) {
                amountAOptimal = quote(balanceB, reserveB, reserveA);
            }
            uint256 swapAmount = balanceA.sub(amountAOptimal).div(2);
            IPancakeRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0 ,path, address(this), block.timestamp.add(300));
        } else if(timesOfA > balanceA.add(swapLimit)) {
            address[] memory path = new address[](2);
            path[0] = pair.token1();
            path[1] = pair.token0();
            uint256 amountBOptimal = 0;
            if ( balanceA > 0 ) {
                amountBOptimal = quote(balanceA, reserveA, reserveB);
            }
            uint256 swapAmount = balanceB.sub(amountBOptimal).div(2);
            IPancakeRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0 ,path, address(this), block.timestamp.add(300));
        }
        balanceA = IERC20(pair.token0()).balanceOf(address(this));
        balanceB = IERC20(pair.token1()).balanceOf(address(this));
        IPancakeRouter(router).addLiquidity(pair.token0(), pair.token1(), balanceA, balanceB, 0, 0, address(this), block.timestamp.add(300));
        IPancakeFarm(farm).deposit(poolId, pair.balanceOf(address(this)));
    }

    function totalAmount() external override view returns(uint256) {
        IPancakeFarm pancakeFarm = IPancakeFarm(farm);
        (uint256 amount,) = pancakeFarm.userInfo(poolId, address(this));
        return amount;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address _lptoken
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        address tokenA =  IPancakePair(_lptoken).token0();
        address tokenB =  IPancakePair(_lptoken).token1();
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_lptoken).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "LPFarmStrategy: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "LPFarmStrategy: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "LPFarmStrategy: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "LPFarmStrategy: ZERO_ADDRESS");
    }

    function setDispatcher(address _dispatcher) external override onlyDispatcher{
        require(_dispatcher != address(0), "LPFarmStrategy: ZERO_ADDRESS");
        dispatcher = _dispatcher;
    }

    function setOperator(address user, bool allow) external override onlyDispatcher{
        require(user != address(0), "WithdrawalAccount: ZERO_ADDRESS");
        operators[user] = allow;
        emit SetOperator(user, allow);
    }

    function sweep(address stoken, address recipient) external onlyOperator {
        require(recipient != address(0), "LPFarmStrategy: ZERO_ADDRESS");
        uint256 balance = IERC20(stoken).balanceOf(address(this));
        if(balance > 0) {
            IERC20(stoken).safeTransfer(recipient, balance);
            emit Sweep(stoken, recipient, balance);
        }
    }

    function setSwapLimit(uint256 _swapLimit) external onlyOperator {
        swapLimit = _swapLimit;
    }

    function setPoolId(uint256 _poolId) external onlyOperator {
        poolId = _poolId;
    }

    function approveTokenToRouter(address token,  uint256 amount) public onlyOperator{
        require(amount > 0, "LPFarmStrategy: INSUFFICIENT_AMOUNT");
        IERC20(token).approve(router, amount);
    }

    function approveLptokenToFarm( uint256 amount) public onlyOperator{
        require(amount > 0, "LPFarmStrategy: INSUFFICIENT_AMOUNT");
        IERC20(lptoken).approve(farm, amount);
    }

    function initApprove() external onlyOperator{
        approveTokenToRouter(IPancakePair(lptoken).token0(), ~uint256(0));
        approveTokenToRouter(IPancakePair(lptoken).token1(), ~uint256(0));
        approveTokenToRouter(farmRewardToken, ~uint256(0));
        approveTokenToRouter(lptoken, ~uint256(0));
        approveLptokenToFarm( ~uint256(0));
    }
}