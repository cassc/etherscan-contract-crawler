// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.8;

import "@nomiclabs/buidler/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Vault is ERC20 {
    using SafeMath for uint256;

    struct entityStruct {
        address id;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 lastWithdrawTime;
        uint256 startTime;
        uint256 endTime;
        uint256 trancheInSecs;
    }

    mapping (address => entityStruct) private _beneficiary;

    // token details
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;

    //  start time
    uint256 private _startTime;

    // total amount of tokens issued    
    uint256 private _totalIssued;

    // entities
    entityStruct[] private _entities;

    // registrar
    address private _registrar;

    // confirmed
    bool private _finalized = false;

    event Claimed(address member, uint256 amount, uint256 claimTime);
    event Registered(address member, uint256 totalAmount, uint256 startTime, uint256 endTime, uint256 trancheTime);
    event Finalized(uint256 time);

    constructor (string memory name, string memory symbol, uint256 supply, uint256 startTime, address registrar) ERC20(name, symbol) public {
        require(supply > 0, "invalid supply");
        require(registrar != address(0), "invalid registrar");
        
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _totalSupply = supply * (10 ** uint256(_decimals));
        _startTime = startTime;
        _registrar = registrar;

        _mint(address(this), _totalSupply);
    }

    function register(address id, uint256 entityTotalAmount, uint256 entityStartTime, uint256 entityEndTime, uint256  entityTrancheInSecs) public returns (bool) {
        require(msg.sender == _registrar, "only registrar can add entries");
        require(_finalized != true, "registration already completed");
        require(_beneficiary[id].totalAmount == 0, "entity allocation already exists");
        require(0 < entityTotalAmount && entityTotalAmount <= _totalSupply, "illegal total amount");
        require(_startTime <= entityStartTime, "entity start time must be later than token start time");
        require(entityStartTime <= entityEndTime, "end time can not be before start time");
        require(entityTrancheInSecs <= entityEndTime.sub(entityStartTime), "allocation time can not be less than tranche");
        require( _totalIssued.add(entityTotalAmount) <= _totalSupply, "total allocation is greater than supply");

        uint256 entityLastWithdrawTime = _startTime;
        uint256 entityClaimedAmount = 0;

        entityStruct memory entity = entityStruct(id, entityTotalAmount, entityClaimedAmount, entityLastWithdrawTime, entityStartTime, entityEndTime, entityTrancheInSecs);

        _beneficiary[id] = entity;        

        _totalIssued = _totalIssued.add(entityTotalAmount);

        _entities.push(entity);

        emit Registered(id, entityTotalAmount, entityStartTime, entityEndTime, entityTrancheInSecs);
        
        return true;
    }

    function finalize() public returns (bool) {
        require(_finalized != true, "already finalized");
        require(msg.sender == _registrar, "only registrar can finalize");
        require(block.timestamp <= _startTime, "not finalized in time");
        
        _finalized = true;

        emit Finalized(block.timestamp);
        return true;
    }

    function members() public view returns (uint256) {
        return _entities.length;
    }

    function isReady() public view returns (bool) {
        return _finalized;
    }

    function registrar() public view returns (address) {
        return _registrar;
    }

    function totalIssued() public view returns (uint256) {
        return _totalIssued;
    }

    function startTime() public view returns (uint256) {
        return _startTime;
    }

    function beneficiary(address id) public view returns (entityStruct memory) {
        return (_beneficiary[id]);
    }

    function _claimAmount(entityStruct memory benefactor) internal view returns (uint256) {
        uint256 totalTranches;

        if (benefactor.trancheInSecs == 0) {
            totalTranches = 1;
        } else {
            totalTranches = benefactor.endTime.sub(benefactor.startTime).div(benefactor.trancheInSecs);
        }
        
        uint256 amountPerTranche;

        if (totalTranches == 0) {
            amountPerTranche = 0;
        } else {
            amountPerTranche = benefactor.totalAmount.div(totalTranches);
        }

        uint256 claimableTranches;

        if (benefactor.trancheInSecs == 0) {
            claimableTranches =  1;
        } else {
            claimableTranches = block.timestamp.sub(benefactor.lastWithdrawTime).div(benefactor.trancheInSecs);
        }

        uint256 claimableAmount = amountPerTranche.mul(claimableTranches);
        
        if (benefactor.endTime <= block.timestamp) {
            claimableAmount = benefactor.totalAmount.sub(benefactor.claimedAmount);
        }

        return claimableAmount;
    }

    function claimable(address id) public view returns (uint256) {
        entityStruct storage benefactor = _beneficiary[id];

        if (benefactor.totalAmount == 0
            || _finalized == false
            || block.timestamp < _startTime 
            || block.timestamp < benefactor.startTime
            || benefactor.claimedAmount == benefactor.totalAmount
            || block.timestamp.sub(benefactor.lastWithdrawTime) < benefactor.trancheInSecs) {
                return 0;
        } else {
            return _claimAmount(benefactor);
        }
    }

    /*
        @dev allows registered entities to withdraw tokens once a tranche has passed. A tranche is defined in seconds. In order for an entity to be eligible for withdraw, the contract state first must be "completed" (all entities have been registered) and the current block timestamp must be later than the contract's start time. 
        
        Entity requirements include the following logic: an entity's withdraw start time must be later than the current block timestamp, an entity must have remaining allocation to withdraw and the tranche time is less than the difference between the entity's last withdraw and the current block timestamp. With all these requirements passing, the total number of tranches is calculated to determine the amount of tokens to allocate per tranche. From this, the number of claimable tranches can be derived to determine the number of tokens to transfer to the entity once allocation updates have been performed. 
        
        NOTE : for entities that are allowed to withdraw immediately, the tranche is registered to zero. In withdraw, there is a check for this convention which prevents division by zero and allows entity to withdraw immediately regardless of end time.
    */
    function withdraw() public returns (bool) {
        require (_finalized == true, "token allocations have not been completed");
        require(_startTime < block.timestamp, "allocations have not started");

        entityStruct storage benefactor = _beneficiary[msg.sender];

        require(benefactor.startTime < block.timestamp, "can not withdraw yet");
        require(benefactor.claimedAmount < benefactor.totalAmount, "no tokens to withdraw");
        require(benefactor.trancheInSecs < block.timestamp.sub(benefactor.lastWithdrawTime), "no tokens to claim");

        uint256 claimableAmount = _claimAmount(benefactor);
        benefactor.lastWithdrawTime = block.timestamp;
        benefactor.claimedAmount = benefactor.claimedAmount.add(claimableAmount);

        require(this.transfer(msg.sender, claimableAmount), "token transfer failed");

        emit Claimed(msg.sender, claimableAmount, block.timestamp);
        
        return true;
    }
}