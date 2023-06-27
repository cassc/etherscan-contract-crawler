// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/**
|   \(_)__ _ _ __  ___ _ _  __| |
 | |) | / _` | '  \/ _ \ ' \/ _` |
 |___/|_\__,_|_|_|_\___/_||_\__,_|
 | || |__ _ _ _  __| |___
 | __ / _` | ' \/ _` (_-<
 |_||_\__,_|_||_\__,_/__/

 Diamonds are forever.
*/
contract DiamondHands is ERC20, Ownable {
    address public uniswapV2Pair;

    constructor() ERC20("Diamond Hands", "DIAMONDS") {
        _mint(address(this), 100_000_000 * 1e18);
        _transfer(address(this), msg.sender, (totalSupply() * 4) / 100);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function startTrading() public payable {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
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
            owner(),
            block.timestamp
        );

        renounceOwnership();
    }
}