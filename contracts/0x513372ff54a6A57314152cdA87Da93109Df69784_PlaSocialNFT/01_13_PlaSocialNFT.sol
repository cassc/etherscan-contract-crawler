// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./CollectionAndSocial.sol";

contract PlaSocialNFT is ERC721, Ownable, CollectionAndSocial {
    using SafeMath for uint256;
    using Strings for uint256;

    // Mapping from collection to minter
    mapping(string => address) public _collectionMinter;
    // Mapping from tokenId to collection
    mapping(uint256 => string) public _collectionForTokenId;
    // Mapping from tokenId to tokenURI
    mapping(uint256 => string) private _tokenURIs;

    // Current token total supply
    uint256 public _totalSupply;

    // Current token mint fee
    uint256 public _mintFee = 0;

    // Set a number what can batch mint max
    uint256 public _maxBatches = 200;

    // Base uri
    string public _baseUri;

    // Set a delat time when owner want to withdraw
    uint256 public _delayWithdrawTime = 1 days;

    // Set a time when owner want to withdraw
    uint256 public _relayWithdrawTime = 0;

    // Set white Address who can mint to others
    address public _whiteAddress;

    event SetBaseURI(address owner, string baseURI);
    event SetTokenURI(uint256 tokenId, string tokenURI);
    event RelayWithdraw(address owner, uint256 relayTime);
    event Withdraw(address owner, uint256 value);
    event UpdateMintFee(uint256 oldFee, uint256 newFee);
    event DoUpdateGroupIdCount(uint256 oldUpdateGroupIdCount, uint256 newUpdateGroupIdCount);

    /**
     * @dev Throws if tokenId not exists.
     */
    modifier exists(uint256 tokenId) {
        require(_exists(tokenId), "PlaNFT: token nonexistent");
        _;
    }

    /**
     * @dev Throws if mintMount bigger than _maxBatches.
     */
    modifier moderate(uint256 amount) {
        require(amount <= _maxBatches, "PlaNFT: mint amount flowover");
        _;
    }

    /**
     * @dev Throws if tx caller not equals _whiteAddress.
     */
    modifier whiteAddrValid() {
        require(msg.sender == _whiteAddress, "PlaNFT: not white address");
        _;
    }

    constructor(
        address whiteAddress_,
        string memory name_,
        string memory symbol_,
        bool socialTypeOptional
    ) ERC721(name_, symbol_) CollectionAndSocial(socialTypeOptional) {
        _whiteAddress = whiteAddress_;
    }

    /**
     * @dev update mint fee
     *
     * @param newMintFee new mint fee
     */
    function _updateMintFee(uint256 newMintFee) public onlyOwner {
        emit UpdateMintFee(_mintFee, newMintFee);
        _mintFee = newMintFee;
    }

    /**
     * @dev update count for updateGroupIdCount
     *
     * @param newUpdateGroupIdCount new updateGroupIdCount
     */
    function _doUpdateGroupIdCount(uint256 newUpdateGroupIdCount) public onlyOwner {
        emit DoUpdateGroupIdCount(_updateGroupIdCount, newUpdateGroupIdCount);
        _updateGroupIdCount = newUpdateGroupIdCount;
    }

    /**
     * @dev update maxMatches
     *
     * @param maxBatches_ new maxBatches_
     */
    function _updateMaxBatches(uint256 maxBatches_) public onlyOwner {
        require(maxBatches_ > 0, "PlaNFT: maxBatches must more than 1");
        _maxBatches = maxBatches_;
    }

    /**
     * @dev withdraw
     *
     * @param to address for withdraw account
     * @param value value
     */
    function withdraw(address to, uint256 value) public onlyOwner {
        require(value <= address(this).balance, "PlaNFT: value must less than balances");
        require(_relayWithdrawTime != 0, "PlaNFT: relayWithdraw not call");
        require(_relayWithdrawTime + _delayWithdrawTime <= block.timestamp, "PlaNFT: delayTime not arrive");
        _relayWithdrawTime = 0;
        payable(to).transfer(value);
        emit Withdraw(to, value);
    }

    /**
     * @dev relay Withdraw
     */
    function relayWithdraw() public onlyOwner {
        _relayWithdrawTime = block.timestamp;
        emit RelayWithdraw(msg.sender, _relayWithdrawTime);
    }

    function minterForCollection(string memory collection) public view collectionExists(collection) returns (address) {
        return collectionMinter(collection);
    }

    /**
     * @dev minter for tokenId
     *
     * @param tokenId tokenId
     */
    function minterForTokenId(uint256 tokenId) public view exists(tokenId) returns (address) {
        return _collectionMinter[_collectionForTokenId[tokenId]];
    }

    function minterForGroupId(uint256 groupId, uint256 socialType)
        public
        view
        groupIdExists(groupId, socialType)
        returns (address)
    {
        return _collectionMinter[_collectionForGroupId[groupId][socialType]];
    }

    function groupIdForTokenId(uint256 tokenId, uint256 socialType) public view exists(tokenId) returns (uint256) {
        return _groupIdForCollection[_collectionForTokenId[tokenId]][socialType];
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseUri = baseURI_;
        emit SetBaseURI(msg.sender, _baseUri);
    }

    function _setWhiteAddress(address newWhiteAddress) public onlyOwner {
        _whiteAddress = newWhiteAddress;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_) public exists(tokenId) {
        require(ERC721.ownerOf(tokenId) == msg.sender, "PlaNFT: not token owner");
        require(bytes(_tokenURIs[tokenId]).length == 0, "PlaNFT: tokenURI exists");
        _tokenURIs[tokenId] = tokenURI_;
        emit SetTokenURI(tokenId, tokenURI(tokenId));
    }

    function tokenURI(uint256 tokenId) public view override exists(tokenId) returns (string memory) {
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return base;
    }

    /**
     * @dev mint new token
     *
     * @param to owner
     * @param collection collection
     * @param amount mint amount
     */
    function mintWithoutSocial(
        address to,
        string memory collection,
        uint256 amount,
        string memory tokenURI_
    ) public payable moderate(amount) collectionVaild(collection) {
        require(_socialTypeOptional, "PlaNFT: social type can't be undefined");

        uint256 totalPay = SafeMath.mul(amount, _mintFee);
        require(msg.value >= totalPay, "PlaNFT: mint fee not enough");

        batchMint(msg.sender, to, collection, 0, UNDEFINED, amount, tokenURI_);

        uint256 diff = SafeMath.sub(msg.value, totalPay);
        if (diff > 0) {
            payable(msg.sender).transfer(diff);
        }
    }

    /**
     * @dev mint new token
     *
     * @param to owner
     * @param collection collection
     * @param groupId groupId
     * @param socialType socialType
     * @param amount mint amount
     */
    function mint(
        address to,
        string memory collection,
        uint256 groupId,
        uint256 socialType,
        uint256 amount,
        string memory tokenURI_
    ) public payable socialTypeExists(socialType) moderate(amount) collectionVaild(collection) {
        uint256 totalPay = SafeMath.mul(amount, _mintFee);
        require(msg.value >= totalPay, "PlaNFT: mint fee not enough");

        batchMint(msg.sender, to, collection, groupId, socialType, amount, tokenURI_);

        uint256 diff = SafeMath.sub(msg.value, totalPay);
        if (diff > 0) {
            payable(msg.sender).transfer(diff);
        }
    }

    /**
     * @dev mint new token
     *
     * @param to owner
     * @param collection collection
     * @param amount mint amount
     * @param tokenURI_ mint tokenURI_
     */
    function mintByWhiteAddressWithoutSocial(
        address to,
        string memory collection,
        uint256 amount,
        string memory tokenURI_
    ) public moderate(amount) whiteAddrValid collectionVaild(collection) {
        batchMint(to, to, collection, 0, UNDEFINED, amount, tokenURI_);
    }

    /**
     * @dev mint new token
     *
     * @param to owner
     * @param collection collection
     * @param groupId groupId
     * @param socialType socialType
     * @param amount mint amount
     * @param tokenURI_ mint tokenURI_
     */
    function mintByWhiteAddress(
        address to,
        string memory collection,
        uint256 groupId,
        uint256 socialType,
        uint256 amount,
        string memory tokenURI_
    ) public socialTypeExists(socialType) moderate(amount) whiteAddrValid collectionVaild(collection) {
        batchMint(to, to, collection, groupId, socialType, amount, tokenURI_);
    }

    /**
     * @dev batch mint new token
     *
     * @param owner minter
     * @param to owner
     * @param collection collection
     * @param groupId groupId
     * @param socialType socialType
     * @param amount mint amount
     */
    function batchMint(
        address owner,
        address to,
        string memory collection,
        uint256 groupId,
        uint256 socialType,
        uint256 amount,
        string memory tokenURI_
    ) internal {
        if (!_setSocialTypeForCollection(owner, collection, groupId, socialType)) _collectionMinter[collection] = owner;

        uint256 newTotalSupply = SafeMath.add(_totalSupply, amount);
        for (uint256 tokenId = _totalSupply; tokenId < newTotalSupply; tokenId++) {
            _collectionForTokenId[tokenId] = collection;
            _safeMint(to, tokenId);
            _tokenURIs[tokenId] = tokenURI_;
            emit SetTokenURI(tokenId, tokenURI(tokenId));
        }

        _totalSupply = newTotalSupply;
    }

    function collectionMinter(string memory collection) internal view virtual override returns (address) {
        return _collectionMinter[collection];
    }

    function excludeCollectionName() internal view virtual override returns (string memory) {
        return name();
    }
}