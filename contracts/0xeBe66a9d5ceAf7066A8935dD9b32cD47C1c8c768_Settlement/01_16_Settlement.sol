// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract Settlement is AccessControlEnumerable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;

    address private _owner;

    string public name = "CryptoFundMeSettlement";
    event Transfer(address indexed _to, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // New role for transfering funds
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    // New role for withdrawing funds
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    constructor() {
        _owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(TRANSFER_ROLE, _owner);
        _setupRole(WITHDRAW_ROLE, _owner);
    }

    function _transfer(address stable_type, address _to, uint256 _value) private nonReentrant whenNotPaused returns (bool success) {
        IERC20(stable_type).safeTransfer(_to, _value);
        emit Transfer(_to, _value);
        return true;
    }


    // Transfer tokens to a specified address 
    function transfer(address stable_type, address _to, uint256 _value) external onlyRole(TRANSFER_ROLE) returns (bool success) {
        require(_value > 0, "Value must be greater than 0");
        return _transfer(stable_type, _to, _value);
    }


    function getStableBalance(address stable_type) public view onlyRole(WITHDRAW_ROLE) returns (uint256 amount){
        IERC20 token = IERC20(address(stable_type));
        // this contract's address
        address _contract = address(this);
        return token.balanceOf(_contract);
    }


    // withdraw amount to owner address
    function withdrawAmount(address stable_type, uint256 amount) public onlyRole(WITHDRAW_ROLE) returns (bool success){
        require(amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(address(stable_type));
        token.safeTransfer(_owner, amount);

        return true;
    }

    // withdraw entire balance of a stable coin to owner address
    function withdrawBalance(address stable_type) public onlyRole(WITHDRAW_ROLE) returns (bool success){
        IERC20 token = IERC20(address(stable_type));

        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(_owner, amount);

        return true;
    }


    /********** ACCESS CONTROL **********/

    // transfer ownership of the contract
    function transferOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        
        // previous owner
        address oldOwner = _owner;
        _owner = newOwner;
        // set new owner as admin
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        // set new owner as transfer role
        _setupRole(TRANSFER_ROLE, newOwner);
        // set new owner as withdraw role
        _setupRole(WITHDRAW_ROLE, newOwner);

        emit OwnershipTransferred(oldOwner, newOwner);

        return true;
    }

    // get all addresses with a specific role
    function getRoleMembers(bytes32 role) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address[] memory){
        // get number of members
        uint256 numMembers = getRoleMemberCount(role);
        // create array of addresses
        address[] memory members = new address[](numMembers);
        // get all members
        for (uint256 i = 0; i < numMembers; i++) {
            members[i] = getRoleMember(role, i);
        }
        return members;
    }

    // add an address to a admin role
    function addAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
        return true;
    }

    // remove an address from an admin role
    function removeAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
        return true;
    }

    // add an address to a transfer role
    function addTransferer(address newTransferer) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        _setupRole(TRANSFER_ROLE, newTransferer);
        return true;
    }

    // remove an address from a transfer role
    function removeTransferer(address transferer) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        revokeRole(TRANSFER_ROLE, transferer);
        return true;
    }

    // add an address to a withdraw role
    function addWithdrawer(address newWithdrawer) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        _setupRole(WITHDRAW_ROLE, newWithdrawer);
        return true;
    }

    // remove an address from a withdraw role
    function removeWithdrawer(address withdrawer) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        revokeRole(WITHDRAW_ROLE, withdrawer);
        return true;
    }

    // get all addresses with admin role
    function getAdmins() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address[] memory){
        // call getRoleMembers with admin role
        return getRoleMembers(DEFAULT_ADMIN_ROLE);
    }

    // get all addresses with transfer role
    function getTransferers() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address[] memory){
        // call getRoleMembers with transfer role
        return getRoleMembers(TRANSFER_ROLE);
    }

    // get all addresses with withdraw role
    function getWithdrawers() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address[] memory){
        // call getRoleMembers with withdraw role
        return getRoleMembers(WITHDRAW_ROLE);
    }

    // pause the contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        _pause();
        return true;
    }

    // unpause the contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        _unpause();
        return true;
    }

}