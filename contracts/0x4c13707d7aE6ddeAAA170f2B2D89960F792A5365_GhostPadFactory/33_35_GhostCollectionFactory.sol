// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import './libraries/AdminWhitelistable.sol';
import './libraries/PayReward.sol';
import './libraries/SafeMath.sol';
import './GhostBaseCollection.sol';
import './GhostNFTMarket.sol';

// import '../node_modules/@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

// contract GhostCollectionFactory is AdminWhitelistable, PayReward, ERC721Holder {
contract GhostCollectionFactory is AdminWhitelistable, PayReward {
    using SafeMath for uint256;
    struct Collection {
        string collectionUID;
        address collection;
        address creator;
        address loyality;
        bool isCreated;
    }
    struct Token {
        string tokenUID;
        uint256 tokenId;
        bool isMinted;
    }

    address public nftmarket;

    mapping(string => Collection) public collectionInfos;
    mapping(string => Token) public tokenInfos;
    string[] private _mintedCollectionUIDs;

    // _mintedTokenUID list for migration (_collectionUID => _tokenUID[])
    mapping(string => string[]) private _mintedTokenUID;

    event UpdateNFTMarket(address nftmarket);
    event UpdateCollectionInformation(
        string uid,
        address collection,
        address creator,
        address loyality,
        bool isCreated
    );
    event UpdateTokenInformation(string uid, uint256 tokenId, bool isMinted);

    constructor(address _nftmarket, address _weth, address _whitelist) {
        _updateAdminWhitelist(_whitelist);
        _updateWETH(_weth);
        _updateNftMarket(_nftmarket);
    }

    function _updateNftMarket(address _newNftMarket) internal {
        nftmarket = _newNftMarket;
        emit UpdateNFTMarket(_newNftMarket);
    }

    function updateNftMarket(address _newNftMarket) external onlyAdminWhitelist {
        return _updateNftMarket(_newNftMarket);
    }

    function isCreatedByUID(string memory _collectionUID) external view returns (bool) {
        return collectionInfos[_collectionUID].isCreated;
    }

    function addressByUID(string memory _collectionUID) external view returns (address) {
        return collectionInfos[_collectionUID].collection;
    }

    function creatorByUID(string memory _collectionUID) external view returns (address) {
        return collectionInfos[_collectionUID].creator;
    }

    function loyalityByUID(string memory _collectionUID) external view returns (address) {
        return collectionInfos[_collectionUID].loyality;
    }

    function tokenIdByUID(string memory _tokenUID) external view returns (uint256) {
        return tokenInfos[_tokenUID].tokenId;
    }

    function getCollectionUIDs() external view returns (string[] memory) {
        return _mintedCollectionUIDs;
    }

    function getTokenUIDs(string memory _collectionUID) external view returns (string[] memory) {
        return _mintedTokenUID[_collectionUID];
    }

    function createCollection(
        string memory _collectionUID,
        string memory _name,
        string memory _symbol,
        address _creator,
        address _loyality,
        uint256 _creatorFee,
        uint256 _refererFee
    ) external returns (address) {
        require(!collectionInfos[_collectionUID].isCreated, 'GCF:Already created.');
        address _collection = address(new GhostBaseCollection(_name, _symbol, _creator));
        GhostNFTMarket(payable(nftmarket)).addCollection(_collection, _loyality, address(0), _creatorFee, _refererFee);
        _mintedCollectionUIDs.push(_collectionUID);
        collectionInfos[_collectionUID] = Collection({
            collectionUID: _collectionUID,
            collection: _collection,
            creator: _creator,
            loyality: _loyality,
            isCreated: true
        });
        emit UpdateCollectionInformation(_collectionUID, _collection, _creator, _loyality, true);
        return _collection;
    }

    function _mint(
        string memory _collectionUID,
        string memory _tokenURI,
        string memory _tokenUID,
        address _to
    ) internal returns (uint256) {
        require(collectionInfos[_collectionUID].isCreated, 'GCF:collection not created.');
        require(!tokenInfos[_tokenUID].isMinted, 'GCF:tokenUID is already minted.');
        address _collection = collectionInfos[_collectionUID].collection;
        uint256 _tokenId = GhostBaseCollection(_collection).mint(_tokenURI, _to);
        tokenInfos[_tokenUID] = Token({tokenUID: _tokenUID, isMinted: true, tokenId: _tokenId});
        _mintedTokenUID[_collectionUID].push(_tokenUID);
        return _tokenId;
    }

    function mint(
        string memory _collectionUID,
        string memory _tokenURI,
        string memory _tokenUID,
        address _to
    ) external payable returns (uint256) {
        address _creator = collectionInfos[_collectionUID].creator;
        require(msg.sender == _creator || isInWhitelist(msg.sender), 'GCF:need creator or whitelist');
        return _mint(_collectionUID, _tokenURI, _tokenUID, _to);
    }

    function mintAndSendViaNFTMarket(
        string memory _collectionUID,
        string memory _tokenURI,
        string memory _tokenUID,
        uint256 _price,
        address _referer,
        address _to
    ) external onlyAdminWhitelist returns (uint256) {
        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = _mint(_collectionUID, _tokenURI, _tokenUID, _to);

        _WETHTransfer(nftmarket, _price);
        GhostNFTMarket(payable(nftmarket)).emitTradeFromPadFactory(
            collectionInfos[_collectionUID].collection,
            _tokenIds,
            _price,
            collectionInfos[_collectionUID].loyality,
            _referer,
            _to
        );
        return _tokenIds[0];
    }

    function batchMintAndSendViaNFTMarket(
        string memory _collectionUID,
        uint256 _price,
        address _referer,
        address _to,
        uint256 _quantity
    ) external onlyAdminWhitelist {
        // mint approve createAskOrder
        address _collection = collectionInfos[_collectionUID].collection;
        uint256 _startTokenId = GhostBaseCollection(_collection).nextTokenId();
        GhostBaseCollection(_collection).batchMint(_to, _quantity);

        uint256[] memory _tokenIds = new uint256[](_quantity);
        for (uint256 index = 0; index < _quantity; index++) {
            _tokenIds[index] = index.add(_startTokenId);
        }
        _WETHTransfer(nftmarket, _price.mul(_quantity));
        GhostNFTMarket(payable(nftmarket)).emitTradeFromPadFactory(
            _collection,
            _tokenIds,
            _price,
            collectionInfos[_collectionUID].loyality,
            _referer,
            _to
        );
    }

    function updateCollectionInfo(
        string memory _collectionUID,
        address _collection,
        address _creator,
        address _loyality,
        address _whitelistChecker,
        uint256 _creatorFee,
        uint256 _refererFee,
        bool _isCreated
    ) external {
        require(
            isInWhitelist(msg.sender) || GhostBaseCollection(_collection).owner() == msg.sender,
            'GhostCollectionFactory: not owner'
        );
        GhostNFTMarket(payable(nftmarket)).modifyCollection(
            _collection,
            _loyality,
            _whitelistChecker,
            _creatorFee,
            _refererFee
        );
        collectionInfos[_collectionUID] = Collection({
            collectionUID: _collectionUID,
            collection: _collection,
            creator: _creator,
            loyality: _loyality,
            isCreated: _isCreated
        });
        emit UpdateCollectionInformation(_collectionUID, _collection, _creator, _loyality, _isCreated);
    }

    function updateTokenUIDInfo(string memory _tokenUID, uint256 _tokenId, bool _isMinted) external onlyAdminWhitelist {
        tokenInfos[_tokenUID] = Token({tokenUID: _tokenUID, tokenId: _tokenId, isMinted: _isMinted});
        emit UpdateTokenInformation(_tokenUID, _tokenId, _isMinted);
    }
}