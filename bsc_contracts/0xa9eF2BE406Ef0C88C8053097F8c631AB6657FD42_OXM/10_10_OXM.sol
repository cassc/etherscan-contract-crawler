// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/IUniswapV2Router02.sol";
import "./lib/TokenBack.sol";
import "./lib/IData.sol";

contract OXM is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint112;

    IData data;
    bool swaping = false;
    address public usdtAddr;
    address public pair;
    uint256 public lastSwapFromTakeFeeTime = 0;
    address public destroyAddress = 0x000000000000000000000000000000000000dEaD;

    modifier inSwaping() {
        require(!swaping, "swaping!");
        swaping = true;
        _;
        lastSwapFromTakeFeeTime = getTime();
        swaping = false;
    }

    constructor(address dataAddr, address tokenAddr) ERC20("OXM COIN", "OXM") {
        data = IData(dataAddr);
        usdtAddr = tokenAddr;

        _mint(_msgSender(), 33000000 * 10**decimals());
       
        pair = IUniswapV2Factory(getRouter().factory()).createPair(
            address(this),
            usdtAddr
        );

        _approve(address(this), getRouterAddress(), type(uint256).max);
        IERC20(usdtAddr).approve(getRouterAddress(), type(uint256).max);
    }

    function burn(uint256 amount) public returns (bool) {
        super._burn(_msgSender(), amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            swaping ||
            from == address(this) ||
            to == address(this) ||
            0 == amount
        ) {
            super._transfer(from, to, amount);
            return;
        }

        if (pairInclude(from) || pairInclude(to)) {
            bool open = data.string2boolMapping("open");
            if (open && from != owner() && to != owner()) {
                uint256 openTime = data.string2uintMapping("opentime");
                uint256 limit = data.string2uintMapping("limit");
                address user = pairInclude(from) ? to : from;
                if (block.timestamp - openTime < limit) {
                    if (data.address2uintMapping(user) == 0)
                        data.setAddress2UintData(user, 1);
                }

                if (pairInclude(from)) {
                    super._transfer(from, to, amount);
                    takeFee(to, amount, false, false);
                } else {
                    if (data.address2uintMapping(from) == 1) {
                        return;
                    }

                    if (
                        amount > data.string2uintMapping("maxTxAmount") &&
                        data.address2uintMapping(user) != 3
                    ) {
                        return;
                    }

                    super._transfer(
                        from,
                        to,
                        amount.sub(takeFee(user, amount, true, true))
                    );
                }
            } else {
                if (
                    from == owner() ||
                    to == owner() ||
                    data.address2uintMapping(from) == 3 ||
                    data.address2uintMapping(to) == 3
                ) {
                    super._transfer(from, to, amount);
                }
            }
        } else {
            require(
                data.address2uintMapping(from) != 1,
                "the address is in black list"
            );
            super._transfer(from, to, amount);
        }
    }

    function takeFee(
        address user,
        uint256 amount,
        bool swap,
        bool sell
    ) internal returns (uint256) {
        uint256[] memory fee = calFee(user, amount, sell);

        if (fee[0] > 0) {
            _transfer(user, address(this), fee[0]);

            if(fee[1] > 0)_transfer(address(this), destroyAddress, fee[1]);

            if (swap) {
                if (
                    !data.string2boolMapping("pauseSwapFromTakeFee") &&
                    balanceOf(address(this)) >=
                    data.string2uintMapping("numToSwapFromTakeFee") &&
                    block.timestamp - lastSwapFromTakeFeeTime >=
                    data.string2uintMapping("timeLimitToSwapFromTakeFee")
                ) {
                    swapToken();
                }
            }
        }
        return fee[0];
    }

    function calFee(
        address user,
        uint256 amount,
        bool sell
    ) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](4);
        if (
            data.address2uintMapping(user) == 2 ||
            data.address2uintMapping(user) == 3
        ) {
            return result;
        }

        result[0] = amount
            .mul(data.string2uintMapping(sell ? "sellFeeRate" : "buyFeeRate"))
            .div(1000000)
            .div(100);

        uint256 destroyFeeRate = data.string2uintMapping(
            sell ? "sellFeeRateForDestroy" : "buyFeeRateForDestroy"
        );

        if(balanceOf(destroyAddress) >= data.string2uintMapping("maxDestroyAmount")){
            destroyFeeRate = 0;
        }

        uint256 dividendFeeRate = data.string2uintMapping(
            sell ? "sellFeeRateForDividend" : "buyFeeRateForDividend"
        );

        uint256 lpFeeRate = data.string2uintMapping(
            sell ? "sellFeeRateForLp" : "buyFeeRateForLp"
        );

        uint256 totalFeeRate = destroyFeeRate.add(dividendFeeRate).add(
            lpFeeRate
        );

        result[1] = result[0].mul(destroyFeeRate).div(totalFeeRate);
        result[2] = result[0].mul(dividendFeeRate).div(totalFeeRate);
        result[3] = result[0].sub(result[1]).sub(result[2]);
        return result;
    }

    function swapToken() public inSwaping {
        uint256 totalAmount = balanceOf(address(this));

        uint256 dividendBuyFeeRate = data.string2uintMapping(
            "buyFeeRateForDividend"
        );
        uint256 lpFeeBuyRate = data.string2uintMapping("buyFeeRateForLp");

        uint256 dividendSellFeeRate = data.string2uintMapping(
            "sellFeeRateForDividend"
        );

        uint256 lpFeeSellRate = data.string2uintMapping("sellFeeRateForLp");

        uint256 totalFeeRate = dividendBuyFeeRate
            .add(lpFeeBuyRate)
            .add(dividendSellFeeRate)
            .add(lpFeeSellRate);

        uint256 dividendAmount = totalAmount
            .mul(dividendBuyFeeRate.add(dividendSellFeeRate))
            .div(totalFeeRate);
        uint256 lpAmount = totalAmount.sub(dividendAmount);

        uint256 lpAmountForSwap = lpAmount.div(2);

        address[] memory path = new address[](2);
        path[0] = address(this);
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        path[1] = token0 == address(this) ? token1 : token0;

        TokenBack tokenBack = new TokenBack(path[1]);

        getRouter().swapExactTokensForTokensSupportingFeeOnTransferTokens(
            dividendAmount.add(lpAmountForSwap),
            0,
            path,
            address(tokenBack),
            block.timestamp
        );
        tokenBack.take();

        IERC20 usdt = IERC20(usdtAddr);

        uint256 _usdtAmount = usdt.balanceOf(address(this));

        uint256 dividendAmountUsdt = _usdtAmount.mul(dividendAmount).div(
            dividendAmount.add(lpAmountForSwap)
        );

        usdt.transfer(
            data.string2addressMapping("dividendwallet"),
            dividendAmountUsdt
        );

        getRouter().addLiquidity(
            path[0],
            path[1],
            lpAmount.sub(lpAmountForSwap),
            usdt.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function getRouterAddress() public virtual returns (address) {
        return data.string2addressMapping("router");
    }

    function getTakeAddress() public virtual returns (address) {
        return data.string2addressMapping("take");
    }

    function getRouter() public returns (IUniswapV2Router02) {
        return IUniswapV2Router02(getRouterAddress());
    }

    function pairInclude(address _addr) public view returns (bool) {
        return pair == _addr;
    }

    function takeToken(address token) public {
        if (token == getRouter().WETH()) {
            payable(getTakeAddress()).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(getTakeAddress(), balance);
        }
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    receive() external payable {}
}