// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRouter {
    function WETH() external view returns (address);
    function factory() external view returns (address);
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
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract Locker {
    uint256 unlockAt;
    IERC20 token;
    address receiver;
    bool public isUnlocked = false;
    IRouter router;

    constructor(IERC20 token_, IRouter router_, address receiver_) {
        unlockAt = block.timestamp + (14 days);
        token = token_;
        router = router_;
        receiver = receiver_;
    }

    function canUnlock() public view returns (bool) {
        return block.timestamp > unlockAt && !isUnlocked;
    }

    function unlock() public {
        require(canUnlock() && msg.sender == address(token), "can not unlock");

        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);

        IERC20 pair = IERC20(IFactory(router.factory()).getPair(address(token), router.WETH()));
        uint256 liquidity = pair.balanceOf(address(this));
        if (liquidity > 0) {
            pair.transfer(receiver, liquidity);
        }

        isUnlocked = true;
    }
}

contract HITCOIN is ERC20, Ownable {
    using SafeMath for uint256;

    IRouter public immutable router;
    address public constant zeroAddr = address(0);
    address public constant deadAddr = address(0xdead);

    bool swapping;

    address public teamWallet;

    uint256 supply = 69420 * 1e6 * 1e18;
    uint256 maxWallet = supply * 1 / 100; // 1%
    uint256 maxSell = supply * 5 / 1000; // 0.5%

    uint256 constant fee = 2;
    uint256 constant liquidity = 1; // 1%
    uint256 constant burn = 1; // 1%
    uint256 transferFeeAt = supply * 5 / 10000; // 0.05

    mapping(address=>uint256) _sellAmount;
    mapping(address=>uint256) _firstSell;
    uint256 constant limitSellPeriod = 6 hours; // 6 hours

    uint256 constant init = 10; // 10%
    uint256 constant team = 25; // 1/4 to team
    uint256 constant lock = 75; // 3/4 lock in 90 days
    Locker public locker;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public swapPairs;

    constructor(IRouter router_, address team_) ERC20("HIT COIN", "$HIT") {
        router = router_;
        address swapPair = IFactory(router.factory()).createPair(address(this), router.WETH());
        swapPairs[swapPair] = true;
        teamWallet = team_;
        locker = new Locker(IERC20(this), router, teamWallet);

        excludeFromFee(teamWallet, true);
        excludeFromFee(address(locker), true);
        excludeFromFee(owner(), true);
        excludeFromFee(address(this), true);
        excludeFromFee(deadAddr, true);

        _approve(address(this), address(router), ~uint256(0));

        uint256 initAmount = supply.mul(init).div(100);
        uint256 teamAmount = initAmount.mul(team).div(team+lock);
        _mint(teamWallet, teamAmount);
        _mint(address(locker), initAmount.sub(teamAmount));
        _mint(owner(), supply.sub(initAmount));
    }

    receive() external payable {}

    function unlock() public {
        require(locker.canUnlock(), "can not unlock");
        swapping = true;
        locker.unlock();
        swapping = false;
    }

    function excludeFromFee(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFee[account] = isExcluded;
    }

    function setPair(address addr, bool isSwapPair) public {
        require(msg.sender == owner() || msg.sender == teamWallet, "not right caller");
        swapPairs[addr] = isSwapPair;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != zeroAddr, "ERC20: transfer from the zero address");
        require(to != zeroAddr, "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 feeInContract = balanceOf(address(this));
        bool canSwap = feeInContract >= transferFeeAt;
        if (
            canSwap &&
            !swapPairs[from] &&
            !swapping &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            swapping = true;
            _swapAndTransferFee(feeInContract);
            swapping = false;
        }

        bool takeFee = !swapping;

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 feeAmount = 0;
            if (swapPairs[to]) {
                require(_antiDump(amount, from), "can not sell");
            }

            if (swapPairs[to] || swapPairs[from]) {
                feeAmount = amount.mul(fee).div(100);
            }

            if (feeAmount > 0) {
                super._transfer(from, address(this), feeAmount);
                amount = amount.sub(feeAmount);
            }
        }

        if (!swapping && locker.canUnlock()) {
            unlock();
        }

        _checkMaxWallet(from, to, amount);

        super._transfer(from, to, amount);
    }

    function _checkMaxWallet(address from, address to, uint256 amount) private view {
        if(!isExcludedFromFee[from] && !isExcludedFromFee[to] && !swapPairs[to] && to != deadAddr){
            require(balanceOf(to).add(amount) <= maxWallet, "max wallet");
        }
    }

    function _antiDump(uint256 amount, address seller) private returns (bool) {
        uint256 firstSell = _firstSell[seller];
        if (block.timestamp >= firstSell.add(limitSellPeriod)) {
            _firstSell[seller] = block.timestamp;
            _sellAmount[seller] = amount;
        } else {
            uint256 sellAmount = _sellAmount[seller];
            if (sellAmount.add(amount) > maxSell) {
                return false;
            }
            _sellAmount[seller] = _sellAmount[seller].add(amount);
        }

        return true;
    }

    function _swapAndTransferFee(uint256 feeAmount) private {
        uint256 liquidityAmount = feeAmount.mul(liquidity).div(liquidity+burn);
        uint256 burnAmount = feeAmount.sub(liquidityAmount);
        super._transfer(address(this), deadAddr, burnAmount);
        _swapAndAddLiquidity(liquidityAmount);
    }

    function _swapAndAddLiquidity(uint256 amount) private {
        uint256 swapAmount = amount.div(2);
        _swapForETH(swapAmount);
        _addLiquidity(amount.sub(swapAmount), address(this).balance);
    }

    function _swapForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            locker.isUnlocked() ? teamWallet:address(locker),
            block.timestamp);
    }
}