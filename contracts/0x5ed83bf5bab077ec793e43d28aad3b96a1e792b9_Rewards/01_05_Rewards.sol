// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Rewards {
    using SafeERC20 for IERC20;

    function sendReward(address[] calldata _users, uint256[] calldata _rewards, address _token, uint256 _total) public {
        IERC20 token = IERC20(_token);
        require(_users.length == _rewards.length, "Arrays length should be equal");
        require(token.allowance(msg.sender, address(this)) >= _total, "Not enough allowance");
        require(token.balanceOf(msg.sender) >= _total, "Not enough USD");
        for (uint256 i = 0; i<_users.length; i++) {
            token.safeTransferFrom(msg.sender, _users[i], _rewards[i]);
        }
    }
}