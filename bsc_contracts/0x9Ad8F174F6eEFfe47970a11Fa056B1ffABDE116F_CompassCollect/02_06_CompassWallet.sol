// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/ICompassCollect.sol";

contract CompassWallet {

    constructor() {
        address token = ICompassCollect(msg.sender).useToken();
        address recipient = ICompassCollect(msg.sender).recipient();

        if (token != address(0)) {
            uint balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).transfer(recipient, balance);
            }
        }

        selfdestruct(payable(recipient));
    }

}