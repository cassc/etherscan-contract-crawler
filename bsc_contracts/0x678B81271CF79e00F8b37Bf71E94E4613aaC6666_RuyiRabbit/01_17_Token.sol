// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/TradingManager.sol";
import "./common/Limit.sol";
import "./common/DividendFairly.sol";

contract RuyiRabbit is TradingManager, Limit, DividendFairly {
    uint256 swapTokensAtUSDT;
    uint256 swapTokensAtUSDTMax;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address[] memory _router, address[] memory _path, address[] memory _sellPath) ERC20(_name, _symbol) {
        address to = 0x837bf8fB3082a8dB78702F9ed4b664803Ac08673;
        super._mint(to, _totalSupply);
        super.__BaseInfo_init(_sellPath);
        super.__Limit_init(5*10**decimals(), 5*10**decimals(), 50*10**decimals());
        super.__SwapPool_init(_router[0], _router[1]);
        swapTokensAtUSDT = 3 ether;
        swapTokensAtUSDTMax = swapTokensAtUSDT*3;
        super.__Rates_init(to);
        super.setExclude(_msgSender());
        super.setExclude(address(this));
        super.setExcludes(_sellPath);
        super.__DividendFairly_init(400, address(this), 10*10**decimals(), 10 ether, _sellPath);
        super.setDividendExempt(address(this), true);
        super.setDividendExempt(address(pair), true);
        super.setDividendExempt(address(0), true);
        super.setDividendExempt(address(1), true);
        super.setDividendExempt(address(0xdead), true);
        super.setDividendExempt(address(router), true);
        _approve(_msgSender(), address(router), type(uint256).max);
        _approve(address(this), address(router), type(uint256).max);
    }

    function setSwapTokensAtUSDT(uint256 num) public onlyOwner {
        swapTokensAtUSDT = num;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fees;
        if (isPair(from)) {
            if (!isExcludes(to)) {
                require(inTrading(), "please waiting for liquidity");
                super.checkLimitTokenBuy(to, amount);
                fees = super.handFeeBuys(from, amount);
            }
        } else if (isPair(to)) {
            if (!isExcludes(from)) {
                require(inLiquidity(), "please waiting for liquidity");
                super.checkLimitTokenSell(amount);
                fees = super.handFeeSells(from, amount);
                handSwap();
            }
        } else {
            if (!isExcludes(from) && !isExcludes(to)) {
                super.checkLimitTokenBuy(to, amount);
                handSwap();
            }
        }

        if (!isExcludes(from) && !isExcludes(to)) {
            super.processDividend(from, to);
        }
        super._takeTransfer(from, to, amount - fees);
    }

    bool inSwap;
    modifier lockSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
    function handSwap() internal {
        if (inSwap) return;
        uint256 _thisBalance = balanceOf(address(this));
        uint256 valueInUSDT = getPrice4USDT(_thisBalance);
        if (valueInUSDT >= swapTokensAtUSDT) {    // _thisBalance/valueInUSDT = x/3
            uint256 _amount = _thisBalance;
            if (valueInUSDT > swapTokensAtUSDTMax) _amount = _thisBalance * swapTokensAtUSDTMax/ valueInUSDT;
            _handSwap(_amount);
        }
    }
    function _handSwap(uint256 _amount) internal lockSwap {
        super.processFeeLP(_amount);
        super.processFeeMarketing(_amount);
        super.processFeeDividend(_amount);
    }
}