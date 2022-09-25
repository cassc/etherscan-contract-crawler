// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/ICollection.sol";
import "./interfaces/IAmetaBox.sol";

contract AmetaBox is
    Ownable,
    ReentrancyGuard,
    Pausable,
    ERC721Enumerable,
    IAmetaBox
{
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter public tokenIdTracker;
    string public baseUrl;
    address public collectionAddress;

    // enumBox type (example SILVER = 1,GOLD=2,DIAMOND =3,...)
    EnumerableSet.UintSet private boxTypes;

    bool public enableOpenBox = false;

    // tokenId (boxId) => boxType
    mapping(uint256 => uint256) public boxTypeOfTokenId;

    mapping(address => bool) public minters;

    event UpdateMinters(address[] minters, bool isAdd);

    /*
     * tokenId: boxId mint,
     * boxType: type of Box
     * to: box receiving address
     */
    event Mint(
        uint256 indexed tokenId,
        uint256 indexed boxType,
        address indexed to
    );

    /*
     * tokenIds: list boxId mint,
     * boxType: type of Box
     * to: box receiving address
     */
    event MintBatch(
        uint256[] tokenIds,
        uint256 indexed boxType,
        address indexed to
    );
    /*
     * owner: owner of box,
     * tokenId: boxId open
     * collectionId: collectionId mint
     * boxType: type of Box
     */
    event OpenBox(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed collectionId,
        uint256 boxType
    );

    event UpdateEnableOpenBox(bool enable);

    // Modifier checking Minter role
    modifier onlyMinter() {
        require(
            msg.sender != address(0) && minters[msg.sender],
            "AmetaBox: account not role minter"
        );
        _;
    }

    // Modifier checking boxType allow
    modifier verifyBoxType(uint256 _boxType) {
        require(
            _boxType > 0 && boxTypes.contains(_boxType),
            "AmetaBox: Box type invalid value"
        );
        _;
    }

    // Modifier verify collection accept
    modifier verifyCollection() {
        require(
            collectionAddress != address(0),
            "AmetaBox: Invalid collection"
        );
        _;
    }

    constructor(string memory _baseUrl) ERC721("Ameta Box", "AmetaBox") {
        baseUrl = _baseUrl;
        minters[msg.sender] = true;
    }

    function updateBoxTypes(uint256[] memory _boxTypes) public onlyOwner {
        for (uint256 i = 0; i < _boxTypes.length; i++) {
            boxTypes.add(_boxTypes[i]);
        }
    }

    function removeBoxTypes(uint256[] memory _boxTypes) public onlyOwner {
        for (uint256 i = 0; i < _boxTypes.length; i++) {
            boxTypes.remove(_boxTypes[i]);
        }
    }

    function setCollectionAddress(address _collectionAddress) public onlyOwner {
        require(
            _collectionAddress != address(0),
            "AmetaBox: Invalid collection input"
        );
        collectionAddress = _collectionAddress;
    }

    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    function updateMinters(address[] memory _minters, bool _isAdd)
        external
        nonReentrant
        onlyOwner
    {
        for (uint256 i = 0; i < _minters.length; i++) {
            minters[_minters[i]] = _isAdd;
        }
        emit UpdateMinters(_minters, _isAdd);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, uint256 _boxType)
        external
        override
        whenNotPaused
        onlyMinter
        verifyBoxType(_boxType)
        returns (uint256)
    {
        tokenIdTracker.increment();
        uint256 tokenId = tokenIdTracker.current();
        _mint(_to, tokenId);
        boxTypeOfTokenId[tokenId] = _boxType;
        emit Mint(tokenId, _boxType, _to);
        return tokenId;
    }

    function mintBatch(
        address _to,
        uint256 _qty,
        uint256 _boxType
    )
        external
        override
        whenNotPaused
        onlyMinter
        verifyBoxType(_boxType)
        returns (uint256[] memory tokenIds)
    {
        require(_qty > 0, "Qty cannot be 0");
        tokenIds = new uint256[](_qty);
        for (uint256 i = 0; i < _qty; i++) {
            tokenIdTracker.increment();
            uint256 tokenId = tokenIdTracker.current();
            _mint(_to, tokenId);
            boxTypeOfTokenId[tokenId] = _boxType;
            tokenIds[i] = tokenId;
        }
        emit MintBatch(tokenIds, _boxType, _to);
        return tokenIds;
    }

    function tokenIdsOfOwner(address _owner)
        external
        view
        override
        returns (uint256[] memory tokenIds)
    {
        uint256 balance = balanceOf(_owner);
        tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _openBox(uint256 _boxId) private {
        require(
            ownerOf(_boxId) == msg.sender,
            "AmetaBox:Caller is not owner of this box"
        );
        uint256 tokenId = ICollection(collectionAddress).mint(msg.sender);
        emit OpenBox(msg.sender, _boxId, tokenId, boxTypeOfTokenId[_boxId]);
        _burn(_boxId);
    }

    function openBox(uint256 _boxId) external override verifyCollection {
        require(enableOpenBox == true, "Open box is disable");
        _openBox(_boxId);
    }

    function openBoxs(uint256[] memory _boxIds)
        external
        override
        verifyCollection
    {
        require(enableOpenBox == true, "Open box is disable");
        for (uint256 i = 0; i < _boxIds.length; i++) {
            _openBox(_boxIds[i]);
        }
    }

    function updateEnableOpenBox(bool _enable) public onlyOwner {
        enableOpenBox = _enable;
        emit UpdateEnableOpenBox(_enable);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return (
            string(
                abi.encodePacked(
                    baseUrl,
                    "/",
                    Strings.toHexString(uint160(address(this)), 20),
                    "/",
                    Strings.toString(_tokenId)
                )
            )
        );
    }

    function viewListBoxType()
        external
        view
        override
        returns (uint256[] memory)
    {
        return boxTypes.values();
    }

    function validateBoxType(uint256 _boxType)
        external
        view
        override
        returns (bool)
    {
        return boxTypes.contains(_boxType);
    }
}