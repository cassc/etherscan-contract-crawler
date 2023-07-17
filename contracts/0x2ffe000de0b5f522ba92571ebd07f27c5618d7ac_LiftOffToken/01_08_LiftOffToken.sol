// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/**

              ,,      ,...                         ,...  ,...
`7MMF'        db    .d' ""mm         .g8""8q.    .d' "".d' ""
  MM                dM`   MM       .dP'    `YM.  dM`   dM`
  MM        `7MM   mMMmmmmMMmm     dM'      `MM mMMmm mMMmm
  MM          MM    MM    MM       MM        MM  MM    MM
  MM      ,   MM    MM    MM       MM.      ,MP  MM    MM
  MM     ,M   MM    MM    MM       `Mb.    ,dP'  MM    MM
.JMMmmmmMMM .JMML..JMML.  `Mbmo      `"bmmd"'  .JMML..JMML.


Fasten Your Seatbelts for the moon

*/
contract LiftOffToken is ERC20, Ownable {
    constructor() ERC20("We Have Lift Off", "LIFTOFF") {
        _mint(address(this), 10_000_000 * 1e18);
        _transfer(address(this), msg.sender, (totalSupply() * 4) / 100);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function startTrading() public payable {
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
            address(0x000000000000000000000000000000000000dEaD),
            block.timestamp
        );

        renounceOwnership();
    }
}