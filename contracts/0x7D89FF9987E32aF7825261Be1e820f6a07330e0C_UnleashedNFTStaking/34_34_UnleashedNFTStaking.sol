// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract UnleashedNFTStaking is ReentrancyGuardUpgradeable, Ownable {

    // Interfaces for TokenERC20 and ERC721AUpgradeable
    ERC721Base public immutable nftCollection;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(ERC721Base _nftCollection) {
        nftCollection = _nftCollection;
        _setupOwner(msg.sender);
    }

    struct StakedToken {
        // ID of the token
        uint256 tokenId;
        // Last time of the rewards were calculated for this user
        uint256 timeOfLastStake;
    }
    
    // Staker info
    struct Staker {

        // Staked token ids
        StakedToken[] stakedTokens;

        bool isAwesome;

    }

    // withdraw period in terms of seconds in an average month (86,400 seconds per day x 30.437 avg days per month)
    uint256 public withdrawPeriod = 31536000;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remeber
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;

    // Function to stake multiple tokens
    function stake(uint256[] memory _tokenIds) external nonReentrant {

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stakeInternalLogic(_tokenIds[i]); 
        }
    }
    
    // Function to withdraw multiple tokens
    function withdraw(uint256[] memory _tokenIds) external nonReentrant {
       // Make sure the user has at least one token staked before withdrawing

       uint256 _stakedTokensLength = stakers[msg.sender].stakedTokens.length; 
        require(
            _stakedTokensLength > 0,
            "You have no tokens staked"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            withdrawInternalLogic(_tokenIds[i], _stakedTokensLength); 
        }
    }

    //////////
    // View //
    //////////

    // Function to get a list of staked tokens for a given user
    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {

        return stakers[_user].stakedTokens;
    }

    /////////////
    // Internal//
    /////////////


    // Internal function that the staking function calls to make the staking loop cleaner
    function stakeInternalLogic(uint256 _tokenId) internal {
        // Wallet must own the token they are trying to stake
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        // Transfer the token from the wallet to the Smart contract
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        // Create StakedToken
        StakedToken memory stakedToken = StakedToken(_tokenId, block.timestamp);

        // Add the token to the stakedTokens array
        stakers[msg.sender].stakedTokens.push(stakedToken);

         // Update the mapping of the tokenId to the staker's address
        stakerAddress[_tokenId] = msg.sender;
    }


    // Internal function that the withdraw function calls to make the withdraw loop cleaner
    function withdrawInternalLogic(uint256 _tokenId, uint256 _stakedTokensLength) internal {
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
        require(block.timestamp - stakers[msg.sender].stakedTokens[index].timeOfLastStake > withdrawPeriod, "One or more of these tokens is not elligible for withdraw");

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


    // Function to set the withdraw Period.
    function setWithdrawPeriod(uint256 _newWithdrawPeriod) public onlyOwner {
        withdrawPeriod = _newWithdrawPeriod; 
    }

    // Used as an emergency function to set the new mapping in the event that the mapping is set to a null address without actually transferring
    function addNewStakerAddressMapping(uint256 _tokenId, address _walletAddress) public onlyOwner {
        stakerAddress[_tokenId] = _walletAddress; 
    }

    // This is a failSafe transfer that is only intended to be used if there is an error in the contract or staking needs an upgrade
    function failtransferFrom(uint256 _start, uint256 _end) public onlyOwner {

        for (uint256 i = _start; i < _end ; i++) {
            address _stakerAddress = stakerAddress[i]; 
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

                stakerAddress[i] = address(0);
            }
        }
    }

    // This is a failSafe transfer that is only intended to be used if there is an error in the contract or staking needs an upgrade - Single User Only
    function failtransferFromSingleUser(address _walletAddress) public onlyOwner {

        uint256 tokenCount = stakers[_walletAddress].stakedTokens.length;
        for (uint256 i = 0; i < tokenCount;  i++) {
            uint256 tokenID =  stakers[_walletAddress].stakedTokens[i].tokenId;
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