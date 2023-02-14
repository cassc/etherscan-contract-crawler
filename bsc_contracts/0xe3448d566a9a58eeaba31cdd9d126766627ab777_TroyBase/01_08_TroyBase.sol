// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TroyBase is ERC20Upgradeable, OwnableUpgradeable {

	mapping(address => bool) public minters;
	uint256 public _maxSupply;

	/**
	* @dev Fired in grantMinterRole()
	*
	* @param account an address which is granted minter role
	* @param sender an address which performed an operation, usually token owner
	*/
	event MinterRoleGranted(address indexed account, address indexed sender);

	/**
	* @dev Fired in revokeMinterRole()
	*
	* @param account an address which is revoked minter role
	* @param sender an address which performed an operation, usually token owner
	*/
	event MinterRoleRevoked(address indexed account, address indexed sender);

	/// @custom:oz-upgrades-unsafe-allow constructor
  	constructor() initializer {}

	function initialize(string memory name_, string memory symbol_) public virtual initializer {
		__Ownable_init();
		__ERC20_init(name_, symbol_);
		_maxSupply = 10000000000000000000000000000;
		grantMinterRole(_msgSender());
	}

	/**
	* @notice Service function to grant minter role
	*
	* @dev this function can only be called by owner
	*
	* @param addr_ an address which is granted minter role
	*/
	function grantMinterRole(address addr_) public onlyOwner {
		require(addr_ != address(0), 'invalid address');
		minters[addr_] = true;
		emit MinterRoleGranted(addr_, _msgSender());
	}

	/**
	* @notice Service function to revoke minter role
	*
	* @dev this function can only be called by owner
	*
	* @param addr_ an address which is revorked minter role
	*/
	function revokeMinterRole(address addr_) public onlyOwner {
		require(addr_ != address(0), 'invalid address');
		minters[addr_] = false;
		emit MinterRoleRevoked(addr_, _msgSender());
	}

	function renounceOwnership() public virtual override onlyOwner {
    		revokeMinterRole(owner());
    		_transferOwnership(address(0));
    }

	function transferOwnership(address newOwner) public virtual override onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		revokeMinterRole(owner());
		grantMinterRole(newOwner);
		_transferOwnership(newOwner);
	}

	function faucet(address to_, uint256 amount_) external {
		require(this.totalSupply() + amount_ <= _maxSupply, "Reach Maxmium Supply");
		require(minters[_msgSender()], 'permission denied');
    	require(to_ != address(0), 'invalid receiver');
		_mint(to_, amount_);
	}

	function increaseMaxSupply( uint256 amount_) external onlyOwner {
    	require(amount_ > 0, 'Amount increased must be greater then 0');
		_maxSupply += amount_;

	}
	function maxSupply() external view returns(uint256) {
		return _maxSupply;
	}

	function burn(uint256 amount_) external {
		_burn(tx.origin, amount_);
	}
}