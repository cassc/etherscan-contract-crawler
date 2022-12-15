// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IRate.sol";

contract Rate is IRate, AccessControl {

    struct RateStruct {
        uint256 price;
        uint256 singleApy;
        uint256 lpApy;
        uint256 updatedAt;
        uint256 createdAt;
        uint256 deletedAt;
    }

    mapping(bytes32 => RateStruct) public override rates;

    event RateCreatedEvent(bytes32 indexed _rateHash, uint256 _price, uint256 _createdAt);
    event RateUpdatedEvent(bytes32 indexed _rateHash, uint256 _price, uint256 _updatedAt);
    event RateDeletedEvent(bytes32 indexed _rateHash, uint256 _deletedAt);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function isActive(bytes32 _rateHash) external view override returns (bool) {
        return rates[_rateHash].createdAt > 0 && rates[_rateHash].deletedAt == 0;
    }

    function createRate(
        bytes32 _rateHash,
        uint256 _price,
        uint256 _singleApy,
        uint256 _lpApy
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        RateStruct storage rate = rates[_rateHash];

        require(rate.createdAt == 0, "created");
        require(_price > 0, "_price");
        require(_singleApy > 0, "_singleApy");
        require(_lpApy > 0, "_lpApy");

        rate.price = _price;
        rate.singleApy = _singleApy;
        rate.lpApy = _lpApy;
        rate.updatedAt = block.timestamp;
        rate.createdAt = block.timestamp;

        emit RateCreatedEvent(_rateHash, rate.price, rate.createdAt);
    }

    function updateRate(
        bytes32 _rateHash,
        uint256 _price,
        uint256 _singleApy,
        uint256 _lpApy
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        RateStruct storage rate = rates[_rateHash];

        require(rate.createdAt > 0, "created");
        require(rate.deletedAt == 0, "deletad");
        require(_price > 0, "_price");
        require(_singleApy > 0, "_singleApy");
        require(_lpApy > 0, "_lpApy");

        rate.price = _price;
        rate.singleApy = _singleApy;
        rate.lpApy = _lpApy;
        rate.updatedAt = block.timestamp;

        emit RateUpdatedEvent(_rateHash, rate.price, rate.updatedAt);
    }

    function deleteRate(bytes32 _rateHash) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        RateStruct storage rate = rates[_rateHash];

        require(rate.createdAt > 0, "created");
        require(rate.deletedAt == 0, "deletad");

        rate.deletedAt = block.timestamp;

        emit RateDeletedEvent(_rateHash, rate.deletedAt);
    }

}