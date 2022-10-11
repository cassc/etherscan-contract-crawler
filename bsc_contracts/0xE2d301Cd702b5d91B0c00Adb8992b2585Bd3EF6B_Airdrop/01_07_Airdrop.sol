// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./Sweeper.sol";

contract Airdrop is Sweeper {
    address[] empty;

    constructor() Sweeper(empty, true) {}

    function doAirdrop(address[] calldata dests, uint256[] calldata values) public onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
            payable(dests[i]).transfer(values[i]);
            i += 1;
        }
        return (i);
    }

    receive() external payable {}
}