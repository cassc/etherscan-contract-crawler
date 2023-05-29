//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NenToken is ERC721Enumerable, Ownable {
    // NenSeller Contract Address
    address public minter;

    address public validator;

    // ERC721 token baseURI
    string public baseURI;

    // TokenID tracker
    uint256 public tokenIdCounter;

    uint256 public answerMaxLength;
    uint256 public creditMaxLength;

    // The token's metadata
    mapping(uint256 => Metadata) public metadatas;

    // Whether answer can be updated
    mapping(uint256 => bool) public isAnswerLocked;

    struct Metadata {
        string answer;
        string credit;
        Attribute attribute;
    }

    struct Request {
        uint256 tokenId;
        Attribute attribute;
    }

    struct Attribute {
        bytes32 questionCategory;
        string question;
        bytes32 attributeSkinTone;
        bytes32 attributeHairFront;
        bytes32 attributeHairBack;
        bytes32 attributeEar;
        bytes32 attributeEyes;
        bytes32 attributeClothing;
        bytes32 attributeDna;
        bytes32 attributeFace;
        bytes32 attributeNeck;
        bytes32 attributeMouth;
        bytes32 attributeSpecial;
    }

    event Minted(uint256 indexed tokenId, address owner, uint256 mintedCount);
    event AttributeSet(uint256 indexed tokenId, Attribute attribute);
    event AnswerUpdated(uint256 indexed tokenId, address owner, string answer, string credit);
    event MinterUpdated(address minter);
    event BaseUriUpdated(string baseUri);
    event AnswerLockedStatusUpdated(uint256 indexed tokenId, bool locked);

    modifier onlyMinter {
        require(msg.sender == minter, "NenToken: sender != minter");
        _;
    }

    constructor(
        string memory _firstBaseURI,
        address _validator
    ) ERC721("Nen", "NEN") {
        baseURI = _firstBaseURI;
        validator = _validator;
        answerMaxLength = 20;
        creditMaxLength = 100;
    }

    // mint with Metadata by minter
    function mint(address ownerAddress, uint256 mintedCount) external onlyMinter {
        _safeMint(ownerAddress, ++tokenIdCounter);
        emit Minted(tokenIdCounter, ownerAddress, mintedCount);
    }

    function _updateAnswer(uint256 tokenId, string calldata answer, string calldata credit) internal {
        // only token owner can update answer
        require(msg.sender == ownerOf(tokenId), "NenToken: sender != token owner");

        // only not locked answer can be updated
        require(!isAnswerLocked[tokenId], "NenToken: answer is locked");

        // validate answer length
        uint256 answerLength = bytes(answer).length;
        require(0 < answerLength && answerLength <= answerMaxLength, "NenToken: answer is out of range");

        // validate credit length
        uint256 creditLength = bytes(credit).length;
        require(0 < creditLength && creditLength <= creditMaxLength, "NenToken: credit is out of range");

        metadatas[tokenId].answer = answer;
        metadatas[tokenId].credit = credit;

        isAnswerLocked[tokenId] = true;

        emit AnswerUpdated(tokenId, msg.sender, answer, credit);
        emit AnswerLockedStatusUpdated(tokenId, isAnswerLocked[tokenId]);
    }

    function updateAnswerWithAttribute(string calldata answer, string calldata credit, Request calldata request, uint8 v, bytes32 r, bytes32 s) external {
        // check correct validator
        require(ecrecover(toEthSignedMessageHash(prepareMessage(request)), v, r, s) == validator, "NenToken: invalid signature");

        require(!isAttributeSet(request.tokenId), "NenToken: attribute already set");
        metadatas[request.tokenId].attribute = request.attribute;

        emit AttributeSet(request.tokenId, request.attribute);

        _updateAnswer(request.tokenId, answer, credit);
    }

    // update answer and lock it
    function updateAnswer(uint256 tokenId, string calldata answer, string calldata credit) external {
        require(isAttributeSet(tokenId), "NenToken: attribute not set");
        _updateAnswer(tokenId, answer, credit);
    }

    // when transfer, answer is unlocked
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (isAnswerLocked[tokenId]) {
            isAnswerLocked[tokenId] = false;
            emit AnswerLockedStatusUpdated(tokenId, isAnswerLocked[tokenId]);
        }
    }

    function isAttributeSet(uint256 tokenId) internal view returns(bool) {
        return bytes(metadatas[tokenId].attribute.question).length != 0;
    }

    // override _baseURI() for tokenURI
    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function prepareMessage(Request calldata request) internal pure returns (bytes32) {
        return keccak256(abi.encode(request));
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    function updateBaseUri(string calldata _baseUri) external onlyOwner {
        baseURI = _baseUri;

        emit BaseUriUpdated(_baseUri);
    }

    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
    }

    function setAnswerMaxLength(uint256 _answerMaxLength) external onlyOwner {
        answerMaxLength = _answerMaxLength;
    }

    function setCreditMaxLength(uint256 _creditMaxlength) external onlyOwner {
        creditMaxLength = _creditMaxlength;
    }
}