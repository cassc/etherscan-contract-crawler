// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Claim is Ownable {
    using SafeERC20 for IERC20;

    address public rewardToken;
    address public treasury;
    bool public claimsDisabled;
    uint256 public totalClaims;
    uint256 public totalRewards;
    uint256 public userCount;
    mapping(address => User) public users;
    struct User {
        uint256 amount;
        uint256 claimed;
    }

    error addressIsZero(string name);
    error claimsStarted();
    error noPendingBalance();
    error unequalArrayLengths();

    event AddRewards(address indexed user, uint256 indexed amount);
    event ClaimRewards(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed msgSender, address indexed token);

    constructor(address _rewardToken, address _treasury) {
        if (_rewardToken == address(0)) revert addressIsZero("_rewardToken");
        if (_treasury == address(0)) revert addressIsZero("_treasury");
        rewardToken = _rewardToken;
        treasury = _treasury;
    }

    function addUserRewards(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        if (addresses.length != amounts.length) revert unequalArrayLengths();
        uint256 amount;
        uint256 newUsers;
        for (uint256 x; x < addresses.length; x++) {
            User storage user = users[addresses[x]];
            if (user.amount == 0) ++newUsers;
            user.amount += amounts[x];
            amount += amounts[x];
            emit AddRewards(addresses[x], amounts[x]);
        }
        totalRewards += amount;
        userCount += newUsers;
    }

    function claimRewards() external {
        User storage user = users[_msgSender()];
        uint256 balance = user.amount - user.claimed;
        if (balance == 0) revert noPendingBalance();
        user.claimed = user.amount;
        totalClaims += balance;
        IERC20(rewardToken).transfer(_msgSender(), balance);
        emit ClaimRewards(_msgSender(), balance);
    }

    function getRewardAmount(
        address userAddress
    ) external view returns (uint256) {
        User memory user = users[userAddress];
        return user.amount - user.claimed;
    }

    function setClaimsDisabled(bool value) external onlyOwner {
        claimsDisabled = value;
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        if (totalClaims > 0) revert claimsStarted();
        if (_rewardToken == address(0)) revert addressIsZero("_rewardToken");
        rewardToken = _rewardToken;
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert addressIsZero("_treasury");
        treasury = _treasury;
    }

    function totalPending() external view returns (uint256) {
        return totalRewards - totalClaims;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawTokens(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(
            treasury,
            IERC20(_token).balanceOf(address(this))
        );
        emit Withdraw(_msgSender(), _token);
    }
}