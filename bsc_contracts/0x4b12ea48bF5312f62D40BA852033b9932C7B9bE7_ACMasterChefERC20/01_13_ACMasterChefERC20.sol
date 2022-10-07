// SPDX-License-Identifier: MIT

//// _____.___.__       .__       ._____      __      .__   _____  ////
//// \__  |   |__| ____ |  |    __| _/  \    /  \____ |  |_/ ____\ ////
////  /   |   |  |/ __ \|  |   / __ |\   \/\/   /  _ \|  |\   __\  ////
////  \____   |  \  ___/|  |__/ /_/ | \        (  <_> )  |_|  |    ////
////  / ______|__|\___  >____/\____ |  \__/\  / \____/|____/__|    ////
////  \/              \/           \/       \/                     ////

pragma solidity 0.8.9;

import './AutoCompoundVault.sol';

interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;
}

/**
 * @title AutoCompound MasterChef
 * @notice vault for auto-compounding tokens on pools using a standard MasterChef contract
 * @author YieldWolf
 */
contract ACMasterChefERC20 is AutoCompoundVault {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _pid,
        address[6] memory _addresses
    ) ERC20(_name, _symbol) AutoCompoundVault(_pid, _addresses) {}

    function _earnToStake(uint256 _earnAmount) internal override {
        if (stakeToken != earnToken) {
            _safeSwap(_earnAmount, address(earnToken), address(stakeToken));
        }
    }

    function _farmDeposit(uint256 amount) internal override {
        IFarm(masterChef).deposit(pid, amount);
    }

    function _farmWithdraw(uint256 amount) internal override {
        IFarm(masterChef).withdraw(pid, amount);
    }

    function _farmEmergencyWithdraw() internal override {
        IFarm(masterChef).emergencyWithdraw(pid);
    }

    function _totalStaked() internal view override returns (uint256 amount) {
        (amount, ) = IFarm(masterChef).userInfo(pid, address(this));
    }
}