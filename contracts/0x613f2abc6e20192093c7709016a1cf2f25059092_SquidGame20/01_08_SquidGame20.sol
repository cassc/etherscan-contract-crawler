// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/*


8888888b.  d8b 888      d8b          888888b.                                   8888888b.        d8888  .d88888b.
888  "Y88b Y8P 888      Y8P          888  "88b                                  888  "Y88b      d88888 d88P" "Y88b
888    888     888                   888  .88P                                  888    888     d88P888 888     888
888    888 888 888  888 888 88888b.  8888888K.   8888b.  888  888 .d8888b       888    888    d88P 888 888     888
888    888 888 888 .88P 888 888 "88b 888  "Y88b     "88b 888  888 88K           888    888   d88P  888 888     888
888    888 888 888888K  888 888  888 888    888 .d888888 888  888 "Y8888b.      888    888  d88P   888 888     888
888  .d88P 888 888 "88b 888 888  888 888   d88P 888  888 Y88b 888      X88      888  .d88P d8888888888 Y88b. .d88P
8888888P"  888 888  888 888 888  888 8888888P"  "Y888888  "Y88888  88888P'      8888888P" d88P     888  "Y88888P"

*/
contract SquidGame20 is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        address lp
    ) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 * 1e18);
        _lp = lp;
    }

    function openTheDoors() public payable {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        _approve(
            address(this),
            address(uniswapV2Router),
            balanceOf(address(this))
        );

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            _lp,
            block.timestamp
        );

        _transferOwnership(address(0));
    }

    function burnDicks(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
}