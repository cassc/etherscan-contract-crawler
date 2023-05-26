// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {IOddworx} from './IOddworx.sol';
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

error NotAdmin();
error InvalidInput();
error NotOwnerOfToken();

struct nftDataStruct { // Stored in 32 bytes / 256 bits
    address ownerAddress; // 20 bytes 
    bool staked; // 1 byte
    uint64 timestamp; // 8 bytes
    bool legacyStaking; // 1 byte
}

/// @title Oddworx Staking
/// @author Mytchall
/// @notice Special Staking contract for ODDX
contract OddworxStaking is Pausable {

    mapping(address => bool) public admin;
    mapping(IERC721 => bool) public nftInterfaces;
    mapping(IERC721 => mapping(uint256 => nftDataStruct)) public nftData;
    IOddworx public oddworxContract;
    bool public nftHoldRewardsActive = true;
    uint256 public STAKING_REWARD = 20 * 10 ** 18;
    uint256 public HOLDING_REWARD = 10 * 10 ** 18;
    address public oddworxContractAddress;

    constructor(address oddworxAddress) {
        oddworxContractAddress = oddworxAddress;
        oddworxContract = IOddworx(oddworxAddress);
        admin[msg.sender] = true;
    }

    /// @notice emitted when an item is purchased
    /// @param user address of the user that purchased an item
    /// @param itemSKU the SKU of the item purchased
    /// @param price the amount paid for the item
    event ItemPurchased(address indexed user, uint256 itemSKU, uint256 price);

    /// @notice emitted when a user stakes a token
    /// @param user address of the user that staked the NFT
    /// @param nftContract which NFT set was used
    /// @param nftId the id of the NFT staked
    event StakedNft(address indexed user, address indexed nftContract, uint256 indexed nftId);

    /// @notice emitted when a user unstakes a token
    /// @param user address of the user that unstaked the NFT
    /// @param nftContract which NFT set was used
    /// @param nftId the id of the NFT unstaked
    /// @param to address where NFT was unstaked to
    event UnstakedNft(address indexed user, address indexed nftContract, uint256 indexed nftId, address to);

    /// @notice emitted when a user claim NFT rewards
    /// @param user address of the user that claimed ODDX
    /// @param nftContract which NFT set was used
    /// @param nftId the id of the NFT that generated the rewards
    /// @param amount the amount of ODDX claimed
    event UserClaimedRewards(address indexed user, address indexed nftContract, uint256 indexed nftId, uint256 amount);

    modifier onlyAdmin() {
        if (admin[msg.sender] != true) revert NotAdmin();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                             General Functions
    //////////////////////////////////////////////////////////////*/
    function pause() external onlyAdmin { _pause(); }
    function unpause() external onlyAdmin { _unpause(); }

    function toggleAdmin(address address_) external onlyAdmin {
        admin[address_] = !admin[address_];
    }

    function mint(address to, uint256 amount) internal {
        oddworxContract.mint(to, amount);
    }

    function burn(address from, uint256 amount) internal {
        oddworxContract.burn(from, amount);
    }

    function setOddworxAddress(address address_) external onlyAdmin {
        oddworxContractAddress = address_;
        oddworxContract = IOddworx(address_);
    }

    function toggleNftInterface(IERC721 address_) external onlyAdmin {
        nftInterfaces[address_] = !nftInterfaces[address_];
    }

    /*///////////////////////////////////////////////////////////////
                             Shop features
    //////////////////////////////////////////////////////////////*/
    /// @notice Buy item in shop by burning Oddx, if NFT ids are supplied, it will claim rewards on them first.
    /// @param itemSKU A unique ID used to identify shop products.
    /// @param amount Amount of Oddx to pay.
    /// @param nftContract which NFT contract to use
    /// @param nftIds Which NFT ids to use
    function buyItem(uint itemSKU, uint amount, IERC721 nftContract, uint[] calldata nftIds, address user) public whenNotPaused {
        address realUser = (admin[msg.sender]==true) ? user : msg.sender;
        if (nftIds.length>0) claimRewards(nftContract, nftIds, realUser);
        oddworxContract.burn(realUser, amount);
        emit ItemPurchased(realUser, itemSKU, amount);
    }

    /*///////////////////////////////////////////////////////////////
                                Staking
    //////////////////////////////////////////////////////////////*/

    /// @notice Get an array of data for a NFT
    /// @param nftContract which NFT contract to use
    /// @param id Which NFT to use
    function getNftData(address nftContract, uint256 id) external view returns (address, bool, uint64, bool) {
        nftDataStruct memory nft = nftData[IERC721(nftContract)][id];
        return (nft.ownerAddress, nft.staked, nft.timestamp, nft.legacyStaking);
    }

    /// @notice Updates either Staked or Holding reward amount
    /// @param newAmount new amount to use, supply number in wei.
    /// @param changeStaking true to change Staking, false to change Hold rewards
    function changeRewardAmount(uint256 newAmount, bool changeStaking) external onlyAdmin {
        (changeStaking == true) ? STAKING_REWARD = newAmount : HOLDING_REWARD = newAmount;
    }


    /// @notice Manually update staking info (contract launch date - 3 weeks)
    /// @param nftContract which NFT contract to use
    /// @param nftIds NFT's to update
    /// @param newTimestamp new timestamp
    function setUserNftData(IERC721 nftContract, uint256[] calldata nftIds, address newOwner, bool isStaked, uint256 newTimestamp, bool usingLegacyStaking) external onlyAdmin {
        for (uint256 i; i<nftIds.length; i++) {
            nftData[nftContract][nftIds[i]] = nftDataStruct(newOwner, isStaked, uint64(newTimestamp), usingLegacyStaking);
        }
    }


    /// @notice Stake NFT and claim any Hold rewards owing if not legacyStaked, otherwise claim Staked rewards and update
    /// @param nftContract NFT contract to use
    /// @param nftIds List of NFTs to stake
    function stakeNfts(IERC721 nftContract, uint256[] calldata nftIds) external whenNotPaused {
        if (!nftInterfaces[nftContract]) revert InvalidInput();
        uint256 totalRewards = 0;
        nftDataStruct memory nft;

        for (uint256 i; i<nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            nft = nftData[nftContract][nftId];

            if (nft.legacyStaking == false) {
                totalRewards += _executeRewards(nftContract, nftId, HOLDING_REWARD, HOLDING_REWARD * 3);
            } else {
                totalRewards += _executeRewards(nftContract, nftId, STAKING_REWARD, 0);
                confirmLegacyStaking(nftContract, nftId);
            }

            nftData[nftContract][nftId] = nftDataStruct(msg.sender, true, uint64(block.timestamp), false);
            _transferNft(nftContract, msg.sender, address(this), nftId);
            emit StakedNft(msg.sender, address(nftContract), nftId);
        }
        if (totalRewards > 0) mint(msg.sender, totalRewards);
    }


    /// @notice Unstake NFT and claim Stake rewards owing, resetting Hold reward time
    /// @param nftContract NFT contract to use
    /// @param nftIds List of NFTs to stake
    function unstakeNfts(IERC721 nftContract, uint256[] calldata nftIds) external whenNotPaused {
        nftDataStruct memory nft;
        uint256 totalRewards;

        for (uint256 i; i<nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            nft = nftData[nftContract][nftId];
            if (nft.staked == false) revert InvalidInput();
            if (nft.ownerAddress != msg.sender) revert NotOwnerOfToken();

            totalRewards += _executeRewards(nftContract, nftId, STAKING_REWARD, 0);
            nftData[nftContract][nftId] = nftDataStruct(msg.sender, false, uint64(block.timestamp), false);
            _transferNft(nftContract, address(this), nft.ownerAddress, nftId);
            emit UnstakedNft(msg.sender, address(nftContract), nftId, msg.sender);
        }
        if (totalRewards > 0) mint(msg.sender, totalRewards);
    }    


    /// @notice Returns amount of rewards to mint 
    /// @dev Emits event assuming mint will happen
    /// @param nftContract NFT contract to use
    /// @param nftId NFT to calculate rewards for
    /// @param rewardAmount Weekly reward amount
    /// @param initialReward Default reward amount
    function _executeRewards(IERC721 nftContract, uint256 nftId, uint256 rewardAmount, uint256 initialReward) internal returns (uint256) {
        uint256 rewards = _rewardsForTimestamp(
            nftData[nftContract][nftId].timestamp,
            rewardAmount,
            initialReward
        );
        emit UserClaimedRewards(msg.sender, address(nftContract), nftId, rewards);
        return rewards;
    }


    /// @notice Emergency Unstake NFT
    /// @param nftContract NFT contract to use
    /// @param nftIds List of NFTs to stake
    /// @param to Where to send NFT
    function unstakeNftEmergency(IERC721 nftContract, uint256[] calldata nftIds, address user, address to) external onlyAdmin {
        for (uint256 i; i<nftIds.length; i++) {
            address realUser = (admin[msg.sender]==true) ? user : msg.sender;
            nftData[nftContract][nftIds[i]] = nftDataStruct(to, false, uint64(block.timestamp), false);
            _transferNft(nftContract, address(this), to, nftIds[i]);
            emit UnstakedNft(realUser, address(nftContract), nftIds[i], to);
        }
    }


    /// @notice Claim either Hold or Claim rewards for each Nft
    /// @param nftContract Which NFT set is being used
    /// @param nftIds NFT id's to claim for
    function claimRewards(IERC721 nftContract, uint256[] calldata nftIds, address user) public whenNotPaused {
        if (!nftInterfaces[nftContract] || msg.sender == address(0)) revert InvalidInput();
        uint256 totalRewards;
        nftDataStruct memory nft;

        address realUser = (admin[msg.sender]==true) ? user : msg.sender;
    
        for (uint256 i; i<nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            nft = nftData[nftContract][nftId];

            if (nft.staked == false) {
                if (nftContract.ownerOf(nftId) != realUser) revert NotOwnerOfToken();
                totalRewards += _executeRewards(nftContract, nftId, HOLDING_REWARD, HOLDING_REWARD * 3);
            } else {
                if (nft.ownerAddress != realUser) revert NotOwnerOfToken();
                totalRewards += _executeRewards(nftContract, nftId, STAKING_REWARD, 0);
                if (nft.legacyStaking == true) confirmLegacyStaking(nftContract, nftId);
            }
            
            nftData[nftContract][nftId].timestamp = uint64(block.timestamp);
        }
        if (totalRewards > 0) mint(realUser, totalRewards);
    }


    /// @notice Calculate Hold or Staked rewards based on timestamp
    /// @param timestamp Timestamp to use
    /// @param rewardValue How much to reward per week
    /// @param initialReward Initial reward if first time claiming
    function _rewardsForTimestamp(uint256 timestamp, uint256 rewardValue, uint256 initialReward) internal view returns (uint256) {
        return (timestamp > 0)
            ? rewardValue * ((block.timestamp - timestamp) / 1 weeks)
            : initialReward;
    }


    /// @notice Actually transfer NFT
    /// @dev Internal only, checks are done before this
    /// @param nftContract NFT contract to use
    /// @param from Where to transfer NFT from
    /// @param to Where to send NFT
    function _transferNft(IERC721 nftContract, address from, address to, uint256 nftId) internal {
        nftContract.transferFrom(from, to, nftId);
    }


    /// @notice Checks if NFT uses legacyStaking and if it's still valid, otherwise update struct to show not staked
    /// @param nftContract Which NFT contract to use
    /// @param nftId Which NFT to check
    function confirmLegacyStaking(IERC721 nftContract, uint256 nftId) internal {
        if (nftContract.ownerOf(nftId) != oddworxContractAddress ) {
            nftData[nftContract][nftId].legacyStaking = false;
            nftData[nftContract][nftId].staked = false; 
        }
    }

}