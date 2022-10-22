// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20_Role.sol";

contract RoleGenerator {

    FactoryRoleFixedNoMintNoBurnNoPause immutable factoryRoleFixedNoMintNoBurnNoPause;
    FactoryRoleFixedNoMintCanBurnNoPause immutable factoryRoleFixedNoMintCanBurnNoPause;
    FactoryRoleFixedNoMintNoBurnCanPause immutable factoryRoleFixedNoMintNoBurnCanPause;
    FactoryRoleFixedNoMintCanBurnCanPause immutable factoryRoleFixedNoMintCanBurnCanPause;
    FactoryRoleUnlimitCanMintCanBurnCanPause immutable factoryRoleUnlimitCanMintCanBurnCanPause;
    FactoryRoleUnlimitCanMintNoBurnCanPause immutable factoryRoleUnlimitCanMintNoBurnCanPause;
    FactoryRoleUnlimitCanMintNoBurnNoPause immutable factoryRoleUnlimitCanMintNoBurnNoPause;
    FactoryRoleUnlimitCanMintCanBurnNoPause immutable factoryRoleUnlimitCanMintCanBurnNoPause;
    FactoryRoleCappedCanMintCanBurnCanPause immutable factoryRoleCappedCanMintCanBurnCanPause;
    FactoryRoleCappedCanMintNoBurnCanPause immutable factoryRoleCappedCanMintNoBurnCanPause;
    FactoryRoleCappedCanMintCanBurnNoPause immutable factoryRoleCappedCanMintCanBurnNoPause;
    FactoryRoleCappedCanMintNoBurnNoPause immutable factoryRoleCappedCanMintNoBurnNoPause;

    constructor(){

        factoryRoleFixedNoMintNoBurnNoPause = new FactoryRoleFixedNoMintNoBurnNoPause();
        factoryRoleFixedNoMintCanBurnNoPause = new FactoryRoleFixedNoMintCanBurnNoPause();
        factoryRoleFixedNoMintNoBurnCanPause = new FactoryRoleFixedNoMintNoBurnCanPause();
        factoryRoleFixedNoMintCanBurnCanPause = new FactoryRoleFixedNoMintCanBurnCanPause();
        factoryRoleUnlimitCanMintCanBurnCanPause = new FactoryRoleUnlimitCanMintCanBurnCanPause();
        factoryRoleUnlimitCanMintNoBurnCanPause = new FactoryRoleUnlimitCanMintNoBurnCanPause();
        factoryRoleUnlimitCanMintNoBurnNoPause = new FactoryRoleUnlimitCanMintNoBurnNoPause();
        factoryRoleUnlimitCanMintCanBurnNoPause = new FactoryRoleUnlimitCanMintCanBurnNoPause();
        factoryRoleCappedCanMintCanBurnCanPause = new FactoryRoleCappedCanMintCanBurnCanPause();
        factoryRoleCappedCanMintNoBurnCanPause = new FactoryRoleCappedCanMintNoBurnCanPause();
        factoryRoleCappedCanMintCanBurnNoPause = new FactoryRoleCappedCanMintCanBurnNoPause();
        factoryRoleCappedCanMintNoBurnNoPause = new FactoryRoleCappedCanMintNoBurnNoPause();
    }

    mapping(address => address[]) ownerToTokenTable;



    function getTokenAdress(address owner) public view returns (address[] memory) {
        return ownerToTokenTable[owner];
    }



    function CreateRoleFixedNoMintNoBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        RoleFixedNoMintNoBurnNoPause token = factoryRoleFixedNoMintNoBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleFixedNoMintNoBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        RoleFixedNoMintNoBurnCanPause token = factoryRoleFixedNoMintNoBurnCanPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleFixedNoMintCanBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        RoleFixedNoMintCanBurnCanPause token = factoryRoleFixedNoMintCanBurnCanPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleFixedNoMintCanBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        RoleFixedNoMintCanBurnNoPause token = factoryRoleFixedNoMintCanBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleUnlimitCanMintCanBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        RoleUnlimitCanMintCanBurnCanPause token = factoryRoleUnlimitCanMintCanBurnCanPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleUnlimitCanMintNoBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        RoleUnlimitCanMintNoBurnCanPause token = factoryRoleUnlimitCanMintNoBurnCanPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleUnlimitCanMintNoBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        RoleUnlimitCanMintNoBurnNoPause token = factoryRoleUnlimitCanMintNoBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleUnlimitCanMintCanBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        RoleUnlimitCanMintCanBurnNoPause token = factoryRoleUnlimitCanMintCanBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleCappedCanMintCanBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns(address) {
                        
                        RoleCappedCanMintCanBurnCanPause token = factoryRoleCappedCanMintCanBurnCanPause.create(name,symbol,initialSupply,owner,decimals,_cap);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleCappedCanMintNoBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns(address) {
                        
                        RoleCappedCanMintNoBurnCanPause token = factoryRoleCappedCanMintNoBurnCanPause.create(name,symbol,initialSupply,owner,decimals,_cap);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleCappedCanMintCanBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns(address) {
                        
                        RoleCappedCanMintCanBurnNoPause token = factoryRoleCappedCanMintCanBurnNoPause.create(name,symbol,initialSupply,owner,decimals,_cap);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateRoleCappedCanMintNoBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns(address) {
                        
                        RoleCappedCanMintNoBurnNoPause token = factoryRoleCappedCanMintNoBurnNoPause.create(name,symbol,initialSupply,owner,decimals,_cap);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    
                                                       
                        

}