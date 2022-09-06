// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IConfetti.sol";

contract MintAndDisperse {
    uint256 public constant cost = 100 * 10**18;

    error LengthMismatch();
    error FailedConfettiTransfer();

    IConfetti public immutable Confetti;

    ISummon public immutable Summon;

    constructor(IConfetti _confetti, ISummon _summon) {
        Confetti = _confetti;
        Summon = _summon;

        Confetti.approve(address(_summon), type(uint256).max);
    }

    function execute(
        uint256 total,
        address[] calldata to,
        uint256[] calldata counts
    ) external {
        if (to.length != counts.length) {
            revert LengthMismatch();
        }

        if (!Confetti.transferFrom(msg.sender, address(this), total * cost)) {
            revert FailedConfettiTransfer();
        }

        for (uint256 i; i < to.length; i++) {
            Summon.mintFightersTo(to[i], counts[i]);
        }
    }
}

interface ISummon {
    function mintFightersTo(address, uint256) external;
}