// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "hardhat/console.sol";
import "../interface/IPriceOracle.sol";

contract ManualPriceOracle is IPriceOracle {

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event SetPrice(address base, address anchor, uint64 timestamp, int256 price);

    address public admin;
    address public pendingAdmin;

    // bytes(base + anchor) => maturity => price
    mapping(bytes => mapping(uint256 => int256)) public manualPrice;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setPrice(
        address base_,
        address anchor_,
        uint64 timestamp_,
        int256 price_
    ) external onlyAdmin {
        bytes memory baseAnchor = abi.encodePacked(base_, anchor_);
        manualPrice[baseAnchor][timestamp_] = price_;
        emit SetPrice(base_, anchor_, timestamp_, price_);
    }

    function refreshPrice(
        address base_,
        address anchor_,
        uint64 fromDate_,
        uint64 toDate_
    ) external override {}

    function getPrice(
        address base_,
        address anchor_,
        uint64 fromDate_,
        uint64 toDate_
    ) external view override returns (int256) {
        fromDate_;
        bytes memory baseAnchor = abi.encodePacked(base_, anchor_);
        return manualPrice[baseAnchor][toDate_];
    }

    function setPendingAdmin(address newPendingAdmin_) external onlyAdmin {
        emit NewPendingAdmin(pendingAdmin, newPendingAdmin_);
        pendingAdmin = newPendingAdmin_;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "only pending admin");
        emit NewAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

}