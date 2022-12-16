// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../security/Administered.sol";

contract CollectionV2 is Administered {

    /**
     * @dev Collection struct
     * @param addr                  Collection address
     * @param price                Price in USD (WEI)
     * @param active                        Status of the collection
     */
    struct CollectionStruct {
        address addr;                         // NFT to sell
        uint256 price;                              // Price in USD
        bool active;                                // active or not
    }

    /**
     * @dev Collection Index struct
     * @param addr                  Collection address
     * @param index                         Index of the collection
     */
    struct CollectionIndexStruct {
        address addr;
        uint256 index;
    }

    /// @dev mapping of CollectionStructs
    mapping(uint256 => CollectionStruct) collections;

    /// @dev mapping for index collection address
    mapping(address => CollectionIndexStruct) collectionIndex;

    /// @dev Total number of Collections
    uint256 public collectionCount = 0;

    constructor() { }

    /**
     * @dev Get Collection list
     */
    function collectionList() external view returns (CollectionStruct[] memory) {
        unchecked {
            uint256 pointer = collectionCount;
            CollectionStruct[] memory p = new CollectionStruct[](pointer);
            
            for (uint256 i = 0; i < pointer; i++) {
                CollectionStruct storage s = collections[i];
                p[i] = s;
            }
            return p;
        }
    }

    /**
     * @dev Add a Collection
     * @param _addr                          NFT contract address
     * @param _pr                               Price in USD (WEI)
     * @param _act                              Status of the CollectionStruct
     */
    function addCollection(
        address _addr,
        uint256 _pr,
        bool _act
    ) external onlyUser {
        require(!isCollection(_addr), "Collection already stored");

        collections[collectionCount] = CollectionStruct(_addr, _pr, _act);
        collectionIndex[_addr] = CollectionIndexStruct(_addr, collectionCount);
        collectionCount++;
    }

    /**
     * @dev Update a Collection
     * @param _id                                  Id of the CollectionStruct
     * @param _type                                Type of change to be made
     * @param _addr                                Address value type
     * @param _p                                    Number value type
     * @param _bool                                Status of the Collection
     */
    function updateCollection(
        uint256 _id,
        uint8 _type,
        address _addr,
        uint256 _p,
        bool _bool
    ) public onlyUser {
        /// @dev Update the price
        if (_type == 1) {
            collections[_id].price = _p;

        /// @dev Update NFT Contract Address
        } else if (_type == 2) {
            collections[_id].addr = _addr;

        /// @dev Update status
        } else if (_type == 3) {
            collections[_id].active = _bool;
        } 
    }

    /**
     * @dev Verify if is a Collection
     * @param _addr Collection Contract Address
     */
    function isCollection(address _addr) private view returns (bool) {
        return (collectionIndex[_addr].addr == address(0x0)) ? false : true;
    }

    /**
     * @dev Get Collection By Address
     * @param _addr                     Address of the Collection
     */
    function getCollectionByAddr(address _addr) public view returns (CollectionStruct memory){
        require(isCollection(_addr), "Invalid Collection");
        CollectionIndexStruct storage row = collectionIndex[_addr];
        return _getCollectionByIdx(row.index);
    }

    /**
     * @dev Get Collection by Index
     * @param _idx                     Index of the Collection
     */
    function _getCollectionByIdx(uint256 _idx) private view returns (CollectionStruct memory) {
        unchecked { return collections[_idx]; }
    }
}