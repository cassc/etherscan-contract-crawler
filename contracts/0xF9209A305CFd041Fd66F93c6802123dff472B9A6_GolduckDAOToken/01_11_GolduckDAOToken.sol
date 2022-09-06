// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IRewardPool.sol";

contract GolduckDAOToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    bool public isRewardEnabled;
    IRewardPool public rewardPool;

    function initialize(address _rewardPool) initializer public {
        __ERC20_init("GolduckDAO", "GOLDUCK");
        __Ownable_init();

        _mint(msg.sender, 100000000000 * 10 ** decimals());
        rewardPool = IRewardPool(_rewardPool);
        isRewardEnabled = true;
    }

    receive() external payable {}

    function updateRewardPool(address newRewardPool) public onlyOwner {
        rewardPool = IRewardPool(newRewardPool);
    }

    function setRewardEnable(bool status) external onlyOwner {
        isRewardEnabled = status;
    }

    function _afterTokenTransfer(address from, address to, uint256) internal override{
        if(isRewardEnabled) {
            rewardPool.setBalance(from, balanceOf(from));
            rewardPool.setBalance(to, balanceOf(to));  
        }  
    }
}