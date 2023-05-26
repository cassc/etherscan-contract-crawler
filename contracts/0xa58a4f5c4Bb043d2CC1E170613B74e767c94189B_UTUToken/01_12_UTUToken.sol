// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

/**
 * @title The Token contract.
 *
 */
contract UTUToken is ERC20Capped, Ownable, AccessControl {
	using SafeERC20 for ERC20;
	using SafeMath for uint256;

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
	bytes32 public constant RECOVERY_ROLE = keccak256("RECOVERY_ROLE");

	mapping(bytes32 => mapping(address => uint256)) public roleAssigned;

	uint256 public activationDelay = 2 days;
	bool public isMigrating;

	/**
	 * Create a new Token contract.
	 *
	 *  @param _cap Token cap.
	 */
	constructor(
		uint256 _cap,
		address[] memory _initialHolders,
		uint256[] memory _initialBalances
	)
		public
		ERC20Capped(_cap)
		ERC20("UTU Coin", "UTU")
	{
		require(_initialHolders.length == _initialBalances.length, "UTU: mismatching array lengths");
		for (uint32 i = 0 ; i < _initialHolders.length; i++) {
			_mint(_initialHolders[i], _initialBalances[i]);
		}
	}

	/**
	 * @dev Assign a new minter.
	 * @param _who address of the new minter.
	 */
	function setupMinter(address _who) public onlyOwner {
		_setupRole(MINTER_ROLE, _who);
		roleAssigned[MINTER_ROLE][_who] = now;
	}

	/**
	 * @dev Assign a new burner.
	 * @param _who address of the new burner.
	 */
	function setupBurner(address _who) public onlyOwner {
		_setupRole(BURNER_ROLE, _who);
		roleAssigned[BURNER_ROLE][_who] = now;
	}

	/**
	 * @dev Assign someone who can recover ETH and Tokens sent to this contract.
	 * @param _who address of the recoverer.
	 */
	function setupRecovery(address _who) public onlyOwner {
		_setupRole(RECOVERY_ROLE, _who);
		roleAssigned[RECOVERY_ROLE][_who] = now;
	}

	/**
	 * @dev Mint new tokens and transfer them.
	 * @param to address Recipient of newly minted tokens.
	 * @param amount uint256 amount of tokens to mint.
	 */
	function mint(address to, uint256 amount) public {
		require(!isMigrating, "cannot mint while migrating");
		require(hasRole(MINTER_ROLE, msg.sender), "Caller not a minter");
		require(active(MINTER_ROLE), "time lock active");
		_mint(to, amount);
	}

	/**
	 * @dev Burn tokens belonging to the caller.
	 * @param amount uint256 amount of tokens to burn.
	 */
	function burn(uint256 amount) public {
		require(hasRole(BURNER_ROLE, msg.sender), "Caller not a burner");
		require(active(BURNER_ROLE), "time lock active");
		_burn(msg.sender, amount);
	}

	/**
	 * @dev Starting the migration process means that no new tokens can be minted.
	 */
	function startMigration() public onlyOwner {
		isMigrating = true;
	}

	/**
	 * Recover tokens accidentally sent to the token contract.
	 *  @param _token address of the token to be recovered. 0x0 address will
	 *                        recover ETH.
	 *  @param _to address Recipient of the recovered tokens
	 *  @param _balance uint256 Amount of tokens to be recovered
	 */
	function recoverTokens(address _token, address payable _to, uint256 _balance)
		external
	{
		require(hasRole(RECOVERY_ROLE, msg.sender), "Caller cannot recover");
		require(active(RECOVERY_ROLE), "time lock active");
		require(_to != address(0), "cannot recover to zero address");

		if (_token == address(0)) { // Recover Eth
			uint256 total = address(this).balance;
			uint256 balance = _balance == 0 ? total : Math.min(total, _balance);
			_to.transfer(balance);
		} else {
			uint256 total = ERC20(_token).balanceOf(address(this));
			uint256 balance = _balance == 0 ? total : Math.min(total, _balance);
			ERC20(_token).safeTransfer(_to, balance);
		}
	}

	/**
	 * @dev Check whether the msg.sender was assigned a role and has waited out
	 * the activationDelay.
	 */
	function active(bytes32 _role) private view returns (bool) {
		return roleAssigned[_role][msg.sender] > 0 && 
			roleAssigned[_role][msg.sender] + activationDelay < now;
	}
}