// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IBonds.sol";
import "./interfaces/IRegistry.sol";

contract BondSwapFactory is Ownable, Pausable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	// ===== STATE VARIABLES =====
	address public registry;
	uint256 public protocolFee; //  5 digit representation of 100%,  5000 = 50%, 700 = 7%, 50 = 0.5% etc
	address public protocolFeeAddress;
	string public baseURI = "https://bondswap.org/bonds/";
	mapping(uint256 => address) public bondsImplVer; // versions of Bonds implementation contracts
	mapping(address => bool) public bondsImplVerBlacklist; // blacklisted implementations
	uint256 currentMaxImplVer;

	// ===== EVENTS =====

	event BaseUriChanged(string newURI);
	event FeeChanged(uint256 newFee);
	event FeeAddressChanged(address newFeeAddress);
	event RegistryChanged(address newRegistryAddress);
	event FactoryMigrated(address newFactoryAddress);
	event NewImplementationAdded(address newImplementationContract, uint256 version);
	event ImplementationBlacklisted(address implementationBlacklisted);
	event ImplementationRemovedFromBlacklist(address implementationBlacklisted);

	constructor(uint256 _protocolFee, address _protocolFeeAddress) {
		protocolFee = _protocolFee;
		protocolFeeAddress = _protocolFeeAddress;
	}

	function createBond(BondInit.BondCreationSettings memory _settings) external whenNotPaused nonReentrant {
		address implAddr = bondsImplVer[_settings.bondContractVersion];
		require(implAddr != address(0), "Factory:VERSION_NOT_FOUND");
		require(bondsImplVerBlacklist[implAddr] == false, "Factory:VERSION_BLACKLISTED");
		require(_settings.bondToken != address(0), "Factory:BOND_TOKEN_ZERO_ADDR");
		require(_settings.bondCreator != address(0), "Factory:CREATOR_ZERO_ADDR");

		uint256 symbolNumber = IRegistry(registry).symbolNumber();

		uint8 decimals;

		try IERC20Metadata(_settings.bondToken).decimals() returns (uint8 v) {
			if (v > 64) {
				revert("Factory:DECIMALS_TOO_HIGH");
			}
			decimals = v;
		} catch {
			revert("Factory:DECIMALS_ERROR");
		}

		BondInit.BondContractConfig memory _conf = BondInit.BondContractConfig({
			uri: baseURI,
			protocolFee: protocolFee,
			protocolFeeAddress: protocolFeeAddress,
			bondToken: _settings.bondToken,
			bondContractVersion: _settings.bondContractVersion,
			bondCreator: _settings.bondCreator,
			bondSymbolNumber: symbolNumber,
			bondTokenDecimals: decimals
		});

		address newBond = clone(implAddr);

		IBonds(newBond).initialize(_conf);

		IRegistry(registry).register(
			_settings.bondToken,
			_settings.bondContractVersion,
			_settings.bondCreator,
			newBond,
			new bytes(0) // use abi.encode to encode params
		);
	}

	function clone(address implementation) internal returns (address instance) {
		assembly {
			let ptr := mload(0x40)
			mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
			mstore(add(ptr, 0x14), shl(0x60, implementation))
			mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
			instance := create(0, ptr, 0x37)
		}
		require(instance != address(0), "Factory:CREATE_FAILED");
	}

	// ======= OWNER SECTION ======

	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
	}

	function recoverETH() external onlyOwner {
		(bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success);
	}

	function updateProtocolFee(uint256 _protocolFee) external onlyOwner {
		require(_protocolFee < 10_000, "Factory:INVALID_FEE");
		protocolFee = _protocolFee;

		emit FeeChanged(_protocolFee);
	}

	function updateProtocolFeeAddress(address _protocolFeeAddress) external onlyOwner {
		require(_protocolFeeAddress != address(0), "Factory:INVALID_ADDR");
		protocolFeeAddress = _protocolFeeAddress;

		emit FeeAddressChanged(_protocolFeeAddress);
	}

	function updateRegistryAddress(address _registryAddress) external onlyOwner {
		require(_registryAddress != address(0), "Factory:INVALID_ADDR");
		registry = _registryAddress;

		emit RegistryChanged(_registryAddress);
	}

	function migrateFactory(address _factory) external onlyOwner {
		require(_factory != address(0), "Factory:INVALID_ADDR");

		_pause();
		emit FactoryMigrated(_factory);
	}

	function updateBondImgURI(string memory _uri) external onlyOwner {
		baseURI = _uri;

		emit BaseUriChanged(_uri);
	}

	function addNewImplementation(address _newImpl) external onlyOwner {
		require(_newImpl != address(0), "Factory:INVALID_ADDR");
		bondsImplVer[currentMaxImplVer] = _newImpl;

		emit NewImplementationAdded(_newImpl, currentMaxImplVer);
		currentMaxImplVer++;
	}

	function addImplementationToBlacklist(uint256 _implVer) external onlyOwner {
		require(bondsImplVer[_implVer] != address(0), "Factory:INVALID_ADDR");

		address implAddr = bondsImplVer[_implVer];
		bondsImplVerBlacklist[implAddr] = true;

		emit ImplementationBlacklisted(implAddr);
	}

	function removeImplementationFromBlacklist(uint256 _implVer) external onlyOwner {
		require(bondsImplVer[_implVer] != address(0), "Factory:INVALID_ADDR");

		address implAddr = bondsImplVer[_implVer];
		bondsImplVerBlacklist[implAddr] = false;

		emit ImplementationRemovedFromBlacklist(implAddr);
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}