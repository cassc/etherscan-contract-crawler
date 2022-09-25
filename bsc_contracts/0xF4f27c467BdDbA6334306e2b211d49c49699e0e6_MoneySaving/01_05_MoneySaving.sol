// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoneySaving is Ownable {
    using Address for address;
    using SafeMath for uint256;

    uint256 private unlockTime;
    uint256 private lockDuration = 120/*50 weeks*/;

    function deposit() external payable onlyOwner {
        if (unlockTime == 0) unlockTime = block.timestamp + lockDuration;
    }

    function increaseLockTime(uint256 _secondsToIncrease) external onlyOwner {
        uint256 _unlockTime = unlockTime.add(_secondsToIncrease);
        require(_unlockTime > unlockTime, "Cannot decrease time");
        unlockTime = _unlockTime;
    }

    function withdraw() external onlyOwner {
        require(balance() > 0, "insufficient funds");
        require(
            block.timestamp > unlockTime,
            "lock time has not expired"
        );

        (bool sent, ) = payable(_msgSender()).call{value: balance()}("");
        require(sent, "Failed to send");
    }

    function balance() public view onlyOwner returns(uint256){
        return _msgSender().balance;
    }

    function getUnlockTime() public view onlyOwner returns(uint256){
        return unlockTime;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Not supported");
    } 

    receive() external payable {}
    fallback() external payable {}
}