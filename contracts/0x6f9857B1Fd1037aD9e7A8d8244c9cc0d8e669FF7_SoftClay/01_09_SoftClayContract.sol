// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface PassportInterface {
    function increaseSoftClay(uint passportId, uint32 amount)external;
    function getSoftClay(uint passportId)external returns(uint32);
    function updateRank(uint256 tokenId, uint32 _pioneerLevel, uint32 _legendLevel)external;
    function decreaseSoftClay(uint passportId, uint32 amount)external;
}

contract SoftClay is AccessControl{
    address private PASSPORT_CONTRACT;
    PassportInterface PassContr;
    //defining the access roles
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    uint32 private _pioneerLevel = 10;
    uint32 private _legendLevel = 100;

    mapping(uint256 => uint32) _claimableSoftClay;

    constructor(address passport){
        require(passport != address(0));
        PASSPORT_CONTRACT = passport;
        PassContr = PassportInterface(PASSPORT_CONTRACT);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
    }
 
    function awardSoftClay(uint256 passportId, uint32 amount)external onlyRole(UPDATER_ROLE){
        // used to give people soft clay for doing good things
        PassContr.increaseSoftClay(passportId, amount);
        PassContr.updateRank(passportId, _pioneerLevel, _legendLevel);
    }

    function userClaimSoftClay(uint256 passportId)external {
        //ability for user to claim soft clay where they pay the gas. 
        uint32 clay = _claimableSoftClay[passportId];
        require(clay>0, "No clay to claim");
        PassContr.increaseSoftClay(passportId, clay);
        PassContr.updateRank(passportId, _pioneerLevel, _legendLevel);
        _claimableSoftClay[passportId] = 0;
    }

    function addClaimableSoftClay(uint[] calldata passportIds, uint32[] calldata amounts)external onlyRole(UPDATER_ROLE){
        require(passportIds.length == amounts.length, "Array lengths don't match");
        for(uint16 i; i< passportIds.length;i++){
            _claimableSoftClay[passportIds[i]] += amounts[i];
        }
    }

    function getClaimableClay(uint passportId)external view returns(uint32){
        return _claimableSoftClay[passportId];
    }

    function redeemSoftClay(uint256 passportId, uint32 amount) external onlyRole(UPDATER_ROLE){
        // spending the dust for something. This function reduces the balance
        // how you recive what you spent it on will be handled by other proceses

        // check have enough dust to redeem.
        require(PassContr.getSoftClay(passportId) >= amount,"Not enough dust in your balance");
        PassContr.decreaseSoftClay(passportId, amount);
        PassContr.updateRank(passportId, _pioneerLevel, _legendLevel);
    }

    function setPioneerLevel(uint32 level) external onlyRole(UPDATER_ROLE) {
        //set the number of soft clay you need to make the pioneer rank
        _pioneerLevel = level;
    }

    function setLegendLevel(uint32 level) external onlyRole(UPDATER_ROLE) {
        // set the number of soft clay an NFT needs to be legend rank
        _legendLevel = level;
    }

    function getPioneerLevel() external view returns (uint32) {
        //returns the number of soft clay at which the NFT's rank would increase to pioneer
        return _pioneerLevel;
    }

    function getLegendLevel() external view returns (uint32) {
        //returns the number of soft clay at which the NFT's rank would increase to legend
        return _legendLevel;
    }

    
}