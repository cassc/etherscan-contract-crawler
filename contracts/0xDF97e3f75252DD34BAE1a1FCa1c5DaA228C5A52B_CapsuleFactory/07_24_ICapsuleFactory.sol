// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IGovernable.sol";

interface ICapsuleFactory is IGovernable {
    function capsuleMinter() external view returns (address);

    function createCapsuleCollection(
        string memory _name,
        string memory _symbol,
        address _tokenURIOwner,
        bool _isCollectionPrivate
    ) external payable returns (address);

    function getAllCapsuleCollections() external view returns (address[] memory);

    function getCapsuleCollectionsOf(address _owner) external view returns (address[] memory);

    function getBlacklist() external view returns (address[] memory);

    function getWhitelist() external view returns (address[] memory);

    function isCapsule(address _capsule) external view returns (bool);

    function isBlacklisted(address _user) external view returns (bool);

    function isWhitelisted(address _user) external view returns (bool);

    function taxCollector() external view returns (address);

    //solhint-disable-next-line func-name-mixedcase
    function VERSION() external view returns (string memory);

    // Special permission functions
    function addToWhitelist(address _user) external;

    function removeFromWhitelist(address _user) external;

    function addToBlacklist(address _user) external;

    function removeFromBlacklist(address _user) external;

    function flushTaxAmount() external;

    function setCapsuleMinter(address _newCapsuleMinter) external;

    function updateCapsuleCollectionOwner(address _previousOwner, address _newOwner) external;

    function updateCapsuleCollectionTax(uint256 _newTax) external;

    function updateTaxCollector(address _newTaxCollector) external;
}