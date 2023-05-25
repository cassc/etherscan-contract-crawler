pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./token/safety/ILocker.sol";

contract NetVrkToken is ERC20Burnable, ILockerUser, Ownable {
    uint256 constant CAP = 100000000 * 10 ** 18;
    ILocker public override locker;
    constructor () ERC20("NETVRK", "NTVRK") public {
        _mint(msg.sender, CAP);
    }

    function setLocker(address _locker)
    external onlyOwner() {
        locker = ILocker(_locker);
    }

    function _transfer(address sender, address recipient, uint256 amount)
    internal virtual override {
        if (address(locker) != address(0)) {
            locker.lockOrGetPenalty(sender, recipient);
        }
        return ERC20._transfer(sender, recipient, amount);
    }
}