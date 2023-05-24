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
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract SpiderInu is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    address public constant zeroAddr = address(0);

    IRouter public immutable router;
    address public swapPair;

    bool private swapping;

    uint256 private marketingShare = 6;
    address private marketing = 0xC261b30adD25f53A9238D1e3f031397108E654E2;
    uint256 private poolShare = 2;
    address private pool = 0x88FbccD2D05849E829cbA148508116B8415e06DF;

    uint256 private supply = 100 * 1e3 * 1e9 * 1e9;

    uint256 public fee = 8;
    uint256 private startBlock;
    bool private starting;
    uint256 private maxBuy = supply;

    uint256 private transferFeeAt = supply * 5 / 10000; // 0.05%

    mapping(address => bool) public isExcludedFromFee;

    constructor(IRouter router_) ERC20("Spider Inu", "$SPINU") {
        router = router_;
        swapPair = IFactory(router.factory()).createPair(address(this), router.WETH());

        excludeFromFee(marketing, true);
        excludeFromFee(pool, true);
        excludeFromFee(owner(), true);
        excludeFromFee(address(this), true);

        _approve(address(this), address(router), ~uint256(0));

        _mint(owner(), supply);
    }

    receive() external payable {}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function excludeFromFee(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFee[account] = isExcluded;
    }

    function _firstBlocksProcess(address to) private {
        if (startBlock == 0 && to == swapPair) {
            starting = true;
            fee = 15;
            startBlock = block.number;
            maxBuy = supply / 100; // max buy 1%
            return;
        } else if (starting == true && block.number > (startBlock + 3)) {
            fee = 8;
            starting = false;
            maxBuy = supply;
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
        bool canSwap = feeInContract >= transferFeeAt;
        if (
            canSwap &&
            from != swapPair &&
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
            if(from == swapPair) {
                require(amount <= maxBuy, "can not buy");
                feeAmount = amount.mul(fee).div(100);
            } else if(to == swapPair) {
                feeAmount = amount.mul(fee).div(100);
            }

            if (feeAmount > 0) {
                super._transfer(from, address(this), feeAmount);
                amount = amount.sub(feeAmount);
            }
        }

        super._transfer(from, to, amount);
    }

    function _swapAndTransferFee(uint256 feeAmount) private {
        _swapForETH(feeAmount);
        uint256 ethAmount = address(this).balance;
        uint256 marketingAmount = ethAmount.mul(marketingShare).div(marketingShare+poolShare);
        payable(marketing).sendValue(marketingAmount);
        payable(pool).sendValue(ethAmount.sub(marketingAmount));
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