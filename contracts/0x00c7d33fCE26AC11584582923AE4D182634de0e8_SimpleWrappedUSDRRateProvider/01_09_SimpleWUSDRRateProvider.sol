// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./constants/roles.sol";
import "./interfaces/IRateProvider.sol";

contract SimpleWrappedUSDRRateProvider is AccessControl, IRateProvider {
    uint256 private _rate;

    constructor(uint256 initialRate) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _rate = initialRate;
    }

    function getRate() external view override returns (uint256) {
        return _rate;
    }

    function setRate(uint256 rate) external onlyRole(CONTROLLER_ROLE) {
        require(rate > _rate, "rate cant be lower than current rate");
        _rate = rate;
    }
}