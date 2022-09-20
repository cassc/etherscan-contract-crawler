// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/ISxTCommunity.sol";

contract SxTCommunity is ISxTCommunity, SxTCommunityStorage, ERC1155, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // Counter for maintaining TokenIDs
    Counters.Counter public currentTokenIndex;
    
    /// @dev This is the constructor function to initialize the contract.
    /// @param tokenName Name of the ERC1155 token
    /// @param tokenSymbol Symbol of the ERC1155 token

    constructor(string memory tokenName, string memory tokenSymbol) ERC1155("") {
        require(!compareStrings(tokenName, ""), "SxTCommunity: Token name cannot be an empty string");
        require(!compareStrings(tokenSymbol, ""), "SxTCommunity: Token symbol cannot be an empty string");
        name = tokenName;
        symbol = tokenSymbol;
    }

    /// @dev This is the function to get the URI for an NFT token 
    /// @param id ID of NFT token for which URI needs to be fetched 
    /// @return tokenUri URI of the NFT with required id

    function uri(uint id) public view override returns (string memory) {
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunity: URI nonexistent token");
        return tokenDetails[id].tokenUri;
    }

    /// @dev This is the function to get the list of available or sold-out NFTs in a paginated JSON string response  
    /// @param pageNumber Page number of the response required
    /// @param pageSize Size of each page of response required
    /// @param isAvailable Category of NFTs to get, true for available to mint NFTs, and false for sold out NFTs 
    /// @return nftsResponseJSON Stringified JSON response having the list of NFT details according to page number, page size, isAvailable( Available for mint or sold-out) 
    /// @return allAcceptableNFTsCount Count of all available or sold-out ( depending on isAvailable param passed) NFTs that the contract has

    function retrieveNFTs(uint256 pageNumber, uint256 pageSize, bool isAvailable) external override view returns(string memory, uint256) {
        string memory nftsResponseJSON = "[]";
        uint256 allAcceptableNFTsCount = 0;
        Token [] memory resultTokens = new Token[](pageSize);
        Token [] memory allAcceptableTokens = new Token[](currentTokenIndex.current());
        for ( uint256 i = currentTokenIndex.current(); i > 0; i--){
            if(isAvailable != checkMaxSupplyReached(i)){
                Token storage tokenTemp = tokenDetails[i];
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
        }
        nftsResponseJSON = getJSONResponse(resultTokens);
        return (nftsResponseJSON, allAcceptableNFTsCount);
    }
    
    /// @dev This is the function to set the price in ethers for an NFT token 
    /// @dev Only the owner can call this function
    /// @param id ID of NFT token for which token price needs to be updated
    /// @param newTokenEthPrice New price in ethers for the NFT token

    function setTokenEthPrice(uint256 id, uint256 newTokenEthPrice) external override onlyOwner  {
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunity: URI nonexistent token");
        require(tokenDetails[id].ethPrice != newTokenEthPrice, "SxTCommunity: New price same as old price");
        require(newTokenEthPrice > 0, "SxTCommunity: New price cannot be zero");
        Token storage token = tokenDetails[id];
        token.hasPrice = true;
        token.ethPrice= newTokenEthPrice;
        emit TokenEthPriceSet(id, token.ethPrice);
    }

    /// @dev This is the function to set the price in ERC20 tokens for an NFT token 
    /// @dev Only the owner can call this function
    /// @param id ID of NFT token for which token price needs to be updated
    /// @param newTokenERC20Price New price in ERC20 tokens for the NFT token

    function setTokenERC20Price(uint256 id, uint256 newTokenERC20Price) external override onlyOwner  {
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunity: URI nonexistent token");
        require(tokenDetails[id].erc20Price != newTokenERC20Price, "SxTCommunity: New price same as old price");
        require(newTokenERC20Price > 0, "SxTCommunity: New price cannot be zero");
        Token storage token = tokenDetails[id];
        token.hasPrice = true;
        token.erc20Price= newTokenERC20Price;
        emit TokenERC20PriceSet(id, token.erc20Price);
    }

    /// @dev This is the function to reset the prices for an NFT token 
    /// @dev Only the owner can call this function
    /// @param id ID of NFT token for which token prices need to be updated

    function resetTokenPrices(uint256 id) external override onlyOwner  {
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunity: URI nonexistent token");
        require(tokenDetails[id].hasPrice, "SxTCommunity: This token is already available for free");
        Token storage token = tokenDetails[id];
        token.hasPrice = false;
        token.erc20Price = 0;
        token.ethPrice = 0;
        emit TokenPriceReset(id);
    }
    
    /// @dev This is the function to set the ERC20 token for accepting price of NFTs 
    /// @dev Only the owner can call this function
    /// @param newSxtToken Address of the particular ERC20 token, for accepting price of NFTs in ERC20 tokens

    function setERC20Token(IERC20 newSxtToken) external override onlyOwner  {
        require(address(newSxtToken) != ZERO_ADDRESS, "SxTCommunity: Address Cannot be Zero Address");
        require(keccak256(abi.encodePacked(newSxtToken)) != keccak256(abi.encodePacked(sxtToken)), "SxTCommunity: Current token is already what you have selected");
        sxtToken = newSxtToken;
        emit Erc20TokenSet(newSxtToken);
    }

    /// @dev This is the function to mint a new NFT token which is available free of cost
    /// @dev Only called when contract is unpaused
    /// @param id ID of NFT token to be bought
    /// @param to Address to which NFT token should be minted to

    function mintNFT(uint256 id, address to) external override whenNotPaused nonReentrant{   
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunity: URI nonexistent token");    
        require(!tokenDetails[id].hasPrice, "SxTCommunity: This token is not free");
        require(!checkMaxSupplyReached(id), "SxTCommunity: Total supply exceeded maximum supply");
        require(!isPreviouslyMintedFrom[id][to], "SxTCommunity: Already minted this NFT once to this account");
        isPreviouslyMintedFrom[id][to] = true;
        Token storage currentToken = tokenDetails[id];
        currentToken.currentTokenSupply += 1;
        _mint(to, id, AMOUNT_BUYABLE, "");
        emit NftMinted(id, to);
    }

    /// @dev This is the function to mint a new NFT token by depositing Ethers
    /// @dev Only called when contract is unpaused
    /// @dev If Token is buyable with Ether and ethPrice > 0, function will accept ethers
    /// @param id ID of NFT token to be bought
    /// @param to Address to which NFT token should be minted to

    function mintNFTUsingEth(uint256 id, address to) external override payable whenNotPaused nonReentrant{
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunity: URI nonexistent token");  
        require(tokenDetails[id].hasPrice && tokenDetails[id].ethPrice > 0, "SxTCommunity: Token Eth Price not yet set");     
        require(!checkMaxSupplyReached(id), "SxTCommunity: Total supply exceeded maximum supply");
        require(!isPreviouslyMintedFrom[id][to], "SxTCommunity: Already minted this NFT once to this account");
        require(msg.value >= tokenDetails[id].ethPrice, "SxTCommunity: Insufficient Ethers sent");
        isPreviouslyMintedFrom[id][to] = true;
        Token storage currentToken = tokenDetails[id];
        currentToken.currentTokenSupply += 1;
        _mint(to, id, AMOUNT_BUYABLE, "");
        emit NftMintedUsingEth(id, to, tokenDetails[id].ethPrice );
    }

    /// @dev This is the function to mint a new NFT token by depositing ERC20 Token
    /// @dev Only called when contract is unpaused
    /// @dev If Token is buyable with ERC20 token and erc20Price > 0, function will transfer ERC20 tokens to contract
    /// @param id ID of NFT token to be bought
    /// @param to Address to which NFT token should be minted to

    function mintNFTUsingERC20(uint256 id, address to) external override whenNotPaused nonReentrant{
        require(address(sxtToken) != ZERO_ADDRESS, "SxTCommunity: ERC20 Token not yet set by owner");
        require(!compareStrings(tokenDetails[id].tokenUri, ""), "SxTCommunity: URI nonexistent token");
        require(tokenDetails[id].hasPrice && tokenDetails[id].erc20Price > 0, "SxTCommunity: Token ERC20 Price not yet set");     
        require(!checkMaxSupplyReached(id), "SxTCommunity: Total supply exceeded maximum supply");
        require(!isPreviouslyMintedFrom[id][to], "SxTCommunity: Already minted this NFT once to this account");
        require(sxtToken.balanceOf(msg.sender) >= tokenDetails[id].erc20Price, "SxTCommunity: Insufficient ERC20 token balance");
        isPreviouslyMintedFrom[id][to] = true;
        bool sent = sxtToken.transferFrom(msg.sender, address(this), tokenDetails[id].erc20Price);
        require(sent, "SxTCommunity: Failed to send ERC20Token");
        Token storage currentToken = tokenDetails[id];
        currentToken.currentTokenSupply += 1;
        _mint(to, id, AMOUNT_BUYABLE, "");
        emit NftMintedUsingERC20(id, to, tokenDetails[id].erc20Price);
    }

    /// @dev This is the function to add new NFT tokens in the contract
    /// @dev Only the owner can call this function
    /// @param newTokenURIs Array of URIs for NFTs to be added
    /// @param hasPrices Array of boolean flags representing whether the NFT token has any price or not
    /// @param newEthPrices Array of prices in Ethers for NFTs to be added
    /// @param newERC20Prices Array of prices in ERC20 Tokens for NFTs to be added
    /// @param maxNewTokenSupplies Array of maximum possible supplies for NFTs to be added

    function addNewNFTs(string [] memory newTokenURIs, bool [] memory hasPrices, uint256 [] memory newEthPrices, uint256 [] memory newERC20Prices, uint256 [] memory maxNewTokenSupplies) external override onlyOwner {
        require(newTokenURIs.length == maxNewTokenSupplies.length && maxNewTokenSupplies.length == hasPrices.length && hasPrices.length == newEthPrices.length && newEthPrices.length == newERC20Prices.length, "SxTCommunity: Array lengths should be same");
        for(uint256 index = 0; index < maxNewTokenSupplies.length; index++){
            Token memory newToken;
            require(maxNewTokenSupplies[index] > 0, "SxTCommunity: Maximum supply cannot be 0");
            require(!compareStrings(newTokenURIs[index], ""), "SxTCommunity: URI cannot be empty string");
            currentTokenIndex.increment();
            uint256 newTokenIndex = currentTokenIndex.current();
            newToken.id = newTokenIndex;
            newToken.tokenUri = newTokenURIs[index];
            newToken.maxTokenSupply = maxNewTokenSupplies[index];
            newToken.hasPrice = hasPrices[index];
            if(hasPrices[index]) {
                require(newEthPrices[index] > 0 || newERC20Prices[index] > 0, "SxTCommunity: Both prices cannot be 0 since NFT hasPrice is true");
                newToken.ethPrice = newEthPrices[index];
                newToken.erc20Price = newERC20Prices[index];
            }
            tokenDetails[newTokenIndex] = newToken;
            emit NewNFTAdded(newTokenIndex);
        }
    }

    /// @dev This is the internal function to check if maximum supply reached for an NFT
    /// @dev This is called inside mintNFT, mintNFTUsingEth, mintNFTUsingERC20 functions
    /// @param id ID of NFT token to be checked

    function checkMaxSupplyReached(uint256 id) view internal returns(bool){
        if(tokenDetails[id].currentTokenSupply < tokenDetails[id].maxTokenSupply)
            return false;
        return true;
    }

    /// @dev This is the internal function to compare 2 strings
    /// @param s1 First string for comparing value
    /// @param s2 Second string for comparing value

    function compareStrings(string memory s1, string memory s2) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2)));
    }

    /// @dev This is the function to withdraw ethers from contract
    /// @dev Only the owner can call this function

    function withdrawEth() external override onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        address payable to = payable(msg.sender);
        require(amount > 0, "SxTCommunity: Zero ether balance");
        to.transfer(amount);
        emit EtherWithdrawn( amount, to);        
    }

    /// @dev This is the function to withdraw ERC20 Tokens from contract
    /// @dev Only the owner can call this function    

    function withdrawERC20() external override onlyOwner nonReentrant {
        uint256 amount = sxtToken.balanceOf(address(this));
        address to = msg.sender;
        require(amount > 0, "SxTCommunity: Zero ERC20 token balance");
        bool sent = sxtToken.transfer(to, amount);
        require(sent, "Failed to send ERC20Token");
        emit Erc20TokenWithdrawn(amount, to);
    }

    /// @dev This is the function to pause the contract

    function pause() external override onlyOwner {
        _pause();
    }

    /// @dev This is the function to unpause the contract

    function unpause() external override onlyOwner {
        _unpause();
    }
}