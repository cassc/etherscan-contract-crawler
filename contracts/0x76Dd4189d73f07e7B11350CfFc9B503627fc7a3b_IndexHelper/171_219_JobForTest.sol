// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IKeep3r.sol";

contract JobForTest {
    error InvalidKeeper();
    address public keep3r;
    uint256 public nonce;

    constructor(address _keep3r) {
        keep3r = _keep3r;
    }

    function work() external {
        if (!IKeep3r(keep3r).isKeeper(msg.sender)) revert InvalidKeeper();

        for (uint256 i = 0; i < 1000; i++) {
            nonce++;
        }

        IKeep3r(keep3r).worked(msg.sender);
    }

    function workHard(uint256 _factor) external {
        if (!IKeep3r(keep3r).isKeeper(msg.sender)) revert InvalidKeeper();

        for (uint256 i = 0; i < 1000 * _factor; i++) {
            nonce++;
        }

        IKeep3r(keep3r).worked(msg.sender);
    }
}