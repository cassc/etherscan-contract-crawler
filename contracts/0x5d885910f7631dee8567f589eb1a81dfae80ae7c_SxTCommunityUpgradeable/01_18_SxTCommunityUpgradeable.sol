// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./SxTCommunityStorageUpgradeable.sol";

contract SxTCommunityUpgradeable is ERC1155SupplyUpgradeable, SxTCommunityStorageUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Counter for maintaining TokenIDs
    CountersUpgradeable.Counter public currentTokenIndex;

    /// @dev This is the initializer function to initialize the contract.
    /// @param tokenName Name of the ERC1155 token
    /// @param tokenSymbol Symbol of the ERC1155 token

    function initialize(string memory tokenName, string memory tokenSymbol) initializer public {
        require(!compareStrings(tokenName, ""), "SxTCommunityUpgradeable: Token name cannot be an empty string");
        require(!compareStrings(tokenSymbol, ""), "SxTCommunityUpgradeable: Token symbol cannot be an empty string");
        name = tokenName;
        symbol = tokenSymbol;
        __StorageUpgradeable_init();
        __ERC1155_init("");
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    /// @dev This is the event to notify that an NFT token is Airdropped.
    /// @param id ID of NFT token bought
    /// @param requestedAirdropCount Number of recepients for whom airdrop requested  
    /// @param successfulAirdropCount Number of recepients for whom airdrop successfully completed    

    event SxTNFTAirdropped(uint256 id, uint256 requestedAirdropCount, uint256 successfulAirdropCount);

    /// @dev This is the event to notify that a new NFT token has been added in contract
    /// @param id ID of NFT token added

    event SxTNFTAdded(uint256 id);

    /// @dev This is the function to get the URI for an NFT token 
    /// @param id ID of NFT token for which URI needs to be fetched 
    /// @return tokenUri URI of the NFT with required id

    function uri(uint id) public view override returns (string memory) {
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunityUpgradeable: URI nonexistent token");
        return tokenDetails[id].tokenUri;
    }

    /// @dev This is the function to get the list of available or sold-out NFTs in a paginated JSON string response  
    /// @param pageNumber Page number of the response required
    /// @param pageSize Size of each page of response required
    /// @param isAirdropPending Category of NFTs to get, true for available to mint NFTs, and false for sold out NFTs 
    /// @return nftsResponseJSON Stringified JSON response having the list of NFT details according to page number, page size, isAvailable( Available for mint or sold-out) 
    /// @return allAcceptableNFTsCount Count of all available or sold-out ( depending on isAvailable param passed) NFTs that the contract has

    function retrieveNFTs(uint256 pageNumber, uint256 pageSize, bool isAirdropPending) external view returns(string memory, uint256) {
        string memory nftsResponseJSON = "[]";
        uint256 allAcceptableNFTsCount = 0;
        SxtNFT [] memory resultTokens = new SxtNFT[](pageSize);
        uint256 [] memory resultTokenSupplies = new uint256 [](pageSize);
        SxtNFT [] memory allAcceptableTokens = new SxtNFT[](currentTokenIndex.current());
        for ( uint256 i = currentTokenIndex.current(); i > 0; i--){
            if(isAirdropPending == checkPendingAirdrop(i, totalSupply(i))){
                SxtNFT storage tokenTemp = tokenDetails[i];
                allAcceptableTokens[allAcceptableNFTsCount] = tokenTemp;
                allAcceptableNFTsCount++;
            }
        }
        if(pageNumber == 0 || pageSize == 0 ){
            return (nftsResponseJSON, allAcceptableNFTsCount);
        }
        uint256 startIndex = ((pageNumber - 1) * pageSize);
        uint256 endIndex = startIndex + pageSize;
        if(startIndex >= currentTokenIndex.current()){
            return (nftsResponseJSON, allAcceptableNFTsCount);
        }
        if(endIndex > currentTokenIndex.current()){
            endIndex = currentTokenIndex.current();
        }
        for ( uint256 j = startIndex; j < endIndex; j++){
            resultTokens[j - startIndex] = allAcceptableTokens[j];
            resultTokenSupplies[j- startIndex] = totalSupply(allAcceptableTokens[j].id);
        }
        nftsResponseJSON = getJSONResponse(resultTokens, resultTokenSupplies);
        return (nftsResponseJSON, allAcceptableNFTsCount);
    }

    /// @dev This is the function to add single new NFT token in the contract
    /// @dev Only the owner can call this function
    /// @param newTokenURI URI for NFT to be added
    /// @param maxNewTokenSupply Maximum possible supply for NFT to be added

    function addSxTNFT(string memory newTokenURI, uint256 maxNewTokenSupply) external onlyOwner {
        require(maxNewTokenSupply > 0, "SxTCommunityUpgradeable: Maximum supply cannot be 0");
        require(!compareStrings(newTokenURI, ""), "SxTCommunityUpgradeable: URI cannot be empty string");
        SxtNFT memory newToken;
        currentTokenIndex.increment();
        uint256 newTokenIndex = currentTokenIndex.current();
        newToken.id = newTokenIndex;
        newToken.tokenUri = newTokenURI;
        newToken.maxTokenSupply = maxNewTokenSupply;
        tokenDetails[newTokenIndex] = newToken;
        emit SxTNFTAdded(newToken.id);
    }

    /// @dev This is the function to airdrop default amount of instances of an NFT token from contract
    /// @dev Only the owner can call this function
    /// @param id ID of NFT token to be airdropped
    /// @param recipients Array of recepient addresses to whom token is to be minted
    
    function airdropSxTNFT(uint256 id, address[] memory recipients) external onlyOwner whenNotPaused nonReentrant{
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunityUpgradeable: URI nonexistent token");
        require(!checkMaxSupply(id, recipients.length, totalSupply(id)), "SxTCommunityUpgradeable: Total supply exceeded maximum supply");
        uint256 successfulAirdropCount;
        for (uint256 index = 0; index < recipients.length; index++) {
            if(recipients[index] != ZERO_ADDRESS && !(isAddressUtilized[id][recipients[index]])){
                successfulAirdropCount += 1;
                isAddressUtilized[id][recipients[index]] = true;
                _mint(recipients[index], id, DEFAULT_AMOUNT, "");
            }
        }
        emit SxTNFTAirdropped(id, recipients.length, successfulAirdropCount);
    }

    /// @dev This is the function to stop the token transfer when the contract is paused

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}