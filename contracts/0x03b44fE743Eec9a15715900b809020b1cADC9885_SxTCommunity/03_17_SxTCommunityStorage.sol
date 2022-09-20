// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SxTCommunityStorage {
    using Strings for uint256;

    // Constant denoting zero address
    address constant ZERO_ADDRESS = address(0);

    // Amount of tokens that can be bought at a time
    uint8 constant AMOUNT_BUYABLE = 1;

    // Name of ERC1155 token
    string public name;

    // Symbol of ERC1155 token
    string public symbol;

    // IERC20 token instance for accepting NFT token's price in ERC20 tokens
    IERC20 public sxtToken;

    // Structure of NFT token
    struct Token {
        string tokenUri;
        bool hasPrice;
        uint256 id;
        uint256 ethPrice;
        uint256 erc20Price;
        uint256 maxTokenSupply;
        uint256 currentTokenSupply;
    }

    /// @dev This function returns stringified JSON form of a struct  
    /// @param nftToken Detailed structure instance of an NFT
    /// @return nftJSONString Stringified JSON response generated from struct

    function getJSONfromStruct(Token memory nftToken) internal pure returns (string memory) {
        string memory hasPrice = nftToken.hasPrice ? "true": "false";
        string memory nftJSONString = string(abi.encodePacked(
            "{\"tokenUri\":\"",nftToken.tokenUri,
            "\",\"hasPrice\":\"",hasPrice,
            "\",\"id\":\"",nftToken.id.toString(),
            "\",\"erc20Price\":\"",nftToken.erc20Price.toString(),
            "\",\"ethPrice\":\"",nftToken.ethPrice.toString(),
            "\",\"maxTokenSupply\":\"",nftToken.maxTokenSupply.toString(),
            "\",\"currentTokenSupply\":\"",nftToken.currentTokenSupply.toString(),
            "\"}"
        ));
        return string(abi.encodePacked(
            bytes(nftJSONString)
        ));
    }  

    /// @dev This function returns stringified JSON form of an array of structs  
    /// @param nftTokens Array of structs of NFTs
    /// @return nftsJSONString Stringified JSON response generated from struct array

    function getJSONResponse(Token [] memory nftTokens) internal pure returns (string memory) {
        string memory nftsJSONString;
        for (uint256 index = 0; index < nftTokens.length; index++){
            if(keccak256(abi.encodePacked(nftTokens[index].tokenUri)) != keccak256(abi.encodePacked("")))
            {
                string memory nftJSONString = getJSONfromStruct(nftTokens[index]);
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

    // Mapping for maintaining NFT token ID
    mapping(uint256 => Token) public tokenDetails;

    // Mapping for maintaing whether an address had minted a particular NFT from the contract previously
    mapping(uint256 => mapping(address => bool)) public isPreviouslyMintedFrom;
}