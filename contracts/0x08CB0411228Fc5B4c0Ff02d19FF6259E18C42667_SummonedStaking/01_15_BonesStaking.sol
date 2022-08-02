// SPDX-License-Identifier: MIT
/*
██████╗░░██████╗░███╗░░░██╗███████╗███████╗░░░░███████╗████████╗░█████╗░██╗░░██╗██╗███╗░░░██╗░██████╗░
██╔══██╗██╔═══██╗████╗░░██║██╔════╝██╔════╝░░░░██╔════╝╚══██╔══╝██╔══██╗██║░██╔╝██║████╗░░██║██╔════╝░
██████╔╝██║░░░██║██╔██╗░██║█████╗░░███████╗░░░░███████╗░░░██║░░░███████║█████╔╝░██║██╔██╗░██║██║░░███╗
██╔══██╗██║░░░██║██║╚██╗██║██╔══╝░░╚════██║░░░░╚════██║░░░██║░░░██╔══██║██╔═██╗░██║██║╚██╗██║██║░░░██║
██████╔╝╚██████╔╝██║░╚████║███████╗███████║░░░░███████║░░░██║░░░██║░░██║██║░░██╗██║██║░╚████║╚██████╔╝
╚═════╝░░╚═════╝░╚═╝░░╚═══╝╚══════╝╚══════╝░░░░╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚═══╝░╚═════╝░
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SummonedStaking is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    struct StakedToken {
        address staker;
        uint tokenId;
    }
    
    // Staker info
    struct Staker {
        uint amountStaked;
        uint specialStaked;
        StakedToken[] stakedTokens;
        uint timeOfLastUpdate;
        uint unclaimedRewards;
    }

    uint private rewardsPerHour = 41700000000000000;
    uint private specialRewardsPerHour = 104200000000000000;

    uint[] public specialTokens;

    mapping(address => Staker) public stakers;
    mapping(uint => address) public stakerAddress;

    constructor(
        IERC721 _nftCollection, 
        IERC20 _rewardsToken,
        uint[] memory _specialTokens
        ) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        specialTokens = _specialTokens;
    }

// ~~~~~~~~~~~~~~~~~~~~ User functions ~~~~~~~~~~~~~~~~~~~~
    function stake(uint _tokenId) external nonReentrant {
        if (stakers[msg.sender].amountStaked > 0) {
            uint rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }
        require(nftCollection.ownerOf(_tokenId) == msg.sender, "You don't own this token!");

        nftCollection.transferFrom(msg.sender, address(this), _tokenId);
        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);
        stakers[msg.sender].stakedTokens.push(stakedToken);
        stakers[msg.sender].amountStaked++;
        for (uint i=0; i < specialTokens.length; i++) {
            if (specialTokens[i] == _tokenId) {
                stakers[msg.sender].specialStaked++;
            }
        }
        stakerAddress[_tokenId] = msg.sender;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }
    
    function withdraw(uint _tokenId) external nonReentrant {
        require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");
        require(stakerAddress[_tokenId] == msg.sender, "You don't own this token!");

        uint rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;
        uint index = 0;
        for (uint i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId 
                && 
                stakers[msg.sender].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }
        stakers[msg.sender].stakedTokens[index].staker = address(0);
        stakers[msg.sender].amountStaked--;
        for (uint i=0; i < specialTokens.length; i++) {
            if (specialTokens[i] == _tokenId) {
                stakers[msg.sender].specialStaked--;
            }
        }
        stakerAddress[_tokenId] = address(0);
        nftCollection.transferFrom(address(this), msg.sender, _tokenId);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    function claimRewards() external {
        uint rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        rewardsToken.safeTransfer(msg.sender, rewards);
    }


// ~~~~~~~~~~~~~~~~~~~~ Various checks ~~~~~~~~~~~~~~~~~~~~
    function availableRewards(address _staker) public view returns (uint) {
        uint rewards = calculateRewards(_staker) +
            stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {
        if (stakers[_user].amountStaked > 0) {
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
            uint _index = 0;

            for (uint j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        else {
            return new StakedToken[](0);
        }
    }

    function getUnstakedTokens(address _user) public view returns (uint[] memory) {
        address NFT = address(nftCollection);
        return ERC721AQueryable(NFT).tokensOfOwner(_user);
    }

// ~~~~~~~~~~~~~~~~~~~~ onlyOwner functions ~~~~~~~~~~~~~~~~~~~~
    function updateRewardsPerHour(uint _newRate) public onlyOwner {
        rewardsPerHour = _newRate;
    }

    function updateSpecialRewardsPerHour(uint _newRate) public onlyOwner {
        specialRewardsPerHour = _newRate;
    }

    /// @notice Emergency use in case someone transfers directly to contract using transferFrom()
    /// Token must be owned by contract and not staked. 
    function manualTransfer(ERC721AQueryable _nft, address _to, uint _tokenId) public onlyOwner {
        require(_nft.ownerOf(_tokenId) == address(this), "Contract does not hold this token");

        _nft.transferFrom(address(this), _to, _tokenId);
    }

// ~~~~~~~~~~~~~~~~~~~~ Internal functions ~~~~~~~~~~~~~~~~~~~~
    function calculateRewards(address _staker) internal view returns (uint _rewards) {
        uint normalRewards = ((((block.timestamp - stakers[_staker].timeOfLastUpdate) * (stakers[_staker].amountStaked - stakers[_staker].specialStaked)) * rewardsPerHour) / 3600);
        uint specialRewards = ((((block.timestamp - stakers[_staker].timeOfLastUpdate) * stakers[_staker].specialStaked) * specialRewardsPerHour) / 3600);


        return (normalRewards + specialRewards);
    }

    // ~~~~~~~~~~~~~~~~~~~~ Misc ~~~~~~~~~~~~~~~~~~~~
    function onERC721Received(
        address, 
        address from, 
        uint, 
        bytes calldata
    ) external pure override returns (bytes4) {
        // @dev address requirement
        require(from == address(0x0), 'You cannot send NFT directly to vault');
        return IERC721Receiver.onERC721Received.selector;
    }
/*__            __    __                     
 /\ \          /\ \__/\ \              __    
 \_\ \     __  \ \ ,_\ \ \____    ___ /\_\   
 /'_` \  /'__`\ \ \ \/\ \ '__`\  / __`\/\ \  
/\ \L\ \/\ \L\.\_\ \ \_\ \ \L\ \/\ \L\ \ \ \ 
\ \___,_\ \__/.\_\\ \__\\ \_,__/\ \____/\ \_\
 \/__,_ /\/__/\/_/ \/__/ \/___/  \/___/  \/_/
*/
}