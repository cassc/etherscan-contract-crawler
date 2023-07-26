// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IRewarderVault } from "./interfaces/IRewarderVault.sol";
import { IWrapperToken } from "./interfaces/IWrapperToken.sol";

contract RewarderVault is IRewarderVault, Ownable {
    using SafeERC20 for IWrapperToken;

    IWrapperToken public immutable rewardToken;
    address public override rewarder;
    address public guardian;

    constructor(address _rewardToken) Ownable() {
        guardian = msg.sender;
        rewardToken = IWrapperToken(_rewardToken);
    }

    function setGuardian(address newGuardian) external override onlyOwner {
        guardian = newGuardian;
        emit UpdateGuardian(newGuardian);
    }

    function fillVault(uint256 amount_) external onlyOwner {
        rewardToken.mint(address(this), amount_);
    }

    function lock() external override {
        require(msg.sender == guardian || msg.sender == owner(), "not guardian");
        if(rewarder != address(0)) {
            rewardToken.safeApprove(rewarder, 0);
        }
    }

    function updateRewarder(address newRewarder) external override onlyOwner {
        if (address(rewarder) != address(0)){
            rewardToken.safeApprove(rewarder, 0);
        }
        rewardToken.safeApprove(newRewarder, ~uint256(0));
        rewarder = newRewarder;
        emit UpdateRewarder(newRewarder);
    }
}