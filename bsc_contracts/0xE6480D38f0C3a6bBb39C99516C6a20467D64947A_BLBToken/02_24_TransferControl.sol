// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./Administration.sol";

/**
 * @title control BLB transfers.
 * @notice users may have access to transfer their whole BLB balance or only a 
 * certain fraction every month(it depends on monthlyLimit).
 * @notice some specific addresses may have restricted access to transfer.
 * @notice owner of the contract can restrict every desired address and also 
 * determine a spending limit for all users.
 * @notice if an address is restricted then the public monthlyLimit is deactivated
 * for it
 */
abstract contract TransferControl is ERC20Capped, Administration {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableMap.AddressToUintMap restrictedAddresses;
    
    struct Month {
        uint256 spent;
        uint256 nonce;
    }

    mapping(address => Month) checkpoints;

    uint256 constant monthlyTime = 30 days;
    uint256 immutable startTime;

   /**
     * @return fraction the numerator of monthly transfer limit rate which denominator
     * is 10**6.
     */ 
    uint256 public monthlyLimit;

    constructor() {
        startTime = block.timestamp;
    }

    /**
     * @dev emits when the admin sets a new value as the monthlyLimit.
     */
    event SetMonthlyTransferLimit(uint256 fraction);

    /**
     * @dev emits when the admin restricts an address.
     */
    event Restrict(address addr, uint256 amount);

    /**
     * @dev emits when the admin districts an address.
     */
    event District(address addr);

    /**
     * @notice set spend limit for monthly transfers.
     * @notice there is no transfer limit if fraction is 10**6.
     *
     * @param fraction the numerator of transfer limit rate which denominator
     * is 10**6.
     *
     * @notice require:
     *  - only owner of contract can call this function.
     *  - maximum fraction can be 10**6 (equal to 100%).
     * 
     * @notice emits a SetMonthlyTransferLimit event.
     */
    function setMonthlyTransferLimit(uint256 fraction) 
        public 
        onlyRole(TRANSFER_LIMIT_SETTER)
    {
        require(fraction <= 10 ** 6, "TransferControl: maximum fraction is 10**6 (equal to 100%)");
        monthlyLimit = fraction;

        emit SetMonthlyTransferLimit(fraction);
    }

    /**
     * @notice restrict an address 
     * @notice the address `addr` will be only able to spend as much as `amount`.
     *
     * @param addr the restricted address.
     * @param amount restricted spendable amount.
     *
     * @notice require:
     *  - only RESTRICTOR_ROLE address can call this function.
     * 
     * @notice emits a Restrict event.
     */
    function restrict(address addr, uint256 amount) public onlyRole(RESTRICTOR_ROLE) {
        restrictedAddresses.set(addr, amount);
        emit Restrict(addr, amount);
    }

    /**
     * @notice district an address 
     * @notice the address `addr` will be free to spend their BLB like regular
     * addresses.
     *
     * @param addr the address that is going to be districted.
     *
     * @notice require:
     *  - only RESTRICTOR_ROLE address can call this function.
     * 
     * @notice emits a District event.
     */
    function district(address addr) public onlyRole(RESTRICTOR_ROLE) {
        restrictedAddresses.remove(addr);
    }

    /**
     * @return boolean true if the address is restricted.
     *
     * @param addr the address that is going to be checked.
     */
    function isRestricted(address addr) public view returns(bool) {
        return restrictedAddresses.contains(addr);
    }

    /**
     * @return amount that the address can spend.
     * 
     * @dev if the address restricted, the amount equals remaining spendable amount for the 
     * address. else if there is a spend limit active for the contract, the amount equals 
     * the address's remaining monthly spendable amount. else the amount equals balance of the
     * address.
     * 
     * @dev MINTER_ROLE can also be restricted so
     * 
     * @param addr the address that is being checked.
     */
    function canSpend(address addr) public view returns(uint256 amount) {
        if (isRestricted(addr)){
            return restrictedAddresses.get(addr);
        } else if(hasRole(MINTER_ROLE, addr)) {
            return cap() - totalSupply();
        } else {
            if(monthlyLimit == 10 ** 6){
                return balanceOf(addr);
            } else {
                uint256 spentAmount;
                if(checkpoints[addr].nonce == (block.timestamp - startTime) / monthlyTime) {
                    spentAmount = checkpoints[addr].spent;
                }
                uint256 monthlyAmount = (balanceOf(addr) + spentAmount) * monthlyLimit / 10 ** 6;
                return monthlyAmount - spentAmount;
            }
        }
    }

    function _spend(address addr, uint256 amount) internal {
        if(isRestricted(addr)) {
            uint256 spendableAmount = restrictedAddresses.get(addr);
            require(amount <= spendableAmount, "TransferControl: amount exceeds spend limit");
            restrictedAddresses.set(addr, spendableAmount - amount);
        } else if (monthlyLimit < 10 ** 6 && !hasRole(MINTER_ROLE, addr)) {
            uint256 currentNonce = (block.timestamp - startTime) / monthlyTime;
            uint256 spentAmount;
            if(checkpoints[addr].nonce == currentNonce) {
                spentAmount = checkpoints[addr].spent;
            }
            uint256 spendingAmount = spentAmount + amount;
            uint256 monthlyAmount = (balanceOf(addr) + spentAmount) * monthlyLimit / 10 ** 6;
            require(spendingAmount <= monthlyAmount, "TransferControl: amount exceeds monthly spend limit");
            checkpoints[addr] = Month(spendingAmount, currentNonce);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        _spend(_msgSender(), amount);

        super._beforeTokenTransfer(from, to, amount);
    }

    function _pureTransfer(address from, address to, uint256 amount) 
        internal 
        virtual
        override 
    {
        _spend(from, amount);
        
        super._pureTransfer(from, to, amount);
    }
}