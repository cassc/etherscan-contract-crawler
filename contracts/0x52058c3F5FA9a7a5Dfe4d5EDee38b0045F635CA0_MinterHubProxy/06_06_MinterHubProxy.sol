//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Interfaces.sol";

contract MinterHubProxy {
    using SafeERC20 for IERC20;

    Hub public hub;

    constructor(Hub _hub) {
        hub = _hub;
    }

    function callAndTransferToChain(
        address to,
        bytes calldata data,
        IERC20 tokenFrom,
        uint256 tokenFromAmount,
        IERC20 tokenTo,
        address refundTo,
        bytes32 destinationChain,
        bytes32 destination,
        uint256 fee
    ) public payable {
        if (msg.value == 0) {
            // deposit "tokenFrom" to this contract
            tokenFrom.transferFrom(msg.sender, address(this), tokenFromAmount);

            // approve "to" contract to spend "tokenFrom"
            tokenFrom.approve(to, tokenFromAmount);
        } else {
            require(address(tokenFrom) == 0x0000000000000000000000000000000000000000 && tokenFromAmount == 0, "MinterHubProxy: set tokenFrom and tokenFromAmount to 0 when passing a value");
        }

        // call "to" contract and calculate the difference of balance of "tokenTo" before and after
        uint256 balanceBefore = tokenTo.balanceOf(address(this));
        Address.functionCallWithValue(to, data, msg.value);
        uint256 toDeposit = tokenTo.balanceOf(address(this)) - balanceBefore;

        // approve "tokenTo" to hub and call "transferToChain"
        tokenTo.approve(address(hub), toDeposit);
        hub.transferToChain(address(tokenTo), destinationChain, destination, toDeposit, fee);

        // refund any remaining tokens
        if (msg.value == 0) {
            if (tokenFrom.balanceOf(address(this)) > 0) {
                tokenFrom.transfer(refundTo, tokenFrom.balanceOf(address(this)));
            }
        } else {
            if (address(this).balance > 0) {
                Address.sendValue(payable(refundTo), address(this).balance);
            }
        }
    }
}