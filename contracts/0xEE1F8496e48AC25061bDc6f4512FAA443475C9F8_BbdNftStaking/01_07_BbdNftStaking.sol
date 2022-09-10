//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//@title NFT Staking contract
contract BbdNftStaking is ERC721Holder, Ownable {
    struct DepositInfo {
        address depositor;
        uint64 lockStart;
    }

    IERC721 public immutable stakeToken;
    IReward public immutable rewardToken;
    uint256 public lockDuration;

    mapping(uint => DepositInfo) public deposits;

    event LockDurationUpdated(uint256 newLockDuration);
    event Deposit(address indexed user, uint256[] tokenIDs);
    event Withdrawal(address indexed user, uint256[] tokenIDs);

    error AlreadyStaked(uint256 tokenId);
    error NeverStaked(uint256 tokenId);
    error NotOwner(uint256 tokenId);
    error CantWithdrawYet(uint256 tokenId);
    error AlreadyWithdrawn(uint256 tokenId);

    /**
     * @param _stakeToken ERC721 stake token contract address
     * @param _stakeToken ERC721 reward token contract address
     * @param _lockDuration Lock duration
     */
    constructor(
        IERC721 _stakeToken,
        IReward _rewardToken,
        uint256 _lockDuration
    ) {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        lockDuration = _lockDuration;
    }


    /**
     * @notice Stake array of tokens and get reward tokens with same IDs
     * @param tokenIds Array of token ID to stake
     */
    function stake (
        uint256[] memory tokenIds
    ) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (deposits[tokenIds[i]].depositor != address(0))
                revert AlreadyStaked(tokenIds[i]);

            if(lockDuration > 0) {
                stakeToken.transferFrom(msg.sender, address(this), tokenIds[i]);
            }
            deposits[tokenIds[i]] = DepositInfo({
                depositor: msg.sender,
                lockStart: uint64(block.timestamp)
            });
        }

        rewardToken.mintTokens(msg.sender, tokenIds);

        emit Deposit(msg.sender, tokenIds);
    }


    /**
     * @notice Withdraw array of staked tokens
     * @param tokenIds Array of token ID to withdraw
     */
    function withdraw (
        uint256[] memory tokenIds
    ) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            //reverts
            if (deposits[tokenIds[i]].depositor == address(0)){
                revert NeverStaked(tokenIds[i]);
            } else if (deposits[tokenIds[i]].depositor != msg.sender) {
                revert NotOwner(tokenIds[i]);
            } else if (deposits[tokenIds[i]].lockStart == 0) {
                revert AlreadyWithdrawn(tokenIds[i]);
            } else if (deposits[tokenIds[i]].lockStart + lockDuration > block.timestamp) {
                revert CantWithdrawYet(tokenIds[i]);
            }

            stakeToken.transferFrom(address(this), msg.sender, tokenIds[i]);
            deposits[tokenIds[i]].lockStart = 0;
        }
        emit Withdrawal(msg.sender, tokenIds);
    }


    /**
     * @notice Sets new Lock time
     * @param _lockDuration Lock duration
     */
    function setLockTime(uint256 _lockDuration) external onlyOwner {
        lockDuration = _lockDuration;
        emit LockDurationUpdated(_lockDuration);
    }
}

interface IReward {
    function mintTokens(address account, uint256[] calldata _itemIds) external;
}