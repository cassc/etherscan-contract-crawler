//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;

    address public treasury;
    // Returns the total staked tokens within the contract
    uint256 public totalSupply;
    uint256 public startTime;
    uint256 public unstakingFee = 15;

    struct Balance {
        uint256 balance;
    }

    mapping(address => Balance) internal _balances;

    constructor(
        address _stakingToken,
        address _treasury
    ) {
        stakingToken = IERC20(_stakingToken);
        treasury = _treasury;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].balance;
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // Increment sender's balances and total supply
        _balances[msg.sender].balance = _balances[msg.sender].balance.add(amount);
        totalSupply = totalSupply.add(amount);
    }

    // Subtract balances withdrawn from the user
    function withdraw(uint256 amount) public virtual {
        totalSupply = totalSupply.sub(amount);
        _balances[msg.sender].balance = _balances[msg.sender].balance.sub(amount);

        // Calculate the withdraw tax (it's 1.5% of the amount)
        uint256 tax = amount.mul(unstakingFee).div(1000);

        // Transfer the tokens to user
        stakingToken.safeTransfer(msg.sender, amount - tax);
        // Tax to treasury
        stakingToken.safeTransfer(treasury, tax);
    }
}