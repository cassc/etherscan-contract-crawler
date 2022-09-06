//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./interfaces/ICheapSwapFactory.sol";

contract CheapSwapTokenOutAddress {
    address public recipient;
    address public tokenOut;
    ICheapSwapFactory public cheapSwapFactory;

    constructor(address _recipient, address _tokenOut) {
        recipient = _recipient;
        tokenOut = _tokenOut;
        cheapSwapFactory = ICheapSwapFactory(msg.sender);
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    receive() external payable {
        cheapSwapFactory.amountInETH_amountOutMin{value: msg.value}(tokenOut, recipient);
    }
}