// SPDX-License-Identifier: MIT
// @author Pendle Labs - pendle.finance
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SingleStakingManager.sol";

contract SingleStaking {
    event Enter(address user, uint256 pendleAmount, uint256 shares);
    event Leave(address user, uint256 pendleAmount, uint256 shares);

    using SafeMath for uint256;
    IERC20 public immutable pendle;
    SingleStakingManager public immutable stakingManager;
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    constructor(IERC20 _pendle) {
        pendle = _pendle;
        stakingManager = SingleStakingManager(msg.sender);
    }

    // Locks Pendle, update the user's shares (non-transferable)
    function enter(uint256 _amount) public returns (uint256 sharesToMint) {
        // Before doing anything, get the unclaimed rewards first
        stakingManager.distributeRewards();
        // Gets the amount of Pendle locked in the contract
        uint256 totalPendle = pendle.balanceOf(address(this));
        if (totalSupply == 0 || totalPendle == 0) {
            // If no shares exists, mint it 1:1 to the amount put in
            sharesToMint = _amount;
        } else {
            // Calculate and mint the amount of shares the Pendle is worth. The ratio will change overtime, as shares is burned/minted and Pendle distributed to this contract
            sharesToMint = _amount.mul(totalSupply).div(totalPendle);
        }
        _mint(msg.sender, sharesToMint);
        // Lock the Pendle in the contract
        pendle.transferFrom(msg.sender, address(this), _amount);
        emit Enter(msg.sender, _amount, sharesToMint);
    }

    // Unlocks the staked + gained Pendle and burns shares
    function leave(uint256 _share) public returns (uint256 rewards) {
        // Before doing anything, get the unclaimed rewards first
        stakingManager.distributeRewards();
        // Calculates the amount of Pendle the shares is worth
        rewards = _share.mul(pendle.balanceOf(address(this))).div(totalSupply);
        _burn(msg.sender, _share);
        pendle.transfer(msg.sender, rewards);
        emit Leave(msg.sender, rewards, _share);
    }

    function _mint(address user, uint256 amount) internal {
        balances[user] = balances[user].add(amount);
        totalSupply = totalSupply.add(amount);
    }

    function _burn(address user, uint256 amount) internal {
        balances[user] = balances[user].sub(amount);
        totalSupply = totalSupply.sub(amount);
    }
}