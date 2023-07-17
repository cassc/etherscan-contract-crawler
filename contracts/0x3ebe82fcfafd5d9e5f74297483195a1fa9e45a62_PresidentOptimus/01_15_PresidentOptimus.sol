// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "./Dividend/DividendTracker.sol";

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
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract PresidentOptimus is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    address public constant zeroAddr = 0x0000000000000000000000000000000000000000;

    IRouter public immutable router;
    IFactory private immutable factory;
    address private immutable weth;
    address private pair = zeroAddr;

    bool private swapping;

    address public marketing = 0x1bcc0cbE5f0427DB89745Cb9d3876c7A01CBe03B;

    uint8 private constant _decimals = 18;
    uint256 private supply = 1e9 * 1e18;

    uint256 public fee = 3;
    uint256 private startTime;
    bool private starting;

    uint256 private constant reward = 2;
    uint256 private transferFeeAt = supply * 5 / 10000; // 0.05%

    mapping(address => bool) public isExcludedFromFee;

    DividendTracker public dividendTracker;
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    uint256 public gasForProcessing = 300000;
    uint256 private miniumForDividend = supply / 1000; // 0.1%

    constructor(IRouter router_) ERC20("President Optimus", "P-OPTIMUS") {
        router = router_;
        weth = router.WETH();
        factory = IFactory(router.factory());

        dividendTracker = new DividendTracker(address(this), miniumForDividend);
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(msg.sender);
        dividendTracker.excludeFromDividends(address(router));

        excludeFromFee(marketing, true);
        excludeFromFee(owner(), true);
        excludeFromFee(address(this), true);

        _approve(address(this), address(router), ~uint256(0));

        _mint(owner(), supply);
    }

    receive() external payable {}

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(
            gas
        );
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function excludeFromFee(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFee[account] = isExcluded;
    }

    function isSwapPair(address addr) private returns (bool) {
        if(pair == zeroAddr) {
            pair = factory.getPair(weth, address(this));
            if (pair == zeroAddr) {
                return false;
            }
            dividendTracker.excludeFromDividends(pair);
        }
        return pair != zeroAddr && pair == addr;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != zeroAddr, "ERC20: transfer from the zero address");
        require(to != zeroAddr, "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (startTime == 0 && isSwapPair(to)) {
            starting = true;
            fee = 5;
            startTime = block.timestamp;
        } else if (starting == true && block.timestamp >= (startTime + 60)) {
            fee = 3;
            starting = false;
        }

        uint256 feeInContract = balanceOf(address(this));
        bool canSwap = feeInContract >= transferFeeAt;
        if (
            canSwap &&
            !isSwapPair(from) &&
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
            if(isSwapPair(from) || isSwapPair(to)) {
                feeAmount = amount.mul(fee).div(100);
            }

            if (feeAmount > 0) {
                super._transfer(from, address(this), feeAmount);
                amount = amount.sub(feeAmount);
            }
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function _swapAndTransferFee(uint256 feeAmount) private {
        uint256 rewardAmount = feeAmount.mul(reward).div(fee);

        _swapForETH(feeAmount.sub(rewardAmount));
        payable(marketing).sendValue(address(this).balance);

        super._transfer(address(this), address(dividendTracker), rewardAmount);
        dividendTracker.distributeRewardDividends(rewardAmount);
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
}