// SPDX-License-Identifier: MIT

/**
 __    __ _____  __    __       __  _____  _           _____    __  ___ 
/ / /\ \ \\_   \/ /   / //\_/\ / _\/__   \/_\    /\ /\ \_   \/\ \ \/ _ \
\ \/  \/ / / /\/ /   / / \_ _/ \ \   / /\//_\\  / //_/  / /\/  \/ / /_\/
 \  /\  /\/ /_/ /___/ /___/ \  _\ \ / / /  _  \/ __ \/\/ /_/ /\  / /_\\ 
  \/  \/\____/\____/\____/\_/  \__/ \/  \_/ \_/\/  \/\____/\_\ \/\____/ 
                                                                                                                                                                                                                                                                                                                                     
*/

/** 
    Project: Willy PPCoin Staking
    Website: https://thewilly.club/

    by RetroBoy (RetroBoy.dev)
*/

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.0;

abstract contract NFTStaking is ReentrancyGuard, Ownable {
    struct StakingInfo {
        address owner;
        uint48 timestamp;
    }

    mapping(uint256 => StakingInfo) internal tokenIdToStakingInfo;

    mapping(address => uint256[]) internal stakerToTokenIds;

    address public token;
    address public nftAddress;
    uint256 public stakeRate;
}

contract WillyPPStakingV2 is NFTStaking {
    constructor(
        address _token,
        address _nftAddress,
        uint256 _stakeRate
    ) {
        token = _token;
        nftAddress = _nftAddress;
        stakeRate = _stakeRate;
    }

    bool public paused = false;

    using SafeMath for uint256;

    event TransferSent(address _from, address _to, uint256 _amount);

    function transferToken(address _to, uint256 _amount) private {
        uint256 erc20balance = IERC20(token).balanceOf(address(this));
        require(_amount <= erc20balance, "No tokens in contract");
        IERC20(token).transfer(_to, _amount);
        emit TransferSent(msg.sender, _to, _amount);
    }

    // Internal Stake Functions

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        uint256 lastIndex = stakerToTokenIds[staker].length - 1;
        stakerToTokenIds[staker][index] = stakerToTokenIds[staker][lastIndex];
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                remove(staker, i);
                break;
            }
        }
    }

    // Stake or Unstake Transactions (write)

    function stakeByIds(uint256[] memory tokenIds) external nonReentrant {
        require(!paused, "Staking is paused");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(nftAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStakingInfo[tokenIds[i]].owner == address(0),
                "You are not the owner of this token"
            );

            IERC721(nftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToStakingInfo[tokenIds[i]].timestamp = uint48(
                block.timestamp
            );
            tokenIdToStakingInfo[tokenIds[i]].owner = msg.sender;
        }
    }

    function unstakeByIds(uint256[] memory tokenIds) external nonReentrant {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStakingInfo[tokenIds[i]].owner == msg.sender,
                "You are not the owner of this token"
            );

            IERC721(nftAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp -
                    uint256(tokenIdToStakingInfo[tokenIds[i]].timestamp)) *
                    stakeRate);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            delete tokenIdToStakingInfo[tokenIds[i]];
        }

        transferToken(msg.sender, totalRewards);
    }

    function unstakeByAmount(uint256 _amount) external nonReentrant {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "You do not have any NFT staked"
        );
        require(
            stakerToTokenIds[msg.sender].length >= _amount,
            "You cannot unstake more tokens than you have staked"
        );
        uint256 totalRewards = 0;

        uint256 unstakeCounter = 0;
        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(nftAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards =
                totalRewards +
                ((block.timestamp -
                    uint256(tokenIdToStakingInfo[tokenId].timestamp)) *
                    stakeRate);

            remove(msg.sender, i - 1);

            delete tokenIdToStakingInfo[tokenId];

            unstakeCounter = unstakeCounter + 1;
            if (unstakeCounter == _amount) {
                break;
            }
        }

        transferToken(msg.sender, totalRewards);
    }

    function unstakeAll() external nonReentrant {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "You do not have any NFT staked"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(nftAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards =
                totalRewards +
                ((block.timestamp -
                    uint256(tokenIdToStakingInfo[tokenId].timestamp)) *
                    stakeRate);

            remove(msg.sender, i - 1);

            delete tokenIdToStakingInfo[tokenId];
        }

        transferToken(msg.sender, totalRewards);
    }

    // Claim Transactions (write)

    function claimByTokenId(uint256 tokenId) external nonReentrant {
        require(
            tokenIdToStakingInfo[tokenId].owner == msg.sender,
            "You are not the owner of this token"
        );

        transferToken(
            msg.sender,
            ((block.timestamp -
                uint256(tokenIdToStakingInfo[tokenId].timestamp)) * stakeRate)
        );

        tokenIdToStakingInfo[tokenId].timestamp = uint48(block.timestamp);
    }

    function claimAll() external nonReentrant {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStakingInfo[tokenIds[i]].owner == msg.sender,
                "You are not the owner of this token"
            );

            totalRewards =
                totalRewards +
                ((block.timestamp -
                    uint256(tokenIdToStakingInfo[tokenIds[i]].timestamp)) *
                    stakeRate);

            tokenIdToStakingInfo[tokenIds[i]].timestamp = uint48(
                block.timestamp
            );
        }

        transferToken(msg.sender, totalRewards);
    }

    // Get Staked Tokens Info (read)

    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function getTokensStakedByIndex(
        address staker,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](limit);

        for (uint256 i = 0; i < limit; i++) {
            result[i] = stakerToTokenIds[staker][offset + i];
        }

        return result;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStakingInfo[tokenId].owner;
    }

    // Get Rewards (read)

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards =
                totalRewards +
                ((block.timestamp -
                    uint256(tokenIdToStakingInfo[tokenIds[i]].timestamp)) *
                    stakeRate);
        }

        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStakingInfo[tokenId].owner != address(0),
            "This NFT is not staked"
        );

        uint256 secondsStaked = block.timestamp -
            uint256(tokenIdToStakingInfo[tokenId].timestamp);

        return secondsStaked * stakeRate;
    }

    // Get PPCoin Balance

    function ppBalance(address _wallet) external view returns (uint256) {
        return IERC20(token).balanceOf(_wallet);
    }

    // Admin Functions

    function emergencyTokenWithdraw() external onlyOwner {
        IERC20(token).transfer(
            address(msg.sender),
            IERC20(token).balanceOf(address(this))
        );
        paused = true;
    }

    function setNftAddress(address _nftAddress) public onlyOwner {
        nftAddress = _nftAddress;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        token = _tokenAddress;
    }

    function setStakeRate(uint256 _newStakeRate) public onlyOwner {
        stakeRate = _newStakeRate;
    }

    function pause(bool _value) public onlyOwner {
        paused = _value;
    }

    // Emergency Withdrawing NFTs, no Rewards transfered

    function emergencyUnstake() external nonReentrant {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "You do not have any staked tokens"
        );

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(nftAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            remove(msg.sender, i - 1);

            delete tokenIdToStakingInfo[tokenId];
        }
    }
}