// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// Dynamic cap starts at 25.000.000
uint constant MIN_DYNAMIC_CAP = 25000000e18;
// mint restriction: 10.000.000 (precisely 10000000000000000030176000) per year broken down to seconds. Assuming a year is exactly 365 days or 31536000 seconds.
uint constant UNITS_PER_SECOND = 317097919837645866;
// seconds until dynamic cap will equal hard cap
// Calculated as: (CAP - MIN_DYNAMIC_CAP) / UNITS_PER_SECOND
// Equals ~7.5 years
uint constant DYNAMIC_CAP_DURATION = 236520000;

contract BrightToken is ERC20, Ownable {
    // 100.000.000 hard cap
    uint256 public constant cap = 100000000e18;
    // deployment timestamp
    uint256 public created = block.timestamp;
    // minting can be locked until this timestamp is reached
    uint256 public mintingLockedUntil = 0;

    constructor()
        ERC20("Bright", "BRIGHT")
    {}

    /**
     * @dev Returns the dynamic cap based on time. Will never exceed hardcap.
     */
    function dynamicCap() public view returns (uint256) {
        // How much time passed since deployment
        uint age_seconds = block.timestamp - created;
        assert(age_seconds >= 0);
        // shortcut in case dynamic cap would exceed hardcap.
        if (age_seconds >= DYNAMIC_CAP_DURATION) {
            return cap;
        }
        return MIN_DYNAMIC_CAP + (age_seconds * UNITS_PER_SECOND);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        // Are we allowed to mint at all?
        require(block.timestamp > mintingLockedUntil, "Minting locked");
        // prevent minting more than dynamic cap
        require(ERC20.totalSupply() + amount <= dynamicCap(), "cap exceeded");
        _mint(to, amount);
    }

    function setMintingLock(uint256 timestamp) public onlyOwner {
        require(timestamp > mintingLockedUntil, "locktime can not be decreased");
        require(timestamp > block.timestamp, "locktime can not be in the past");
        mintingLockedUntil = timestamp;
    }
}