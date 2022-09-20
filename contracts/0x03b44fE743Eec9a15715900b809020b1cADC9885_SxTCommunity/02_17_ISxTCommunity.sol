// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../SxTCommunityStorage.sol";

interface ISxTCommunity {

    /// @dev This is the event to notify that price in ethers of an NFT is set
    /// @param id ID of NFT token for which token price is updated
    /// @param newTokenEthPrice New price in ethers set for the NFT token
    
    event TokenEthPriceSet(uint256 id, uint256 newTokenEthPrice);

    /// @dev This is the event to notify that price in ERC20 tokens of an NFT is set
    /// @param id ID of NFT token for which token price is updated
    /// @param newTokenERC20Price New price in ERC20 tokens set for the NFT token
    
    event TokenERC20PriceSet(uint256 id, uint256 newTokenERC20Price);

    /// @dev This is the event to notify that prices of an NFT are reset to zero
    /// @param id ID of NFT token for which token pricse are updated
    event TokenPriceReset(uint256 id);

    /// @dev This is the event to notify that an ERC20 token for buying NFTs is set.
    /// @param sXtToken Address of the ERC20 token set

    event Erc20TokenSet(IERC20 sXtToken);

    /// @dev This is the event to notify that an NFT token is bought free of cost.
    /// @param id ID of NFT token bought
    /// @param to Address of the NFT buyer  

    event NftMinted(uint256 id, address to);

    /// @dev This is the event to notify that an NFT token is bought using ethers.
    /// @param id ID of NFT token bought
    /// @param to Address of the NFT buyer  
    /// @param tokenPrice Price for the NFT token bought

    event NftMintedUsingEth(uint256 id, address to, uint256 tokenPrice);

    /// @dev This is the event to notify that an NFT token is bought using ERC20 tokens.
    /// @param id ID of NFT token bought
    /// @param to Address of the NFT buyer  
    /// @param tokenPrice Price for the NFT token bought

    event NftMintedUsingERC20(uint256 id, address to, uint256 tokenPrice);

    /// @dev This is the event to notify that a new NFT token has been added in contract
    /// @param id ID of NFT token added

    event NewNFTAdded(uint256 id);

    /// @dev This is the event to notify that all ethers are withdrawn from contract by owner.
    /// @param amount Amount of ethers withdrawn
    /// @param to Address of the owner to which ethers are sent

    event EtherWithdrawn(uint256 amount, address payable to);

    /// @dev This is the event to notify that all ERC20 tokens are withdrawn from contract by owner.
    /// @param amount Amount of tokens withdrawn
    /// @param to Address of the owner to which ERC20 tokens are transferred

    event Erc20TokenWithdrawn(uint256 amount, address to);

    /// @dev This is the function to get the list of available or sold-out NFTs in a paginated JSON string response  
    /// @param pageNumber Page number of the response required
    /// @param pageSize Size of each page of response required
    /// @param isAvailable Category of NFTs to get, true for available to mint NFTs, and false for sold out NFTs 
    /// @return nftsResponseJSON Stringified JSON response having the list of NFT details according to page number, page size, isAvailable( Available for mint or sold-out) 
    /// @return allAcceptableNFTsCount Count of all available or sold-out ( depending on isAvailable param passed) NFTs that the contract has

    function retrieveNFTs(uint256 pageNumber, uint256 pageSize, bool isAvailable) external view returns(string memory nftsResponseJSON, uint256 allAcceptableNFTsCount);

    /// @dev This is the function to set the price in ethers for an NFT token 
    /// @dev Only the owner can call this function
    /// @param id ID of NFT token for which token price needs to be updated
    /// @param newTokenEthPrice New price in ethers for the NFT token
    
    function setTokenEthPrice(uint256 id, uint256 newTokenEthPrice) external;

    /// @dev This is the function to set the price in ERC20 tokens for an NFT token 
    /// @dev Only the owner can call this function
    /// @param id ID of NFT token for which token price needs to be updated
    /// @param newTokenERC20Price New price in ERC20 tokens for the NFT token
    
    function setTokenERC20Price(uint256 id, uint256 newTokenERC20Price) external;

    /// @dev This is the function to reset the prices for an NFT token 
    /// @dev Only the owner can call this function
    /// @param id ID of NFT token for which token prices need to be updated

    function resetTokenPrices(uint256 id) external;

    /// @dev This is the function to set the ERC20 token for accepting price of NFTs 
    /// @dev Only the owner can call this function
    /// @param newSxtToken Address of the particular ERC20 token, for accepting price of NFTs in ERC20 tokens

    function setERC20Token(IERC20 newSxtToken) external;

    /// @dev This is the function to buy a new NFT token which is available free of cost
    /// @dev Only called when contract is unpaused
    /// @param id ID of NFT token to be bought
    /// @param to Address to which NFT token should be minted to

    function mintNFT(uint256 id, address to) external;

    /// @dev This is the function to buy a new NFT token using Ethers
    /// @dev Only called when contract is unpaused
    /// @dev If Token is buyable with Ether and ethPrice > 0, function will accept ethers
    /// @param id ID of NFT token to be bought
    /// @param to Address to which NFT token should be minted to

    function mintNFTUsingEth(uint256 id, address to) external payable;

    /// @dev This is the function to buy a new NFT token using ERC20 Token
    /// @dev Only called when contract is unpaused
    /// @dev If Token is buyable with ERC20 token and erc20Price > 0, function will transfer ERC20 tokens to contract
    /// @param id ID of NFT token to be bought
    /// @param to Address to which NFT token should be minted to

    function mintNFTUsingERC20(uint256 id, address to) external;

    /// @dev This is the function to add new NFT tokens in the contract
    /// @dev Only the owner can call this function
    /// @param newTokenURIs Array of URIs for NFTs to be added
    /// @param maxNewTokenSupplies Array of maximum possible supplies for NFTs to be added
    /// @param hasPrices Array of boolean flags representing whether the NFT token has any price or not
    /// @param newEthPrices Array of prices in Ethers for NFTs to be added
    /// @param newERC20Prices Array of prices in ERC20 Tokens for NFTs to be added

    function addNewNFTs(string [] memory newTokenURIs, bool [] memory hasPrices, uint256 [] memory newEthPrices, uint256 [] memory newERC20Prices, uint256 [] memory maxNewTokenSupplies) external;
    
    /// @dev This is the function to withdraw ethers from contract
    /// @dev Only the owner can call this function

    function withdrawEth() external;

    /// @dev This is the function to withdraw ERC20 Tokens from contract
    /// @dev Only the owner can call this function    

    function withdrawERC20() external;

    /// @dev This is the function to pause the contract

    function pause() external;

    /// @dev This is the function to unpause the contract

    function unpause() external;
  
}