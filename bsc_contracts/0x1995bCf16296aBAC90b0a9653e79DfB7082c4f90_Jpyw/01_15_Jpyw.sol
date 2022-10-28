// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract Jpyw is ERC20Upgradeable, AccessControlEnumerableUpgradeable {
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant BLOCK_LIST_ROLE = keccak256("BLOCK_LIST_ROLE");

	EnumerableSetUpgradeable.AddressSet private blockList;

	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

	/**
	 * Initialize the passed address as AddressRegistry address.
	 */
	function initialize() external initializer {
		__ERC20_init("JPY World", "JPYW");
		__AccessControlEnumerable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(BURNER_ROLE, _msgSender());
		_setupRole(MINTER_ROLE, _msgSender());
		_setupRole(BLOCK_LIST_ROLE, _msgSender());
	}

	function decimals() public pure override returns (uint8) {
		return 2;
	}

	function mint(address _account, uint256 _amount) external {
		require(hasRole(MINTER_ROLE, _msgSender()), "illegal access(mint)");
		_mint(_account, _amount);
	}

	function burn(address _account, uint256 _amount) external {
		require(hasRole(BURNER_ROLE, _msgSender()), "illegal access(burn)");
		_burn(_account, _amount);
	}

	function addToBlockList(address _account) external {
		require(
			hasRole(BLOCK_LIST_ROLE, _msgSender()),
			"illegal access(block list)"
		);
		blockList.add(_account);
	}

	function removeFromBlockList(address _account) external {
		require(
			hasRole(BLOCK_LIST_ROLE, _msgSender()),
			"illegal access(block list)"
		);
		blockList.remove(_account);
	}

	function isBlockList(address _account) external view returns (bool) {
		return blockList.contains(_account);
	}

	function _afterTokenTransfer(
		address _from,
		address _to,
		uint256 _amount
	) internal virtual override {
		super._afterTokenTransfer(_from, _to, _amount);
		require(
			blockList.contains(_from) == false,
			"illegal access(block list)"
		);
		require(blockList.contains(_to) == false, "illegal access(block list)");
	}
}