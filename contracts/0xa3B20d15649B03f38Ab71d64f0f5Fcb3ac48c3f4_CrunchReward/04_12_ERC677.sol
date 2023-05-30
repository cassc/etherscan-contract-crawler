// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC677.sol";
import "./IERC677.sol";
import "./IERC677Receiver.sol";

abstract contract ERC677 is IERC677, ERC20 {
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bool success) {
        super.transfer(recipient, amount);

        emit TransferAndCall(msg.sender, recipient, amount, data);

        if (isContract(recipient)) {
            IERC677Receiver receiver = IERC677Receiver(recipient);
            receiver.onTokenTransfer(msg.sender, amount, data);
        }

        return true;
    }

    function isContract(address addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(addr)
        }
        return length > 0;
    }
}