// SPDX-License-Identifier: MIT
//
//
//  ________  ________  ________  ________  ________  _________
// |\   __  \|\   __  \|\   __  \|\   __  \|\   ____\|\___   ___\
// \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \  \___|\|___ \  \_|
//  \ \   __  \ \  \\\  \ \  \\\  \ \  \\\  \ \_____  \   \ \  \
//   \ \  \|\  \ \  \\\  \ \  \\\  \ \  \\\  \|____|\  \   \ \  \
//    \ \_______\ \_______\ \_______\ \_______\____\_\  \   \ \__\
//     \|_______|\|_______|\|_______|\|_______|\_________\   \|__|
//                                            \|_________|
//
//
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TZRKT is ERC721AQueryable, ERC721ABurnable, Ownable {
	// constants
	uint256 public constant MAX_SUPPLY = 10000;

	// private variables
	string private _baseTokenURI;
	address private _minter;

	// events
	event MinterChanged(address indexed previousMinter, address indexed newMinter);

	constructor() ERC721A("BOOOST TZRKT", "TZRKT") {}

	/**
	 * @notice set minter of the contract to a new account (`newMinter`).
	 * can only be called by owner
	 * @param newMinter address of new minter
	 */
	function setMinter(address newMinter) public onlyOwner {
		require(newMinter != address(0), "setMinter: new minter is the zero address.");
		address oldMinter = _minter;
		_minter = newMinter;
		emit MinterChanged(oldMinter, newMinter);
	}

	/**
	 * @notice mint TZRKT
	 * can only be called by minter
	 * @param to address being minted to
	 * @param amount amount of mint
	 */
	function mint(address to, uint256 amount) public onlyMinter {
		require(_totalMinted() <= MAX_SUPPLY, "mint: exceeded maximum supply.");
		require(_totalMinted() + amount <= MAX_SUPPLY, "mint: exceeded maximum supply.");

		_mint(to, amount);
	}

	/**
	 * @notice set Base Token URI
	 * can only be called by owner
	 * @param baseTokenURI base URI of token
	 */
	function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
		_baseTokenURI = baseTokenURI;
	}

	/**
	 * @notice check minter
	 */
	modifier onlyMinter() {
		_checkMinter();
		_;
	}

	/**
	 * @notice throws if the sender is not the minter or owner.
	 */
	function _checkMinter() internal view {
		require(
			_minter == _msgSenderERC721A() || owner() == _msgSenderERC721A(),
			"_checkMinter: caller is not the minter or owner."
		);
	}

	//------------------//
	// Custom overrides //
	//------------------//
	/**
	 * @dev See {ERC721-_baseURI}
	 */
	function _baseURI() internal view override returns (string memory) {
		return _baseTokenURI;
	}
}