// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract SimpleDEXTax is ERC20 {

    address public immutable fund;
    address public immutable pair;

    constructor(address fund_, address factory_, address weth9_) ERC20("LFG", "LFG") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
        fund = fund_;
        // create a pair
        pair = IUniswapV2Factory(factory_).createPair(address(this), address(weth9_));
    }

    // checks whether the transfer is a swap
    function _isSwap(address sender_, address recipient_) internal view returns (bool result) {
        if (sender_ == pair || recipient_ == pair) {
            result = true;
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint tax = (amount / 100) * 100; // 5% tax

        if (_isSwap(sender, recipient)) {    
            super._transfer(sender, recipient, amount - tax);
            super._transfer(sender, fund, tax);
        } else {
            super._transfer(sender, recipient, amount);
        }

    }
}