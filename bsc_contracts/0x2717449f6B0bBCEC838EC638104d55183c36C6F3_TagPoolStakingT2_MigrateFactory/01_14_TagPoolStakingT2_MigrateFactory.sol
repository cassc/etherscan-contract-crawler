// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "../../../interfaces/iTagToken.sol";

import "./TagPoolStakingT2_Migrate.sol";

contract TagPoolStakingT2_MigrateFactory is AccessControl {
    using SafeCast for *;
    using SafeMath for uint256;
    using Address for address;


    uint256 private ctr;


    mapping(uint256 => address) private PoolStakingAddressMigration;

    event create(address indexed _POOLSTAKINGCONTRACT);

    constructor() public AccessControl() {

        ctr = 0;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //Factory Fx
    function createPool(
        address _dToken,
        address _Token
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ctr = ctr.add(1);
        TagPoolStakingT2_Migrate TPool = new TagPoolStakingT2_Migrate(_dToken,_Token , msg.sender);
        address TPA = address(TPool);
        PoolStakingAddressMigration[ctr] = TPA;
        emit create(TPA);
    }

    //Factory Fx

    function getPoolStakingMigrationCtr(uint256 _ctr) public view returns (address) {
        return PoolStakingAddressMigration[_ctr];
    }

    function getCtr() public view returns (uint256) {
        return ctr;
    }
}