// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Rocks is ERC1155, Ownable {
	using Strings for uint256;

	address public signerAddress;

	bool public isFrozen = false;

	string public name = "Tom Sachs: Rocket Factory - Mars Rocks";

	address[] public minterAddresses;

	address public useRocksAddress;

	modifier contractIsNotFrozen() {
		require(isFrozen == false, "This function can not be called anymore");
		_;
	}

	modifier onlyMinter() {
		bool isAllowed;

		for (uint256 i; i < minterAddresses.length; i++) {
			if (minterAddresses[i] == msg.sender) {
				isAllowed = true;

				break;
			}
		}

		require(isAllowed, "Minter: caller is not an allowed minter");

		_;
	}

	constructor() ERC1155("https://tomsachsrocketfactory.mypinata.cloud/ipfs/") {}

	function uri(uint256 _tokenId) public view virtual override returns (string memory) {
		return string(abi.encodePacked(ERC1155.uri(_tokenId), _tokenId.toString()));
	}

	// ONLY OWNER

	/**
	 * @dev Sets the base URI for the API that provides the NFT data.
	 */
	function setURI(string memory _uri) external onlyOwner contractIsNotFrozen {
		_setURI(_uri);
	}

	/**
	 * @dev Empty transaction to leave a record in the blockchain history of the URI for
	 * the revealed tokens
	 */
	function setRevealedURI(string memory _uri) external onlyOwner {}

	/**
	 * @dev Freezes the smart contract
	 */
	function freeze() external onlyOwner {
		isFrozen = true;
	}

	/**
	 * @dev Adds an address that is allowed to mint
	 */
	function addMinterAddress(address _minterAddress) external onlyOwner {
		minterAddresses.push(_minterAddress);
	}

	/**
	 * @dev Removes permission to mint to an address
	 */
	function removeMinterAddress(address _minterAddress) external onlyOwner {
		for (uint256 i; i < minterAddresses.length; i++) {
			if (minterAddresses[i] != _minterAddress) {
				continue;
			}

			minterAddresses[i] = minterAddresses[minterAddresses.length - 1];

			minterAddresses.pop();
		}
	}

	/**
	 * @dev Sets the address that it's allowed to call the function useRocks
	 */
	function setUseRocksAddress(address _useRocksAddress) external onlyOwner {
		useRocksAddress = _useRocksAddress;
	}

	// END ONLY OWNER

	/**
	 * @dev Mints rocks to the given address
	 */
	function mint(
		address _recipient,
		uint256[] memory _ids,
		uint256[] memory _amounts
	) external onlyMinter contractIsNotFrozen {
		_mintBatch(_recipient, _ids, _amounts, "");
	}

	/**
	 * @dev Uses rocks
	 */
	function useRocks(
		address _owner,
		uint256[] memory _rockTypes,
		uint256[] memory _amounts
	) external {
		require(msg.sender == useRocksAddress, "Caller is not allowed");

		_burnBatch(_owner, _rockTypes, _amounts);
	}
}