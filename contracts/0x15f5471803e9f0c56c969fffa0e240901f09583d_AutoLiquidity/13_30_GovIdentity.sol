// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../storage/GovIdentityStorage.sol";

/// @title manager role
/// @notice provide a unified identity address pool
contract GovIdentity {

    constructor() {
        _init();
    }

    function _init() internal{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = msg.sender;
        identity.rewards = msg.sender;
        identity.strategist[msg.sender]=true;
        identity.admin[msg.sender]=true;
    }

    modifier onlyAdmin() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(isAdmin(msg.sender), "!admin");
        _;
    }

    modifier onlyStrategist() {
        require(isStrategist(msg.sender), "!strategist");
        _;
    }

    modifier onlyGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(msg.sender == identity.governance, "!governance");
        _;
    }

    modifier onlyStrategistOrGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(identity.strategist[msg.sender] || msg.sender == identity.governance, "!governance and !strategist");
        _;
    }

    modifier onlyAdminOrGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(identity.admin[msg.sender] || msg.sender == identity.governance, "!governance and !admin");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = _governance;
    }

    function setRewards(address _rewards) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.rewards = _rewards;
    }

    function setStrategist(address _strategist,bool enable) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.strategist[_strategist]=enable;
    }

    function setAdmin(address _admin,bool enable) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.admin[_admin]=enable;
    }

    function getGovernance() public view returns(address){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.governance;
    }

    function getRewards() public view returns(address){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.rewards ;
    }

    function isStrategist(address _strategist) public view returns(bool){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.strategist[_strategist];
    }

    function isAdmin(address _admin) public view returns(bool){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.admin[_admin];
    }


}