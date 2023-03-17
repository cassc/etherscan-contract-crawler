// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "forge-std/console.sol";
import "@thirdweb-dev/contracts/base/ERC20Base.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../src/NFTStaking.sol";

contract TykesVerificationV2 is ReentrancyGuardUpgradeable, Ownable {

    // Interfaces for TokenERC20 and ERC721AUpgradeable
    ERC721Base public immutable nftCollection;
    ERC721Base public immutable brbNFTCollection;
    NFTStaking public immutable brbNFTStaking365;
    NFTStaking public immutable nftStaking30;
    NFTStaking public immutable nftStaking180;
    NFTStaking public immutable nftStaking365;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(ERC721Base _nftCollection, ERC721Base _brbNFTCollection, NFTStaking _brbNFTStaking365, NFTStaking _nftStaking30, NFTStaking _nftStaking180, NFTStaking _nftStaking365) {
        nftCollection = _nftCollection; 
        brbNFTCollection = _brbNFTCollection; 
        brbNFTStaking365 = _brbNFTStaking365;
        nftStaking30 = _nftStaking30;
        nftStaking180 = _nftStaking180;
        nftStaking365 = _nftStaking365;
        _setupOwner(msg.sender);
    }

    struct CollectionData {
        // Name of Collection
        string collectionName;
        // Number Owned
        uint256 balance;
    }

    // Staker info
    struct User {

        // Tykes Collection Struct
        CollectionData tykesCollectionData;
        CollectionData brbCollectionData;
    }

    //////////
    // View //
    //////////

    // Function to get a list of tokens that the user holds
    function verifyTykesOwnership(address _holder) public view returns (uint256) {

        // Pass in the address of the person you want verified
        return getNumTykesOwned(_holder);
    }

    // Function to get a list of tokens that the user holds
    function verifyBRBOwnership(address _holder) public view returns (uint256) {

         // Pass in the address of the person you want verified
        return getNumBRBOwned(_holder);
    }

    function verifyCombinedOwnership(address _holder) public view returns (User memory) {

        // Get total number of Tykes Owned
        uint256 totalTykesOwned = getNumTykesOwned(_holder);
        // Get total number of BRB Owned
        uint256 totalBRBOwned = getNumBRBOwned(_holder);

        // Format the results in a struct
        CollectionData memory tykesCollection = CollectionData('TYKES', totalTykesOwned); 
        CollectionData memory brbCollection = CollectionData('BRB', totalBRBOwned); 
        User memory user = User(tykesCollection, brbCollection);

        return (user);
    }

    /////////////
    // Internal//
    /////////////

    // Internal Function to get a list of tokens that the user holds
    function getNumTykesOwned(address _holder) internal view returns (uint256){
        uint256 numOwned = nftCollection.balanceOf(_holder); 
        console.log('Number of  Tyke NFTs just held: ', numOwned); 
        uint256 num30DayStaked = nftStaking30.getStakedTokens(_holder).length; 
        console.log('Number of Tyke NFTs Staked for 30 Days: ', num30DayStaked); 
        uint256 num180DayStaked = nftStaking180.getStakedTokens(_holder).length; 
        console.log('Number of Tyke NFTs Staked for 180 Days: ', num180DayStaked); 
        uint256 num365DayStaked = nftStaking365.getStakedTokens(_holder).length; 
        console.log('Number of Tyke NFTs Staked for 365 Days: ', num365DayStaked); 

        uint256 totalBalance = numOwned + num30DayStaked + num180DayStaked + num365DayStaked; 

        return totalBalance;
    }

     // Internal Function to get a list of tokens that the user holds
    function getNumBRBOwned(address _holder) internal view returns (uint256){
        // Pass in the address of the person you want verified
        // check balance of 
        uint256 numOwned = brbNFTCollection.balanceOf(_holder); 
        console.log('Number of BRB NFTs just held: ', numOwned); 
        uint256 num365DayStaked = brbNFTStaking365.getStakedTokens(_holder).length; 
        console.log('Number of BRB NFTs Staked for 365 Days: ', num365DayStaked); 

        uint256 totalBalance = numOwned + num365DayStaked; 

        return totalBalance;
    }


    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}