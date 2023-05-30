// SPDX-License-Identifier: WTFPL
import "./Ownable.sol";
pragma solidity >=0.8.0;


contract Timelocked is Ownable {

    uint256 public unlocked; // timestamp unlock migration
    uint256 public modify;   // timestamp disallow changes

    /**
    * @dev Require unlock time met
    */
    modifier onlyUnlocked() {
        require(block.timestamp >= unlocked, "Timelock#onlyUnlocked: not unlocked");
        _;
    }

    /**
    * @dev Require modifier time not met
    */
    modifier onlyModify() {
        require(block.timestamp < modify, "Timelock#onlyModify: cannot modify");
        _;
    }

    constructor(uint256 unlock_, uint256 modify_, address owner_) {
        require(unlock_ > block.timestamp, 'Timelock#not greater');
        unlocked = unlock_;
        modify = modify_;
        _setOwner(owner_);
    }

    function updateUnlock(
        uint256 unlock_
    ) 
        public
        onlyOwner
        onlyModify
    {
        unlocked = unlock_;
    }
}