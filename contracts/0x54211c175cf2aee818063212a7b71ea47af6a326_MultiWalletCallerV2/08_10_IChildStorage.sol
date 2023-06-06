// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChildStorage {
    function addChildAddress_EPEzCt7SLk (address _user, address _newChild) external;
    function child (address, uint256) external view returns (address);
    function childCount (address) external view returns (uint256);
    function controller (address) external view returns (bool);
    function delegateRegistry () external view returns (address);
    function kudasai () external view returns (address);
    function operator () external view returns (address);
    function ownedNFTId (address) external view returns (uint256);
    function owner () external view returns (address);
    function renounceOwnership () external;
    function setController (address _contract, bool _set) external;
    function setDelegateRegistry (address _contract) external;
    function setKudasai (address _contract) external;
    function setNFTId (address _user, uint256 _nftId) external;
    function setOperator (address _contract) external;
    function setSpaceId (string calldata _str) external;
    function spaceId () external view returns (bytes32);
    function transferOwnership (address newOwner) external;
}