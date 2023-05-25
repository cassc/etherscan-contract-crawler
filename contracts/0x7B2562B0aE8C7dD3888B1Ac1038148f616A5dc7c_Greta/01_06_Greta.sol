// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///////////////////////////////////////////
//   _____ _____  ______ _______         //
//  / ____|  __ \|  ____|__   __|/\      //
// | |  __| |__) | |__     | |  /  \     //
// | | |_ |  _  /|  __|    | | / /\ \    //
// | |__| | | \ \| |____   | |/ ____ \   //
//  \_____|_|  \_\______|  |_/_/    \_\. //
//                                       //
///////////////////////////////////////////     

contract Greta is Ownable, ERC20 {
    bool public limited;
    uint256 public constant INITIAL_SUPPLY = 36800000000 * 10**18;
    uint256 public constant INITIAL_MAX_HOLD = 1288000000 * 10**18;
    address public uniswapV2Pair;
    
    constructor() ERC20("Greta", "GRETA") {
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
    ) override internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= INITIAL_MAX_HOLD , "Forbidden");
        }
    }
}