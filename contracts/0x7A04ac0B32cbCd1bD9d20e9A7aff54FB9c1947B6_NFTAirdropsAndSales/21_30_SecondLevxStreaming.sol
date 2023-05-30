// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "./LevxStreaming.sol";

contract SecondLevxStreaming is LevxStreaming {
    constructor(
        address _levx,
        address _signer,
        address _wallet,
        uint64 _deadline
    ) LevxStreaming(_levx, _signer, _wallet, _deadline) {}
}