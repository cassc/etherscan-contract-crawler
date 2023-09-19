// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/IKreyptNFT.sol";

contract KreyptPianoLong is ERC721A, ERC2981, AccessControl, IKreyptNFT {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public owner;
    string public cgu = "ipfs://QmedgDRPE1g5czfHrkxv6PWEVR5tiSRSygnzvMRvZdWGM3";
    uint96 public creatorFees = 400; // 400 = 4%

    // Bytes32 Sentence => Sentence
    mapping(bytes32 => string) public sentence;
    // Bytes32 Clear Sentence => Sentence Cleared by the Kreypt Algo
    mapping(bytes32 => string) public clearSentence;
    // TokenId => Sentence
    mapping(uint256 => string) public sentenceByTokenId;
    // TokenId => TokenURI
    mapping(uint256 => string) private _tokenURIs;


    constructor(address _minter, address _creator) ERC721A("Kreypt Music - Piano", "KMPI") {
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, _minter);
        _setDefaultRoyalty(_creator, creatorFees);
    }

    /*
        @notice Mint a batch of tokens
        @param owners : The owners of the tokens
        @param sentences : The sentences of the tokens
        @param clearSentences : The sentence cleared by the Kreypt Algo of the tokens
        @param tokenUris : The token uris of the tokens
    */
    function mintBatch(
        address[] memory fors,
        string[] memory sentences,
        string[] memory clearSentences,
        string[] memory tokenUris
    ) public override {
        require(hasRole(MINTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "KreyptPianoLong: don't have the right role (MINTER_ROLE or DEFAULT_ADMIN_ROLE))");
        require(fors.length == sentences.length && sentences.length == clearSentences.length && clearSentences.length == tokenUris.length, "KreyptPianoLong: invalid parameters");
        for (uint256 i = 0; i < fors.length; i++) {
            mint(fors[i], sentences[i], clearSentences[i], tokenUris[i]);
        }
    }

    /*
        @notice Mint a token
        @param _for The owner of the token
        @param _sentence The sentence of the token
        @param _clearSentence : The sentence cleared by the Kreypt Algo of the token
        @param tokenUri : The token uri of the token
    */
    function mint(
        address _for,
        string memory _sentence,
        string memory _clearSentence,
        string memory tokenUri
    ) public override returns (uint256){
        require(hasRole(MINTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "KreyptPianoLong: don't have the right role (MINTER_ROLE or DEFAULT_ADMIN_ROLE))");
        useASentence(_sentence, _clearSentence);
        uint256 tokenId = _nextTokenId();
        _safeMint(_for, 1);
        _tokenURIs[tokenId] = tokenUri;

        return tokenId;
    }

    /*
        @notice Check if a sentence and a clear sentence is available
        @param _sentenceBytes32 : The sentence hashed with keccak256
        @param _clearSentenceBytes32 : The sentence cleared by the Kreypt Algo hashed with keccak256
        @return bool : True if the sentence and the clear sentence are available, false otherwise
    */
    function isSentenceAvailable(
        bytes32 _sentenceBytes32,
        bytes32 _clearSentenceBytes32
    ) public view override returns (bool) {
        return (bytes(sentence[_sentenceBytes32]).length == 0 && bytes(clearSentence[_clearSentenceBytes32]).length == 0);
    }

    /*
        @notice Use and block a sentence and a clear sentence
        @param _sentence : The sentence
        @param _clearSentence : The sentence cleared by the Kreypt Algo
    */
    function useASentence(string memory _sentence, string memory _clearSentence) internal {
        bytes32 _sentenceBytes32 = keccak256(abi.encodePacked(_sentence));
        bytes32 _clearSentenceBytes32 = keccak256(abi.encodePacked(_clearSentence));
        require(isSentenceAvailable(_sentenceBytes32, _clearSentenceBytes32), "KreyptPianoLong: sentence already used");
        sentenceByTokenId[totalSupply()] = _sentence;
        sentence[_sentenceBytes32] = _sentence;
        clearSentence[_clearSentenceBytes32] = _clearSentence;
    }

    /*
        @notice Update all the royalties
        @param creator: The address where to send creator fees (can be a wallet or a contract)
        @param feeNumerator : The fee numerator of the royalties (0 = 0%, 10000 = 100%)
    */
    function updateRoyalties(address creator, uint96 feeNumerator) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(creator, feeNumerator);
    }

    /*
        @notice Update a specific token royalties
        @param _tokenId : The token id
        @param creator: The address where to send creator fees (can be a wallet or a contract)
        @param feeNumerator : The fee numerator of the royalties (0 = 0%, 10000 = 100%)
    */
    function updateTokenRoyalties(uint256 _tokenId, address creator, uint96 feeNumerator) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, creator, feeNumerator);
    }

    /*
        @notice Update the token uri, used for example when the token is finalized
        @param tokenId : The token id
        @param _tokenURI : The token uri
    */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external virtual override {
        require(hasRole(MINTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "KreyptPianoLong: don't have the right role (MINTER_ROLE or DEFAULT_ADMIN_ROLE))");
        require(_exists(tokenId), "KreyptPianoLong: URI set for nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId); // To be compatible with the EIP-4906 : https://docs.opensea.io/docs/metadata-standards
        emit TokenURIUpdate(tokenId, _tokenURI);
    }

    /*
        @notice Get the token uri
        @param tokenId : The token id
    */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IKreyptNFT) returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /*
        @dev Transfert smart contract ownership
        @param newAddress : New owner address
    */
    function transferOwnership(address newAddress) override(IKreyptNFT) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAddress != address(0), "Invalid Address");
        _revokeRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(DEFAULT_ADMIN_ROLE, newAddress);
        owner = newAddress;
    }

    /*
        @dev Update smart contract CGU
        @param newAddress : New CGU
    */
    function updateCgu(string memory newCgu) override(IKreyptNFT) public onlyRole(DEFAULT_ADMIN_ROLE) {
        cgu = newCgu;
        emit CguUpdate(newCgu);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

}