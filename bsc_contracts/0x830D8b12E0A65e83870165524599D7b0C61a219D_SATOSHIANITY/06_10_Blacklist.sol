pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklist is Ownable {
    mapping(address => bool) public isBlacklisted;

    function setBlacklist(address addr, bool blacklisted) public onlyOwner {
        isBlacklisted[addr] = blacklisted;
    }
}