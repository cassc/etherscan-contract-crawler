// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BondSwapRegistry is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
	// ====== STATE VARIABLES ========
	uint256 public registryVersion;
	uint256 public symbolNumber;
	address public factory;
	// key is a token address, value is a list of all bonds contracts
	mapping(address => address[]) public allBondContracts;
	// list of blacklisted bond tokens, so tokens for which we create bonds, key is token contract address
	mapping(address => bool) public blacklistedBondTokens;
	// list of blacklisted bond contracts, so already created bond contracts by factory, key is bond contract address
	mapping(address => bool) public blacklistedBondContracts;

	// ====== EVENTS =======
	event FactoryChanged(address newFactoryAddr);
	event NewBondContract(address token, uint256 version, address creator, address bondContract, uint256 symbolNumber);
	event BondTokenBlacklisted(address token);
	event BondTokenRemovedFromBlacklist(address token);
	event BondContractBlacklisted(address bondContract);
	event BondContractRemovedFromBlacklist(address bondContract);

	function register(
		address _token,
		uint256 _version,
		address _creator,
		address _bondContract,
		bytes calldata _optionalData // use abi.decode to decode params
	) external virtual whenNotPaused {
		require(factory != address(0), "Registry:INIT_FACTORY");
		require(msg.sender == factory, "Registry:ACCESS_DENIED");
		require(!blacklistedBondTokens[_token], "Registry:TOKEN_BLACKLISTED");

		allBondContracts[_token].push(_bondContract);

		emit NewBondContract(_token, _version, _creator, _bondContract, symbolNumber);
		symbolNumber++;
	}

	function getBondContracts(address _token) external view returns (address[] memory) {
		return allBondContracts[_token];
	}

	// ======= UUPS ========
	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize(uint256 _regVer) external initializer {
		registryVersion = _regVer;
		symbolNumber = 0;

		__Ownable_init();
		__Pausable_init();
		__UUPSUpgradeable_init();
	}

	// ======= RESTRICTED =======

	function addToBondTokensBlacklist(address _token) external virtual onlyOwner {
		blacklistedBondTokens[_token] = true;
		emit BondTokenBlacklisted(_token);
	}

	function removeFromBondTokensBlacklist(address _token) external virtual onlyOwner {
		blacklistedBondTokens[_token] = false;
		emit BondTokenRemovedFromBlacklist(_token);
	}

	function addToBondContractsBlacklist(address _bond) external virtual onlyOwner {
		blacklistedBondContracts[_bond] = true;
		emit BondContractBlacklisted(_bond);
	}

	function removeFromBondContractsBlacklist(address _bond) external virtual onlyOwner {
		blacklistedBondContracts[_bond] = false;
		emit BondContractRemovedFromBlacklist(_bond);
	}

	function updateFactory(address _factory) external virtual onlyOwner {
		factory = _factory;
		emit FactoryChanged(_factory);
	}

	function updateRegVersion(uint256 _regVer) external virtual onlyOwner {
		registryVersion = _regVer;
	}

	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}