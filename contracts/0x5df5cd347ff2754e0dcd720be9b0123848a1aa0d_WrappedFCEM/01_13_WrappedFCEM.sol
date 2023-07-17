// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/AccessControl.sol";

contract WrappedFCEM is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    /** @notice Current global transaction status 
	 *  TRUE - tansaction available
     *  FALSE - tansaction not available
	 */ 
	bool public isTransactionsOn;

    /// 
    enum Permission { global, forbidden, allowed }

    /// Special permissions to allow/prohibit transactions to get tokens for specific accounts
	/// 0 - depends on isTransactionsOn
	/// 1 - always "forbidden"
	/// 2 - always "allowed"
	mapping (address => Permission) public permissionToReceive;

    /// Special permissions to allow/prohibit transactions to move tokens for specific accounts
	/// 0 - depends on isTransactionsOn
	/// 1 - always "forbidden"
	/// 2 - always "allowed"
	mapping (address => Permission) public permissionToTransfer;

    event Minted(address to, uint amount);
    event Burned(address from, uint amount);
    event TransactionsUpdated(address sender, bool newValue);
    event HolderReceivePermissionUpdated(address holder, Permission newValue);
    event HolderTransferPermissionUpdated(address holder, Permission newValue);

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TREASURER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        isTransactionsOn = true;
        /// @dev Forbids current contract address receive tokens
        permissionToReceive[address(this)] = Permission.forbidden;
    }

    function updateGlobalPermission(bool value) external onlyRole(ADMIN_ROLE) {
        isTransactionsOn = value;

        emit TransactionsUpdated(msg.sender, value);
    }

    function mint(address to, uint256 amount) public onlyRole(TREASURER_ROLE) {
        require(isTransactionAllowed(to, address(0)));
        super._mint(to, amount);

        emit Minted(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(TREASURER_ROLE) {
        require(isTransactionAllowed(from, address(0)));
        super._burn(from, amount);

        emit Burned(from, amount);
    }

	function updatePermissionToReceive(address account, Permission permissionValue) external onlyRole(ADMIN_ROLE) {
        require(permissionToReceive[ account ] != permissionValue, "Permission has been already set to value");
        permissionToReceive[ account ] = permissionValue;

        emit HolderReceivePermissionUpdated(account, permissionValue);
    }

	function updatePermissionToTransfer(address account, Permission permissionValue) external onlyRole(ADMIN_ROLE) {
        require(permissionToTransfer[ account ] != permissionValue, "Permission has been already set to value");
        permissionToTransfer[ account ] = permissionValue;

        emit HolderTransferPermissionUpdated(account, permissionValue);
    }

    // Function transactions On now validate for definit address 
	function isTransactionAllowed(address accountFrom, address accountTo) public view returns( bool ) {
		return ( permissionToTransfer[ accountFrom ] == Permission.global && isTransactionsOn ) || permissionToTransfer[ accountFrom ] == Permission.allowed &&
               ( permissionToReceive [ accountTo ]   == Permission.global && isTransactionsOn ) || permissionToReceive [ accountTo ]   == Permission.allowed;
	}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        require(permissionToTransfer[ from ] == Permission.global && isTransactionsOn || permissionToTransfer[ from ] == Permission.allowed, "Sender is not allowed to transfer");
        require(permissionToReceive [ to ]   == Permission.global && isTransactionsOn || permissionToReceive [ to ]   == Permission.allowed, "Recipient is not allowed to receive");
    }
}