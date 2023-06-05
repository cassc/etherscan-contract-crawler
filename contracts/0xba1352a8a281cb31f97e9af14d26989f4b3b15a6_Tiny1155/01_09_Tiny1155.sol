// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/*
	It saves bytecode to revert on custom errors instead of using require
	statements. We are just declaring these errors for reverting with upon various
	conditions later in this contract.
*/
error CollectionURIHasBeenLocked ();
error ContractURIHasBeenLocked ();
error BalanceQueryForZeroAddress ();
error AccountsAndIdsLengthMismatched ();
error SettingApprovalStatusForSelf ();
error IdsAndAmountsLengthsMismatch ();
error TransferToZeroAddress ();
error CallerIsNotOwnerOrApproved ();
error InsufficientBalanceForTransfer ();
error MintToZeroAddress ();
error MintIdsAndAmountsLengthsMismatch ();
error DoNotHaveRigthToSetMetadata ();
error CanNotEditMetadateThatFrozen ();
error DoNotHaveRigthToLockURI ();
error ERC1155ReceiverRejectTokens ();
error NonERC1155Receiver ();
error NotAnAdmin ();
error TransferIsLocked ();
error BurnFromZeroAddress ();
error InsufficientBalanceForBurn ();
error BurnIdsAndAmountsLengthsMismatch ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title  A lite ERC-1155 item creation contract.
	@author Tim Clancy <@_Enoch>
	@author Qazawat Zirak
	@author Rostislav Khlebnikov <@_catpic5buck>
	@author Nikita Elunin
	@author Mikhail Rozalenok
	@author Egor Dergunov

	This contract represents the NFTs within a single collection. It allows for a
	designated collection owner address to manage the creation of NFTs within this
	collection. The collection owner grants approval to or removes approval from
	other addresses governing their ability to mint NFTs from this collection.

	This contract is forked from the inherited OpenZeppelin dependency, and uses
	ideas from the original ERC-1155 reference implementation.

	January 15th, 2022.
*/
contract Tiny1155 is ERC165, Ownable, IERC1155MetadataURI {
	using Address for address;

	/// The name of this ERC-1155 contract.
	string public name;

	/** 
		The ERC-1155 URI for tracking item metadata, supporting {id} substitution. 
		For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
		more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
	*/
	string private metadataUri;

	/// A mapping from token IDs to address balance.
	mapping ( uint256 => mapping ( address => uint256 )) internal balances;

	/// A mappigng that keeps track of totals supplies per token ID.
	mapping ( uint256 => uint256 ) public circulatingSupply;

	/**
		This is a mapping from each address to per-address operator approvals. 
		Operators are those addresses that have been approved to transfer tokens on 
		behalf of the approver.
	*/
	mapping( address => mapping( address => bool )) public operatorApprovals;

	/// Whether or not the metadata URI has been locked to future changes.
	bool public uriLocked;

	/// A mapping to track administrative callers who have been set by the owner.
	mapping ( address => bool ) private administrators;

	/**
		Variable that contains info about locks for each item with id from 0 to 
		254. If bit with number of _id contains 1 then item transfers locked. If 
		255th bit is 1 then all transfers locked.
	*/
	bytes32 public transferLocks;

	/**
		An event that gets emitted when the metadata collection URI is changed.

		@param oldURI The old metadata URI.
		@param newURI The new metadata URI.
	*/
	event URIChanged (
		string indexed oldURI,
		string indexed newURI
	);

	/**
		An event that indicates we have set a permanent metadata URI for a token.

		@param operator Address that locked URI.
		@param value The value of the permanent metadata URI.
	*/
	event URILocked (
		address indexed operator,
		string value
	);

	/**
		An event that gets emitted when owner or admin called allTransferLocked
		function.
		
		@param time Time, when function was called.
		@param isLocked Bool value that represents is token transfers locked.
	*/
	event AllTransfersLocked (
		bool indexed isLocked,
		uint256 indexed time
	);

	/**
		An event that gets emitted when owner or admin called allTransferLocked 
		function.

		@param time Time, when function was called.
		@param isLocked Bool value that represents is token transfers locked.
		@param id Id of token for which transfers is locked.
	*/
	event TransfersLocked (
		bool indexed isLocked,
		uint256 indexed time,
		uint256 id
	);

	/**
		A modifier to see if a caller is an approved administrator.
	*/
	modifier onlyAdmin () {
		if (_msgSender() != owner() && !administrators[_msgSender()]) {
			revert NotAnAdmin();
		}
		_;
	}

	/** 
		Construct a new Tiny1155 item collection.

		@param _name The name to assign to this item collection contract.
		@param _metadataURI The metadata URI to perform later token ID substitution 
			with.
	*/
	constructor (
		string memory _name,
		string memory _metadataURI
	) {
		name = _name;
		metadataUri = _metadataURI;
	}

	/**
		EIP-165 function. Hardcoded value is INTERFACE_ERC1155 interface id.
	*/
	function supportsInterface (
		bytes4 _interfaceId
	)	public view virtual override(ERC165, IERC165) returns (bool) {
		return
			_interfaceId == type(IERC1155).interfaceId ||
			_interfaceId == type(IERC1155MetadataURI).interfaceId ||
			(super.supportsInterface(_interfaceId));
	}

	/**
		Returns the URI for token type `id`. If the `\{id\}` substring is present 
		in the URI, it must be replaced by clients with the actual token type ID.
	*/
	function uri (uint256) external view returns (string memory) {
		return metadataUri;
	}

	/**
		This function allows the original owner of the contract to add or remove
		other addresses as administrators. Administrators may perform mints and may
		lock token transfers.

		@param _newAdmin The new admin to update permissions for.
		@param _isAdmin Whether or not the new admin should be an admin.
	*/
	function setAdmin (
		address _newAdmin,
		bool _isAdmin
	) external onlyOwner {
		administrators[_newAdmin] = _isAdmin;
	}

	/**
		Allow the item collection owner or an approved manager to update the
		metadata URI of this collection. This implementation relies on a single URI
		for all items within the collection, and as such does not emit the standard
		URI event. Instead, we emit our own event to reflect changes in the URI.

		@param _uri The new URI to update to.
	*/
	function setURI(string calldata _uri) external virtual onlyOwner {
		if (uriLocked) {
			revert CollectionURIHasBeenLocked();
		}
		string memory oldURI = metadataUri;
		metadataUri = _uri;
		emit URIChanged(oldURI, _uri);
	}

		/**
		Retrieve the balance of a particular token `_id` for a particular address
		`_owner`.

		@param _owner The owner to check for this token balance.
		@param _id The ID of the token to check for a balance.
		@return The amount of token `_id` owned by `_owner`.
	*/
		function balanceOf(address _owner, uint256 _id)
				public
				view
				virtual
				returns (uint256)
		{
				if (_owner == address(0)) {
						revert BalanceQueryForZeroAddress();
				}
				return balances[_id][_owner];
		}

		/**
		Retrieve in a single call the balances of some mulitple particular token
		`_ids` held by corresponding `_owners`.

		@param _owners The owners to check for token balances.
		@param _ids The IDs of tokens to check for balances.
		@return the amount of each token owned by each owner.
	*/
		function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
				external
				view
				virtual
				returns (uint256[] memory)
		{
				if (_owners.length != _ids.length) {
						revert AccountsAndIdsLengthMismatched();
				}

				// Populate and return an array of balances.
				uint256[] memory batchBalances = new uint256[](_owners.length);
				for (uint256 i; i < _owners.length; ++i) {
						batchBalances[i] = balanceOf(_owners[i], _ids[i]);
				}
				return batchBalances;
		}

		/**
		This function returns true if `_operator` is approved to transfer items
		owned by `_owner`.

		@param _owner The owner of items to check for transfer ability.
		@param _operator The potential transferrer of `_owner`'s items.
		@return Whether `_operator` may transfer items owned by `_owner`.
	*/
		function isApprovedForAll(address _owner, address _operator)
				public
				view
				virtual
				returns (bool)
		{
				return operatorApprovals[_owner][_operator];
		}

		/**
		Enable or disable approval for a third party `_operator` address to manage
		(transfer or burn) all of the caller's tokens.

		@param _operator The address to grant management rights over all of the
			caller's tokens.
		@param _approved The status of the `_operator`'s approval for the caller.
	*/
		function setApprovalForAll(address _operator, bool _approved)
				external
				virtual
		{
				if (_msgSender() == _operator) {
						revert SettingApprovalStatusForSelf();
				}
				operatorApprovals[_msgSender()][_operator] = _approved;
				emit ApprovalForAll(_msgSender(), _operator, _approved);
		}

		/** 
				ERC-1155 dictates that any contract which wishes to receive ERC-1155 tokens
				must explicitly designate itself as such. This function checks for such
				designation to prevent undesirable token transfers.

				@param _operator The caller who triggers the token transfer.
				@param _from The address to transfer tokens from.
				@param _to The address to transfer tokens to.
				@param _id The specific token ID to transfer.
				@param _amount The amount of the specific `_id` to transfer.
				@param _data Additional call data to send with this transfer.
			*/
		function _doSafeTransferAcceptanceCheck(
				address _operator,
				address _from,
				address _to,
				uint256 _id,
				uint256 _amount,
				bytes calldata _data
		) private {
				if (_to.isContract()) {
						try
								IERC1155Receiver(_to).onERC1155Received(
										_operator,
										_from,
										_id,
										_amount,
										_data
								)
						returns (bytes4 response) {
								if (
										response != IERC1155Receiver(_to).onERC1155Received.selector
								) {
										revert ERC1155ReceiverRejectTokens();
								}
						} catch Error(string memory reason) {
								revert(reason);
						} catch {
								revert NonERC1155Receiver();
						}
				}
		}

		/**
		The batch equivalent of `_doSafeTransferAcceptanceCheck()`.

		@param _operator The caller who triggers the token transfer.
		@param _from The address to transfer tokens from.
		@param _to The address to transfer tokens to.
		@param _ids The specific token IDs to transfer.
		@param _amounts The amounts of the specific `_ids` to transfer.
		@param _data Additional call data to send with this transfer.
	*/
		function _doSafeBatchTransferAcceptanceCheck(
				address _operator,
				address _from,
				address _to,
				uint256[] calldata _ids,
				uint256[] calldata _amounts,
				bytes calldata _data
		) private {
				if (_to.isContract()) {
						try
								IERC1155Receiver(_to).onERC1155BatchReceived(
										_operator,
										_from,
										_ids,
										_amounts,
										_data
								)
						returns (bytes4 response) {
								if (
										response !=
										IERC1155Receiver(_to).onERC1155BatchReceived.selector
								) {
										revert ERC1155ReceiverRejectTokens();
								}
						} catch Error(string memory reason) {
								revert(reason);
						} catch {
								revert NonERC1155Receiver();
						}
				}
		}

		/**
		This function performs an unsafe transfer of amount `_amount` of token ID 
		`_id` from address `_from` to address `_to`. The transfer is considered 
		unsafe because it does not validate that the receiver can actually take 
		proper receipt of an ERC-1155 token.

		@param _from The address to transfer the token with ID of `_id` from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token to transfer.
		@param _amount The amount of the specific `_id` to transfer.
	*/
		function transferFrom(
				address _from,
				address _to,
				uint256 _id,
				uint256 _amount
		) public {
				if (_to == address(0)) {
						revert TransferToZeroAddress();
				}
				if (_from != _msgSender() && !isApprovedForAll(_from, _msgSender())) {
						revert CallerIsNotOwnerOrApproved();
				}
				bytes32 _transferLocks = transferLocks;
				if (_transferLocks >> 255 == bytes32(uint256(1))) {
						revert TransferIsLocked();
				}
				if ((_transferLocks << (255 - _id)) >> 255 == bytes32(uint256(1))) {
						revert TransferIsLocked();
				}

				uint256 fromBalance = balances[_id][_from];
				if (fromBalance < _amount) {
						revert InsufficientBalanceForTransfer();
				}
				unchecked {
						balances[_id][_from] = fromBalance - _amount;
						balances[_id][_to] += _amount;
				}

				emit TransferSingle(_msgSender(), _from, _to, _id, _amount);
		}

		/**
		This function performs an unsafe batch transfer of `_amounts` amounts of 
		tokens IDs `_ids` from address `_from` to address `_to`. The transfer is 
		considered unsafe because it does not validate that the receiver can actually 
		take proper receipt of an ERC-1155 token.

		@param _from The address to transfer the token with ID of `_id` from.
		@param _to The address to transfer the token to.
		@param _ids The ID of the token to transfer.
		@param _amounts The amount of the specific `_id` to transfer.
	*/
		function batchTransferFrom(
				address _from,
				address _to,
				uint256[] calldata _ids,
				uint256[] calldata _amounts
		) public {
				if (_ids.length != _amounts.length) {
						revert IdsAndAmountsLengthsMismatch();
				}
				if (_to == address(0)) {
						revert TransferToZeroAddress();
				}
				if (_from != _msgSender() && !isApprovedForAll(_from, _msgSender())) {
						revert CallerIsNotOwnerOrApproved();
				}
				bytes32 _transferLocks = transferLocks;
				if (_transferLocks >> 255 == bytes32(uint256(1))) {
						revert TransferIsLocked();
				}

				// Validate transfer and perform all batch token sends.
				for (uint256 i; i < _ids.length; ++i) {
						// Update all specially-tracked balances.
						uint256 id = _ids[i];
						uint256 amount = _amounts[i];
						if ((_transferLocks << (255 - id)) >> 255 == bytes32(uint256(1))) {
								revert TransferIsLocked();
						}

						uint256 fromBalance = balances[id][_from];
						if (fromBalance < amount) {
								revert InsufficientBalanceForTransfer();
						}
						unchecked {
								balances[id][_from] = fromBalance - amount;
								balances[id][_to] += amount;
						}
				}

				emit TransferBatch(_msgSender(), _from, _to, _ids, _amounts);
		}

		/**
		Transfer on behalf of a caller or one of their authorized token managers
		items from one address to another.

		@param _from The address to transfer tokens from.
		@param _to The address to transfer tokens to.
		@param _id The specific token ID to transfer.
		@param _amount The amount of the specific `_id` to transfer.
		@param _data Additional call data to send with this transfer.
	*/
		function safeTransferFrom(
				address _from,
				address _to,
				uint256 _id,
				uint256 _amount,
				bytes calldata _data
		) external virtual {
				transferFrom(_from, _to, _id, _amount);
				_doSafeTransferAcceptanceCheck(
						_msgSender(),
						_from,
						_to,
						_id,
						_amount,
						_data
				);
		}

		/**
		Transfer on behalf of a caller or one of their authorized token managers
		items from one address to another.

		@param _from The address to transfer tokens from.
		@param _to The address to transfer tokens to.
		@param _ids The specific token IDs to transfer.
		@param _amounts The amounts of the specific `_ids` to transfer.
		@param _data Additional call data to send with this transfer.
	*/
		function safeBatchTransferFrom(
				address _from,
				address _to,
				uint256[] calldata _ids,
				uint256[] calldata _amounts,
				bytes calldata _data
		) external virtual {
				batchTransferFrom(_from, _to, _ids, _amounts);
				_doSafeBatchTransferAcceptanceCheck(
						msg.sender,
						_from,
						_to,
						_ids,
						_amounts,
						_data
				);
		}

		/**
		Mint a token into existence and send it to the `_recipient`
		address.

		@param _recipient The address to receive NFT.
		@param _id The item ID for the new item to create.
		@param _amount The amount of item ID to create.
	 */
		function mintSingle(
				address _recipient,
				uint256 _id,
				uint256 _amount
		) external virtual onlyAdmin {
				if (_recipient == address(0)) {
						revert MintToZeroAddress();
				}

				unchecked {
						circulatingSupply[_id] = circulatingSupply[_id] + _amount;
						balances[_id][_recipient] = balances[_id][_recipient] + _amount;
				}

				emit TransferSingle(_msgSender(), address(0), _recipient, _id, _amount);
		}

		/**
		Mint a batch of tokens into existence and send them to the `_recipient`
		address.

		@param _recipient The address to receive all NFTs.
		@param _ids The item IDs for the new items to create.
		@param _amounts The amount of each corresponding item ID to create.
	*/
		function mintBatch(
				address _recipient,
				uint256[] calldata _ids,
				uint256[] calldata _amounts
		) external virtual onlyAdmin {
				if (_recipient == address(0)) {
						revert MintToZeroAddress();
				}
				if (_ids.length != _amounts.length) {
						revert MintIdsAndAmountsLengthsMismatch();
				}

				// Loop through each of the batched IDs to update balances.
				for (uint256 i; i < _ids.length; ++i) {
						uint256 id = _ids[i];
						uint256 amount = _amounts[i];
						// Update storage of special balances and circulating values.
						unchecked {
								circulatingSupply[id] = circulatingSupply[id] + amount;
								balances[id][_recipient] = balances[id][_recipient] + amount;
						}
				}

				emit TransferBatch(
						_msgSender(),
						address(0),
						_recipient,
						_ids,
						_amounts
				);
		}

		/**
		This function allows an address to destroy some of its items.

		@param _from The address whose item is burning.
		@param _id The item ID to burn.
		@param _amount The amount of the corresponding item ID to burn.
	*/
		function burnSingle(
				address _from,
				uint256 _id,
				uint256 _amount
		) external virtual onlyAdmin {
				if (_from == address(0)) {
						revert BurnFromZeroAddress();
				}

				uint256 fromBalance = balances[_id][_from];
				if (fromBalance < _amount) {
						revert InsufficientBalanceForBurn();
				}
				unchecked {
						balances[_id][_from] = fromBalance - _amount;
						circulatingSupply[_id] -= _amount;
				}

				emit TransferSingle(_msgSender(), _from, address(0), _id, _amount);
		}

		/**
		This function allows an address to destroy multiple different items in a
		single call.

		@param _from The address whose items are burning.
		@param _ids The item IDs to burn.
		@param _amounts The amounts of the corresponding item IDs to burn.
	*/
		function burnBatch(
				address _from,
				uint256[] calldata _ids,
				uint256[] calldata _amounts
		) external virtual onlyAdmin {
				if (_from == address(0)) {
						revert BurnFromZeroAddress();
				}
				if (_ids.length != _amounts.length) {
						revert BurnIdsAndAmountsLengthsMismatch();
				}

				for (uint256 i; i < _ids.length; ++i) {
						uint256 id = _ids[i];
						uint256 amount = _amounts[i];

						uint256 fromBalance = balances[id][_from];
						if (fromBalance < amount) {
								revert InsufficientBalanceForBurn();
						}
						unchecked {
								balances[id][_from] = fromBalance - amount;
								circulatingSupply[id] -= amount;
						}
				}

				emit TransferBatch(_msgSender(), _from, address(0), _ids, _amounts);
		}

		/**
		Allow the item collection owner or an associated manager to forever lock the
		metadata URI on the entire collection to future changes.
	*/
		function lockURI() external onlyOwner {
				uriLocked = true;
				emit URILocked(msg.sender, metadataUri);
		}

		/**
		This function allows the owner to lock the transfer of all token IDs. This
		is designed to prevent whitelisted presale users from using the secondary
		market to undercut the auction before the sale has ended.

		@param _locked The status of the lock; true to lock, false to unlock.
	*/
		function lockAllTransfers(bool _locked) external onlyOwner {
				bytes32 mask = bytes32(uint256(1));
				mask <<= 255;

				if (_locked) {
						transferLocks |= mask;
				} else {
						mask = ~mask;
						transferLocks &= mask;
				}
				emit AllTransfersLocked(_locked, block.timestamp);
		}

		/**
		This function allows an administrative caller to lock the transfer of
		particular token IDs. This is designed for a non-escrow staking contract
		that comes later to lock a user's tokens while still letting them keep it in
		their wallet.

		@param _id The ID of the token to lock.
		@param _locked The status of the lock; true to lock, false to unlock.
	*/
		function lockTransfer(uint256 _id, bool _locked) external onlyAdmin {
				bytes32 mask = bytes32(uint256(1));
				mask <<= _id;

				if (_locked) {
						transferLocks |= mask;
				} else {
						mask = ~mask;
						transferLocks &= mask;
				}
				emit TransfersLocked(_locked, block.timestamp, _id);
		}
}