// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FlightTickets is ERC1155, Ownable {
	event RocketUsed(address indexed from, uint256 indexed rocketId);
	event PatchUsed(address indexed from, uint256 indexed patchId);

	using Strings for uint256;

	modifier contractIsNotFrozen() {
		require(isFrozen == false, "This function can not be called anymore");
		_;
	}

	modifier callerIsUser() {
		require(tx.origin == msg.sender, "The caller is another contract");
		_;
	}

	uint256 constant TICKET_A = 0;
	uint256 constant TICKET_B = 1;
	uint256 constant TICKET_C = 2;
	uint256 constant TICKET_D = 3;
	uint256 constant TICKET_E = 4;
	uint256 constant TICKET_F = 5;

	uint256 constant TICKET_A_USED = 6;
	uint256 constant TICKET_B_USED = 7;
	uint256 constant TICKET_C_USED = 8;
	uint256 constant TICKET_D_USED = 9;
	uint256 constant TICKET_E_USED = 10;
	uint256 constant TICKET_F_USED = 11;

	uint256 constant TICKET_TYPES_QTY = 6;

	struct DevMint {
		uint256 tokenType;
		uint256 quantity;
		address recipient;
	}

	mapping(uint16 => bool) public usedRockets;
	mapping(uint16 => bool) public usedPatches;

	address public signerAddress;

	address public rocksContractAddress;

	IERC721 public rocketsContract;

	IERC721 public patchesContract;

	bool public isFrozen = false;

	string public name = "Tom Sachs: Rocket Factory - Mothership Tickets";

	constructor()
		ERC1155("https://tomsachsrocketfactory.mypinata.cloud/ipfs/QmZ6BfohT2jhS8MS3MJkyM9f7RkwMFSw9A2abiZVwG9oKf/")
	{}

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
	 * @dev Gives tokens to the given addresses
	 */
	function devMintTokensToAddresses(DevMint[] memory _mintData) external onlyOwner contractIsNotFrozen {
		require(_mintData.length > 0, "At least one token should be minted");

		for (uint256 i; i < _mintData.length; i++) {
			require(_mintData[i].tokenType < TICKET_TYPES_QTY, "Invalid ticket type");

			_mint(_mintData[i].recipient, _mintData[i].tokenType, _mintData[i].quantity, "");
		}
	}

	/**
	 * @dev Sets the address that generates the signatures for whitelisting
	 */
	function setSignerAddress(address _signerAddress) external onlyOwner {
		signerAddress = _signerAddress;
	}

	/**
	 * @dev SetSets the address of the rocks smart contract
	 */
	function setRocksContractAddress(address _rocksContractAddress) external onlyOwner {
		rocksContractAddress = _rocksContractAddress;
	}

	/**
	 * @dev SetSets the Rockets contract
	 */
	function setRocketsContract(address _rocketsContractAddress) external onlyOwner {
		rocketsContract = IERC721(_rocketsContractAddress);
	}

	/**
	 * @dev SetSets the Patches contract
	 */
	function setPatchesContractAddress(address _patchesContractAddress) external onlyOwner {
		patchesContract = IERC721(_patchesContractAddress);
	}

	/**
	 * @dev Freezes the smart contract
	 */
	function freeze() external onlyOwner {
		isFrozen = true;
	}

	// END ONLY OWNER

	/**
	 * @dev Mints tickets
	 */
	function mintTickets(
		uint256[] memory _ticketTypes,
		uint256[] memory _amounts,
		uint16[] memory _rocketIds,
		uint16[] memory _patchIds,
		uint256 _fromTimestamp,
		uint256 _toTimestamp,
		bytes calldata _signature
	) external contractIsNotFrozen callerIsUser {
		require(_ticketTypes.length == _amounts.length, "Amount of mints per tickets does not match the ticket array");

		uint256 _totalTicketsAmount;
		for (uint256 i; i < _amounts.length; i++) {
			_totalTicketsAmount += _amounts[i];
		}

		require(
			_rocketIds.length + _patchIds.length == _totalTicketsAmount,
			"The amount of tickets to be minted does not match the rockets and patches"
		);

		bytes32 messageHash = generateMessageHash(
			msg.sender,
			_fromTimestamp,
			_toTimestamp,
			_ticketTypes,
			_amounts,
			_rocketIds,
			_patchIds
		);

		address recoveredWallet = ECDSA.recover(messageHash, _signature);
		require(recoveredWallet == signerAddress, "Invalid signature for the caller");

		require(block.timestamp >= _fromTimestamp, "Too early to mint");
		require(block.timestamp <= _toTimestamp, "Mint window is closed");

		for (uint256 i; i < _rocketIds.length; i++) {
			require(!usedRockets[_rocketIds[i]], "Ticket already claimed for the given Rocket");
			require(rocketsContract.ownerOf(_rocketIds[i]) == msg.sender, "Invalid owner for the given rocketId");

			usedRockets[_rocketIds[i]] = true;

			emit RocketUsed(msg.sender, _rocketIds[i]);
		}

		for (uint256 i; i < _patchIds.length; i++) {
			require(!usedPatches[_patchIds[i]], "Ticket already claimed for the given Patch");
			require(patchesContract.ownerOf(_patchIds[i]) == msg.sender, "Invalid owner for the given patchId");

			usedPatches[_patchIds[i]] = true;
			emit PatchUsed(msg.sender, _patchIds[i]);
		}

		for (uint256 i; i < _ticketTypes.length; i++) {
			require(_ticketTypes[i] < TICKET_TYPES_QTY, "Invalid ticket type");
		}

		_mintBatch(msg.sender, _ticketTypes, _amounts, "");
	}

	/**
	 * @dev Exchanges tickets for used tickets
	 */
	function useTickets(
		address _owner,
		uint256[] memory _ticketTypes,
		uint256[] memory _amounts
	) external {
		require(msg.sender == rocksContractAddress, "Caller is not the rocks contract");

		_burnBatch(_owner, _ticketTypes, _amounts);

		uint256[] memory _usedTypes = new uint256[](_ticketTypes.length);
		for (uint256 i; i < _ticketTypes.length; i++) {
			_usedTypes[i] = _ticketTypes[i] + TICKET_TYPES_QTY;
		}

		_mintBatch(_owner, _usedTypes, _amounts, "");
	}

	/**
	 * @dev Generate a message hash for the given parameters
	 */
	function generateMessageHash(
		address _address,
		uint256 _fromTimestamp,
		uint256 _toTimestamp,
		uint256[] memory _ticketTypes,
		uint256[] memory _amounts,
		uint16[] memory _rocketIds,
		uint16[] memory _patchIds
	) internal pure returns (bytes32) {
		uint256 signatureBytes = 20 + // address
			32 + // fromTimeStamp
			32 + // toTimeStamp
			(_ticketTypes.length * 32) +
			(_amounts.length * 32) +
			(_rocketIds.length * 32) +
			(_patchIds.length * 32);

		return
			keccak256(
				abi.encodePacked(
					"\x19Ethereum Signed Message:\n",
					signatureBytes.toString(),
					_address,
					_fromTimestamp,
					_toTimestamp,
					_ticketTypes,
					_amounts,
					_rocketIds,
					_patchIds
				)
			);
	}
}