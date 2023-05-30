// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract BambooFactory is ERC20Burnable, Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet; 

    IERC721Enumerable public immutable pandaContract;

    uint256 rewardsEnd = 33043333;
    bool finalizedRewardsEnd;

    uint256 constant REWARDS_PER_BLOCK = 4000000000000000;

    event Staked(address indexed account, uint256[] tokenIds);
    event Unstaked(address indexed account, uint256[] tokenIds);
    event RewardsClaimed(address indexed account, uint256 amount);

    mapping(uint256 => uint256) public lastClaimedBlockForToken;
    mapping(address => EnumerableSet.UintSet) private stakedTokens;

    mapping(uint256 => bool) claimedHolderRewards;

    constructor(        
        string memory name,
        string memory symbol,
        address _pandaContract
    ) ERC20(name, symbol)  {

        pandaContract = IERC721Enumerable(_pandaContract);

        _mint(0x5b92a53E91495052B7849EA585Bec7E99c75293B, 300000000000000000000000);

        _pause();        
    }     

    function stakePandas(uint256[] calldata tokenIds) external whenNotPaused nonReentrant {
        require(tokenIds.length <= 40 && tokenIds.length > 0, "Stake: amount prohibited");

        for (uint256 i; i < tokenIds.length; i++) {
            require(pandaContract.ownerOf(tokenIds[i]) == msg.sender, "Stake: sender not owner");

            pandaContract.safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            lastClaimedBlockForToken[tokenIds[i]] = uint128(block.number);
            stakedTokens[msg.sender].add(tokenIds[i]);
        }        

        emit Staked(msg.sender, tokenIds);
    }    

    function unstakePandas(uint256[] calldata tokens) external whenNotPaused nonReentrant {
        require(tokens.length <= 40 && tokens.length > 0, "Unstake: amount prohibited");

        uint256 rewards;

        for (uint256 i; i < tokens.length; i++) {
            require(
                stakedTokens[msg.sender].contains(tokens[i]), 
                "Unstake: token not staked"
            );
            
            rewards += calculateStakingRewards(tokens[i]);

            stakedTokens[msg.sender].remove(tokens[i]);
            delete lastClaimedBlockForToken[tokens[i]];
           
            pandaContract.safeTransferFrom(address(this), msg.sender, tokens[i]);
        }

        _mint(msg.sender, rewards);

        emit Unstaked(msg.sender, tokens);
        emit RewardsClaimed(msg.sender, rewards);
    }   

    function claimStakingRewards(uint256[] calldata tokens) external whenNotPaused {
        require(tokens.length > 0, "no panda id given");

        uint256 rewards;

        for (uint256 i; i < tokens.length; i++) {
            require(
                stakedTokens[msg.sender].contains(tokens[i]), 
                "token not staked"
            );          
            
            rewards += calculateStakingRewards(tokens[i]);
            lastClaimedBlockForToken[tokens[i]] = block.number;
        }

        _mint(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }    

    function claimHolderRewards() external whenNotPaused {
        
        uint256 rewards;

        for(uint256 i; i < pandaContract.balanceOf(msg.sender); i++) {

            uint256 tokenId = pandaContract.tokenOfOwnerByIndex(msg.sender, i);
            
            if(!claimedHolderRewards[tokenId]) {
                claimedHolderRewards[tokenId] = true;
                rewards += calculateHolderRewards(tokenId);
            }
        }
        require(rewards > 0, "no rewards to claim");
        
        _mint(msg.sender, rewards);
    }

    function calculateHolderRewards(uint256 tokenId) public pure returns (uint256) {

        if(tokenId <= 300) {
            return 1000000000000000000000;
        } else if (tokenId <= 500) {
            return 750000000000000000000;
        } else if(tokenId <= 1000) {
            return 500000000000000000000;
        } else if(tokenId <= 1500) {
            return 250000000000000000000;
        } else if(tokenId <= 2500) {
            return 200000000000000000000;
        } else if(tokenId <= 3000) {
            return 150000000000000000000;
        } else {
            return 100000000000000000000;
        } 
    }

    function finalizeRewardsEnd() external onlyOwner {
        require(!finalizedRewardsEnd, "already finalized");

        finalizedRewardsEnd = true;
    }

    function setEndingBlock(uint256 _rewardsEnd) external onlyOwner {
        require(!finalizedRewardsEnd, "already finalized");

        rewardsEnd = _rewardsEnd;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }        

    function calculateStakingRewardsByAccount(address account) external view returns (uint256) {
        uint256 rewards;

        for (uint256 i; i < stakedTokens[account].length(); i++) {
            rewards += calculateStakingRewards(stakedTokens[account].at(i));
        }

        return rewards;
    }    

    function calculateStakingRewards(uint256 tokenID) public view returns (uint256) {
        require(lastClaimedBlockForToken[tokenID] != 0, "token not staked");

        uint256 toBlock = rewardsEnd < block.number ? rewardsEnd : block.number;

        return REWARDS_PER_BLOCK * (toBlock - lastClaimedBlockForToken[tokenID]);    
    }      

    function stakedPandasOf(address account) external view returns (uint256[] memory) {
      uint256[] memory tokenIds = new uint256[](stakedTokens[account].length());

      for (uint256 i; i < tokenIds.length; i++) {
        tokenIds[i] = stakedTokens[account].at(i);
      }

      return tokenIds;
    }    

    function onERC721Received(address operator, address, uint256, bytes memory) public view override returns (bytes4) {
        require(operator == address(this), "Operator not staking contract");

        return this.onERC721Received.selector;
    }
}