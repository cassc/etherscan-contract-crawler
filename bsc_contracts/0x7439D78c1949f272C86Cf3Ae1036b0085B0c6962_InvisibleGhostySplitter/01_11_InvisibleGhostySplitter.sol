// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../utils/Recoverable.sol";

/**
 * @title Contract to manage distribution of BNB rewards to holders of tokens
 *
 * @dev Holders of the token are eligable to claim BNB send to this contract 
 * - holders receive an equal split relative to maxSupply
 * - rewards are bound to the tokenId. 
 * - unclaimed rewards can be claimed by a new owner after transfer.
 * 
 * Developed by Fab
 */
 
contract InvisibleGhostySplitter is Recoverable {
    using SafeMath for uint256;

    IERC721Enumerable public immutable token;
    uint256 public immutable tokenMaxSupply;

    mapping(uint256 => uint256) private claimedForToken;
    uint256 private totalClaimedForTokens;
    uint256 private rewardPerToken = 0;

    event RewardsReceived(uint256 amount, uint256 rewardPerToken);
    event RewardsClaimed(address holder, uint256 tokenId, uint256 amount);


    constructor(address _token, uint256 _maxSupply) {
        token = IERC721Enumerable(_token);
        tokenMaxSupply = _maxSupply;
    }


    receive() external payable {
        rewardPerToken += (msg.value / tokenMaxSupply);
        emit RewardsReceived(msg.value, rewardPerToken);
    }

    /**
     * @notice Claim pending rewards of all owned tokens. For more than 1000 tokens owned use {claimForTokensBySize}.
     * @dev This would exceeds max gas costs for > 1000 tokens in caller wallet.
     */
    function claimForTokens() external {
        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 0, "No tokens owned");
        require(balance <= 1000, "use claimForTokensBySize");

        uint256 totalPending = 0;

        uint256 pending;
        uint256 tokenId;
        for (uint256 i = 0; i < balance; ++i) {
            tokenId = token.tokenOfOwnerByIndex(msg.sender, i);
            pending = rewardPerToken - claimedForToken[tokenId];

            claimedForToken[tokenId] += pending;
            totalPending += pending;

            emit RewardsClaimed(msg.sender, tokenId, pending);
        }

        totalClaimedForTokens += totalPending;
        Address.sendValue(payable(msg.sender), totalPending);
    }


    /**
     * @notice Claim pending rewards of all owned tokens given a `cursor` and `size` of its token list
     * @dev Use this method for holders with more than 1000 tokens in total
     * @param cursor: cursor
     * @param size: size (max 1000)
     */
    function claimForTokensBySize(
        uint256 cursor,
        uint256 size
    ) external {
        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 0, "No tokens owned");
        require(size <= 1000, "Max claim size exeeded");

        uint256 length = size;
        if (length > balance - cursor) {
            length = balance - cursor;
        }

        uint256 totalPending = 0;

        uint256 pending;
        uint256 tokenId;
        for (uint256 i = 0; i < length; i++) {
            tokenId = token.tokenOfOwnerByIndex(msg.sender, cursor + i);
            pending = rewardPerToken - claimedForToken[tokenId];

            claimedForToken[tokenId] += pending;
            totalPending += pending;

            emit RewardsClaimed(msg.sender, tokenId, pending);
        }

        totalClaimedForTokens += totalPending;

        Address.sendValue(payable(msg.sender), totalPending);
    }

    /**
     * @notice Pending rewards for all tokens of `user`.
     * @dev Use this method for holders with more than 3000 tokens in total
     */
    function pendingForTokensBySize(address user, uint256 cursor, uint256 size)
        external
        view
        returns (uint256 pending, uint256 length)
    {
        uint256 balance = token.balanceOf(user);
        require(size <= 3000, "max size 3000");

        length = size;
        if (length > balance - cursor) {
            length = balance - cursor;
        }

        pending = length * rewardPerToken;
        for (uint256 i = 0; i < length; i++) {
            pending -= claimedForToken[token.tokenOfOwnerByIndex(user, cursor + i)];
        }
    }

    /**
     * @notice Pending rewards for all tokens of `user`.
     */
    function pendingForTokens(address _user)
        external
        view
        returns (uint256 pending)
    {
        uint256 balance = token.balanceOf(_user);
        require(balance <= 3000, "use pendingForTokensBySize");
        pending = balance * rewardPerToken;
        for (uint256 i = 0; i < balance; ++i) {
            pending -= claimedForToken[token.tokenOfOwnerByIndex(_user, i)];
        }
    }

    function walletHoldings(address _user) external view returns (uint256) {
        uint256 balance = token.balanceOf(_user);
        return balance;
    }

    /**
     * @notice Pending rewards for given `_tokenId`.
     */
    function pendingForToken(uint256 _tokenId)
        external
        view
        returns (uint256 pending)
    {
        require(token.ownerOf(_tokenId) != address(0), "Invalid tokenId");
        pending = rewardPerToken - claimedForToken[_tokenId];
    }
}