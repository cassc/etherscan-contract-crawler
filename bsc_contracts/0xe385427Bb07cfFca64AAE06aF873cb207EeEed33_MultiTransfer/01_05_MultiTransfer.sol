// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MultiTransfer {
    ERC20 constant token = ERC20(0x55d398326f99059fF775485246999027B3197955);

    struct Transfer {
        address addr;
        uint256 amount;
    }

    function tst(Transfer[] calldata transfers) external {
        for (uint8 i = 0; i < transfers.length; i++) {
            token.transfer(transfers[i].addr, transfers[i].amount);
        }
    }
}