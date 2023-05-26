// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./InterfaceExchangeRegistryPreUrano.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PreUranoRegistry is AccessControl, InterfaceExchangeRegistryPreUrano {
    bytes32 public constant DEPOSIT_CONTRACT = keccak256("DEPOSIT_CONTRACT");
    bytes32 public constant WITHDRAWAL_CONTRACT =
        keccak256("WITHDRAWAL_CONTRACT");

    address public contractOwner;

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private addrToDepositValues;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private addrDepositSet;

    // solhint-disable-next-line
    constructor() {
        contractOwner = msg.sender;
        //creator as default admin
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
       //_grantRoleAdmin(REGISTRY_OWNER, );
        _setRoleAdmin(DEPOSIT_CONTRACT, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(WITHDRAWAL_CONTRACT, DEFAULT_ADMIN_ROLE);
    }

    function getRegistryOwner() external view returns (address) {
        return contractOwner;
    }

    function setRegistryOwner(address _newOwner) external {
        require(msg.sender == contractOwner, "only owner function");
        //revoke role to old admin
        require(
            contractOwner != _newOwner,
            "you cannot revoke the admin role at the address you are assigning it to"
        );
        _revokeRole(DEFAULT_ADMIN_ROLE, contractOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        contractOwner = _newOwner;
    }

    function authorizeWithdrawalContract(address _newWithdrawalContract)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "require admin role");
        grantRole(WITHDRAWAL_CONTRACT, _newWithdrawalContract);
    }

    function deauthorizeWithdrawalContract(address _oldWithdrawalContract)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "require admin role");
        require(
            contractOwner != _oldWithdrawalContract,
            "you cannot deauthorize the contract owner"
        );
        revokeRole(WITHDRAWAL_CONTRACT, _oldWithdrawalContract);
    }

    function authorizeDepositContract(address _newDepositContract) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "require admin role");
        grantRole(DEPOSIT_CONTRACT, _newDepositContract);
    }

    function deauthorizeDepositContract(address _oldDepositContract) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "require admin role");
        require(
            contractOwner != _oldDepositContract,
            "you cannot deauthorize the contract owner"
        );
        revokeRole(DEPOSIT_CONTRACT, _oldDepositContract);
    }

    function isAddressAuthorizedWithdrawer(address _contractAddress)
        external
        view
        returns (bool)
    {
        return hasRole(WITHDRAWAL_CONTRACT, _contractAddress);
    }

    function isAddressAuthorizedDepositer(address _contractAddress)
        external
        view
        returns (bool)
    {
        return hasRole(DEPOSIT_CONTRACT, _contractAddress);
    }

    function addAmountToDeposit(address _amountOwner, uint256 _amount)
        external
    {
        require(
            hasRole(DEPOSIT_CONTRACT, msg.sender),
            "only deposit manager"
        );
        require(_amount > 0, "positive, non zero amount required");
        uint256 currentAmount;
        if (!addrDepositSet.contains(_amountOwner)) {
            //register the amount owner as amount owner
            addrDepositSet.add(_amountOwner);
            currentAmount = 0;
        } else {
            currentAmount = addrToDepositValues.get(_amountOwner);
        }
        //update amount
        uint256 newAmount = currentAmount + _amount;
        addrToDepositValues.set(_amountOwner, newAmount);
    }

    function removeAmountFromDeposit(address _amountOwner, uint256 _amount)
        external
    {
        require(
            addrDepositSet.contains(_amountOwner),
            "missing owner in registry"
        );
        uint256 currentAmount = addrToDepositValues.get(_amountOwner);
        require(
            currentAmount >= _amount,
            "the quantity removed exceeds the quantity possessed"
        );
        require(
            hasRole(WITHDRAWAL_CONTRACT, msg.sender),
            "only withdraw manager"
        );
        uint256 newAmount = currentAmount - _amount;
        addrToDepositValues.set(_amountOwner, newAmount);
    }

    function getDepositedAmount(address _depositOwner)
        external
        view
        returns (uint256)
    {
        require(
            addrDepositSet.contains(_depositOwner),
            "missing owner in registry"
        );
        return addrToDepositValues.get(_depositOwner);
    }

    function isDepositOwner(address _depositOwner)
        external
        view
        returns (bool)
    {
        return addrDepositSet.contains(_depositOwner);
    }

    function listDepositOwners() external view returns (address[] memory) {
        return addrDepositSet.values();
    }
}