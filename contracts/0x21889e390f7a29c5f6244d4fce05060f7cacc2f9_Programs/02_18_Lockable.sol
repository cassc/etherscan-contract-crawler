pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Lockable is Ownable {
    mapping(address => bool) public blockStatus;

    function isLocked(address to) public view returns (bool) {
        return blockStatus[to];
    }

    function lock(address to) public onlyOwner {
        require(to != owner(), 'cannot lock owner address');
        require(!isLocked(to), 'address already locked');

        blockStatus[to] = true;
    }

    function unlock(address to) public onlyOwner {
        require(isLocked(to), 'address is not locked');
        blockStatus[to] = false;
    }
}