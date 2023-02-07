// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./OXAI.sol";

contract OXAIFairLaunch {
    OXAI public immutable oxai;

    uint256 public immutable launchTime;

    uint256 public immutable distributeAmount;

    uint256 public totalStaked;

    mapping(address /*user*/ => uint256) public staked;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    error AlreadyLaunched();
    error NotLaunched();

    constructor(OXAI _oxai, uint256 _launchTime, uint256 _distributeAmount) {
        oxai = _oxai;
        launchTime = _launchTime;
        distributeAmount = _distributeAmount;
    }

    receive() external payable {
        stake();
    }

    /// @dev Stake ETH to receive fairlaunched OXAI
    function stake() public payable {
        if (block.timestamp >= launchTime) {
            revert AlreadyLaunched();
        }
        staked[msg.sender] += msg.value;
        totalStaked += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    /// @dev Withdraws the staked amount and receive OXAI.
    /// @dev This function can only be called after the launch time.
    function withdraw() external {
        if (block.timestamp < launchTime) {
            revert NotLaunched();
        }
        uint256 amount = staked[msg.sender];
        staked[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "withdraw failed");
        oxai.mint(msg.sender, amount * distributeAmount / totalStaked);
        emit Withdrawn(msg.sender, amount);
    }

    /// @dev Returns the amount of OXAI that will be distributed per deposit.
    function amountPerDeposit() external view returns (uint256) {
        return distributeAmount * 1e18 / totalStaked;
    }

    /// @dev Returns the amount of OXAI that will be distributed per deposit after the given amount is deposited.
    /// @param _amount The amount to be deposited.
    function amountPerDepositAfter(uint256 _amount) external view returns (uint256) {
        return (distributeAmount) * 1e18 / (totalStaked + _amount);
    }
}