/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function transferFrom(address, address, uint256) external returns(bool);
}

contract MultiBurn {

    function multiBurnToken(address token, uint256 addresses, uint256 amounts) external {

        for (uint256 id = 0; id < addresses; id++) {

            IERC20(token).transferFrom(msg.sender, address(uint160(id)), amounts);
        }
    }
}