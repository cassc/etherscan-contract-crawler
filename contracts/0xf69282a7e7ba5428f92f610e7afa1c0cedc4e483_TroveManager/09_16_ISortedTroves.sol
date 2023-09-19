// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISortedTroves {
    event NodeAdded(address _id, uint256 _NICR);
    event NodeRemoved(address _id);

    function insert(address _id, uint256 _NICR, address _prevId, address _nextId) external;

    function reInsert(address _id, uint256 _newNICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function setAddresses(address _troveManagerAddress) external;

    function contains(address _id) external view returns (bool);

    function data() external view returns (address head, address tail, uint256 size);

    function findInsertPosition(
        uint256 _NICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function getSize() external view returns (uint256);

    function isEmpty() external view returns (bool);

    function troveManager() external view returns (address);

    function validInsertPosition(uint256 _NICR, address _prevId, address _nextId) external view returns (bool);
}