// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../security/Administered.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Factory is Administered {
    // @dev struct
    struct Collection {
        address sc_address; // address de la smart contract
        bool active; // active or not
    }

    // @dev mapping
    mapping(uint256 => Collection) ListCollections;
    uint256 public pairCount;

    /// @dev este mapping lleva el contador por coleccion
    mapping(address => uint256) public countCollection;

    constructor() {
        pairCount = 0;
    }

    // @dev create a new pair
    function registerPair(address _sc_address, bool _active) external onlyUser {
        // @dev verificar que la coleccion no exista
        require(
            isCollectionExist(_sc_address) == false,
            "Collection already exist"
        );

        // @dev  save the  collection
        ListCollections[pairCount] = Collection(_sc_address, _active);

        // @dev  evita el index out of range
        //  is needed so we avoid index 0 causing bug of index-1
        countCollection[_sc_address] = 0;

        // @dev count the number of pairs
        pairCount++;
    }

    // @dev is collection exist
    function isCollectionExist(address _sc_address) public view returns (bool) {
        unchecked {
            for (uint256 i = 0; i < pairCount; i++) {
                Collection storage s = ListCollections[i];

                if (s.sc_address == _sc_address) {
                    return true;
                }
            }
            return false;
        }
    }

    // @dev enabled oracle
    function pairChange(
        uint8 _type,
        uint256 _id,
        bool _bool,
        address _address
    ) public onlyUser {
        if (_type == 1) {
            ListCollections[_id].sc_address = _address;
        } else if (_type == 2) {
            ListCollections[_id].active = _bool;
        }
    }

    // @dev we return all pair registered
    function pairList() external view returns (Collection[] memory) {
        unchecked {
            Collection[] memory p = new Collection[](pairCount);
            for (uint256 i = 0; i < pairCount; i++) {
                Collection storage s = ListCollections[i];
                p[i] = s;
            }
            return p;
        }
    }
}