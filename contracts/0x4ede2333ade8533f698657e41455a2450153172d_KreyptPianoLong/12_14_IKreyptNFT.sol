// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IKreyptNFT {
    function mint(address _for, string memory _sentence, string memory _clearSentence, string memory tokenUri) external returns (uint256);

    function mintBatch(address[] memory owners, string[] memory sentences, string[] memory clearSentences, string[] memory tokenUris) external;

    function isSentenceAvailable(bytes32 _sentenceBytes32, bytes32 _clearSentenceBytes32) external view returns (bool);

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function updateTokenRoyalties(uint256 _tokenId, address creator, uint96 feeNumerator) external;

    function updateRoyalties(address creator, uint96 feeNumerator) external;

    function transferOwnership(address newAddress) external;

    function updateCgu(string memory newCgu) external;

    // Events

    event TokenURIUpdate(uint256 tokenId, string tokenURI);

    event MetadataUpdate(uint256 tokenId);

    event CguUpdate(string cgu);
}