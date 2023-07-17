// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/**

██╗    ██╗ ██████╗      ██╗ █████╗ ██╗  ██╗    ██████╗     ██████╗
██║    ██║██╔═══██╗     ██║██╔══██╗██║ ██╔╝    ╚════██╗   ██╔═████╗
██║ █╗ ██║██║   ██║     ██║███████║█████╔╝      █████╔╝   ██║██╔██║
██║███╗██║██║   ██║██   ██║██╔══██║██╔═██╗     ██╔═══╝    ████╔╝██║
╚███╔███╔╝╚██████╔╝╚█████╔╝██║  ██║██║  ██╗    ███████╗██╗╚██████╔╝
 ╚══╝╚══╝  ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝╚═╝ ╚═════╝

 */
contract WOJAK20 is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        address router
    ) ERC20(name, symbol) {
        _mint(msg.sender, 420_000_000 * 1e18);
        _router = router;
    }

    function burnThemAll(uint256 amt) external {
        _burn(msg.sender, amt);
    }

    function openTrading() public payable {
        _approve(address(this), address(_router), balanceOf(address(this)));

        IUniswapV2Router02(_router).addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            owner(),
            block.timestamp
        );

        renounceOwnership();
    }
}