// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Token is ERC20PresetMinterPauser, Ownable {

    uint256 public unlockTime;
    uint256 public unlockPercent;
    uint256 public duration;
    uint256 public constant total = 32000 * 10**9 * 10**18;

    mapping(address => User) public users;
    using SafeMath for uint256;

    struct User {
        uint256 lockedBalance;
        uint256 unlockPerSecond;
        uint256 unlockAt;
    }

    struct Airdrop {
        address wallet;
        uint256 amount;
    }

    constructor() ERC20PresetMinterPauser("Pond2.0X", "PNDX") {
        unlockTime    = 1694736000;
        unlockPercent = 1;
        duration      = 2592000;

        _mint(msg.sender, total);
    }

    function setUnLockTime(uint256 _unlockTime) onlyOwner external {
        require(_unlockTime > block.timestamp, "Unlock Time Invalid");
        unlockTime = _unlockTime;
    }

    function setUnlockPercent(uint8 _unlockPercent) onlyOwner external {
        require(_unlockPercent > 0, "Unlock Percent Invalid");
        unlockPercent = _unlockPercent;
    }

    function setDuration(uint8 _duration) onlyOwner external {
        require(_duration > 0, "Duration Invalid");
        duration = _duration;
    }

    function mint(address to, uint256 amount) public override {
        revert('Exceed Total Supply');
    }

    function transferLockToken(address _wallet, uint256 _amount) public {
        users[_wallet].lockedBalance   = users[_wallet].lockedBalance.add(_amount);
        users[_wallet].unlockPerSecond = users[_wallet].lockedBalance.mul(unlockPercent).div(100).div(duration);

        super.transfer(_wallet, _amount);
    }

    function batchTransferLockToken(Airdrop[] memory _airdrops) public {
        for (uint256 i = 0; i < _airdrops.length; i++) {
            // don't use this.transferTokenLock because payer modifier
            address wallet = _airdrops[i].wallet;
            uint256 amount = _airdrops[i].amount;

            users[wallet].lockedBalance = users[wallet].lockedBalance.add(amount);
            users[wallet].unlockPerSecond = users[wallet].lockedBalance.mul(unlockPercent).div(100).div(duration);

            super.transfer(wallet, amount);
        }
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        uint256 availableAmount = getAvailableBalance(_msgSender());
        require(availableAmount >= _amount, "Not Enough Available Token");

        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        uint256 availableAmount = getAvailableBalance(_from);
        require(availableAmount >= _amount, "Not Enough Available Token");

        return super.transferFrom(_from, _to, _amount);
    }

    function getAvailableBalance(address _wallet) public view returns (uint256) {
        return balanceOf(_wallet).sub(users[_wallet].lockedBalance);
    }

    function getLockedBalance(address _wallet) public view returns (uint256) {
        return users[_wallet].lockedBalance;
    }

    function unlock() public {
        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp >= unlockTime, "Not Unlock Time");

        address sender = _msgSender();
        require(users[sender].lockedBalance > 0, "No Token Locked To Be Unlocked");

        if (users[sender].unlockAt < unlockTime) // Default
            users[sender].unlockAt = unlockTime;

        uint256 unlockAmount = getUnlockAmount(sender, currentTimestamp);
        require(unlockAmount > 0, "Zero Unlock Amount");

        users[sender].lockedBalance = users[sender].lockedBalance.sub(unlockAmount);
        users[sender].unlockAt = currentTimestamp;
    }

    function getUnlockAmount(address _wallet, uint256 _currentTimestamp) public view returns (uint256) {
        uint256 diff = _currentTimestamp.sub(users[_wallet].unlockAt);
        uint256 unlockAmount = diff.mul(users[_wallet].unlockPerSecond);

        return unlockAmount > users[_wallet].lockedBalance ? users[_wallet].lockedBalance : unlockAmount;
    }
}