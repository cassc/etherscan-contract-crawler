// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import '../core/Timelock.sol';
import './MasterChef.sol';
import '../interfaces/IBEP20.sol';

contract MasterChefTimelock is Timelock {

    mapping(address => bool) public existsPools;
    mapping(address => uint) public pidOfPool;
    mapping(uint256 => bool) public isExcludedPidUpdate;
    MasterChef masterChef;

    struct SetMigratorData {
        address migrator;
        uint timestamp;
        bool exists;
    }
    SetMigratorData setMigratorData;

    struct TransferOwnershipData {
        address newOwner;
        uint timestamp;
        bool exists;
    }
    TransferOwnershipData transferOwnershipData;

    struct TransferBabyTokenOwnershipData {
        address newOwner;
        uint timestamp;
        bool exists;
    }
    TransferBabyTokenOwnershipData transferBabyTokenOwnerShipData;

    struct TransferSyrupTokenOwnershipData {
        address newOwner;
        uint timestamp;
        bool exists;
    }
    TransferSyrupTokenOwnershipData transferSyrupTokenOwnerShipData;

    constructor(MasterChef masterChef_, address admin_, uint delay_) Timelock(admin_, delay_) {
        require(address(masterChef_) != address(0), "illegal masterChef address");
        require(admin_ != address(0), "illegal admin address");
        masterChef = masterChef_;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.?");
        _;
    }

    function excludedPidUpdate(uint256 _pid) external onlyAdmin{
        isExcludedPidUpdate[_pid] = true;
    }
    
    function includePidUpdate(uint256 _pid) external onlyAdmin{
        isExcludedPidUpdate[_pid] = false;
    }
    

    function addExistsPools(address pool, uint pid) external onlyAdmin {
        require(existsPools[pool] == false, "Timelock:: pair already exists");
        existsPools[pool] = true;
        pidOfPool[pool] = pid;
    }

    function delExistsPools(address pool) external onlyAdmin {
        require(existsPools[pool] == true, "Timelock:: pair not exists");
        delete existsPools[pool];
        delete pidOfPool[pool];
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyAdmin {
        masterChef.updateMultiplier(multiplierNumber);
    }

    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate) external onlyAdmin {
        require(address(_lpToken) != address(0), "_lpToken address cannot be 0");
        require(existsPools[address(_lpToken)] == false, "Timelock:: pair already exists");
        _lpToken.balanceOf(msg.sender);
        uint pid = masterChef.poolLength();
        masterChef.add(_allocPoint, _lpToken, false);
        if(_withUpdate){
            massUpdatePools();
        }
        pidOfPool[address(_lpToken)] = pid;
        existsPools[address(_lpToken)] = true;
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyAdmin {
        require(_pid < masterChef.poolLength(), 'Pool does not exist');

        masterChef.set(_pid, _allocPoint, false);
        if(_withUpdate){
            massUpdatePools();
        }
    }

    function massUpdatePools() public {
        uint256 length = masterChef.poolLength();
        for (uint256 pid = 0; pid < length; ++pid) {
            if(!isExcludedPidUpdate[pid]){
                masterChef.updatePool(pid);
            }
        }
    }

    function setMigrator(IMigratorChef _migrator) external onlyAdmin {
        require(address(_migrator) != address(0), "_migrator address cannot be 0");
        if (setMigratorData.exists) {
            cancelTransaction(address(masterChef), 0, "", abi.encodeWithSignature("setMigrator(address)", address(_migrator)), setMigratorData.timestamp);
        }
        queueTransaction(address(masterChef), 0, "", abi.encodeWithSignature("setMigrator(address)", address(_migrator)), block.timestamp + delay);
        setMigratorData.migrator = address(_migrator);
        setMigratorData.timestamp = block.timestamp + delay;
        setMigratorData.exists = true;
    }

    function executeSetMigrator() external onlyAdmin {
        require(setMigratorData.exists, "Timelock::setMigrator not prepared");
        executeTransaction(address(masterChef), 0, "", abi.encodeWithSignature("setMigrator(address)", address(setMigratorData.migrator)), setMigratorData.timestamp);
        setMigratorData.migrator = address(0);
        setMigratorData.timestamp = 0;
        setMigratorData.exists = false;
    }
    /*
    function transferBabyTokenOwnerShip(address newOwner_) external onlyAdmin { 
        masterChef.transferBabyTokenOwnerShip(newOwner_);
    }

    function transferSyrupOwnerShip(address newOwner_) external onlyAdmin { 
        masterChef.transferSyrupOwnerShip(newOwner_);
    }
    */

    function transferBabyTokenOwnerShip(address newOwner) external onlyAdmin {
        if (transferBabyTokenOwnerShipData.exists) {
            cancelTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferBabyTokenOwnerShip(address)", transferBabyTokenOwnerShipData.newOwner), transferBabyTokenOwnerShipData.timestamp);
        }
        queueTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferBabyTokenOwnerShip(address)", address(newOwner)), block.timestamp + delay);
        transferBabyTokenOwnerShipData.newOwner = newOwner;
        transferBabyTokenOwnerShipData.timestamp = block.timestamp + delay;
        transferBabyTokenOwnerShipData.exists = true;
    }

    function executeTransferBabyOwnership() external onlyAdmin {
        require(transferBabyTokenOwnerShipData.exists, "Timelock::setMigrator not prepared");
        executeTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferBabyTokenOwnerShip(address)", address(transferBabyTokenOwnerShipData.newOwner)), transferBabyTokenOwnerShipData.timestamp);
        transferBabyTokenOwnerShipData.newOwner = address(0);
        transferBabyTokenOwnerShipData.timestamp = 0;
        transferBabyTokenOwnerShipData.exists = false;
    }

    function transferSyrupTokenOwnerShip(address newOwner) external onlyAdmin {
        if (transferSyrupTokenOwnerShipData.exists) {
            cancelTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferSyrupOwnerShip(address)", transferSyrupTokenOwnerShipData.newOwner), transferSyrupTokenOwnerShipData.timestamp);
        }
        queueTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferSyrupOwnerShip(address)", address(newOwner)), block.timestamp + delay);
        transferSyrupTokenOwnerShipData.newOwner = newOwner;
        transferSyrupTokenOwnerShipData.timestamp = block.timestamp + delay;
        transferSyrupTokenOwnerShipData.exists = true;
    }

    function executeTransferSyrupOwnership() external onlyAdmin {
        require(transferSyrupTokenOwnerShipData.exists, "Timelock::setMigrator not prepared");
        executeTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferSyrupOwnerShip(address)", address(transferSyrupTokenOwnerShipData.newOwner)), transferSyrupTokenOwnerShipData.timestamp);
        transferSyrupTokenOwnerShipData.newOwner = address(0);
        transferSyrupTokenOwnerShipData.timestamp = 0;
        transferSyrupTokenOwnerShipData.exists = false;
    }

    function transferOwnership(address newOwner) external onlyAdmin {
        if (transferOwnershipData.exists) {
            cancelTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferOwnership(address)", transferOwnershipData.newOwner), transferOwnershipData.timestamp);
        }
        queueTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferOwnership(address)", address(newOwner)), block.timestamp + delay);
        transferOwnershipData.newOwner = newOwner;
        transferOwnershipData.timestamp = block.timestamp + delay;
        transferOwnershipData.exists = true;
    }

    function executeTransferOwnership() external onlyAdmin {
        require(transferOwnershipData.exists, "Timelock::setMigrator not prepared");
        executeTransaction(address(masterChef), 0, "", abi.encodeWithSignature("transferOwnership(address)", address(transferOwnershipData.newOwner)), transferOwnershipData.timestamp);
        transferOwnershipData.newOwner = address(0);
        transferOwnershipData.timestamp = 0;
        transferOwnershipData.exists = false;
    }

}