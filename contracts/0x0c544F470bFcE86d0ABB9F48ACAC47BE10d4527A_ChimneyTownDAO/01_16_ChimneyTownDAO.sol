// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./base/ERC721Checkpointable.sol";
import "./interfaces/iChimneyTownDAO.sol";

contract ChimneyTownDAO is iChimneyTownDAO, ERC721Checkpointable, Ownable {

    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private _nextReserveId = 9900;
    uint256 private _remainingReserved = 100;
    uint256 private _remainingForSale = 9900;
    uint256 private _priceInWei;
    uint256[] private _mintedTokenIdList;
    string private __baseURI;
    bool private _isOnSale;
    bool private _isMetadataFrozen;
    bytes32 private _merkleRoot;
    mapping(address => bool) private _claimMap;

    constructor(string memory baseURI) ERC721("CHIMNEY TOWN DAO", "CTD") {
        __baseURI = baseURI;
    }

    modifier onSale() {
        require(_isOnSale, "ChimneyTownDAO: Not on sale");
        _;
    }

    //******************************
    // view functions
    //******************************
    function remainingForSale() public view override returns (uint256) {
        return _remainingForSale;
    }

    function remainingReserved() public view override returns (uint256) {
        return _remainingReserved;
    }

    function priceInWei() public view override returns (uint256) {
        return _priceInWei;
    }

    function isOnSale() public view override returns (bool) {
        return _isOnSale;
    }

    function merkleRoot() public view override returns (bytes32) {
        return _merkleRoot;
    }

    function isClaimed(address account) external view override returns (bool) {
        return _claimMap[account];
    }

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external override view returns (uint256[] memory) {

        uint256 minted = _mintedTokenIdList.length;

        if (minted == 0) {
            return _mintedTokenIdList;
        }
        if (minted < offset) {
            return new uint256[](0);
        }

        uint256 length = limit;
        if (minted < offset + limit) {
            length = minted - offset;
        }
        uint256[] memory list = new uint256[](length);
        for (uint256 i = offset; i < offset + limit; i++) {
            if (_mintedTokenIdList.length <= i) {
                break;
            }
            list[i - offset] = _mintedTokenIdList[i];
        }

        return list;
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ChimneyTownDAO: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    //******************************
    // public functions
    //******************************
    function mint(uint256 tokenId) external override payable onSale {
        require(msg.value == _priceInWei, "ChimneyTownDAO: Invalid price");
        require(tokenId < _nextReserveId, "ChimneyTownDAO: Invalid token id");
        _mintedTokenIdList.push(tokenId);
        _remainingForSale--; 
        _safeMint(msg.sender, tokenId);
    }

    function mintBatch(uint256[] memory tokenIdList) external override payable onSale {
        uint256 quantity = tokenIdList.length;
        require(msg.value == _priceInWei * quantity, "ChimneyTownDAO: Invalid price");
        _remainingForSale -= quantity;

        for (uint256 i; i < quantity; i++) {
            require(tokenIdList[i] < _nextReserveId, "ChimneyTownDAO: Invalid token id");
            _mintedTokenIdList.push(tokenIdList[i]);
            _safeMint(msg.sender, tokenIdList[i]);
        }
    }

    function claim(uint256 tokenId, bytes32[] calldata merkleProof) external override payable {
        require(_merkleRoot != "", "ChimneyTownDAO: No merkle root");
        require(!_claimMap[msg.sender], "ChimneyTownDAO: Account minted token already");
        require(tokenId < _nextReserveId, "ChimneyTownDAO: Invalid token id");
        require(MerkleProof.verify(merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ChimneyTownDAO: Can not verify");

        _mintedTokenIdList.push(tokenId);
        _remainingForSale--;
        _claimMap[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
    }

    //******************************
    // admin functions
    //******************************
    function updateBaseURI(string calldata newBaseURI) external override onlyOwner {
        require(!_isMetadataFrozen, "ChimneyTownDAO: Metadata is frozen");
        __baseURI = newBaseURI;
    }

    function freezeMetadata() external override onlyOwner {
        _isMetadataFrozen = true;
    }

    function mintReserve(uint256 quantity, address to) external override onlyOwner {
        _remainingReserved -= quantity;
        for (uint256 i = _nextReserveId; i < _nextReserveId + quantity; i++) {
            _safeMint(to, i);
        }
        _nextReserveId += quantity;
    }

    function setMerkleRoot(bytes32 __merkleRoot) external override onlyOwner {
        _merkleRoot = __merkleRoot;
    }

    function setPrice(uint256 __priceInWei) external override onlyOwner {
        _priceInWei = __priceInWei;
    }

    function setSaleStatus(bool __isOnSale) public override onlyOwner {
        require(_priceInWei != 0, "ChimneyTownDAO: Price is not set yet");
        _isOnSale = __isOnSale;
    }

    function withdraw(address payable to, uint256 amountInWei) external override onlyOwner {
        Address.sendValue(to, amountInWei);
    }

    receive() external payable {}

}