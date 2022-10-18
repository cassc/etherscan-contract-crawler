//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "crypto-subscriptions/contracts/BillingDate.sol";

contract MonthlyClaim is Ownable, Pausable, BillingDate {
    using EnumerableSet for EnumerableSet.AddressSet;
    struct UserInfo {
        uint256 amount;
        uint256 tokenIndex;
        uint256 lastClaimRound;
        bytes32 label;
    }
    struct ClaimRound {
        uint256 startsAt;
        uint8 claimDateIndex;
    }

    mapping(address => UserInfo) public usersInfo;
    EnumerableSet.AddressSet private usersSet;

    mapping(uint256 => ClaimRound) public claimRounds;
    uint256 public currentClaimRound;

    uint8[] public claimDates;
    address[] public tokens;

    event SetUserInfo(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed lastClaimRound,
        uint256 tokenIndex,
        bytes32 label
    );
    event UserRemoved(address indexed user);
    event Claimed(
        address indexed user,
        uint256 indexed amount,
        address indexed token
    );
    event NewRoundCreated(
        uint256 indexed newClaimRoundId,
        uint256 indexed startsAt,
        uint8 indexed claimDate
    );
    event SetToken(uint256 indexed index, address indexed token);

    constructor(
        uint256 currentClaimRound_,
        uint256 nextClaimTimestamp,
        uint8 nextClaimDateIndex,
        uint8[] memory claimDates_
    ) {
        currentClaimRound = currentClaimRound_;

        claimRounds[currentClaimRound + 1] = ClaimRound({
            startsAt: nextClaimTimestamp,
            claimDateIndex: nextClaimDateIndex
        });

        claimDates = claimDates_;
    }

    function allUsers() external view returns (address[] memory) {
        return usersSet.values();
    }

    function usersCount() external view returns (uint256) {
        return usersSet.length();
    }

    function usersSetInfo(uint256 start, uint256 limit)
        external
        view
        returns (address[] memory, UserInfo[] memory)
    {
        uint256 _usersCount = usersSet.length();
        if (limit == 0) limit = _usersCount;
        require((start + limit) <= _usersCount, "Invalid start & limit");

        address[] memory users = new address[](limit);
        UserInfo[] memory _usersSetInfo = new UserInfo[](limit);
        for (uint256 i = start; i < limit; i++) {
            address user = usersSet.at(i);
            users[i] = user;
            _usersSetInfo[i] = usersInfo[user];
        }

        return (users, _usersSetInfo);
    }

    function allClaimDates() external view returns (uint8[] memory) {
        return claimDates;
    }

    function currentRoundData() external view returns (ClaimRound memory) {
        return claimRounds[currentClaimRound];
    }

    function tokensCount() external view returns (uint256) {
        return tokens.length;
    }

    function allTokens() external view returns (address[] memory) {
        return tokens;
    }

    function setTokenByIndex(uint256 index, address token) external onlyOwner {
        require(index <= tokens.length, "Invalid index");

        if (index == tokens.length) tokens.push(token);
        else tokens[index] = token;

        emit SetToken(index, token);
    }

    function setUsersInfo(
        address[] calldata users,
        uint256[] calldata amounts,
        uint256[] calldata lastClaimRounds,
        uint256[] calldata tokenIndexes,
        bytes32[] calldata labels
    ) external onlyOwner {
        require(users.length == amounts.length, "Values do not match");
        require(
            amounts.length == lastClaimRounds.length,
            "Values do not match"
        );
        require(
            lastClaimRounds.length == tokenIndexes.length,
            "Values do not match"
        );
        require(tokenIndexes.length == labels.length, "Values do not match");

        for (uint256 index = 0; index < users.length; index++) {
            _setUserInfo(
                users[index],
                amounts[index],
                lastClaimRounds[index],
                tokenIndexes[index],
                labels[index]
            );
        }
    }

    function setUserInfo(
        address user,
        uint256 amount,
        uint256 lastClaimRound,
        uint256 tokenIndex,
        bytes32 label
    ) external onlyOwner {
        _setUserInfo(user, amount, lastClaimRound, tokenIndex, label);
    }

    function removeUser(address user) external onlyOwner {
        delete usersInfo[user];
        usersSet.remove(user);

        emit UserRemoved(user);
    }

    function claim() external whenNotPaused {
        _executeClaim(msg.sender);
    }

    function executeClaim(address user) external onlyOwner {
        _executeClaim(user);
    }

    function executeClaims(address[] calldata users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            _executeClaim(users[index]);
        }
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _setUserInfo(
        address user,
        uint256 amount,
        uint256 lastClaimRound,
        uint256 tokenIndex,
        bytes32 label
    ) internal {
        require(tokens[tokenIndex] != address(0), "Token does not exist");
        require(amount > 0, "Amount must be > 0");

        UserInfo storage userInfoStorage = usersInfo[user];
        userInfoStorage.amount = amount;
        userInfoStorage.tokenIndex = tokenIndex;
        userInfoStorage.lastClaimRound = lastClaimRound;
        userInfoStorage.label = label;

        if (!usersSet.contains(user)) {
            usersSet.add(user);
        }

        emit SetUserInfo(user, amount, lastClaimRound, tokenIndex, label);
    }

    function _executeClaim(address user) internal {
        uint256 currentClaimRound_ = currentClaimRound;
        require(
            claimRounds[currentClaimRound_].startsAt < block.timestamp,
            "claimRound is not started yet"
        );

        ClaimRound memory newClaimRound = claimRounds[currentClaimRound_ + 1];

        bool newClaimRoundStarted = newClaimRound.startsAt > 0 &&
            newClaimRound.startsAt < block.timestamp;
        if (newClaimRoundStarted) {
            delete claimRounds[currentClaimRound_];
            // increment currentClaimRound and create round, if new one already started
            currentClaimRound++;
            currentClaimRound_++;

            _createNewRound(newClaimRound);
        }

        UserInfo memory userInfo = usersInfo[user];
        require(userInfo.amount > 0, "No tokens for claim");
        require(
            userInfo.lastClaimRound < currentClaimRound_,
            "Already claimed"
        );

        address token = tokens[userInfo.tokenIndex];
        uint256 amount = userInfo.amount *
            (currentClaimRound_ - userInfo.lastClaimRound);

        IERC20(token).transfer(user, amount);
        usersInfo[user].lastClaimRound = currentClaimRound_;

        emit Claimed(user, amount, token);
    }

    function _createNewRound(ClaimRound memory claimRound) internal {
        uint8[] memory claimDates_ = claimDates;
        uint8 nextClaimDateIndex = claimRound.claimDateIndex;

        bool isLastIndex = claimRound.claimDateIndex == claimDates_.length - 1;
        if (isLastIndex) nextClaimDateIndex = 0;
        else nextClaimDateIndex++;

        uint256 nextClaimTimestamp;

        uint8 nextClaimDate = claimDates_[nextClaimDateIndex];
        if (isLastIndex) {
            nextClaimTimestamp = getTimestampOfNextDate(
                block.timestamp,
                nextClaimDate
            );
        } else {
            uint8 currentClaimDate = claimDates_[claimRound.claimDateIndex];
            nextClaimTimestamp =
                claimRound.startsAt +
                (nextClaimDate - currentClaimDate) *
                1 days;
        }

        uint256 newClaimRoundId = currentClaimRound + 1;
        claimRounds[newClaimRoundId] = ClaimRound({
            startsAt: nextClaimTimestamp,
            claimDateIndex: nextClaimDateIndex
        });

        emit NewRoundCreated(
            newClaimRoundId,
            nextClaimTimestamp,
            nextClaimDate
        );
    }
}