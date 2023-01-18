// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBNBHandler.sol";
import "./interfaces/IWBNB.sol";

/*
    This contract is used because of restriction after Istanbul hardfork. Namely, there's
    gas limit in address.transfer function call. And this function is used by WBNB so
    we running out of gas every time we're calling withdraw method and trying to receive
    native BNB on upgradeable contract which uses DELEGATE_CALL to proxy call to it's
    implementation. This contract can be used to bypass this limitation this way:
      1) WBNB.transfer(address(BNBHandler), 1 ether);
      2) BNBHandler.withdraw(address(BNBHandler), 1 ether);
*/
contract BNBHandler is IBNBHandler {
    receive() external payable {
        emit Received(msg.value, msg.sender);
    }

    function withdraw(address wbnb, uint256 amount) external {
        IWBNB(wbnb).withdraw(amount);

        // using call against transfer to bypass "transfer"'s gas limit
        (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
        require(success, "BNBHandler: transfer_call_failed");

        emit Sent(amount, msg.sender);
    }
}