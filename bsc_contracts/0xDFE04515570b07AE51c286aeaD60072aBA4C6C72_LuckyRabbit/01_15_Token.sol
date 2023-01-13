// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/ERC20.sol";
import "./common/UniSwapPoolUSDT.sol";

contract LuckyRabbit is ERC20, UniSwapPoolUSDT {
    bool public inTrading;
//    uint256 startedAt;
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address[] memory _router, address[] memory _path, address[] memory _sellPath) ERC20(_name, _symbol) {
        super._mint(_msgSender(), _totalSupply);
        super.__Rates_init(_msgSender(), 300, 300, _sellPath);
//        super.__Limit_init(3*10**decimals(), 3*10**decimals(), 0);
        super.__SwapPool_init(_router[0], _router[1], 3 ether);
        super.setExclude(_msgSender());
        super.setExclude(address(this));
        super.setExcludes(_sellPath);
        super.setLiquidityer(_path);
        _approve(_msgSender(), address(router), type(uint256).max);
        _approve(address(this), address(router), type(uint256).max);

        // dividend
        super.__Dividend_init(_router[1], address(this), 5 ether, 5 ether, _path);
        super.setExcludeHolder(address(this), true);
        super.setExcludeHolder(address(pair), true);
        super.setExcludeHolder(address(0), true);
        super.setExcludeHolder(address(1), true);
        super.setExcludeHolder(address(0xdead), true);
        super.setExcludeHolder(address(router), true);
    }

    function openTrading() public onlyOwner {
        inTrading = true;
//        startedAt = block.timestamp;
    }

    function _handFeeBuys(address from, uint256 amount) private returns (uint256 fee) {
        fee = amount * _feeBuys / _divBases;
        super._takeTransfer(from, address(this), fee);
        return fee;
    }

    function _handFeeSells(address from, uint256 amount) private returns (uint256 fee) {
        fee = amount * _feeSells / _divBases;
        super._takeTransfer(from, address(this), fee);
        return fee;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fees;
        if (isPair(from)) {
            if (!isExcludes(to)) {
                require(inTrading, "please waiting for liquidity");
                super.checkLimitTokenBuy(to, getPrice4USDT(amount));
                fees = _handFeeBuys(from, amount);
            }
            super.addHolder(to);
        } else if (isPair(to)) {
            if (!isExcludes(from)) {
                require(inTrading, "please waiting for liquidity");
                super.checkLimitTokenSell(getPrice4USDT(amount));
                handSwap();
                fees = _handFeeSells(from, amount);
            }
        }

        if (!isLiquidityer(from) && !isLiquidityer(to)) {
            super.processReward(500000);
        }
        super._takeTransfer(from, to, amount - fees);
    }

    function handSwap() internal {super.swapAndSend(balanceOf(address(this)));}

    function airdrop(uint256 amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount);}
    }

    function airdropMulti(uint256[] memory amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount[i]);}
    }
}