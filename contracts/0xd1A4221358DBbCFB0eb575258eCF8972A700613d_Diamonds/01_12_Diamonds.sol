// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Diamonds is Ownable, ERC721 {
    using Strings for uint256;
    using Address for address payable;

    uint256 constant private _SUPPLY = 200;
    uint256 constant private _MINT_PRICE = 1 ether;
    uint256 constant private _MINT_PERIOD = 2 days;

    uint256 constant private _ROYALTY_PCT = 5;

    uint256 constant private ENTROPY_HEIGHT_DIFF = 5;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bytes32 immutable private _merkleRoot;

    uint256 private _nextTokenId;
    string private _URI;

    bytes32 private _baseEntropy;

    uint256 public saleStart;
    bytes32 public shuffleProof;

    bool public revealed;
    bool public freezed;

    mapping(address => bool) public claimed;

    modifier noContract() {
        require(!Address.isContract(_msgSender()));
        _;
        // solhint-disable-next-line not-rely-on-time
        _baseEntropy = keccak256(abi.encodePacked(_baseEntropy, _msgSender(), block.timestamp));
    }

    constructor(bytes32 merkleRoot, address owner, uint256 timestamp, bytes32 proof, string memory uri) ERC721("Tribe Diamonds", "TRIBE DMNDS") {
        _merkleRoot = merkleRoot;
        transferOwnership(owner);
        saleStart = timestamp;
        shuffleProof = proof;
        _URI = uri;
        _baseEntropy = keccak256(abi.encodePacked(
                                                  block.coinbase,
                                                  // solhint-disable-next-line not-rely-on-time
                                                  block.timestamp,
                                                  block.difficulty,
                                                  blockhash(block.number - 1)
                                                  ));
     }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || ERC721.supportsInterface(interfaceId);
    }

    function updateSale(uint256 timestamp, string calldata uri) external onlyOwner() {
        require(block.timestamp < saleStart + _MINT_PERIOD, 'sale ended');
        saleStart = timestamp;
        _URI = uri;
    }

    function withdraw() external onlyOwner() {
        payable(owner()).sendValue(address(this).balance);
    }

    function royaltyInfo(uint256 /* tokenId*/, uint256 salePrice) external view
        returns (address receiver, uint256 royaltyAmount) {
        return (owner(), salePrice * _ROYALTY_PCT / 100);
    }

    event Mint(uint256 indexed tokenId, bytes32 tokenSeed, uint256 chainEntropyBlock);

    function mint(bytes32[] calldata merkleProof) external payable noContract() {
        require(_nextTokenId < _SUPPLY, 'no more supply');
        require(block.timestamp > saleStart, 'sale not started');
        require(block.timestamp < saleStart + _MINT_PERIOD, 'sale ended');

        require(!claimed[_msgSender()], 'already minted');
        require(isWhitelisted(_msgSender(), merkleProof), 'not allowed');

        require(msg.value >= _MINT_PRICE,'not enough');

        claimed[_msgSender()] = true;
        _nextTokenId++;

        _mint(_msgSender(), _nextTokenId);
        _baseEntropy = keccak256(abi.encodePacked(_baseEntropy, merkleProof[0]));
        emit Mint(_nextTokenId, _baseEntropy, block.number + ENTROPY_HEIGHT_DIFF);
    }

    function mint3(uint16 count) external onlyOwner() {
        require(block.timestamp < saleStart + _MINT_PERIOD, 'sale ended');
        for (uint16 i = 0; i < count; i++) {
            require(_nextTokenId < _SUPPLY, 'no more supply');
            _nextTokenId++;
            _mint(_msgSender(), _nextTokenId);
            _baseEntropy = keccak256(abi.encodePacked(_baseEntropy, i));
            emit Mint(_nextTokenId, _baseEntropy, block.number + ENTROPY_HEIGHT_DIFF);
        }
    }

    function reveal(bytes32 shuffleSeed, string calldata uri) external onlyOwner() {
        require(keccak256(abi.encodePacked(shuffleSeed)) == shuffleProof);
        require(!freezed, 'already freezed');
        _URI = uri;
        revealed = true;
    }

    function freeze() external onlyOwner() {
        require(revealed, 'not revealed');
        require(!freezed, 'already freezed');
        freezed = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed) return string(abi.encodePacked(_URI, "/", tokenId.toString(), ".json"));
        return _URI;
    }

    function isWhitelisted(address account, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, _merkleRoot, keccak256(abi.encodePacked(account)));
    }

}