// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SxTCommunityStorageUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;

    // Constant denoting zero address
    address constant ZERO_ADDRESS = address(0);

    // Amount of tokens that can be bought at a time
    uint8 constant DEFAULT_AMOUNT = 1;

    // Name of ERC1155 token
    string public name;

    // Symbol of ERC1155 token
    string public symbol;

    // Structure of NFT token
    struct SxtNFT {
        string tokenUri;
        uint256 id;
        uint256 maxTokenSupply;
    }

    // Mapping for maintaining NFT token ID
    mapping(uint256 => SxtNFT) public tokenDetails;

    // Mapping for maintaing whether an address had minted a particular NFT from the contract previously
    mapping(uint256 => mapping(address => bool)) public isAddressUtilized; 
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __StorageUpgradeable_init() internal onlyInitializing {
        __StorageUpgradeable_init_unchained();
    }

    function __StorageUpgradeable_init_unchained() internal onlyInitializing {
    }

    /// @dev This function returns stringified JSON form of a struct  
    /// @param nftToken Detailed structure instance of an NFT
    /// @return nftJSONString Stringified JSON response generated from struct

    function getJSONfromStruct(SxtNFT memory nftToken, uint256 nftTotalSupply) internal pure returns (string memory) {
        string memory nftJSONString = string(abi.encodePacked(
            "{\"tokenUri\":\"",nftToken.tokenUri,
            "\",\"id\":\"",nftToken.id.toString(),
            "\",\"maxTokenSupply\":\"",nftToken.maxTokenSupply.toString(),
            "\",\"currentTokenSupply\":\"",nftTotalSupply.toString(),
            "\"}"
        ));
        return string(abi.encodePacked(
            bytes(nftJSONString)
        ));
    }  

    /// @dev This function returns stringified JSON form of an array of structs  
    /// @param nftTokens Array of structs of NFTs
    /// @return nftsJSONString Stringified JSON response generated from struct array

    function getJSONResponse(SxtNFT [] memory nftTokens, uint256 [] memory nftTotalSupply) internal pure returns (string memory) {
        string memory nftsJSONString;
        for (uint256 index = 0; index < nftTokens.length; index++){
            if(keccak256(abi.encodePacked(nftTokens[index].tokenUri)) != keccak256(abi.encodePacked("")))
            {
                string memory nftJSONString = getJSONfromStruct(nftTokens[index], nftTotalSupply[index]);
                if(index != 0 )
                    nftsJSONString = string(abi.encodePacked( nftsJSONString, ","));
                nftsJSONString = string(abi.encodePacked(nftsJSONString, nftJSONString));                
            }
            else 
            {
                break;
            }
        }
        nftsJSONString = string(abi.encodePacked("[", nftsJSONString, "]"));
        return nftsJSONString;
    }

    /// @dev This is the internal function to check if maximum supply reached for an NFT
    /// @dev This is called inside mintNFT, mintNFTUsingEth, mintNFTUsingERC20 functions
    /// @param id ID of NFT token to be checked
    /// @param quantity Quantity of NFT token to be minted

    function checkMaxSupply(uint256 id, uint256 quantity, uint256 totalSupply) view internal returns(bool){
        if((totalSupply + quantity) <= tokenDetails[id].maxTokenSupply)
            return false;
        return true;
    }

    /// @dev This is the internal function to check if NFT is sold out already
    /// @dev This is called inside mintNFT, mintNFTUsingEth, mintNFTUsingERC20 functions
    /// @param id ID of NFT token to be checked

    function checkPendingAirdrop(uint256 id, uint256 totalSupply) view internal returns(bool){
        if(totalSupply < tokenDetails[id].maxTokenSupply)
            return true;
        return false;
    }

    /// @dev This is the internal function to compare 2 strings
    /// @param s1 First string for comparing value
    /// @param s2 Second string for comparing value

    function compareStrings(string memory s1, string memory s2) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2)));
    }

    /// @dev This is the function to pause the contract

    function pause() external onlyOwner {
        _pause();
    }

    /// @dev This is the function to unpause the contract

    function unpause() external onlyOwner {
        _unpause();
    }

    // For Future Usage

    // Mapping between the address and boolean for whitelisting
    mapping (address => bool) public whiteList;

    // Mapping between the NFT ID and address and boolean for whitelisting
    mapping (uint256 => mapping (address => bool)) public whiteListForNFT;
}