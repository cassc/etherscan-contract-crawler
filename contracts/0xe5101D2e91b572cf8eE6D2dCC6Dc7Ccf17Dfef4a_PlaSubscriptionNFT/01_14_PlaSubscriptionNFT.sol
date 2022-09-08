// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./CollectionAndSocial.sol";

contract PlaSubscriptionNFT is ERC721, Ownable, CollectionAndSocial {
    using SafeMath for uint256;
    using Strings for uint256;

    // Mapping from collection to collectionInfo
    mapping(string => Collection) private _collectionDetails;
    // Mapping from tokenId to collection
    mapping(uint256 => string) public _collectionForTokenId;
    // Mapping from tokenId to subscriptEndTime
    mapping(uint256 => uint256) public _subscriptEndTime;
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

    struct Collection {
        // minter for collection
        address minter;
        // subscriptCycle for collection
        uint256 subscriptCycle;
        // paymentToken for collection
        address paymentToken;
        // subscriptPrice for collection
        uint256 subscriptPrice;
    }

    modifier exists(uint256 tokenId) {
        require(_exists(tokenId), "PlaNFT: token nonexistent");
        _;
    }

    modifier moderate(uint256 amount) {
        require(amount <= _maxBatches, "PlaNFT: mint amount flowover");
        _;
    }

    modifier whiteAddrValid() {
        require(msg.sender == _whiteAddress, "PlaNFT: not white address");
        _;
    }

    constructor(
        address whiteAddress_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) CollectionAndSocial(false) {
        _whiteAddress = whiteAddress_;
    }

    function _updateMintFee(uint256 newMintFee) public onlyOwner {
        emit UpdateMintFee(_mintFee, newMintFee);
        _mintFee = newMintFee;
    }

    function _doUpdateGroupIdCount(uint256 newUpdateGroupIdCount) public onlyOwner {
        emit DoUpdateGroupIdCount(_updateGroupIdCount, newUpdateGroupIdCount);
        _updateGroupIdCount = newUpdateGroupIdCount;
    }

    function _updateMaxBatches(uint256 maxBatches_) public onlyOwner {
        require(maxBatches_ > 0, "PlaNFT: maxBatches must more than 1");
        _maxBatches = maxBatches_;
    }

    function _renewal(uint256 tokenId, uint256 renewalCycle) public exists(tokenId) {
        require(ERC721.ownerOf(tokenId) == msg.sender, "PlaNFT: caller must be owner of tokenId");
        Collection memory collection = _collectionDetails[_collectionForTokenId[tokenId]];
        IERC20(collection.paymentToken).transferFrom(
            msg.sender,
            collection.minter,
            SafeMath.mul(renewalCycle, collection.subscriptPrice)
        );
        if (_subscriptEndTime[tokenId] > block.timestamp) {
            _subscriptEndTime[tokenId] = SafeMath.add(
                _subscriptEndTime[tokenId],
                SafeMath.mul(collection.subscriptCycle, renewalCycle)
            );
        } else {
            _subscriptEndTime[tokenId] = SafeMath.add(
                block.timestamp,
                SafeMath.mul(collection.subscriptCycle, renewalCycle)
            );
        }
    }

    function _updateSubscriptPay(
        string memory collection,
        address paymentToken,
        uint256 subscriptPrice
    ) public collectionExists(collection) {
        require(_collectionDetails[collection].minter == msg.sender, "PlaNFT: caller must be minter of collection");
        _collectionDetails[collection].paymentToken = paymentToken;
        _collectionDetails[collection].subscriptPrice = subscriptPrice;
    }

    function withdraw(address to, uint256 value) public onlyOwner {
        require(value <= address(this).balance, "PlaNFT: value must less than balances");
        require(_relayWithdrawTime != 0, "PlaNFT: relayWithdraw not call");
        require(_relayWithdrawTime + _delayWithdrawTime <= block.timestamp, "PlaNFT: delayTime not arrive");
        _relayWithdrawTime = 0;
        payable(to).transfer(value);
        emit Withdraw(to, value);
    }

    function relayWithdraw() public onlyOwner {
        _relayWithdrawTime = block.timestamp;
        emit RelayWithdraw(msg.sender, _relayWithdrawTime);
    }

    function minterForTokenId(uint256 tokenId) public view exists(tokenId) returns (address) {
        return _collectionDetails[_collectionForTokenId[tokenId]].minter;
    }

    function subscriptCycleForTokenId(uint256 tokenId) public view exists(tokenId) returns (uint256) {
        return _collectionDetails[_collectionForTokenId[tokenId]].subscriptCycle;
    }

    function subscriptPriceForTokenId(uint256 tokenId) public view exists(tokenId) returns (uint256) {
        return _collectionDetails[_collectionForTokenId[tokenId]].subscriptPrice;
    }

    function paymentTokenForTokenId(uint256 tokenId) public view exists(tokenId) returns (address) {
        return _collectionDetails[_collectionForTokenId[tokenId]].paymentToken;
    }

    function minterForCollection(string memory collection) public view collectionExists(collection) returns (address) {
        return collectionMinter(collection);
    }

    function subscriptCycleForCollection(string memory collection)
        public
        view
        collectionExists(collection)
        returns (uint256)
    {
        return _collectionDetails[collection].subscriptCycle;
    }

    function subscriptPriceForCollection(string memory collection)
        public
        view
        collectionExists(collection)
        returns (uint256)
    {
        return _collectionDetails[collection].subscriptPrice;
    }

    function paymentTokenForCollection(string memory collection)
        public
        view
        collectionExists(collection)
        returns (address)
    {
        return _collectionDetails[collection].paymentToken;
    }

    function groupIdForTokenId(uint256 tokenId, uint256 socialType) public view exists(tokenId) returns (uint256) {
        return _groupIdForCollection[_collectionForTokenId[tokenId]][socialType];
    }

    function minterForGroupId(uint256 groupId, uint256 socialType)
        public
        view
        groupIdExists(groupId, socialType)
        returns (address)
    {
        return _collectionDetails[_collectionForGroupId[groupId][socialType]].minter;
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

    function mint(
        address to,
        string memory collection,
        uint256 groupId,
        uint256 socialType,
        uint256 subscriptCycle,
        address paymentToken,
        uint256 subscriptPrice,
        uint256 amount,
        string memory tokenURI_
    ) public payable socialTypeExists(socialType) moderate(amount) collectionVaild(collection) {
        uint256 totalPay = SafeMath.mul(amount, _mintFee);
        require(msg.value >= totalPay, "PlaNFT: mint fee not enough");
        batchMint(
            msg.sender,
            to,
            collection,
            groupId,
            socialType,
            subscriptCycle,
            paymentToken,
            subscriptPrice,
            amount,
            tokenURI_
        );
        uint256 diff = SafeMath.sub(msg.value, totalPay);
        if (diff > 0) {
            payable(msg.sender).transfer(diff);
        }
    }

    function mintByWhiteAddress(
        address to,
        string memory collection,
        uint256 groupId,
        uint256 socialType,
        uint256 subscriptCycle,
        address paymentToken,
        uint256 subscriptPrice,
        uint256 amount,
        string memory tokenURI_
    ) public socialTypeExists(socialType) moderate(amount) whiteAddrValid collectionVaild(collection) {
        batchMint(
            to,
            to,
            collection,
            groupId,
            socialType,
            subscriptCycle,
            paymentToken,
            subscriptPrice,
            amount,
            tokenURI_
        );
    }

    function batchMint(
        address owner,
        address to,
        string memory collection,
        uint256 groupId,
        uint256 socialType,
        uint256 subscriptCycle,
        address paymentToken,
        uint256 subscriptPrice,
        uint256 amount,
        string memory tokenURI_
    ) internal {
        if (!_setSocialTypeForCollection(owner, collection, groupId, socialType))
            _collectionDetails[collection] = Collection(owner, subscriptCycle, paymentToken, subscriptPrice);

        uint256 newTotalSupply = SafeMath.add(_totalSupply, amount);
        for (uint256 tokenId = _totalSupply; tokenId < newTotalSupply; tokenId++) {
            _collectionForTokenId[tokenId] = collection;
            _subscriptEndTime[tokenId] = block.timestamp + subscriptCycle;
            _safeMint(to, tokenId);
            _tokenURIs[tokenId] = tokenURI_;
            emit SetTokenURI(tokenId, tokenURI(tokenId));
        }

        _totalSupply = newTotalSupply;
    }

    function collectionMinter(string memory collection) internal view virtual override returns (address) {
        return _collectionDetails[collection].minter;
    }

    function excludeCollectionName() internal view virtual override returns (string memory) {
        return name();
    }
}