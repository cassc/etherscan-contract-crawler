// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract QGPTIdo is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public projectAddress;
    IERC20 public usdt;
    uint256 public total;
    uint256 public investAmount;
    uint256 public startTime;
    uint256 public endTime;
    string[] public emails;

    event Join(address _user, string _email, uint256 _amount);

    constructor(
        IERC20 _usdt, 
        address _projectAddress, 
        uint256 _investAmount,
        uint256 _startTime, 
        uint256 _endTime
    ) {
        usdt = _usdt;
        projectAddress = _projectAddress;
        investAmount = _investAmount;
        startTime = _startTime;
        endTime = _endTime;
    }

    function setUsdt(IERC20 _usdt) public onlyOwner {
        usdt = _usdt;
    }

    function setInvestAmount(uint256 _investAmount) public onlyOwner {
        investAmount = _investAmount;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
         startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
         endTime = _endTime;
    }

    function setProjectAddress(address _projectAddress) public onlyOwner {
        projectAddress = _projectAddress;
    }

    function withdrawToken(IERC20 _token) public onlyOwner {
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }

    function emailLength() public view returns (uint256) {
        return emails.length;
    }

    function join(string memory _email) public nonReentrant {
        require(startTime != endTime && startTime != 0, "time wrong");
        require(projectAddress != address(0), "projectAddress wrong");
        require(investAmount != 0, "investAmount wrong");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "over time");
        usdt.safeTransferFrom(msg.sender, projectAddress, investAmount);
        total += investAmount;
        emails.push(_email);
        emit Join(msg.sender, _email, investAmount);
    }

    function getEmails() public view returns (string[] memory) {
        return emails;
    }

}