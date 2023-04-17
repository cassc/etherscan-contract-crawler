//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../library/EGoldUtils.sol";
import "../../../interfaces/iEGoldIdentity.sol";

contract EGoldMigrator3 is AccessControl {
    using SafeMath for uint256;

    IEGoldIdentity Identity;

    constructor() AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setup( address _identity ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Identity = IEGoldIdentity(_identity);
    }

    function bulkMigrator( address[] memory addr , EGoldUtils.userData[] memory userData ) external onlyRole(DEFAULT_ADMIN_ROLE){
        require( addr.length == userData.length , "EGoldMigrator : Invalid length");
        for (uint256 i = 0; i <= addr.length ; i += 1 ) {
            Identity.setUser( addr[i] , userData[i]);
        }
    }

}