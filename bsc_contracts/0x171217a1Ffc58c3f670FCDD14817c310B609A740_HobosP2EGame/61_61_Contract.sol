// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

// Import thirdweb contracts
import "@thirdweb-dev/contracts/drop/DropERC1155.sol"; // For my collection of boosterss
import "@thirdweb-dev/contracts/token/TokenERC20.sol"; // For my ERC-20 Token contract
import "@thirdweb-dev/contracts/openzeppelin-presets/utils/ERC1155/ERC1155Holder.sol"; // For my ERC-1155 Receiver contract

// OpenZeppelin (ReentrancyGuard)
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HobosP2EGame is ReentrancyGuard, ERC1155Holder {
    // Store our two other contracts here (Edition Drop and Token)
    DropERC1155 public immutable boostersNftCollection;
    TokenERC20 public immutable rewardsToken;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(DropERC1155 boostersContractAddress, TokenERC20 HOBTContractAddress) {
        boostersNftCollection = boostersContractAddress;
        rewardsToken = HOBTContractAddress;
    }

    struct MapValue {
        bool isData;
        uint256 value;
    }

    // Mapping of player addresses to their current boosters
    // By default, player has no boosters. They will not be in the mapping.
    // Mapping of address to boosters is not set until they stake a one.
    // In this example, the tokenId of the boosters is the multiplier for the reward.
    mapping (address => MapValue) public playerboosters;

    // Mapping of player address until last time they staked/withdrew/claimed their rewards
    // By default, player has no last time. They will not be in the mapping.
    mapping (address => MapValue) public playerLastUpdate;

    function stake(uint256 _tokenId) external nonReentrant {
        // Ensure the player has at least 1 of the token they are trying to stake
        require(boostersNftCollection.balanceOf(msg.sender, _tokenId) >= 1, "You must have at least 1 of the boosters you are trying to stake");

        // If they have a boosters already, send it back to them.
        if (playerboosters[msg.sender].isData) {
            // Transfer using safeTransfer
            boostersNftCollection.safeTransferFrom(address(this), msg.sender, playerboosters[msg.sender].value, 1, "Returning your old boosters");
        }

        // Calculate the rewards they are owed, and pay them out.
        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        // Transfer the boosters to the contract
        boostersNftCollection.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "Staking your boosters");

        // Update the playerboosters mapping
        playerboosters[msg.sender].value = _tokenId;
        playerboosters[msg.sender].isData = true;

        // Update the playerLastUpdate mapping
        playerLastUpdate[msg.sender].isData = true;
        playerLastUpdate[msg.sender].value = block.timestamp;
    }


    function withdraw() external nonReentrant {
        // Ensure the player has a boosters
        require(playerboosters[msg.sender].isData, "You do not have a boosters to withdraw.");

        // Calculate the rewards they are owed, and pay them out.
        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        // Send the boosters back to the player
        boostersNftCollection.safeTransferFrom(address(this), msg.sender, playerboosters[msg.sender].value, 1, "Returning your old boosters");

        // Update the playerboosters mapping
        playerboosters[msg.sender].isData = false;

        // Update the playerLastUpdate mapping
        playerLastUpdate[msg.sender].isData = true;
        playerLastUpdate[msg.sender].value = block.timestamp;
    }

    function claim() external nonReentrant {
        // Calculate the rewards they are owed, and pay them out.
        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        // Update the playerLastUpdate mapping
        playerLastUpdate[msg.sender].isData = true;
        playerLastUpdate[msg.sender].value = block.timestamp;
    }        

    // ===== Internal ===== \\

    // Calculate the rewards the player is owed since last time they were paid out
    // The rewards rate is 20,000,000 per block.
    // This is calculated using block.timestamp and the playerLastUpdate.
    // If playerLastUpdate or playerboosters is not set, then the player has no rewards.
    function calculateRewards(address _player)
        public
        view
        returns (uint256 _rewards)
    {
        // If playerLastUpdate or playerboosters is not set, then the player has no rewards.
        if (!playerLastUpdate[_player].isData || !playerboosters[_player].isData) {
            return 0;
        }

        // Calculate the time difference between now and the last time they staked/withdrew/claimed their rewards
        uint256 timeDifference = block.timestamp - playerLastUpdate[_player].value;

        // Calculate the rewards they are owed
        uint256 rewards = timeDifference * 100_000_000_000_000_000 * (playerboosters[_player].value + 1);

        // Return the rewards
        return rewards;
        
    }
}