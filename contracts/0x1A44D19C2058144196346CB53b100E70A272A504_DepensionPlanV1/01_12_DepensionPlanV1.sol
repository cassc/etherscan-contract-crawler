// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract DepensionPlanV1 is AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Info {
        address customer;
        uint256 amount;
        uint16 planType;
        bool active;
    }

    bytes32 public constant roleAccess = keccak256("DepensionPlan");
    address private _depensionToken;
    address private _depensionTokenVault;

    mapping(uint32 => Info) private _planInfo;
    uint32 private _planId;

    event Transfer(address from, address to, address token, uint256 amount);
    event     Plan(uint32 planId, address customer, uint256 amount, uint16 planType);
    event  Deposit(uint32 planId, address customer, uint256 amount, uint32 planType, address token);
    event Withdraw(uint32 planId, address customer, uint256 amount, uint32 planType, address token);

    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(roleAccess, msg.sender);
        _grantRole(roleAccess, address(this));
        setDepensionTokenVault(address(this));
    }

    function transferToken(address from, address to, address token, uint256 amount) public onlyRole(roleAccess) {
        require(amount > 0, "InvalidAmount");
        require(from != address(0) && to != address(0) && token != address(0), "InvalidAddress");
        if (from == address(this)) { IERC20Upgradeable(token).safeTransfer(to, amount); } 
        else { IERC20Upgradeable(token).safeTransferFrom(from, to, amount); }
        
        emit Transfer(from, to, token, amount);
    }

    function setDepensionToken(address depensionToken_) public onlyRole(roleAccess) {
        _depensionToken = depensionToken_;
    }

    function setDepensionTokenVault(address depensionTokenVault_) public onlyRole(roleAccess) {
        _depensionTokenVault = depensionTokenVault_;
    }

    function getTokenBalanceThisContract(address token) public view returns(uint256) {
        return getBalance(token, address(this));
    }

    function getBalance(address token, address address_) public view returns(uint256) {
        return IERC20Upgradeable(token).balanceOf(address_);
    }

    function getDepensionToken() public view returns(address) {
        return _depensionToken;
    }

    function getDepensionTokenVault() public view returns(address) {
        return _depensionTokenVault;
    }

    function newPlan(address customer, uint256 amount, uint16 planType) public onlyRole(roleAccess) returns(uint32) {
        _planId +=1;
        _planInfo[_planId] = Info({
            customer: customer,
            amount: amount,
            planType: planType,
            active: true
        });
        emit Plan(_planId, customer, amount, planType);
        return _planId;
    }

    function _removePlan(uint32 planId) internal { _planInfo[planId].active = false; }
    function getPlan(uint32 planId) public view returns(Info memory) { return _planInfo[planId]; }
    function getCurrentPlanId() public view returns(uint32) { return _planId; }

    function deposit(
        address customer, 
        address token, 
        uint256 inputAmount, 
        uint16 planType, 
        address recipient, 
        uint256 dTokenAmount
    ) public onlyRole(roleAccess) {

        require(inputAmount > 0, "InvalidInput");
        transferToken(customer, recipient, token, inputAmount);
        transferToken(getDepensionTokenVault(), customer, getDepensionToken(), dTokenAmount);
        
        uint32 planId = newPlan(customer, inputAmount, planType);
        emit Deposit(planId, customer, inputAmount, planType, token);
    }

    function withdraw(
        address customer, 
        uint32 planId, 
        address token, 
        uint256 outputAmount, 
        address source, 
        uint256 dTokenAmount
    ) public onlyRole(roleAccess) {  

        Info memory planInfo = _planInfo[planId];
        require( planInfo.active, "AlreadyRemovedPlan" );
        require( customer == planInfo.customer, "InvalidCustomer" );
        
        transferToken(customer, getDepensionTokenVault(), getDepensionToken(), dTokenAmount);
        transferToken(source, customer, token, outputAmount);

        _removePlan(planId);
        emit Withdraw(planId, customer, outputAmount, planInfo.planType, token);
    }
}