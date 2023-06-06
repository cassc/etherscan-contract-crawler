// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IETHHandler.sol";
import "./interfaces/IWETH.sol";

/*
    This contract is used because of restriction after Istanbul hardfork. Namely, there's
    gas limit in address.transfer function call. And this function is used by WETH so
    we running out of gas every time we're calling withdraw method and trying to receive
    native ETH on upgradeable contract which uses DELEGATE_CALL to proxy call to it's
    implementation. This contract can be used to bypass this limitation this way:
      1) WETH.transfer(address(ETHHandler), 1 ether);
      2) ETHHandler.withdraw(address(ETHHandler), 1 ether);
*/
contract ETHHandler is IETHHandler {
    receive() external payable {
        emit Received(msg.value, msg.sender);
    }

    function withdraw(address weth, uint256 amount) external {
        IWETH(weth).withdraw(amount);

        // using call against transfer to bypass "transfer"'s gas limit
        (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
        require(success, "ETHHandler: transfer_call_failed");

        emit Sent(amount, msg.sender);
    }
}