// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit UNI in Compound and earn interest.
contract CompoundStrategyUNI is CompoundStrategy {
    string public constant NAME = "Compound-Strategy-UNI";
    string public constant VERSION = "3.0.2";

    // cUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550
    constructor(address _pool, address _swapManager)
        CompoundStrategy(_pool, _swapManager, 0x35A18000230DA775CAc24873d00Ff85BccdeD550)
    {}
}