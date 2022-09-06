// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MigrationHelper is Ownable {

    IERC20 public sylToken;
    IERC20 public oSylToken;

    event Migrate(address indexed _address, uint256 _amount);

    constructor(address _sylTokenAddr, address _oSylTokenAddr) {
        sylToken = IERC20(_sylTokenAddr);
        oSylToken = IERC20(_oSylTokenAddr);
    }

    fallback() external payable { }
    receive() external payable { }

    function migrate() external {
        uint256 balance = oSylToken.balanceOf(msg.sender);
        require(balance != 0, "MigrationHelper: Empty balance of MockSYL");
        oSylToken.transferFrom(msg.sender, address(this), balance);
        sylToken.transfer(msg.sender, balance);
        emit Migrate(msg.sender, balance);
    }

    function withdrawSyl() external onlyOwner {
        sylToken.transfer(owner(), sylToken.balanceOf(address(this)));
    }

    function setSylToken(address _sylTokenAddr) external onlyOwner {
        sylToken = IERC20(_sylTokenAddr);
    }

    function setOSylToken(address _oSylTokenAddr) external onlyOwner {
        oSylToken = IERC20(_oSylTokenAddr);
    }
}