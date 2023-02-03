// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract RDNAdjustments is AccessControlEnumerable {
    bytes32 public constant ADJUST_ROLE = keccak256("ADJUSTSTRUCTINC_ROLE");

    struct Adjustment {
        uint structPointsInc;
        uint ownPointsInc;
        uint structPointsMin;
        uint ownPointsMin;
        uint levelMin;
        uint dirLevelMin;
    }

    mapping (uint => Adjustment) public adjustments;

    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ADJUST_ROLE, _admin);
    }

    function adjustUser(uint _userId, uint _structPointsInc, uint _ownPointsInc, uint _structPointsMin, uint _ownPointsMin, uint _levelMin, uint _dirLevelMin) public onlyRole(ADJUST_ROLE) {
        Adjustment memory adjustment = Adjustment(_structPointsInc, _ownPointsInc, _structPointsMin, _ownPointsMin, _levelMin, _dirLevelMin);
        adjustments[_userId] = adjustment;
    }

    function getAdjustment(uint _userId) public view returns(Adjustment memory) {
        return adjustments[_userId];
    }

}