// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

contract SnailCoin is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    address private constant zeroAddr = 0x0000000000000000000000000000000000000000;

    IRouter private immutable router;
    IFactory private immutable factory;
    address private immutable weth;
    address public pair = zeroAddr;

    bool private swapping;

    address private marketing = 0x4D479791a077E1d4c5F6aD665d5B5DED105A1555;

    uint8 private constant _decimals = 18;
    uint256 private supply = 1000 * (10**9) * (10**18);

    uint256 public fee = 0;
    uint256 public maxTx = supply;
    uint256 private startTime;
    bool private starting;

    mapping(address => bool) public isExcludedFromFee;

    constructor(IRouter router_) ERC20("Snail Coin", "Snail") {
        router = router_;
        weth = router.WETH();
        factory = IFactory(router.factory());

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

    function excludeFromFee(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFee[account] = isExcluded;
    }

    function isSwapPair(address addr) private returns (bool) {
        if(pair == zeroAddr) {
            pair = factory.getPair(weth, address(this));
        }
        return pair != zeroAddr && pair == addr;
    }

    function _firstBlocksProcess(address to) private {
        if (startTime == 0 && isSwapPair(to)) {
            starting = true;
            fee = 5;
            startTime = block.timestamp;
            maxTx = supply / 100; // 1%
            return;
        } else if (starting == true) {
            // max tx 1% in first block
            if(maxTx < supply && block.timestamp >= (startTime + 12)) {
                maxTx = supply;
            }
            // fee in first 1min
            if(block.timestamp >= (startTime + 60)) {
                fee = 0;
                starting = false;
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != zeroAddr, "ERC20: transfer from the zero address");
        require(to != zeroAddr, "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        _firstBlocksProcess(to);

        uint256 feeInContract = balanceOf(address(this));
        if (
            feeInContract > 0 &&
            !isSwapPair(from) &&
            !swapping &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            swapping = true;
            _swapAndTransferFee();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 feeAmount = 0;
            if(isSwapPair(from) || isSwapPair(to)) {
                require(amount <= maxTx, "can not transfer");
                feeAmount = amount.mul(fee).div(100);
            }

            if (feeAmount > 0) {
                super._transfer(from, address(this), feeAmount);
                amount = amount.sub(feeAmount);
            }
        }

        super._transfer(from, to, amount);
    }

    function _swapAndTransferFee() private {
        _swapForETH(balanceOf(address(this)));
        payable(marketing).sendValue(address(this).balance);
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