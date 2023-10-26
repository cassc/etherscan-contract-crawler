// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardsPool.sol";
import "./interfaces/IStakedCredmark.sol";

contract StakedCredmark is IStakedCredmark, Ownable, ERC20("StakedCredmark", "xCMK") {
    IERC20 public credmark;
    IRewardsPool private _rewardsPool;

    constructor(IERC20 _credmark) {
        credmark = _credmark;
    }

    uint32 private constant REWARDS_INTERVAL_S = 8 hours;

    function setRewardsPool(address rewardsPool) external override onlyOwner {
        _rewardsPool = IRewardsPool(rewardsPool);
    }

    function cmkBalance() public view override returns (uint256) {
        return credmark.balanceOf(address(this));
    }

    function cmkBalanceOf(address account) external view override returns (uint256) {
        return sharesToCmk(balanceOf(account));
    }

    function sharesToCmk(uint256 sharesAmount) public view override returns (uint256 cmkAmount) {
        if (totalSupply() > 0 && cmkBalance() > 0) {
            cmkAmount = (sharesAmount * cmkBalance()) / totalSupply();
        } else {
            cmkAmount = sharesAmount;
        }
    }

    function cmkToShares(uint256 cmkAmount) public view override returns (uint256 sharesAmount) {
        if (totalSupply() > 0 && cmkBalance() > 0) {
            sharesAmount = (cmkAmount * totalSupply()) / cmkBalance();
        } else {
            sharesAmount = cmkAmount;
        }
    }

    function issueRewards() internal {
        if (
            address(_rewardsPool) != address(0) &&
            block.timestamp - _rewardsPool.getLastRewardTime() > REWARDS_INTERVAL_S
        ) {
            _rewardsPool.issueRewards();
        }
    }

    function createShare(uint256 cmkAmount) external override returns (uint256 sharesAmount) {
        issueRewards();
        sharesAmount = cmkToShares(cmkAmount);
        _mint(msg.sender, sharesAmount);
        SafeERC20.safeTransferFrom(credmark, msg.sender, address(this), cmkAmount);
    }

    function removeShare(uint256 sharesAmount) external override {
        issueRewards();
        uint256 cmkAmount = sharesToCmk(sharesAmount);
        _burn(msg.sender, sharesAmount);
        SafeERC20.safeTransfer(credmark, msg.sender, cmkAmount);
    }
}