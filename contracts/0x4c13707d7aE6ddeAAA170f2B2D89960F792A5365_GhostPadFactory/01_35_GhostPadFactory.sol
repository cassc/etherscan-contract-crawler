// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './libraries/AdminWhitelistable.sol';
import './libraries/CollectionWhitelistable.sol';
import './libraries/PayReward.sol';
import './libraries/SafeMath.sol';
import './GhostCollectionFactory.sol';
import './GhostWhitelist.sol';
import '../node_modules/@openzeppelin/contracts/utils/Strings.sol';

contract GhostPadFactory is AdminWhitelistable, CollectionWhitelistable, PayReward {
    using SafeMath for uint256;
    address public collectionFactory;

    mapping(address => LaunchPadInfo) public launchPadInfos;
    address[] public launchPadCollections;
    mapping(string => mapping(address => uint256)) public mintedCounts;
    // collectionUID => collection address

    struct LaunchPadInfo {
        string collectionUID;
        address collection;
        uint256 startBlock;
        uint256 endBlock;
        uint256 maxAlloc;
        uint256 price;
        uint256 currentSupply;
        bool isRegistered;
        string ipfsDirURI;
        address whitelist;
    }

    /* Event */
    event UpdateCollectionFactory(address _address);
    event CreateLaunchPad(
        string _collectionUID,
        address _collection,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxAlloc,
        uint256 _price,
        uint256 _currentSupply,
        bool _isRegistered,
        string _ipfsDirURI,
        address whitelist
    );
    event MintLaunchPad(address indexed _collection, address _msgSender, uint256 _quantity);

    constructor(address _weth, address _whitelist, address _collectionFactory, address _collectionWhitelist) {
        _updateWETH(_weth);
        _updateAdminWhitelist(_whitelist);
        collectionFactory = _collectionFactory;
        _updateCollectionWhitelist(_collectionWhitelist);
    }

    function _updateCollectionFactory(address _newCollectionFactory) internal {
        collectionFactory = _newCollectionFactory;
        emit UpdateCollectionFactory(_newCollectionFactory);
    }

    function updateCollectionFactory(address _newCollectionFactory) external onlyAdminWhitelist {
        return _updateCollectionFactory(_newCollectionFactory);
    }

    function getCollections() external view returns (address[] memory) {
        return launchPadCollections;
    }

    function launchPadInfosByUID(string memory _collectionUID) external view returns (LaunchPadInfo memory) {
        address _address = GhostCollectionFactory(payable(collectionFactory)).addressByUID(_collectionUID);
        return launchPadInfos[_address];
    }

    function createLaunchPad(
        string memory _collectionUID,
        string memory _dirURI,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxAlloc,
        uint256 _price,
        address _whitelist
    ) external {
        // onlyCollectionWhitelist
        require(
            isCollectionWhitelist(msg.sender) || isInWhitelist(msg.sender),
            'GhostLaunchPad:not admin or collection owner.'
        );

        // Create Collection
        address _collection = GhostCollectionFactory(payable(collectionFactory)).addressByUID(_collectionUID);
        require(GhostBaseCollection(_collection).owner() == msg.sender, 'GhostLaunchPad : not owner.');
        require(!isActive(_collection), 'GhostLaunchPad : already launchpad is active');

        // Setting Launch Pad
        if (!launchPadInfos[_collection].isRegistered) {
            launchPadCollections.push(_collection);
        }
        return
            _createLaunchPad(
                _collectionUID,
                _collection,
                _startBlock,
                _endBlock,
                _maxAlloc,
                _price,
                0,
                true,
                _dirURI,
                _whitelist
            );
    }

    function _executeNewOrder(address _collection, address _referer, uint256 _quantity) internal {
        require(
            launchPadInfos[_collection].startBlock < block.number &&
                block.number < launchPadInfos[_collection].endBlock,
            'GhostLaunchPad : Not for a period of time.'
        );

        // allocation check
        require(
            launchPadInfos[_collection].maxAlloc == 0 ||
                launchPadInfos[_collection].currentSupply.add(_quantity) <= launchPadInfos[_collection].maxAlloc,
            'GhostLaunchPad : Current supply is above max allocation.'
        );

        // whitelist check //////////////////////////////////////////////////////////////
        require(isMintable(msg.sender, _collection, _quantity), 'GhostLaunchPad:not in whitelist.');
        _updateMintedCounts(msg.sender, _collection, _quantity);

        _WETHTransfer(collectionFactory, launchPadInfos[_collection].price.mul(_quantity));
        GhostCollectionFactory(payable(collectionFactory)).batchMintAndSendViaNFTMarket(
            launchPadInfos[_collection].collectionUID,
            launchPadInfos[_collection].price,
            _referer,
            msg.sender,
            _quantity
        );
        launchPadInfos[_collection].currentSupply = launchPadInfos[_collection].currentSupply.add(_quantity);
        emit MintLaunchPad(_collection, msg.sender, _quantity);
    }

    function isMintable(address _user, address _collection, uint256 _quantity) public view returns (bool) {
        address _whitelist = launchPadInfos[_collection].whitelist;
        if (_whitelist == address(0)) {
            return true;
        }
        uint256 _mintedCount = getRoundMintedCounts(_user, _collection);
        return GhostWhitelist(_whitelist).isMintable(_user, _mintedCount.add(_quantity));
    }

    function _updateMintedCounts(address _user, address _collection, uint256 _quantity) internal {
        string memory _key = string(
            abi.encodePacked(
                launchPadInfos[_collection].collectionUID,
                '-',
                Strings.toString(launchPadInfos[_collection].startBlock)
            )
        );
        uint256 _mintedCount = mintedCounts[_key][_user];
        mintedCounts[_key][_user] = _mintedCount.add(_quantity);
    }

    function getRoundMintedCounts(address _user, address _collection) public view returns (uint256) {
        string memory _key = string(
            abi.encodePacked(
                launchPadInfos[_collection].collectionUID,
                '-',
                Strings.toString(launchPadInfos[_collection].startBlock)
            )
        );
        return mintedCounts[_key][_user];
    }

    function mintByETH(address _collection, address _referer, uint256 _quantity) external payable {
        _WETHDeposit();
        _executeNewOrder(_collection, _referer, _quantity);
    }

    function mintByWETH(address _collection, address _referer, uint256 _quantity) external {
        _WETHTransferFrom(msg.sender, address(this), launchPadInfos[_collection].price);
        _executeNewOrder(_collection, _referer, _quantity);
    }

    function isFinished(address _collection) public view returns (bool) {
        LaunchPadInfo memory info = launchPadInfos[_collection];
        return info.currentSupply == info.maxAlloc || info.endBlock < block.number;
    }

    function isActive(address _collection) public view returns (bool) {
        LaunchPadInfo memory info = launchPadInfos[_collection];
        return info.currentSupply < info.maxAlloc && block.number < info.endBlock; // default currentSupply and maxAlloc is 0
    }

    function _createLaunchPad(
        string memory _collectionUID,
        address _collection,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxAlloc,
        uint256 _price,
        uint256 _currentSupply,
        bool _isRegistered,
        string memory _ipfsDirURI,
        address _whitelist
    ) internal {
        launchPadInfos[_collection] = LaunchPadInfo({
            collectionUID: _collectionUID,
            collection: _collection,
            startBlock: _startBlock,
            endBlock: _endBlock,
            maxAlloc: _maxAlloc,
            price: _price,
            currentSupply: _currentSupply,
            isRegistered: _isRegistered,
            ipfsDirURI: _ipfsDirURI,
            whitelist: _whitelist
        });
        GhostBaseCollection(_collection).setBaseURI(_ipfsDirURI);
        emit CreateLaunchPad(
            _collectionUID,
            _collection,
            _startBlock,
            _endBlock,
            _maxAlloc,
            _price,
            _currentSupply,
            _isRegistered,
            _ipfsDirURI,
            _whitelist
        );
    }

    function migrateLaunchPad(
        string memory _collectionUID,
        address _collection,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxAlloc,
        uint256 _price,
        uint256 _currentSupply,
        bool _isRegistered,
        string memory _ipfsDirURI,
        address _whitelist
    ) external onlyAdminWhitelist {
        return
            _createLaunchPad(
                _collectionUID,
                _collection,
                _startBlock,
                _endBlock,
                _maxAlloc,
                _price,
                _currentSupply,
                _isRegistered,
                _ipfsDirURI,
                _whitelist
            );
    }

    function pushLaunchPadCollections(address _collection) external onlyAdminWhitelist {
        launchPadCollections.push(_collection);
    }
}