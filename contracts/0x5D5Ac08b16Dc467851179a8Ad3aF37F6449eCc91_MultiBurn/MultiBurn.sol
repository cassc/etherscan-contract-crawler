/**
 *Submitted for verification at Etherscan.io on 2023-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function transferFrom(address, address, uint256) external returns(bool);
}

contract MultiBurn {

    function multiBurnToken(address token, uint256 startAddress, uint256 endAddress, uint256 amounts) external {

        for (uint256 id = startAddress; id <= endAddress; id++) {

            IERC20(token).transferFrom(msg.sender, address(uint160(id)), amounts);
        }
    }
}