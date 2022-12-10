// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract BustadAssetOracle is AccessControl {
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    event AddedRealEstate(
        string cadastralNumber,
        string note,
        uint256 value,
        uint256 date,
        uint256 share
    );

    event RemovedRealEstate(
        string cadastralNumber,
        string note,
        uint256 sellPrice,
        uint256 purchasePrice,
        uint256 date,
        uint256 share
    );

    event UpdatedRealEstateValue(
        string indexed cadastralNumber,
        string note,
        uint256 indexed value,
        uint256 indexed date
    );

    event UpdatedBankAccountBalance(        
        uint256 indexed value,
        uint256 indexed date
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addRealEstate(
        string calldata cadastralNumber,
        string calldata note,
        uint256 value,
        uint256 date,
        uint256 share
    ) external onlyRole(MAINTAINER_ROLE) {
        emit AddedRealEstate(cadastralNumber, note, value, date, share);
    }

    function removeRealEstate(
        string calldata cadastralNumber,
        string calldata note,
        uint256 sellPrice,
        uint256 purchasePrice,
        uint256 date,
        uint256 share
    ) external onlyRole(MAINTAINER_ROLE) {
        emit RemovedRealEstate(
            cadastralNumber,
            note,
            sellPrice,
            purchasePrice,
            date,
            share
        );
    }

    function updateRealEstateValue(
        string calldata cadastralNumber,
        string calldata note,
        uint256 value,
        uint256 date
    ) external onlyRole(MAINTAINER_ROLE) {
        emit UpdatedRealEstateValue(
            cadastralNumber,
            note,
            value,
            date
        );
    }

    function updateBankAccountBalance(
        uint256 value,
        uint256 date
    ) external onlyRole(MAINTAINER_ROLE) {
        emit UpdatedBankAccountBalance(
            value,
            date
        );
    }
}