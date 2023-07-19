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
        uint256 stakeAt;
    }

    address public bird;
    address public weth;
    address public pool;
    IRouter public router;

    mapping(address => mapping(address => Stake)) public stakes;
    mapping(address => bool) public supportedTokens;
    uint256 public unStakeFee = 4;
    uint256 public stakeTime = 7 days;
    uint256 public apr = 25;
    uint256 public minimalStake = 1 * 1e9;

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

    function setStakeTime(uint256 time) public onlyOwner {
        require(time > 0, "time is zero");
        stakeTime = time;
    }

    function setApr(uint256 apr_) public onlyOwner {
        require(apr_ > 0, "apr is zero");
        apr = apr_;
    }

    function stakeETH() public payable {
        uint256 wethAmount = msg.value;
        uint256 rewardAmount = _stake(weth, wethAmount);
        IWETH(weth).deposit{value: wethAmount}();
        IWETH(weth).transfer(pool, wethAmount);
        if (rewardAmount > 0) {
            IERC20(bird).transferFrom(pool, msg.sender, rewardAmount);
        }
    }

    function stakeToken(address token, uint256 amount) public {
        require(token != weth, "please use stakeETH function");
        uint256 rewardAmount = _stake(token, amount);
        if (rewardAmount > 0) {
            IERC20(bird).transferFrom(pool, msg.sender, rewardAmount);
        }
        require(IERC20(token).transferFrom(msg.sender, pool, amount), "transfer error");
    }

    function _stake(address token, uint256 amount) private returns (uint256) {
        require(supportedTokens[token], "not support");
        require(amount >= minimalStake, "stake too small");
        Stake storage stake = stakes[msg.sender][token];

        uint256 rewardAmount = 0;
        if (stake.amount > 0 && stake.lastClaim <= block.timestamp) {
            rewardAmount = _claim(token);
        }
        stake.amount = stake.amount.add(amount);
        stake.lastClaim = block.timestamp;
        stake.stakeAt = block.timestamp;
        return rewardAmount;
    }

    function unStakeETH() public {
        Stake memory stake = stakes[msg.sender][weth];
        if (stake.amount > 0 && stake.lastClaim < block.timestamp) {
            claim(weth);
        }
        (uint256 receiveAmount, uint256 feeAmount) = _unStake(weth);
        uint256 ethAmount = receiveAmount.add(feeAmount);
        IWETH(weth).transferFrom(pool, address(this), ethAmount);
        IWETH(weth).withdraw(ethAmount);
        (bool success,) = msg.sender.call{value:receiveAmount}(new bytes(0));
        require(success, "un-stake eth error");
        if (feeAmount > 0) {
            (success,) = pool.call{value:feeAmount}(new bytes(0));
            require(success, "transfer fee error");
        }
    }

    function unStakeToken(address token) public {
        require(token != weth, "please use unStakeETH function");
        Stake memory stake = stakes[msg.sender][token];
        if (stake.amount > 0 && stake.lastClaim < block.timestamp) {
            claim(token);
        }
        (uint256 receiveAmount,) = _unStake(token);
        require(IERC20(token).transferFrom(pool, msg.sender, receiveAmount), "un-stake error");
    }

    function _unStake(address token) private returns (uint256, uint256) {
        Stake storage stake = stakes[msg.sender][token];
        require(stake.amount > 0, "can not un-stake");
        uint256 amount = stake.amount;
        uint256 fee = 0;
        if (block.timestamp < stake.stakeAt.add(stakeTime)) {
            fee = amount.mul(unStakeFee).div(100);
            amount = amount.sub(fee);
        }
        stake.amount = 0;
        stake.stakeAt = 0;
        stake.earned = 0;
        stake.lastClaim = 0;
        return (amount, fee);
    }

    function claim(address token) public {
        uint256 rewardAmount = _claim(token);
        IERC20(bird).transferFrom(pool, msg.sender, rewardAmount);
    }

    function _claim(address token) private returns (uint256)  {
        Stake storage stake = stakes[msg.sender][token];
        require(stake.amount > 0 && stake.lastClaim <= block.timestamp, "can not claim");

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

        uint256 rewardAmount = amountOut
            .mul(apr).div(100)
            .mul(block.timestamp.sub(stake.lastClaim)).div(365 days);
        stake.lastClaim = block.timestamp;
        stake.earned = stake.earned.add(rewardAmount);
        return rewardAmount;
    }

}