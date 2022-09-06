// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelBlossomSimpleReveal is Ownable {
    uint public startRevealTimestamp;
    uint public revealInterval;
    uint public revealStates;
    bool public revealLocked = false;

    constructor(uint _revealInterval, uint _revealStates) {
        revealInterval = _revealInterval;
        revealStates = _revealStates;
    }

    function lockReveal() external onlyOwner {
        revealLocked = true;
    }

    function setStartRevealTimestamp(uint value) external onlyOwner {
        require(!revealLocked, "PixelBlossomSimpleReveal: Reveal is locked");

        startRevealTimestamp = value;
    }

    function state() external view returns(uint) {
        if (startRevealTimestamp > block.timestamp || startRevealTimestamp == 0) {
            return 0;
        }
        uint value = (block.timestamp - startRevealTimestamp) / (revealInterval / revealStates);
        return value < revealStates ? value : revealStates;
    }
}