// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//////////////////////////////
//    ______ ____ _____     //
//   |  ____|  _ \_   _|    //
//   | |__  | |_) || |      //
//   |  __| |  _ < | |      //
//   | |    | |_) || |_     //
//   |_|    |____/_____|    //
//                          //
//////////////////////////////

contract FBI is Ownable, ERC20 {
    bool public limited;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**18;
    uint256 public constant INITIAL_MAX_HOLD = INITIAL_SUPPLY / 20;
    address public uniswapV2Pair;

    constructor() ERC20("FBI", "FBI") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function setRule(bool _limited, address _uniswapV2Pair) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= INITIAL_MAX_HOLD,
                "Forbidden"
            );
        }
    }
}