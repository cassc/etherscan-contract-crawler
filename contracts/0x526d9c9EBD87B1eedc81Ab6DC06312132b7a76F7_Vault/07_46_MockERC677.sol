// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC677} from "../interfaces/IERC20/IERC677.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC677Receiver} from "../interfaces/IERC20/IERC677Receiver.sol";

contract MockERC677 is IERC677, ERC20 {
    using Address for address;
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    constructor() ERC20("TestToken", "TTKN") {
        _mint(msg.sender, 10000 * (10**uint256(decimals())));
    }

    function transferAndCall(
        address _to,
        uint256 amount,
        bytes memory _data
    ) public override returns (bool success) {
        super.transfer(_to, amount);
        emit Transfer(msg.sender, _to, amount, _data);
        if (_to.isContract()) {
            _contractFallback(_to, amount, _data);
        }
        return true;
    }

    function _contractFallback(
        address _to,
        uint256 amount,
        bytes memory _data
    ) private {
        IERC677Receiver receiver = IERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, amount, _data);
    }
}