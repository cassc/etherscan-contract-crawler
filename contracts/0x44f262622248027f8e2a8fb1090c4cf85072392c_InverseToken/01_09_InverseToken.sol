pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../token/safety/ILocker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract InverseToken is ERC20Burnable, ILockerUser, Ownable {
    uint256 constant CAP = 90000000 * 10 ** 18;
    ILocker public override locker;
    constructor () ERC20("INVERSE", "XIV") public {
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