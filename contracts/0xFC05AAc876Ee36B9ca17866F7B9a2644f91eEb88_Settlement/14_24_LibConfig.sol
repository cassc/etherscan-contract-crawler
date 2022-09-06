//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "../Types.sol";

library LibConfig {


    function store(Types.Config storage cs, Types.Config memory config) public {
        cs.devTeam = config.devTeam;
        cs.minFee = config.minFee;
        cs.penaltyFee = config.penaltyFee;
        cs.lockoutBlocks = config.lockoutBlocks;
        require(cs.devTeam != address(0), "Invalid dev team address");
    }

    function copy(Types.Config storage config) public view returns(Types.Config memory) {
        Types.Config memory cs;
        cs.devTeam = config.devTeam;
        cs.minFee = config.minFee;
        cs.penaltyFee = config.penaltyFee;
        cs.lockoutBlocks = config.lockoutBlocks;
        require(cs.devTeam != address(0), "Invalid dev team address");
        return cs;
    }
    

    //============== VIEWS ================/
    
    function getDevTeam(Types.Config storage _config) external view returns (address) {
        return _config.devTeam;
    }

    function getLockoutBlocks(Types.Config storage _config) external view returns (uint8) {
        return _config.lockoutBlocks;
    }

    function getMinFee(Types.Config storage _config) external view returns (uint128) {
        return _config.minFee;
    }

    function getPenaltyFee(Types.Config storage _config) external view returns (uint128) {
        return _config.penaltyFee;
    }

    //=============== MUTATIONS ============/

    function setDevTeam(Types.Config storage _config, address team) external{
        _config.devTeam = team;
    }

    function setLockoutBlocks(Types.Config storage _config, uint8 blocks) external{
        _config.lockoutBlocks = blocks;
    }

    function setMinFee(Types.Config storage _config, uint128 fee) external{
        _config.minFee = fee;
    }

    function setPenaltyFee(Types.Config storage _config, uint128 fee) external{
        _config.penaltyFee = fee;
    }
    
}