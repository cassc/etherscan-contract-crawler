// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

interface IXENNFTContract {
    function ownerOf(uint256) external view returns (address);
}

contract NFTRegistry {
    struct NFT {
        uint256 tokenId;
        string category;
    }

    struct User {
        NFT[] userNFTs;
        uint256 userRewards; // Tracks total rewards sebt to user.
        uint256 userPoints;
        uint256 userLastRewarded; //-----------------
        uint256 lastRewardRatio;
    }

    mapping(address => User) public users;
    mapping(uint256 => string) private categoryMap;
    mapping(uint256 => address) public currentHolder;
    mapping(string => uint256) public globalCounters;

    uint256 private constant XUNICORN_MIN_ID = 1;
    uint256 private constant XUNICORN_MAX_ID = 100;
    uint256 private constant EXOTIC_MIN_ID = 101;
    uint256 private constant EXOTIC_MAX_ID = 1000;
    uint256 private constant LEGENDARY_MIN_ID = 1001;
    uint256 private constant LEGENDARY_MAX_ID = 3000;
    uint256 private constant EPIC_MIN_ID = 3001;
    uint256 private constant EPIC_MAX_ID = 6000;
    uint256 private constant RARE_MIN_ID = 6001;
    uint256 private constant RARE_MAX_ID = 10000;

    mapping(uint256 => uint256) private rewardsMap;
    address public nftContractAddress;
    uint256 public totalRewards;
    uint256 public totalPoints;
    uint256 public rewardRatio;

    uint256 private constant XUNICORN_WEIGHT = 50;
    uint256 private constant EXOTIC_WEIGHT = 50;
    uint256 private constant LEGENDARY_WEIGHT = 25;
    uint256 private constant EPIC_WEIGHT = 10;
    uint256 private constant RARE_WEIGHT = 5;
    uint256 private constant COLLECTOR_WEIGHT = 0;

    constructor(address _nftContractAddress) {
        nftContractAddress = _nftContractAddress;

        rewardsMap[XUNICORN_WEIGHT] = 50;
        rewardsMap[EXOTIC_WEIGHT] = 50;
        rewardsMap[LEGENDARY_WEIGHT] = 25;
        rewardsMap[EPIC_WEIGHT] = 10;
        rewardsMap[RARE_WEIGHT] = 5;
        rewardsMap[COLLECTOR_WEIGHT] = 0;

        // Initialize totalRewards and totalPoints with small non-zero values
        totalRewards = 1 wei; // 1 wei
        totalPoints = 1;
    }

    event NFTRegistered(address indexed user, uint256 tokenId, uint256 rewards);
    event RewardsWithdrawn(address indexed user, uint256 amount);
    
    receive() external payable {
        totalRewards += msg.value;
        rewardRatio += msg.value / totalPoints;
    }

    function addToPool() external payable {
        totalRewards += msg.value;
        rewardRatio += msg.value / totalPoints;
    }

    function registerNFT(uint256 tokenId) public {
        address player = msg.sender;
        require(IXENNFTContract(nftContractAddress).ownerOf(tokenId) == player, "You don't own this NFT.");

        // Calculate the reward points for the NFT
        uint256 rewardPoints = getTokenWeight(tokenId);

        // Check if the NFT was previously registered to a different user
        address  previousOwner = getNFTOwner(tokenId);
        require(previousOwner != player, "You already have this NFT regestered");
        if (previousOwner != address(0) && previousOwner != player) {
            User storage previousOwnerData = users[previousOwner];
            uint256 previousRewardPoints = previousOwnerData.userPoints;
            uint256 previousRewardAmount = calculateReward(previousOwner);
            address payable previousOwnerpay = payable(previousOwner);
            
            // Remove the previous owner's points
            previousOwnerData.userPoints -= previousRewardPoints;
            
            // Pay the previous owner their rewards
            previousOwnerpay.transfer(previousRewardAmount);
            
            
        }
        User storage currentUserData = users[player];

        if (currentUserData.lastRewardRatio != rewardRatio && currentUserData.lastRewardRatio != 0) {
            withdrawRewards();
        }

        // Update the user's rewards, points, and last rewarded timestamp

        currentUserData.userPoints += rewardPoints;
        totalPoints += rewardPoints;
        currentUserData.lastRewardRatio = rewardRatio;

        // Update the NFT ownership
        setNFTOwner(tokenId, player);
        emit NFTRegistered(player, tokenId, rewardPoints);
    }

    function registerNFTs(uint256[] memory tokenIds) external {
        uint len = tokenIds.length;
            for (uint256 i = 0; i < len; i++) {
                registerNFT(tokenIds[i]);
            }
    }
    

    function isNFTRegistered(uint256 tokenId) public view returns (bool) {
        address player = msg.sender;
        NFT[] storage userNFTs = users[player].userNFTs;
        uint len = userNFTs.length;
        for (uint256 j = 0; j < len; j++) {
            if (userNFTs[j].tokenId == tokenId) {
                return true;
            }
        }
        return false;
    }

    function setNFTOwner(uint256 tokenId, address owner) private {
        require(currentHolder[tokenId] != owner, "NFT already registered by the caller.");

        string memory category = getCategory(tokenId);
        currentHolder[tokenId] = owner;

        // Increment the global counter for the NFT class
        globalCounters[category]++;

        // Add the token ID to the user's NFTs
        users[owner].userNFTs.push(NFT(tokenId, category));
    }

    function getNFTOwner(uint256 tokenId) public view returns (address) {
        return currentHolder[tokenId];
    }

    function getCategory(uint256 tokenId) public pure returns (string memory) {
        if (tokenId >= XUNICORN_MIN_ID && tokenId <= XUNICORN_MAX_ID) {
            return "Xunicorn";
        } else if (tokenId >= EXOTIC_MIN_ID && tokenId <= EXOTIC_MAX_ID) {
            return "Exotic";
        } else if (tokenId >= LEGENDARY_MIN_ID && tokenId <= LEGENDARY_MAX_ID) {
            return "Legendary";
        } else if (tokenId >= EPIC_MIN_ID && tokenId <= EPIC_MAX_ID) {
            return "Epic";
        } else if (tokenId >= RARE_MIN_ID && tokenId <= RARE_MAX_ID) {
            return "Rare";
        } else if (tokenId > RARE_MAX_ID) {
            return "Collector";
        } else {
            revert("Invalid token ID.");
        }
    }

    function calculateReward(address user) public view returns (uint256) {
        User storage userData = users[user];
        uint256 lastRewardRatio = userData.lastRewardRatio;
        uint256 newRewards = rewardRatio - lastRewardRatio;

        return newRewards * userData.userPoints;
    }

    function withdrawRewards() public payable {
        address player = msg.sender;
        User storage userData = users[player];
        require(userData.userPoints > 0, "No XenFT's registered for this user");

        
        if (!_hasValidOwnership(player)) {
            uint len = userData.userNFTs.length;
            for (uint256 i = 0; i < len; i++) {
                if(!_isNFTOwner(userData.userNFTs[i].tokenId, player)) {
                    // remove points for this NFT
                    userData.userPoints -= getTokenWeight(userData.userNFTs[i].tokenId);
                    // remove NFT from user's list
                    userData.userNFTs[i] = userData.userNFTs[userData.userNFTs.length - 1];
                    userData.userNFTs.pop();
                    

                    // using min, to make sure i is not negative
                    // i should be decreased to rerun the check for the NFT switched from the end
                    i = i == 0 ? i : i - 1;
                }
            }
        }

        uint256 rewardAmount = calculateReward(player);
        require(rewardAmount > 0, "No new rewards available for withdrawal.");

        // Effects
        userData.userRewards += rewardAmount;
        userData.userLastRewarded = totalRewards;
        userData.lastRewardRatio = rewardRatio;

        // Interactions
        payable(player).transfer(rewardAmount);
        emit RewardsWithdrawn(player, rewardAmount);
    }

    function _isNFTOwner(uint256 tokenId, address owner) public view returns (bool) {
        IXENNFTContract nftContract = IXENNFTContract(nftContractAddress);
        address nftOwner = nftContract.ownerOf(tokenId);

        return nftOwner == owner;
    }

    
    function getTokenWeight(uint256 tokenId) public pure returns (uint256) {
        if (tokenId >= XUNICORN_MIN_ID && tokenId <= XUNICORN_MAX_ID) {
            return XUNICORN_WEIGHT;
        } else if (tokenId >= EXOTIC_MIN_ID && tokenId <= EXOTIC_MAX_ID) {
            return EXOTIC_WEIGHT;
        } else if (tokenId >= LEGENDARY_MIN_ID && tokenId <= LEGENDARY_MAX_ID) {
            return LEGENDARY_WEIGHT;
        } else if (tokenId >= EPIC_MIN_ID && tokenId <= EPIC_MAX_ID) {
            return EPIC_WEIGHT;
        } else if (tokenId >= RARE_MIN_ID && tokenId <= RARE_MAX_ID) {
            return RARE_WEIGHT;
        } else if (tokenId > EPIC_MAX_ID) {
            return COLLECTOR_WEIGHT;
        } else {
            revert("Invalid token ID.");
        }
    }

    function getUserNFTCounts(address user) external view returns (uint256[] memory) {
        uint256[] memory nftCounts = new uint256[](6); // Array to store NFT counts for each category

        User storage userData = users[user];
        NFT[] storage userNFTs = userData.userNFTs;

        // Iterate over the user's registered NFTs and count them for each category
        uint len = userNFTs.length;
        for (uint256 i = 0; i < len; i++) {
            NFT storage nft = userNFTs[i];
            string memory category = nft.category;

            if (keccak256(bytes(category)) == keccak256(bytes("Xunicorn"))) {
                nftCounts[0]++;
            } else if (keccak256(bytes(category)) == keccak256(bytes("Exotic"))) {
                nftCounts[1]++;
            } else if (keccak256(bytes(category)) == keccak256(bytes("Legendary"))) {
                nftCounts[2]++;
            } else if (keccak256(bytes(category)) == keccak256(bytes("Epic"))) {
                nftCounts[3]++;
            } else if (keccak256(bytes(category)) == keccak256(bytes("Rare"))) {
                nftCounts[4]++;
            } else if (keccak256(bytes(category)) == keccak256(bytes("Collector"))) {
                nftCounts[5]++;
            }
        }

        return nftCounts;
    }

    function _hasValidOwnership(address user) public view returns (bool) {
        User storage userData = users[user];
        uint256 totalPointsOwned = 0;
        uint len = userData.userNFTs.length;
        for (uint256 i = 0; i < len; i++) {
            NFT storage nft = userData.userNFTs[i];
            if (_isNFTOwner(nft.tokenId, user)) {
                totalPointsOwned += getTokenWeight(nft.tokenId);
            } else {
                return false;
            }
        }

        return totalPointsOwned == userData.userPoints;
    }
}