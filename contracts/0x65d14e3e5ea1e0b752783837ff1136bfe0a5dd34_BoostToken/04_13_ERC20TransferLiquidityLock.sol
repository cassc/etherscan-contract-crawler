// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistAdminRole.sol";
import "./ERC20Distributable.sol";
import "../BoostToken.sol";

contract ERC20TransferLiquidityLock is IERC20, ERC20Distributable, WhitelistAdminRole {
    using SafeMath for uint256;

    event Rebalance(uint256 tokenBurnt);
    event RewardLiquidityProviders(uint256 liquidityRewards);

    address public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) unlocked;

    // How much tokens to lock on each transfer, 100 = 1%, 50 = 2%, 25 = 4%, etc
    uint256 public callerRewardDivisor;
    uint256 public rebalanceDivisor;

    uint256 public minRebalanceAmount;
    uint256 public lastRebalance;
    uint256 public rebalanceInterval;

    uint256 public lpUnlocked;
    bool public locked;

    Balancer balancer;

    event LpFeeTaken(address from, uint256 amount);

    constructor() public {
        lastRebalance = block.timestamp;
        callerRewardDivisor = 50;
        rebalanceDivisor = 50;
        rebalanceInterval = 1 hours;
        lpUnlocked = block.timestamp + 90 days;
        minRebalanceAmount = 100 ether;

        balancer = new Balancer();

        _isFeeless[address(this)] = true;
        _isFeeless[address(balancer)] = true;
        _isFeeless[msg.sender] = true;
        locked = false;
        unlocked[msg.sender] = true;
        unlocked[address(balancer)] = true;
    }

    // receive eth from uniswap swap
    function() external payable {}

    function setUniswapV2Router(address _uniswapV2Router) public onlyWhitelistAdmin {
        require(uniswapV2Router == address(0), "BoostToken::setUniswapV2Router: already set");
        uniswapV2Router = _uniswapV2Router;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) public onlyWhitelistAdmin {
        require(uniswapV2Pair == address(0), "BoostToken::setUniswapV2Pair: already set");
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setRebalanceDivisor(uint256 _rebalanceDivisor) public onlyWhitelistAdmin {
        if (_rebalanceDivisor != 0) {
            require(_rebalanceDivisor >= 10, "BoostToken::setRebalanceDivisor: too small");
        }
        rebalanceDivisor = _rebalanceDivisor;
    }

    function setRebalanceInterval(uint256 _interval) public onlyWhitelistAdmin {
        rebalanceInterval = _interval;
    }

    function setCallerRewardDivisior(uint256 _rewardDivisor) public onlyWhitelistAdmin {
        if (_rewardDivisor != 0) {
            require(_rewardDivisor >= 10, "BoostToken::setCallerRewardDivisor: too small");
        }
        callerRewardDivisor = _rewardDivisor;
    }

    function unlockLP() public onlyWhitelistAdmin {
        require(now > lpUnlocked, "Not unlocked yet");
        uint256 amount = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).transfer(msg.sender, amount);
    }

    function toggleFeeless(address account) public onlyWhitelistAdmin {
        _isFeeless[account] = !_isFeeless[account];
    }

    function toggleUnlockable(address account) public onlyWhitelistAdmin {
        unlocked[account] = !unlocked[account];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (locked && unlocked[from] != true && unlocked[to] != true) {
            revert("ERC20TransferLiquidityLock: Locked until the end of the presale");
        }
        super._transfer(from, to, amount);
    }

    function getBalancerAddress() public view onlyWhitelistAdmin returns (address) {
        return address(balancer);
    }

    function rebalanceLiquidity() public {
        require(balanceOf(msg.sender) >= minRebalanceAmount, "ERC20TransferLiquidityLock: You have to own enough tokens");
        require(block.timestamp > lastRebalance + rebalanceInterval, 'ERC20TransferLiquidityLock: Too soon to re-balance');
        require(uniswapV2Pair != address(0), "ERC20TransferLiquidityLock: Uniswap pair is not set");

        lastRebalance = block.timestamp;

        // Take 2% from the Uniswap pool of tokens...
        uint256 amountToRemove = IERC20(uniswapV2Pair).balanceOf(address(this)).div(rebalanceDivisor);
        // Exchange them for ETH, which is sent to the Balancer...
        remLiquidity(amountToRemove);
        // Balancer uses the ETH to buy tokens back,
        // then sends 4% of tokens to the caller and burns other tokens
        uint _locked = balancer.rebalance(callerRewardDivisor);

        emit Rebalance(_locked);
    }

    // Removes tokens from liquidity pool and send result ETH to the Balancer
    function remLiquidity(uint256 lpAmount) private returns (uint ETHAmount) {
        IERC20(uniswapV2Pair).approve(uniswapV2Router, lpAmount);
        (ETHAmount) = IUniswapV2Router02(uniswapV2Router)
        .removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            lpAmount,
            0,
            0,
            address(balancer),
            block.timestamp
        );
    }

    // returns token amount
    function lockableSupply() external view returns (uint256) {
        return balanceOf(address(this));
    }

    // returns token amount
    function lockedSupply() external view returns (uint256) {
        uint256 lpTotalSupply = IERC20(uniswapV2Pair).totalSupply();
        uint256 lpBalance = lockedLiquidity();
        uint256 percentOfLpTotalSupply = lpBalance.mul(1e12).div(lpTotalSupply);

        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        uint256 _lockedSupply = uniswapBalance.mul(percentOfLpTotalSupply).div(1e12);
        return _lockedSupply;
    }

    // returns token amount
    function burnedSupply() external view returns (uint256) {
        uint256 lpTotalSupply = IERC20(uniswapV2Pair).totalSupply();
        uint256 lpBalance = burnedLiquidity();
        uint256 percentOfLpTotalSupply = lpBalance.mul(1e12).div(lpTotalSupply);

        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        uint256 _burnedSupply = uniswapBalance.mul(percentOfLpTotalSupply).div(1e12);
        return _burnedSupply;
    }

    // returns LP amount, not token amount
    function burnableLiquidity() public view returns (uint256) {
        return IERC20(uniswapV2Pair).balanceOf(address(this));
    }

    // returns LP amount, not token amount
    function burnedLiquidity() public view returns (uint256) {
        return IERC20(uniswapV2Pair).balanceOf(address(0));
    }

    // returns LP amount, not token amount
    function lockedLiquidity() public view returns (uint256) {
        return burnableLiquidity().add(burnedLiquidity());
    }
}


contract Balancer {
    using SafeMath for uint256;
    BoostToken token;
    address public burnAddr = 0x000000000000000000000000000000000000dEaD;

    constructor() public {
        token = BoostToken(msg.sender);
    }

    function() external payable {}

    function rebalance(uint callerRewardDivisor) external returns (uint256) {
        require(msg.sender == address(token), "only token");

        swapEthForTokens(address(this).balance);

        uint256 lockableBalance = token.balanceOf(address(this));
        uint256 callerReward = lockableBalance.div(callerRewardDivisor);
        uint256 burnAmount = lockableBalance.sub(callerReward);

        token.transfer(tx.origin, callerReward);
        token.transfer(burnAddr, burnAmount);

        return burnAmount;
    }

    function swapEthForTokens(uint256 EthAmount) private {
        address[] memory uniswapPairPath = new address[](2);
        uniswapPairPath[0] = IUniswapV2Router02(token.uniswapV2Router()).WETH();
        uniswapPairPath[1] = address(token);

        token.approve(token.uniswapV2Router(), EthAmount);

        IUniswapV2Router02(token.uniswapV2Router())
        .swapExactETHForTokensSupportingFeeOnTransferTokens.value(EthAmount)(
            0,
            uniswapPairPath,
            address(this),
            block.timestamp
        );
    }
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
}

interface IUniswapV2Pair {
    function sync() external;
}