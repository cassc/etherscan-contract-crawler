// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/ICellRepository.sol";
import "../../libs/CellData.sol";

/**
 * @title Interface for interaction with particular cell
 */
abstract contract ACellRepository is ICellRepository, Multicall {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    //  are meta cells
    EnumerableSet.UintSet private idSet;
    mapping(address => uint256[]) private userIndexesArray;
    mapping(address => mapping(uint256 => CellData.Cell)) public addressToMap;

    function _addMetaCell(CellData.Cell memory _cell) internal {
        require(
            _getMetaCell(_cell.tokenId).user == address(0),
            "Token already exists"
        );

        EnumerableSet.add(idSet, _cell.tokenId);
        addressToMap[_cell.user][_cell.tokenId] = _cell;

        userIndexesArray[_cell.user].push(_cell.tokenId);
        emit AddMetaCell(_cell, block.timestamp);
    }

    function _removeMetaCell(address _user, uint256 _tokenId) internal {
        CellData.Cell memory _cell = _getMetaCell(_tokenId);
        require(
            _cell.user != address(0),
            "Token not exists"
        );

        require(
            addressToMap[_user][_tokenId].user == _user,
            "User is no the owner"
        );
        EnumerableSet.remove(idSet, _tokenId);
        emit RemoveMetaCell(_cell, block.timestamp);

        uint256 indexInArray = _getIndexInCellsArray(_user, _tokenId);
        require(indexInArray != type(uint256).max, "No such index");
        userIndexesArray[_user][indexInArray] = userIndexesArray[_user][
            userIndexesArray[_user].length - 1
        ];
        userIndexesArray[_user].pop();
        delete addressToMap[_user][_tokenId];
        
    }

    function _getIndexInCellsArray(address _user, uint256 _value)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < userIndexesArray[_user].length; i++) {
            if (userIndexesArray[_user][i] == _value) {
                return i;
            }
        }
        return type(uint256).max;
    }

    /**
     * @dev Returns meta cell id's for particular user
     */
    function getUserMetaCellsIndexes(address _user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return userIndexesArray[_user];
    }

    function _updateMetaCell(CellData.Cell memory _cell, address _owner)
        internal
    {
        CellData.Cell memory cell = _getMetaCell(_cell.tokenId);
        require(cell.user != address(0), "Token not exists");
        emit UpdateMetaCell(cell, _cell, block.timestamp);
        cell = _cell;

        //uint256 index = idToIndex[cell.tokenId];
        addressToMap[_owner][_cell.tokenId] = cell;
    }

    function getMetaCell(uint256 _tokenId)
        external
        view
        override
        returns (CellData.Cell memory)
    {
        return _getMetaCell( _tokenId);
    }

    function _getMetaCell(uint256 _tokenId)
        internal
        view
        returns (CellData.Cell memory _metaCell)
    {
        if (!EnumerableSet.contains(idSet, _tokenId)) {
            return _metaCell;
        }

        address _ownerOf = ownerOf(_tokenId);

        require(
            addressToMap[_ownerOf][_tokenId].user == _ownerOf,
            "User is not the owner"
        );

        _metaCell = addressToMap[_ownerOf][_tokenId];
        return _metaCell;
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address);
}