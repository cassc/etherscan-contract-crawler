/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address,uint) external returns (bool);
}

contract Faucet {
    address private constant INU = 0x67372e5b5279044E188E1a25cA95975BB9b7a0e8;

    uint last;

    function drip() external {
        require(block.timestamp - last > 4 hours, 'wait');
        require(msg.sender == tx.origin, 'contract');
        last = block.timestamp;
        IERC20(INU).transfer(msg.sender, 1e17);
    }
}