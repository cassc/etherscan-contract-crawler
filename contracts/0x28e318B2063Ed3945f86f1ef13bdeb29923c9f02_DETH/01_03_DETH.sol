// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title DETH Wrapper Contract
/// @dev Users can deposit $ETH assets to this contract and receive $DETH back.
/// Every $DETH is backed by $ETH at a 1:1 ratio.
/// @author BlockHub DAO

contract DETH is ERC20("DETH Wrapper", "DETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}