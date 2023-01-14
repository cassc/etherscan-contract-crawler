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
    uint256 public stakeRate = 115740740740740;

    address nullAddress = 0x0000000000000000000000000000000000000000;
    address public token;
    address public nftAddress;

    uint256 public tokenAmount;
    uint256 public tokenBalance;

    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    mapping(uint256 => address) internal tokenIdToStaker;

    mapping(address => uint256[]) internal stakerToTokenIds;
}

contract WillyPPStaking is NFTStaking {
    bool public paused = false;

    using SafeMath for uint256;

    event TransferReceived(address _from, uint256 _amount);
    event TransferSent(address _from, address _to, uint256 _amount);

    receive() external payable {
        tokenBalance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }

    function transferToken(address _to, uint256 _amount) private {
        uint256 erc20balance = IERC20(token).balanceOf(address(this));
        require(_amount <= erc20balance, "No tokens in contract");
        IERC20(token).transfer(_to, _amount);
        emit TransferSent(msg.sender, _to, _amount);
    }

    function setNftAddress(address _nftAddress) public onlyOwner {
        nftAddress = _nftAddress;
        return;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        token = _tokenAddress;
        return;
    }

    function setStakeRate(uint256 _newStakeRate) public onlyOwner {
        stakeRate = _newStakeRate;
    }

    function pause(bool _value) public onlyOwner {
        paused = _value;
    }

    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public nonReentrant {
        require(!paused);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(nftAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "NFT must be staked by you!"
            );

            IERC721(nftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAll() public nonReentrant {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least 1 NFT Staked"
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
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) * stakeRate);

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;
        }

        transferToken(msg.sender, totalRewards);
    }

    function unstakeByIds(uint256[] memory tokenIds) public nonReentrant {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(nftAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    stakeRate);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        transferToken(msg.sender, totalRewards);
    }

    function claimByTokenId(uint256 tokenId) public nonReentrant {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );

        transferToken(
            msg.sender,
            ((block.timestamp - tokenIdToTimeStamp[tokenId]) * stakeRate)
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimAll() public nonReentrant {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    stakeRate);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        transferToken(msg.sender, totalRewards);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    stakeRate);
        }

        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(tokenIdToStaker[tokenId] != nullAddress, "NFT is not staked!");

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];

        return secondsStaked * stakeRate;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }

    function ppBalance(address _wallet) external view returns (uint256) {
        return IERC20(token).balanceOf(_wallet);
    }

    function emergencyTokenWithdraw() external onlyOwner {
        IERC20(token).transfer(
            address(msg.sender),
            IERC20(token).balanceOf(address(this))
        );
        paused = true;
    }

    // Emergency Withdrawing NFTs, no Rewards transfered

    function emergencyUnstake() public nonReentrant {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least 1 NFT Staked"
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
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) * stakeRate);

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;
        }
    }
}