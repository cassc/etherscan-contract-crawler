// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./FrozenToken.sol";
import "./token/ERC20/utils/SafeERC20.sol";

contract MarketingTheKey{
    using SafeERC20 for FrozenToken;

    address public caller;
    address public stackingContract;
    FrozenToken public _depositToken;
    address public _owner;
    
    address public extraFund;

    uint256[7] public pools;
    uint256[7] public poolsC;

    mapping(address => uint256) public refAmount;
    mapping(address => uint256) public refAmountAll;
    mapping(address => bool) public userActive;
    address[] public users;
    uint256[15] public percentsToLine = [233, 117, 70, 47, 47, 23, 23, 23, 47, 47, 47, 11, 11, 11, 11];

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not Owner");
        _;
    }

    modifier onlyLegalCaller() {
        require(msg.sender == caller || msg.sender == _owner, "caller is not Legal Caller");
        _;
    }

    modifier onlyStackingContract() {
        require(msg.sender == stackingContract || msg.sender == _owner, "caller is not Stacking Contract Caller");
        _;
    }

    constructor(address owner, address _caller, FrozenToken depositToken, address _stackingContract, address _extraFund){
        _owner = owner;
        caller = _caller;
        _depositToken = depositToken;
        stackingContract = _stackingContract;
        extraFund = _extraFund;
    }

    function setDepositToken(FrozenToken depositToken) public onlyOwner{
        _depositToken = depositToken;
    }

    function setStackingContract(address _stackingContract) public onlyOwner{
        stackingContract = _stackingContract;
    }

    function setExtraFund(address _extraFund) public onlyOwner{
        extraFund = _extraFund;
    }

    function setCaller(address _caller) public onlyOwner{
        caller = _caller;
    }

    function depositPools(address user, uint256 amount, uint256 allStackingAmount) public onlyStackingContract{
        pools[0] += amount * 70 / 1000;
        pools[1] += amount * 47 / 1000;
        pools[2] += amount * 23 / 1000;
        pools[3] += amount * 23 / 1000;
        pools[4] += amount * 23 / 1000;
        pools[5] += amount * 23 / 1000;
        pools[6] += amount * 23 / 1000;

        poolsC[0] += amount * 70 / 1000;
        poolsC[1] += amount * 47 / 1000;
        poolsC[2] += amount * 23 / 1000;
        poolsC[3] += amount * 23 / 1000;
        poolsC[4] += amount * 23 / 1000;
        poolsC[5] += amount * 23 / 1000;
        poolsC[6] += amount * 23 / 1000;

        refAmount[user] += amount * 768 / 1000;
        refAmountAll[user] += amount * 768 / 1000;
        if(!userActive[user]){
            users.push(user);
            userActive[user] = true;
        }
    }

    function addUsersToDepositPools(address[] memory _users, uint256[] memory _amounts) public onlyOwner{
        for(uint256 i = 0; i < _users.length; i++){
            refAmount[_users[i]] += _amounts[i];
            refAmountAll[_users[i]] += _amounts[i];
            if(!userActive[_users[i]]){
                users.push(_users[i]);
                userActive[_users[i]] = true;
            }
        }
    }

    function addAmountsToPools(uint256 _pool, uint256 _amount) public onlyOwner{
        pools[_pool] += _amount;
        poolsC[_pool] += _amount;
    }

    function widthdrawBonuses(address[] memory _users, address[] memory payUsers, uint8[] memory lines) public onlyLegalCaller{
        for(uint256 i; i < _users.length; i++){
            widthdrawBonus(_users[i], payUsers[i], lines[i]);
        }
    }

    function widthdrawBonus(address user, address payUser, uint8 line) public onlyLegalCaller{
        if(refAmount[payUser] >= refAmountAll[payUser] * percentsToLine[line] / 768){
            uint256 a = refAmountAll[payUser] * percentsToLine[line] / 768;
            _depositToken.safeTransfer(user, a);
            refAmount[payUser] -= a;
        }
        if(refAmount[payUser] <= 0){
            refAmountAll[payUser] = 0;
        }
    }

    function widthdrawPools(address[] memory _users, uint8[] memory _pools, uint256[] memory _amounts) public onlyLegalCaller{
        for(uint256 i; i < _users.length; i++){
            widthdrawPool(_users[i], _pools[i], _amounts[i]);
        }
    }

    function widthdrawPool(address user, uint8 pool, uint256 amount) public onlyLegalCaller{
        _depositToken.safeTransfer(user, amount);
        pools[pool] -= amount;
    }

    function getUsers() public view returns(address[] memory){
        return users;
    }

    function getRefAmount(address user) public view returns(uint256){
        return refAmount[user];
    }

    function getPoolAmount(uint8 pool) public view returns(uint256, uint256){
        return (pools[pool], poolsC[pool]);
    }

    function widthdrawFunds(uint256 amount) public onlyLegalCaller{
        _depositToken.safeTransfer(extraFund, amount);
    }
}