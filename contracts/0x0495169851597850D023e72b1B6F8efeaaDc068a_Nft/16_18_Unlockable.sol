pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Unlockable is Ownable {
    bool public unlockableContent;

    function enableUnlockable() public onlyOwner returns (bool) {
        unlockableContent = true;
        return unlockableContent;
    }

    function disableUnlockable() public onlyOwner returns (bool) {
        unlockableContent = false;
        return unlockableContent;
    }

    function getUnlockStatus() public view returns (bool) {
        return unlockableContent;
    }
}