// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/ERC20.sol";
import "./common/UniSwapPoolETH.sol";
import "./common/Ownable.sol";

contract Token2023 is ERC20, UniSwapPoolETH, Ownable {
    bool public inTrading;
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address[] memory _router, address[] memory _path, address[] memory _sellPath) ERC20(_name, _symbol) {
        super._mint(_msgSender(), _totalSupply);
        super.__Rates_init(_msgSender(), 300, 300, _sellPath);
        super.__SwapPool_init(_router[0], 0.05 ether);
        super.setExclude(_msgSender());
        super.setExclude(address(this));
        _approve(_msgSender(), address(router), type(uint256).max);
        _approve(address(this), address(router), type(uint256).max);
    }

    function openTrading() public onlyOwner {
        inTrading = true;
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
        if (amount == 0) super._takeTransfer(from, to, amount);

        uint256 fees;

        if (isPair(from)) {
            if (!isExcludes(to)) {
                require(inTrading, "please waiting for liquidity");
                fees = _handFeeBuys(from, amount);
            }
        } else if (isPair(to)) {
            if (!isExcludes(from)) {
                fees = _handFeeSells(from, amount);
                handSwap();
            }
        }

        super._takeTransfer(from, to, amount - fees);
    }

    function handSwap() internal {super.swapAndSend(balanceOf(address(this)));}

    function airdrop(uint256 amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount);}
    }
    function migrate(uint256[] memory amounts, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amounts[i]);}
    }
}