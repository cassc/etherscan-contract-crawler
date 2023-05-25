// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./StandardToken.sol";


abstract contract AccountStorage is StandardToken {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    struct AccountData {
        address sponsor;
        uint256 balance;
        uint256 selfBuy;
        uint256 directBonus;
        uint256 reinvestedAmount;
        uint256 withdrawnAmount;
        int256 stakingValue;
    }


    struct MigrationData {
        address account;
        address sponsor;
        uint256 tokensToMint;
        uint256 selfBuy;
    }


    bool private _accountsMigrated = false;

    EnumerableSet.AddressSet private _accounts;
    mapping (address => AccountData) private _accountsData;

    bytes32 constant public ACCOUNT_MANAGER_ROLE = keccak256("ACCOUNT_MANAGER_ROLE");

    event AccountCreation(address indexed account, address indexed sponsor);
    event AccountMigrationFinished();
    event DirectBonusPaid(address indexed account, address indexed fromAccount, uint256 amountOfEthereum);
    event AccountSponsorUpdated(address indexed account, address indexed oldSponsor, address indexed newSponsor);


    modifier isRegistered(address account) {
        require(_accountsMigrated, "AccountStorage: account data isn't migrated yet, try later");
        require(hasAccount(account), "AccountStorage: account must be registered first");
        _;
    }


    modifier hasEnoughBalance(uint256 amount) {
        require(amount <= balanceOf(msg.sender), "AccountStorage: insufficient account balance");
        _;
    }


    modifier hasEnoughAvailableEther(uint256 amount) {
        uint256 totalBonus = totalBonusOf(msg.sender);
        require(totalBonus > 0, "AccountStorage: you don't have any available ether");
        require(amount <= totalBonus, "AccountStorage: you don't have enough available ether to perform operation");
        _;
    }


    constructor() {
        addAccountData(address(this), address(0));
    }


    function migrateAccount(address account, address sponsor, uint256 tokensToMint, uint256 selfBuy) public {
        MigrationData[] memory data = new MigrationData[](1);
        data[0] = MigrationData(account, sponsor, tokensToMint, selfBuy);
        migrateAccountsInBatch(data);
    }


    function migrateAccountsInBatch(MigrationData[] memory data) public {
        require(hasRole(ACCOUNT_MANAGER_ROLE, msg.sender), "AccountStorage: must have account manager role to migrate data");
        require(!_accountsMigrated, "AccountStorage: account data migration method is no more available");

        for (uint i = 0; i < data.length; i += 1) {
            address curAddress = data[i].account;
            address curSponsorAddress = data[i].sponsor;
            uint256 tokensToMint = data[i].tokensToMint;
            uint256 selfBuy = data[i].selfBuy;
            if (curSponsorAddress == address(0)) {
                curSponsorAddress = address(this);
            }
            addAccountData(curAddress, curSponsorAddress);
            _accounts.add(curAddress);

            increaseTotalSupply(tokensToMint);
            increaseBalanceOf(curAddress, tokensToMint);
            increaseSelfBuyOf(curAddress, selfBuy);
            emit AccountCreation(curAddress, curSponsorAddress);
        }
    }


    function isDataMigrated() public view returns(bool) {
        return _accountsMigrated;
    }


    function finishAccountMigration() public {
        require(hasRole(ACCOUNT_MANAGER_ROLE, msg.sender), "AccountStorage: must have account manager role to migrate data");
        require(!_accountsMigrated, "AccountStorage: account data migration method is no more available");

        _accountsMigrated = true;
        emit AccountMigrationFinished();
    }


    function createAccount(address sponsor) public returns(bool) {
        require(_accountsMigrated, "AccountStorage: account data isn't migrated yet, try later");
        require(!hasAccount(msg.sender), "AccountStorage: account already exists");

        address account = msg.sender;

        if (sponsor == address(0)) {
            sponsor = address(this);
        }

        addAccountData(account, sponsor);
        _accounts.add(account);

        emit AccountCreation(account, sponsor);
        return true;
    }


    function setSponsorFor(address account, address newSponsor) public {
        require(hasRole(ACCOUNT_MANAGER_ROLE, msg.sender), "AccountStorage: must have account manager role to change sponsor for account");
        address oldSponsor = _accountsData[account].sponsor;
        _accountsData[account].sponsor = newSponsor;
        emit AccountSponsorUpdated(account, oldSponsor, newSponsor);
    }


    function getAccountsCount() public view returns(uint256) {
        return _accounts.length();
    }


    function hasAccount(address account) public view returns(bool) {
        return _accounts.contains(account);
    }


    function sponsorOf(address account) public view returns(address) {
        return _accountsData[account].sponsor;
    }


    function selfBuyOf(address account) public view returns(uint256) {
        return _accountsData[account].selfBuy;
    }


    function balanceOf(address account) public override view returns(uint256) {
        return _accountsData[account].balance;
    }


    function directBonusOf(address account) public view returns(uint256) {
        return _accountsData[account].directBonus;
    }


    function withdrawnAmountOf(address account) public view returns(uint256) {
        return _accountsData[account].withdrawnAmount;
    }


    function reinvestedAmountOf(address account) public view returns(uint256) {
        return _accountsData[account].reinvestedAmount;
    }


    function stakingBonusOf(address account) public virtual view returns(uint256);


    function totalBonusOf(address account) public view returns(uint256) {
        return directBonusOf(account) + stakingBonusOf(account) - withdrawnAmountOf(account) - reinvestedAmountOf(account);
    }


    function increaseSelfBuyOf(address account, uint256 amount) internal {
        _accountsData[account].selfBuy =_accountsData[account].selfBuy.add(amount);
    }


    function increaseBalanceOf(address account, uint256 amount) internal {
        _accountsData[account].balance = _accountsData[account].balance.add(amount);
    }


    function decreaseBalanceOf(address account, uint256 amount) internal {
        _accountsData[account].balance = _accountsData[account].balance.sub(amount, "AccountStorage: amount exceeds balance");
    }


    function addDirectBonusTo(address account, uint256 amount) internal {
        _accountsData[account].directBonus = _accountsData[account].directBonus.add(amount);
        emit DirectBonusPaid(account, msg.sender, amount);
    }


    function addWithdrawnAmountTo(address account, uint256 amount) internal {
        _accountsData[account].withdrawnAmount = _accountsData[account].withdrawnAmount.add(amount);
    }


    function addReinvestedAmountTo(address account, uint256 amount) internal {
        _accountsData[account].reinvestedAmount = _accountsData[account].reinvestedAmount.add(amount);
    }


    function stakingValueOf(address account) internal view returns(int256) {
        return _accountsData[account].stakingValue;
    }


    function increaseStakingValueFor(address account, int256 amount) internal {
        _accountsData[account].stakingValue += amount;
    }


    function decreaseStakingValueFor(address account, int256 amount) internal {
        _accountsData[account].stakingValue -= amount;
    }


    function addAccountData(address account, address sponsor) private {
        AccountData memory accountData = AccountData({
            sponsor: sponsor,
            balance: 0,
            selfBuy: 0,
            directBonus: 0,
            reinvestedAmount: 0,
            withdrawnAmount: 0,
            stakingValue: 0
        });
        _accountsData[account] = accountData;
    }
}