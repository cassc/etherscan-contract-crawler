// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH {
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IRouter {
    function WETH() external view returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract BirdCoinStake is Ownable {
    using SafeMath for uint256;

    struct Stake {
        uint256 amount;
        uint256 lastClaim;
        uint256 earned;
    }

    address public bird;
    address public weth;
    address public pool;
    IRouter public router;

    mapping(address => mapping(address => Stake)) public stakes;
    mapping(address => bool) public supportedTokens;
    uint256 public unStakeFee = 4;
    uint256 public claimTime = 15 days;
    uint256 public reward = 5;

    constructor(address bird_, address pool_, address router_) {
        router = IRouter(router_);

        bird = bird_;
        weth = router.WETH();
        pool = pool_;
        supportedTokens[bird] = true;
        supportedTokens[weth] = true;
    }
    receive() external payable {}

    function setSupportedToken(address token, bool isSupported) public onlyOwner {
        supportedTokens[token] = isSupported;
    }

    function setUnStakeFee(uint256 fee) public onlyOwner {
        require(fee <= 20, "over fee");
        unStakeFee = fee;
    }

    function setClaimTime(uint256 time) public onlyOwner {
        require(time > 0, "time is zero");
        claimTime = time;
    }

    function stakeETH() public payable {
        uint256 rewardAmount = _stake(weth, msg.value);
        if (rewardAmount > 0) {
            IERC20(bird).transferFrom(pool, msg.sender, rewardAmount);
        }
    }

    function stakeToken(address token, uint256 amount) public {
        uint256 rewardAmount = _stake(token, amount);
        if (rewardAmount > 0) {
            IERC20(bird).transferFrom(pool, msg.sender, rewardAmount);
        }
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "transfer error");
    }

    function _stake(address token, uint256 amount) private returns (uint256) {
        require(supportedTokens[token], "not support");
        require(amount > 0, "stake 0");
        Stake storage stake = stakes[msg.sender][token];

        uint256 rewardAmount = 0;
        if (stake.lastClaim != 0 && stake.amount > 0 && (stake.lastClaim + claimTime) <= block.timestamp) {
            rewardAmount = _claim(token);
        }
        stake.amount = stake.amount.add(amount);
        stake.lastClaim = block.timestamp;
        return rewardAmount;
    }

    function unStakeETH(uint256 amount) public {
        (uint256 receiveAmount, uint256 feeAmount) = _unStake(weth, amount);
        (bool success,) = msg.sender.call{value:receiveAmount}(new bytes(0));
        require(success, "un-stake eth error");
        (success,) = pool.call{value:feeAmount}(new bytes(0));
        require(success, "transfer fee error");
    }

    function unStakeToken(address token, uint256 amount) public {
        (uint256 receiveAmount, uint256 feeAmount) = _unStake(token, amount);
        require(IERC20(token).transfer(msg.sender, receiveAmount), "un-stake error");
        require(IERC20(token).transfer(pool, feeAmount), "transfer fee error");
    }

    function _unStake(address token, uint256 amount) private returns (uint256, uint256) {
        Stake storage stake = stakes[msg.sender][token];
        require(amount > 0 && stake.amount >= amount, "can not un-stake");
        stake.amount = stake.amount.sub(amount);
        uint256 fee = amount.mul(unStakeFee).div(100);
        return (amount.sub(fee), fee);
    }

    function claim(address token) public {
        uint256 rewardAmount = _claim(token);
        IERC20(bird).transferFrom(pool, msg.sender, rewardAmount);
    }

    function _claim(address token) private returns (uint256)  {
        Stake storage stake = stakes[msg.sender][token];
        require(stake.amount > 0, "not have any to claim");
        require((stake.lastClaim + claimTime) <= block.timestamp, "period not pass");
        uint256 periods = block.timestamp.sub(stake.lastClaim).div(claimTime);
        stake.lastClaim = stake.lastClaim.add(periods.mul(claimTime));

        uint256 amountOut = 0;
        if (token == weth) {
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = bird;
            uint[] memory amounts = router.getAmountsOut(stake.amount, path);
            amountOut = amounts[amounts.length-1];
        } else if (token == bird) {
            amountOut = stake.amount;
        } else {
            address[] memory path = new address[](3);
            path[0] = token;
            path[1] = weth;
            path[2] = bird;
            uint[] memory amounts = router.getAmountsOut(stake.amount, path);
            amountOut = amounts[amounts.length-1];
        }
        require(amountOut > 0, "amount out is 0");

        uint256 rewardAmount = amountOut.mul(reward).div(1000).mul(periods);
        stake.earned = stake.earned.add(rewardAmount);
        return rewardAmount;
    }

}