// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/ERC20.sol";
import "./common/UniSwapPoolUSDT.sol";

contract Token888 is ERC20, UniSwapPoolUSDT {
    bool public inTrading;
    uint256 startedAt;
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address[] memory _router, address[] memory _path, address[] memory _sellPath) ERC20(_name, _symbol) {
        super._mint(_msgSender(), _totalSupply);
        super.__Rates_init(_msgSender(), 700, 700, _sellPath);
        super.__Limit_init(3*10**decimals(), 3*10**decimals(), 5*10**decimals());
        super.__SwapPool_init(_router[0], _router[1], 3 ether);
        super.setExclude(_msgSender());
        super.setExclude(address(this));
        super.setExcludes(_sellPath);
        _approve(_msgSender(), address(router), type(uint256).max);
        _approve(address(this), address(router), type(uint256).max);
    }

    function openTrading() public onlyOwner {
        inTrading = true;
        startedAt = block.timestamp;
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
                require(inTrading || isLiquidityer(to), "please waiting for liquidity");
                super.checkLimitTokenBuy(to, amount);
                fees = _handFeeBuys(from, amount);
            }
        } else if (isPair(to)) {
            if (!isExcludes(from)) {
                super.checkLimitTokenSell(amount);
                fees = _handFeeSells(from, amount);
                handSwap();
            }
        } else {
            if (!isExcludes(from) && !isExcludes(to)) super.checkLimitTokenBuy(to, amount);
        }
        super._takeTransfer(from, to, amount - fees);
    }

    function handSwap() internal {super.swapAndSend(balanceOf(address(this)));}

    function removeAllLimit() public onlyOwner {
        super.removeLimit();
        super.resetRates(300, 300);
    }
    function airdrop(uint256 amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount);}
    }
}