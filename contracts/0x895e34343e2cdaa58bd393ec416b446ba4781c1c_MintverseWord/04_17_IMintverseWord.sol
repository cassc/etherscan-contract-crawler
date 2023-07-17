// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWord.sol";

interface IMintverseWord is IWord {
    // Return true if the minter is eligible to claim the given amount word token with the signature.
    function verify(uint256 maxQuantity, bytes calldata SIGNATURE) external view returns(bool);
    // Changes the addon status of an address by owner.
    function mintGiveawayDictionary(address to, bool addon) external;
    // Mints tokens to an address with specific wordId by owner. 
    function mintGiveawayWord(address to, uint16 wordId, uint48 mintTimestamp) external;
    // Whitelisted addresses mint specific amount of tokens with signature & maximum mintable amount to verify.
    function mintWhitelistWord(uint256 quantity, uint256 maxClaimNum, bool addon, bytes calldata SIGNATURE) external payable;
    // Public addresses mint specific amount of tokens.
    function mintPublicWord(bool addon) external payable;
    // Word token owners send five parameters to define the word.
    function defineWord(uint256 tokenId, string calldata definer, uint8 partOfSpeech1, uint8 partOfSpeech2, string calldata relatedWord, string calldata description) external;

    // Add the wordId to the end of random word bank.
    function settleExpiredWord(uint256 startTokenId, uint256 endTokenId) external;

    // View function to get the metadata of a specific token with tokenId.
    function getTokenProperties(uint256 tokenId) external view returns(string memory definer, uint256 wordId, uint256 categoryId, uint256 partOfSpeechId1, uint256 partOfSpeechId2, string memory relatedWord, string memory description);
    // View function to get the expired timestamp of a specific token with tokenId.
    function getTokenExpirationTime(uint256 tokenId) external view returns(uint256 expirationTime);
    // View function to get the status(dead or alive) of a specific token with tokenId.
    function getTokenStatus(uint256 tokenId) external view returns(bool writtenOrNot);
    // View function to get all the metadatas of the word tokens of the given address.
    function getTokenPropertiesByOwner(address owner) external view returns(TokenInfo[] memory tokenInfos);
    // View function to get all the expired timestamps of the word tokens of the given address.
    function getTokenExpirationTimeByOwner(address owner) external view returns(uint256[] memory expirationTimes);
    // View function to get all the status(dead or alive) of the word tokens of the given address.
    function getTokenStatusByOwner(address owner) external view returns(bool[] memory writtenOrNot);
    // View function to check if the given address has purchased the addon dictionary.
    function getAddonStatusByOwner(address owner) external view returns(bool addon);
    // View function to get all the token Id that a address owns.
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
    // View function to get all the dictionary supply for dictionary contract.
    function getTotalDictionary() external view returns (uint256 amount);

    // Set the variables to enable the whitelist mint phase by owner.
    function setWLMintPhase(bool hasWLMintStarted, uint256 wlMintTimestamp) external;
    // Set the variables to enable the public mint phase by owner.
    function setPublicMintPhase(bool hasPublicMintStarted, uint256 publicMintTimestamp) external;

    // Set the price for minter to purchase addon dictionary.
    function setDictPrice(uint256 price) external;
    // Set the expiration time period of the token.
    function setExpirationTime(uint48 expirationPeriod) external;
    // Set the reveal timestamp to adjust tokens mint time.
    function setRevealTimestamp(uint48 newRevealTimestamp) external;
    // Set the categoryId of a specific token by tokenId.
    function setCategoryByTokenId(uint256 tokenId, uint8 categoryId) external;

    // **SYSTEM EMERGENCY CALLS**
    // Set the maximum supply of the random tokens by owner.
    function setMaxRandomWordTokenAmt(uint256 amount) external;
    // Set the maximum supply of the giveaway tokens by owner.
    function setMaxGiveawayWordTokenAmt(uint256 amount) external;
    // Set the maximum supply of the dictionary by owner.
    function setMaxDictAmt(uint256 amount) external;
    // Set the index for head of random word.
    function setHeadRandomWordId(uint16 index) external;
    // Set the index for tail of random word.
    function setTailRandomWordId(uint16 index) external;
    // Set the index for tail of random word.
    function setSettleHeadRandomWordId(uint16 index) external;
    // Set the offset of the designated word id.
    function setWordIdOffset(uint16 offsetAmount) external;

    // **TOKEN EMERGENCY CALLS**
    // Set the wordId of a specific token by tokenId.
    function setTokenWordIdByTokenId(uint256 tokenId, uint16 wordId) external;
    // Set the mint time of a specific token by tokenId.
    function setTokenMintTimeByTokenId(uint256 tokenId, uint48 mintTimestamp) external;
    // Set the defined status of a specific token by tokenId.
    function setTokenDefineStatusByTokenId(uint256 tokenId, bool definedOrNot) external;

    // Set the URI to return the tokens metadata.
    function setBaseTokenURI(string calldata newBaseTokenURI) external;
    // Set the URI for the legal document.
    function setLegalDocumentURI(string calldata newLegalDocumentURI) external;
    // Set the URI for the system mechanism document.
    function setSystemMechanismDocumentURI(string calldata newSystemMechanismDocumentURI) external;
    // Set the URI for the animation code document.
    function setAnimationCodeDocumentURI(string calldata newAnimationCodeDocumentURI) external;
    // Set the URI for the visual rebuild method document.
    function setVisualRebuildDocumentURI(string calldata newVisualRebuildDocumentURI) external;
    // Set the URI for the erc721 technical document.
    function setERC721ATechinalDocumentURI(string calldata newERC721ATechinalDocumentURI) external;
    // Set the URI for the wordId mapping document.
    function setWordIdMappingDocumnetURI(string calldata newWordIdMappingDocumnetURI) external;
    // Set the URI for the partOfSpeechId mapping document.
    function setPartOfSpeechIdMappingDocumentURI(string calldata newPartOfSpeechIdMappingDocumentURI) external;
    // Set the URI for the categoryId mapping document.
    function setCategoryIdMappingDocumentURI(string calldata newCategoryIdMappingDocumentURI) external;
    // Set the URI for the metadata mapping document.
    function setMetadataMappingDocumentURI(string calldata newMetadataMappingDocumentURI) external;
    // Set the address to transfer the contract fund to.
    function setTreasury(address treasury) external;
    // Withdraw all the fund inside the contract to the treasury address.
    function withdrawAll() external payable;
    // This event is triggered whenever a call to #mintGiveawayWord, #mintWhitelistWord, and #mintPublicWord succeeds.
    event mintWordEvent(address owner, uint256 quantity, uint256 totalSupply);
    // This event is triggered whenever a call to #defineWord succeeds.
    event wordDefinedEvent(uint256 tokenId);
    // This event is triggered whenever a call to #settleExpiredWord succeeds.
    event moveWordToTheBack(uint256 oriWordId, uint256 newWordId);
}