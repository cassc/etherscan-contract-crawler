// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MasterChefFunds is Ownable {
    using SafeERC20 for IERC20;

    address public fief;

    address public masterChef;

    constructor(address _fief, address _owner) {
        require(_fief != address(0x0), "!fief");
        require(_owner != address(0x0), "!owner");
        fief = _fief;
        _transferOwnership(_owner);
    }

    function balanceOfFief() public view returns (uint256) {
        return IERC20(fief).balanceOf(address(this));
    }

    function setMasterChef(address _masterChef) external onlyOwner {
        require(_masterChef != masterChef, "!master_chef");

        if (masterChef != address(0x0)) {
            IERC20(fief).safeApprove(masterChef, 0);
        }
        if (_masterChef != address(0x0)) {
            IERC20(fief).safeApprove(_masterChef, type(uint256).max);
        }
        masterChef = _masterChef;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        uint256 balance = balanceOfFief();
        uint256 balanceToWithdraw = _amount == 0 || _amount > balance ? balance : _amount;
        IERC20(fief).safeTransfer(owner(), balanceToWithdraw);
    }
}