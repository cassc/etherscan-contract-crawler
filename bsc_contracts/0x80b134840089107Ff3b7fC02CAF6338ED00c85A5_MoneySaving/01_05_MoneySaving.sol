// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoneySaving is Ownable {
    using Address for address;
    using SafeMath for uint256;

    uint private unlockTime = 0;
    uint private lockDuration = 120;

    function deposit() external payable onlyOwner {
        setTime();
    }

    function setTime() private {
        if (unlockTime == 0) unlockTime = block.timestamp + lockDuration;
    }

    function setLockDuration(uint _lockDuration) external onlyOwner {
        require(_lockDuration > lockDuration, 'You cannot decrease lockDuration');
        lockDuration = _lockDuration;
        unlockTime = block.timestamp + lockDuration;
    }

    function increaseLockTime(uint _secondsToIncrease) external onlyOwner {
        uint _unlockTime = unlockTime.add(_secondsToIncrease);
        require(_unlockTime > unlockTime, "Cannot decrease time");
        unlockTime = _unlockTime;
    }

    function withdraw() external onlyOwner {
        require(balance() > 0, "insufficient funds");
        require(block.timestamp > unlockTime, "lock time has not expired");

        (bool sent, ) = payable(_msgSender()).call{value: balance()}("");
        require(sent, "Failed to send");
        unlockTime = 0;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRemainTime() public view returns (uint) {
        if (unlockTime > block.timestamp)
            return unlockTime.sub(block.timestamp);
        return 0;
    }

    function getCurrentTime() public view returns (uint) {
        return block.timestamp;
    }

    function getUnlockTime() public view returns (uint) {
        return unlockTime;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Not supported");
    }

    receive() external payable {
        setTime();
    }

    fallback() external payable {
        setTime();
    }
}