// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Deployed on Ethereum Mainnet
// https://etherscan.io/address/0x86cc79b8bf3ac9c153a6856f43eaa6d599a9423f

contract N3onixVesting is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // cliff period when tokens are frozen
    uint32 public constant CLIFF_MONTHS = 6;

    // period of time when tokens are getting available
    uint32 public constant VESTING_MONTHS_COUNT = 36;

    // seconds in 1 month
    uint32 public constant MONTH = 2628000;

    // tokens that will be delivered
    IERC20 public immutable token;

    struct UserInfo {
        uint256 accumulated;
        uint256 paidOut;
        uint256 vestingStartTime;
        uint256 vestingEndTime;
        bool isStarted;
    }

    // user info storage
    mapping(address => UserInfo) public users;

    // sum of all tokens to be paid
    uint256 public totalTokensToPay;

    // sum of all tokens has been paid
    uint256 public totalTokensPaid;

    // vesting duration
    uint40 public immutable vestingPeriod;

    event UsersBatchAdded(address[] users, uint256[] amounts);

    event CountdownStarted(
        uint256 vestingStartTime,
        uint256 vestingEndTime,
        address[] users
    );

    event TokensClaimed(address indexed user, uint256 amount);

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);

        vestingPeriod = MONTH * VESTING_MONTHS_COUNT;
    }

    /**
     * @dev add private users and assign amount to claim. Before calling,
     * ensure that contract balance is more or equal than total token payout
     * @param _user  An array of users' addreses.
     * @param _amount An array of amount values to be assigned to users respectively.
     */
    function addPrivateUser(address[] memory _user, uint256[] memory _amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _user.length; i++) {
            require(_amount[i] != 0, "Vesting: some amount is zero");

            if (users[_user[i]].accumulated != 0) {
                totalTokensToPay -= users[_user[i]].accumulated;
            }

            users[_user[i]].accumulated = _amount[i];
            totalTokensToPay += _amount[i];
        }

        // solhint-disable-next-line reason-string
        require(
            totalTokensToPay - totalTokensPaid <=
                token.balanceOf(address(this)),
            "Vesting: total tokens to pay exceed balance"
        );

        emit UsersBatchAdded(_user, _amount);
    }

    /**
     * @dev Start vesting countdown. Can only be called by contract owner.
     */
    function startCountdown(address[] memory _users) external onlyOwner {
        uint256 startTime = block.timestamp + (MONTH * CLIFF_MONTHS);
        uint256 endTime = startTime + vestingPeriod;

        for (uint256 index = 0; index < _users.length; index++) {
            UserInfo storage userInfo = users[_users[index]];

            require(
                !userInfo.isStarted,
                "Vesting: countdown is already started"
            );
            require(
                users[_users[index]].accumulated != 0,
                "Vesting: unknown user"
            );

            userInfo.vestingStartTime = startTime;

            userInfo.vestingEndTime = endTime;
            userInfo.isStarted = true;
        }

        emit CountdownStarted(startTime, endTime, _users);
    }

    /**
     * @dev Claims available tokens from the contract.
     */
    function claimToken() external nonReentrant {
        UserInfo storage userInfo = users[msg.sender];

        require(
            (userInfo.accumulated - userInfo.paidOut) > 0,
            "Vesting: not enough tokens to claim"
        );

        uint256 availableAmount = calcAvailableToken(
            userInfo.accumulated,
            userInfo.vestingStartTime,
            userInfo.vestingEndTime,
            userInfo.isStarted
        );
        availableAmount -= userInfo.paidOut;

        userInfo.paidOut += availableAmount;

        totalTokensPaid += availableAmount;

        token.safeTransfer(msg.sender, availableAmount);

        emit TokensClaimed(msg.sender, availableAmount);
    }

    function getUserInfo(address user)
        public
        view
        returns (
            uint256 availableAmount,
            uint256 paidOut,
            uint256 totalAmountToPay,
            uint256 vestingStartTime,
            uint256 vestingEndTime,
            bool isStarted
        )
    {
        UserInfo storage userInfo = users[user];
        return (
            calcAvailableToken(
                userInfo.accumulated,
                userInfo.vestingStartTime,
                userInfo.vestingEndTime,
                userInfo.isStarted
            ) - userInfo.paidOut,
            userInfo.paidOut,
            userInfo.accumulated,
            userInfo.vestingStartTime,
            userInfo.vestingEndTime,
            userInfo.isStarted
        );
    }

    /**
     * @dev calcAvailableToken - calculate available tokens
     * @param _amount  An input amount used to calculate vesting's output value.
     * @return availableAmount_ An amount available to claim.
     */
    function calcAvailableToken(
        uint256 _amount,
        uint256 vestingStartTime,
        uint256 vestingEndTime,
        bool isStarted
    ) private view returns (uint256 availableAmount_) {
        // solhint-disable-next-line not-rely-on-time
        if (!isStarted || block.timestamp <= vestingStartTime) {
            return 0;
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > vestingEndTime) {
            return _amount;
        }

        return
            (_amount *
                // solhint-disable-next-line not-rely-on-time
                (block.timestamp - vestingStartTime)) / vestingPeriod;
    }
}