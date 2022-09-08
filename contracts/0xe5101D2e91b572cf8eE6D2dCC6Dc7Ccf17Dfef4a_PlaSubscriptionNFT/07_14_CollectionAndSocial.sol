// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract CollectionAndSocial is Ownable {
    using SafeMath for uint256;

    // Mapping from groupId and socicalType to collection
    mapping(uint256 => mapping(uint256 => string)) public _collectionForGroupId;
    // Mapping from collection and socicalType to groupId
    mapping(string => mapping(uint256 => uint256)) public _groupIdForCollection;
    // Mapping from collection and socicalType to update count
    mapping(string => mapping(uint256 => uint256)) public _updateCountForCollection;
    // Mapping from number to socialTypes
    mapping(uint256 => string) public _socialTypes;

    // Set a count what can update groupId
    uint256 public _updateGroupIdCount = 1;

    // undefined social type
    uint256 public constant UNDEFINED = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    // determine if socialType could be undefined
    bool public _socialTypeOptional = false;

    /**
     * @dev Throws if collection not exists.
     */
    modifier collectionExists(string memory collection) {
        require(collectionMinter(collection) != address(0), "PlaNFT: collection nonexistent");
        _;
    }

    /**
     * @dev Throws if collection equals contract name.
     */
    modifier collectionVaild(string memory collection) {
        require(!equals(excludeCollectionName(), collection), "PlaNFT: collection can't equal contract name");
        _;
    }

    /**
     * @dev Throws if groupId not exists.
     */
    modifier groupIdExists(uint256 groupId, uint256 socialType) {
        require(socialType != UNDEFINED, "PlaNFT: socialType undefined");
        require(bytes(_collectionForGroupId[groupId][socialType]).length != 0, "PlaNFT: groupId nonexistent");
        _;
    }

    /**
     * @dev Throws if socialType not exists.
     */
    modifier socialTypeExists(uint256 socialType) {
        require(socialType != UNDEFINED, "PlaNFT: socialType undefined");
        require(bytes(_socialTypes[socialType]).length != 0, "PlaNFT: socialType nonexistent");
        _;
    }

    constructor(bool socialTypeOptional) {
        _socialTypeOptional = socialTypeOptional;

        // The groupId starting with 0 represents Telegram
        _socialTypes[0] = "Telegram";

        // The groupId starting with 1 represents Discord
        _socialTypes[1] = "Discord";
    }

    /**
     * @dev update groupId for collection
     *
     * @param collection collection
     * @param groupId new groupId
     * @param socialType socialType
     */
    function _updateCollectionGroupId(
        string memory collection,
        uint256 groupId,
        uint256 socialType
    ) public virtual socialTypeExists(socialType) {
        require(socialType != UNDEFINED, "PlaNFT: socialType undefined");
        require(collectionMinter(collection) == msg.sender, "PlaNFT: collection minter can't match");
        require(bytes(_collectionForGroupId[groupId][socialType]).length == 0, "PlaNFT: groupId has exists");
        require(
            _updateCountForCollection[collection][socialType] < _updateGroupIdCount,
            "PlaNFT: update count must less than _updateGroupIdCount"
        );
        _updateCountForCollection[collection][socialType] = _updateCountForCollection[collection][socialType] + 1;
        _groupIdForCollection[collection][socialType] = groupId;
    }

    /**
     * @dev set social type for collection
     *
     * @param collection collection to set social type
     * @param groupId groupId
     * @param socialType social type - must in _socialTypes
     */
    function setSocialTypeForCollection(
        string memory collection,
        uint256 groupId,
        uint256 socialType
    ) public socialTypeExists(socialType) collectionVaild(collection) {
        address minter = collectionMinter(collection);
        if (minter != address(0)) {
            require(minter == _msgSender(), "PlaNFT: collection minter can't match");
        } else {
            require(bytes(_collectionForGroupId[groupId][socialType]).length == 0, "PlaNFT: groupId has exists");
        }

        _collectionForGroupId[groupId][socialType] = collection;
        _groupIdForCollection[collection][socialType] = groupId;
        _updateCountForCollection[collection][socialType] = 1;
    }

    function equals(string memory _first, string memory _second) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(_first)) == keccak256(abi.encodePacked(_second)));
    }

    /**
     * @dev set social type for collection
     *
     * @param owner owner of collection
     * @param collection collection to set social type
     * @param groupId groupId
     * @param socialType social type - must in _socialTypes
     * @return true for collection's owner exists
     */
    function _setSocialTypeForCollection(
        address owner,
        string memory collection,
        uint256 groupId,
        uint256 socialType
    ) internal returns (bool) {
        address minter = collectionMinter(collection);
        bool ownerExists = (minter != address(0));

        if (ownerExists) {
            require(minter == owner, "PlaNFT: collection minter can't match");
            require(
                socialType == UNDEFINED || _groupIdForCollection[collection][socialType] == groupId,
                "PlaNFT: collection for groupId can't match"
            );
        } else {
            if (socialType != UNDEFINED) {
                require(bytes(_collectionForGroupId[groupId][socialType]).length == 0, "PlaNFT: groupId has exists");

                _collectionForGroupId[groupId][socialType] = collection;
                _groupIdForCollection[collection][socialType] = groupId;
                _updateCountForCollection[collection][socialType] = 1;
            }
        }

        return ownerExists;
    }

    /**
     * @dev add new social type
     *
     * @param socialType new socialType
     * @param socialName new socialName
     */
    function _setSocialTypes(uint256 socialType, string memory socialName) public virtual onlyOwner {
        require(socialType != UNDEFINED, "PlaNFT: socialType undefined");
        require(bytes(_socialTypes[socialType]).length == 0, "PlaNFT: socialType nonexistent");
        _socialTypes[socialType] = socialName;
    }

    function collectionMinter(string memory collection) internal view virtual returns (address);

    function excludeCollectionName() internal view virtual returns (string memory);
}