// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./EGoldRate.sol";

contract EGoldRateFactory is AccessControl {
    using SafeCast for *;
    using SafeMath for uint256;
    using Address for address;

    event createInstance( address indexed _addr , address _lp );

    constructor() AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //Factory Fx
    function create(
        uint8 _ratetype,
        address _lp
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        EGoldRate instance = new EGoldRate( _ratetype , _lp ,  msg.sender );
        emit createInstance( address(instance) , _lp);
    }
    //Factory Fx

}