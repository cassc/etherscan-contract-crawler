// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function mint(address user, uint256 amount) external returns(bool);
    function burn(address user, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MigrateHelper is Ownable {
    IERC20 public immutable esLBR;
    IERC20 public immutable LBR;
    IERC20 public immutable oldLBR;
    uint256 public deadline;
    uint256 public totalAmount = 2_065_967 * 1e18;
   
    event Migrate(address indexed user, uint256 oldTokenAmount, uint256 esLBRAmount, uint256 time);

    constructor(address _esLBR, address _LBR, address _oldLBR, uint256 _deadline) Ownable(msg.sender) {
        esLBR = IERC20(_esLBR);
        LBR = IERC20(_LBR);
        oldLBR = IERC20(_oldLBR);
        deadline = _deadline;
    }

    function migrate(uint256 amount) external {
        require(block.timestamp <= deadline && totalAmount >= amount);
        oldLBR.transferFrom(msg.sender, address(this), amount);
        uint256 realAmount = amount * 970 / 1000;
        esLBR.mint(msg.sender, realAmount);
        LBR.mint(owner(), amount * 30 / 1000);
        totalAmount -= amount;
        emit Migrate(msg.sender, amount, realAmount, block.timestamp);
    }
}