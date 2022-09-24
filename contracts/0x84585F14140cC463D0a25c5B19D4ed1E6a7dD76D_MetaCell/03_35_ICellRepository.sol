// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "../../libs/CellData.sol";
/**
 * @title Interface for interaction with particular cell
 */
interface ICellRepository {
    event AddMetaCell(CellData.Cell metaCell, uint256 timestamp);
    event UpdateMetaCell(
        CellData.Cell currentMetaCell,
        CellData.Cell newMetaCell,
        uint256 timestamp
    );
    event RemoveMetaCell(CellData.Cell metaCell, uint256 timestamp);

    function addMetaCell(CellData.Cell memory _cell) external;

    function removeMetaCell(uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns meta cell id's for particular user
     */
    function getUserMetaCellsIndexes(address _user)
        external
        view
        returns (uint256[] memory);

    function updateMetaCell(CellData.Cell memory _cell, address _owner)
        external;

    function getMetaCell(uint256 _tokenId)
        external
        view
        returns (CellData.Cell memory);
}