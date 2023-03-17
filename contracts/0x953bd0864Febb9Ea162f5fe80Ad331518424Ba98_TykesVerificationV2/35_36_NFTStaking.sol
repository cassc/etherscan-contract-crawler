// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract NFTStaking is ReentrancyGuardUpgradeable, Ownable {

    // Interfaces for TokenERC20 and ERC721AUpgradeable
    ERC20Base public immutable rewardsToken;
    ERC721Base public immutable nftCollection;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(ERC721Base _nftCollection, ERC20Base _rewardsToken) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        _setupOwner(msg.sender);
    }

    struct StakedToken {
        // ID of the token
        uint16 tokenId;
        // Last time of the rewards were calculated for this user
        uint64 timeOfLastStake;
        // Last time of the rewards were calculated for this user
        uint64 timeOfLastClaim;
    }
    
    // Staker info
    struct Staker {

        // Staked token ids
        StakedToken[] stakedTokens;

        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint128 unclaimedRewards;

    }

    // BaseRate Info
    struct BaseRate {
        // Staked token ids
        uint16 tokenId;
        // rate given to each token based on Rarity
        uint128 dailyRate;
    }

    // SoulOwner Info
    struct SoulOwner {
        // Staked token ids
        address walletAddress;
        // flag to set if they are a soul owner or not
        bool isSoulOwner;
    }


    // withdraw period in terms of seconds in an average month (86,400 seconds per day x 30.437 avg days per month)
    uint64 public withdrawPeriod = 2629757;

    // Percent the treasury gets on top of each claim amount
    uint8 public treasuryPercentage = 35;

    // Percent the soul NFT awards an owner on top of the claim amount
    uint8 public soulPercentage = 11;

    // Treasury Wallet Address
    address public treasury = 0x87885321fAEF5F7F549009a60eE13C735c3438df; 

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token to Base Rate Rarity
    mapping(uint16 => uint128) public baseRates;

    // Mapping of Token Id to staker. Made for the SC to remeber
    // who to send back the ERC721 Token to.
    mapping(uint16 => address) public stakerAddress;

    // Mapping of address to bool of whether staker owns a Soul NFT
    mapping(address => bool) public soulOwner;

    // Function to stake multiple tokens
    function stake(uint16[] memory _tokenIds) external nonReentrant {

        for (uint32 i = 0; i < _tokenIds.length; i++) {
            stakeInternalLogic(_tokenIds[i]); 
        }
    }
    
    // Function to withdraw multiple tokens
    function withdraw(uint16[] memory _tokenIds) external nonReentrant {
       // Make sure the user has at least one token staked before withdrawing

       uint256 _stakedTokensLength = stakers[msg.sender].stakedTokens.length; 
        require(
            _stakedTokensLength > 0,
            "You have no tokens staked"
        );

        // Forces the user to set claimed Rewards on Withdraw
        updateUnclaimedInternal(_stakedTokensLength); 


        for (uint16 i = 0; i < _tokenIds.length; i++) {
            withdrawInternalLogic(_tokenIds[i], _stakedTokensLength); 
        }
    }

    // Function to claim rewards
    function claimRewards() external {
        uint128 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");

        // Loop through each staked Token and update the timeOfLastClaim
        uint256 _stakedTokensLength = stakers[msg.sender].stakedTokens.length; 
        for (uint256 i = 0; i < _stakedTokensLength; i++) {
            stakers[msg.sender].stakedTokens[uint16(i)].timeOfLastClaim = uint32(block.timestamp);
        }

        // Set Claim Reward to 0
        stakers[msg.sender].unclaimedRewards = 0;

        // Mint Tokens from ERC20 Token Staking Contractß
        rewardsToken.mintTo(msg.sender, rewards);

        // Mint Tokens from ERC20 Token Staking Contract to Treasury
        rewardsToken.mintTo(treasury, (rewards * treasuryPercentage) / 100);
    }

    // function used to calculate and set rewards upon withdraw
    function updateUnclaimedInternal(uint256 _stakedTokensLength) internal {
        uint128 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;

        // Loop through each staked Token and update the timeOfLastClaim
        for (uint256 i = 0; i < _stakedTokensLength; i++) {
            stakers[msg.sender].stakedTokens[uint16(i)].timeOfLastClaim = uint32(block.timestamp);
        }

        // Set Claim Rewards
        stakers[msg.sender].unclaimedRewards = rewards;

    }


    //////////
    // View //
    //////////

    // Function to view the available rewards
    function availableRewards(address _staker) public view returns (uint128) {
        uint128 rewards = calculateRewards(_staker) +
            stakers[_staker].unclaimedRewards;
        return rewards;
    }

    // Function to get a list of staked tokens for a given user
    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {

        return stakers[_user].stakedTokens;
    }

    /////////////
    // Internal//
    /////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and dailyRate.
    function calculateRewards(address _staker)
        internal
        view
        returns (uint128 _rewards)
    {
        // Get all Tokens that the address owns
        // Loop through each one and set the reward
        // return reward for each token that the address owns
        _rewards = 0;

        // for each staked Token in the Stakers array by address
        uint256 _stakedTokensLength = stakers[_staker].stakedTokens.length; 
         for (uint256 i = 0; i < _stakedTokensLength; i++) {

            // Get time of Last Stake
            uint64 timeOfLastStake = stakers[_staker].stakedTokens[uint16(i)].timeOfLastStake;

            // Get time of Last Claim
            uint64 timeOfLastClaim = stakers[_staker].stakedTokens[uint16(i)].timeOfLastClaim;

            // Get the user's current Rate 
            // TODO: Call to get this tokenId's base rate from external source
            uint128 rate = (baseRates[stakers[_staker].stakedTokens[uint16(i)].tokenId] * 1e18);

            if (withdrawPeriod < block.timestamp - timeOfLastStake) {
                if ((int64(withdrawPeriod) - (int64(timeOfLastClaim) - int64(timeOfLastStake))) > 0) {
                    _rewards += ((withdrawPeriod - (timeOfLastClaim - timeOfLastStake)) * rate) / 86400;
                }
                else {
                    _rewards += 0; 
                }
            }
            else {
                _rewards += ((uint64(block.timestamp) - timeOfLastClaim) * rate) / 86400; 
            }
        }

        // If the user is a soul owner, give them a 10% bonus
        if(soulOwner[msg.sender]) {
            _rewards = (_rewards * uint128(soulPercentage)) / 10;
        }

        return (_rewards); 
    }

    // Internal function that the staking function calls to make the staking loop cleaner
    function stakeInternalLogic(uint16 _tokenId) internal {
        // Wallet must own the token they are trying to stake
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        // Transfer the token from the wallet to the Smart contract
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        // Create StakedToken
        StakedToken memory stakedToken = StakedToken(_tokenId, uint32(block.timestamp), uint32(block.timestamp));

        // Add the token to the stakedTokens array
        stakers[msg.sender].stakedTokens.push(stakedToken);

         // Update the mapping of the tokenId to the staker's address
        stakerAddress[_tokenId] = msg.sender;
    }


    // Internal function that the withdraw function calls to make the withdraw loop cleaner
    function withdrawInternalLogic(uint16 _tokenId, uint256 _stakedTokensLength) internal {
        // Wallet must own the token they are trying to withdraw
        require(stakerAddress[_tokenId] == msg.sender, "You don't own one or more of these tokens!");

        // Find the index of this token id in the stakedTokens array
        uint256 index = 0;
        for (uint256 i = 0; i < _stakedTokensLength; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId 
            ) {
                index = i;
                break;
            }
        }

        // Check to see if token is elligible for withdraw based on stakedToken or extendedStake timestamp
        require(uint32(block.timestamp) - stakers[msg.sender].stakedTokens[index].timeOfLastStake > withdrawPeriod, "One or more of these tokens is not elligible for withdraw");

        // On Withdraw, the user is ending their ability to compound. 
        remove(index); 

        stakerAddress[_tokenId] = address(0);

        // Transfer the token back to the withdrawer
        nftCollection.transferFrom(address(this), msg.sender, _tokenId);
    }

    function remove(uint256 index) internal{
      stakers[msg.sender].stakedTokens[index] = stakers[msg.sender].stakedTokens[stakers[msg.sender].stakedTokens.length - 1];
      stakers[msg.sender].stakedTokens.pop();
    }

    function removeFailSafe(uint256 index, address _wallet) internal{
      stakers[_wallet].stakedTokens[index] = stakers[_wallet].stakedTokens[stakers[_wallet].stakedTokens.length - 1];
      stakers[_wallet].stakedTokens.pop();
    }
    /////////////
    // Owner Only //
    /////////////


    // Function to set base rates
    function setBaseRate(BaseRate[] memory _newBaseRates) public onlyOwner {

        // Get each object passed in to setBaseRate
         for (uint16 i = 0; i < _newBaseRates.length; i++) {
            // Add Mapping for each object 
             baseRates[_newBaseRates[i].tokenId] = _newBaseRates[i].dailyRate;
        }
    }

    // Function to set who is a soul owner
    function setSoulOwners(SoulOwner[] memory _newSoulOwners) public onlyOwner {
        // Get each object passed in to setBaseRate
         for (uint16 i = 0; i < _newSoulOwners.length; i++) {
            // Add Mapping for each object
             soulOwner[_newSoulOwners[i].walletAddress] = _newSoulOwners[i].isSoulOwner;
        }
    }

    // Function to set the withdraw Period.
    function setWithdrawPeriod(uint32 _newWithdrawPeriod) public onlyOwner {
        withdrawPeriod = _newWithdrawPeriod; 
    }

    // Function to set the treasury address
    function setTreasuryAddress(address _newTreasuryAddress) public onlyOwner {
        treasury = _newTreasuryAddress; 
    }

    // Function to set the treasury percentage
    function setTreasuryPercentage(uint8 _newtreasuryPercentage) public onlyOwner {
        treasuryPercentage = _newtreasuryPercentage; 
    }

    // Function to set Soul Percentage
    function setSoulPercentage(uint8 _newtsoulPercentage) public onlyOwner {
        soulPercentage = _newtsoulPercentage; 
    }

    // Used as an emergency function to set the new mapping in the event that the mapping is set to a null address without actually transferring
    function addNewStakerAddressMapping(uint256 _tokenId, address _walletAddress) public onlyOwner {
        stakerAddress[uint16(_tokenId)] = _walletAddress; 
    }

    // This is a failSafe transfer that is only intended to be used if there is an error in the contract or staking needs an upgrade
    function failtransferFrom(uint256 _start, uint256 _end) public onlyOwner {

        for (uint256 i = _start; i < _end ; i++) {
            address _stakerAddress = stakerAddress[uint16(i)]; 
            if (_stakerAddress != 0x0000000000000000000000000000000000000000 ) {

                uint256 index = 0;
                uint256 _stakedTokensLength = stakers[_stakerAddress].stakedTokens.length; 
                for (uint256 j = 0; j < _stakedTokensLength; j++) {
                    if (
                        stakers[_stakerAddress].stakedTokens[j].tokenId == i 
                    ) {
                        index = j;
                        break;
                    }
                }

                removeFailSafe(index, _stakerAddress); 

                nftCollection.transferFrom(address(this), _stakerAddress, i);

                stakerAddress[uint16(i)] = address(0);
            }
        }
    }

    // This is a failSafe transfer that is only intended to be used if there is an error in the contract or staking needs an upgrade - Single User Only
    function failtransferFromSingleUser(address _walletAddress) public onlyOwner {

        uint16 tokenCount = uint16(stakers[_walletAddress].stakedTokens.length);
        for (uint16 i = 0; i < tokenCount;  i++) {
            uint16 tokenID =  stakers[_walletAddress].stakedTokens[i].tokenId;
            nftCollection.transferFrom(address(this), _walletAddress, tokenID);
            stakerAddress[tokenID] = address(0);
        }
        
        delete stakers[_walletAddress].stakedTokens;
    }


    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}