// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenPoolRewardVault is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    address public immutable pool;

    constructor() {
        pool = msg.sender;
    }

    function initialize(IERC20 _rewardToken) external {
        require(msg.sender == pool, "Not pool");
        
        rewardToken = _rewardToken;

        // Infinite approve
        rewardToken.safeApprove(_msgSender(), ~uint256(0));
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(address _targetAddress, uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(_targetAddress, _amount);
    }
}