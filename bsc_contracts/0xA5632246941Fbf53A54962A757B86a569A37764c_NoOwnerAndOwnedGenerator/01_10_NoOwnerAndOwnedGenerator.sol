// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20_OwnedAndNot.sol";


contract NoOwnerAndOwnedGenerator {
    FactoryNoOwnerFixedNoMintNoBurnNoPause immutable factoryNoOwnerFixedNoMintNoBurnNoPause;
    FactoryNoOwnerFixedNoMintCanBurnNoPause immutable factoryNoOwnerFixedNoMintCanBurnNoPause;
    FactoryOwnedFixedNoMintNoBurnNoPause immutable factoryOwnedFixedNoMintNoBurnNoPause;
    FactoryOwnedFixedNoMintCanBurnNoPause immutable factoryOwnedFixedNoMintCanBurnNoPause;
    FactoryOwnedFixedNoMintNoBurnCanPause immutable factoryOwnedFixedNoMintNoBurnCanPause;
    FactoryOwnedFixedNoMintCanBurnCanPause immutable factoryOwnedFixedNoMintCanBurnCanPause;
    FactoryOwnedUnlimitCanMintCanBurnCanPause immutable factoryOwnedUnlimitCanMintCanBurnCanPause;
    FactoryOwnedUnlimitCanMintNoBurnCanPause immutable factoryOwnedUnlimitCanMintNoBurnCanPause;
    FactoryOwnedUnlimitCanMintNoBurnNoPause immutable factoryOwnedUnlimitCanMintNoBurnNoPause;
    FactoryOwnedUnlimitCanMintCanBurnNoPause immutable factoryOwnedUnlimitCanMintCanBurnNoPause;
    FactoryOwnedCappedCanMintCanBurnCanPause immutable factoryOwnedCappedCanMintCanBurnCanPause;
    FactoryOwnedCappedCanMintNoBurnCanPause immutable factoryOwnedCappedCanMintNoBurnCanPause;
    FactoryOwnedCappedCanMintCanBurnNoPause immutable factoryOwnedCappedCanMintCanBurnNoPause;
    FactoryOwnedCappedCanMintNoBurnNoPause immutable factoryOwnedCappedCanMintNoBurnNoPause;
    

    constructor(){
        factoryNoOwnerFixedNoMintNoBurnNoPause = new FactoryNoOwnerFixedNoMintNoBurnNoPause();
        factoryNoOwnerFixedNoMintCanBurnNoPause = new FactoryNoOwnerFixedNoMintCanBurnNoPause();
        factoryOwnedFixedNoMintNoBurnNoPause = new FactoryOwnedFixedNoMintNoBurnNoPause();
        factoryOwnedFixedNoMintCanBurnNoPause = new FactoryOwnedFixedNoMintCanBurnNoPause();
        factoryOwnedFixedNoMintNoBurnCanPause = new FactoryOwnedFixedNoMintNoBurnCanPause();
        factoryOwnedFixedNoMintCanBurnCanPause = new FactoryOwnedFixedNoMintCanBurnCanPause();
        factoryOwnedUnlimitCanMintCanBurnCanPause = new FactoryOwnedUnlimitCanMintCanBurnCanPause();
        factoryOwnedUnlimitCanMintNoBurnCanPause = new FactoryOwnedUnlimitCanMintNoBurnCanPause();
        factoryOwnedUnlimitCanMintNoBurnNoPause = new FactoryOwnedUnlimitCanMintNoBurnNoPause();
        factoryOwnedUnlimitCanMintCanBurnNoPause = new FactoryOwnedUnlimitCanMintCanBurnNoPause();
        factoryOwnedCappedCanMintCanBurnCanPause = new FactoryOwnedCappedCanMintCanBurnCanPause();
        factoryOwnedCappedCanMintNoBurnCanPause = new FactoryOwnedCappedCanMintNoBurnCanPause();
        factoryOwnedCappedCanMintCanBurnNoPause = new FactoryOwnedCappedCanMintCanBurnNoPause();
        factoryOwnedCappedCanMintNoBurnNoPause = new FactoryOwnedCappedCanMintNoBurnNoPause();

    }

    mapping(address => address[]) ownerToTokenTable;

    function getTokenAdress(address owner) public view returns (address[] memory) {
        return ownerToTokenTable[owner];
    }


    function CreateNoOwnerFixedNoMintNoBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        NoOwnerFixedNoMintNoBurnNoPause token = factoryNoOwnerFixedNoMintNoBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateNoOwnerFixedNoMintCanBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        NoOwnerFixedNoMintCanBurnNoPause token = factoryNoOwnerFixedNoMintCanBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedFixedNoMintNoBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        OwnedFixedNoMintNoBurnNoPause token = factoryOwnedFixedNoMintNoBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedFixedNoMintNoBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        OwnedFixedNoMintNoBurnCanPause token = factoryOwnedFixedNoMintNoBurnCanPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedFixedNoMintCanBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        OwnedFixedNoMintCanBurnCanPause token = factoryOwnedFixedNoMintCanBurnCanPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedFixedNoMintCanBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        OwnedFixedNoMintCanBurnNoPause token = factoryOwnedFixedNoMintCanBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedUnlimitCanMintCanBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        OwnedUnlimitCanMintCanBurnCanPause token = factoryOwnedUnlimitCanMintCanBurnCanPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedUnlimitCanMintNoBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        OwnedUnlimitCanMintNoBurnCanPause token = factoryOwnedUnlimitCanMintNoBurnCanPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedUnlimitCanMintNoBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        OwnedUnlimitCanMintNoBurnNoPause token = factoryOwnedUnlimitCanMintNoBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedUnlimitCanMintCanBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns(address) {
                        
                        OwnedUnlimitCanMintCanBurnNoPause token = factoryOwnedUnlimitCanMintCanBurnNoPause.create(name,symbol,initialSupply,owner,decimals);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedCappedCanMintCanBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns(address) {
                        
                        OwnedCappedCanMintCanBurnCanPause token = factoryOwnedCappedCanMintCanBurnCanPause.create(name,symbol,initialSupply,owner,decimals,_cap);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedCappedCanMintNoBurnCanPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns(address) {
                        
                        OwnedCappedCanMintNoBurnCanPause token = factoryOwnedCappedCanMintNoBurnCanPause.create(name,symbol,initialSupply,owner,decimals,_cap);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedCappedCanMintCanBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns(address) {
                        
                        OwnedCappedCanMintCanBurnNoPause token = factoryOwnedCappedCanMintCanBurnNoPause.create(name,symbol,initialSupply,owner,decimals,_cap);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }

    function CreateOwnedCappedCanMintNoBurnNoPause(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns(address) {
                        
                        OwnedCappedCanMintNoBurnNoPause token = factoryOwnedCappedCanMintNoBurnNoPause.create(name,symbol,initialSupply,owner,decimals,_cap);
                        ownerToTokenTable[owner].push(address(token));
                        return address(token);
    }













    
                                                       
                        

}