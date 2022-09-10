// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

import "../EthereumContracts/contracts/interfaces/IERC1155.sol";
import "../EthereumContracts/contracts/interfaces/IERC1155Receiver.sol";
import "../EthereumContracts/contracts/interfaces/IERC1155MetadataURI.sol";
import "../EthereumContracts/contracts/utils/ERC2981Base.sol";
import "../EthereumContracts/contracts/utils/IOwnable.sol";
import "../EthereumContracts/contracts/utils/IPausable.sol";
import "../EthereumContracts/contracts/utils/ITradable.sol";
import "../EthereumContracts/contracts/utils/IWhitelistable_ECDSA.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Pass is Context, IERC1155MetadataURI, IOwnable, IPausable, ITradable, IWhitelistable_ECDSA, ERC2981Base {
	// Error
	error IERC1155_APPROVE_CALLER();
	error IERC1155_ARRAY_LENGTH_MISMATCH();
	error IERC1155_CALLER_NOT_APPROVED( address from, address operator );
	error IERC1155_REJECTED();
	error IERC1155_INSUFFICIENT_BALANCE( address from, uint256 id, uint256 balance );
	error IERC1155_NON_ERC1155_RECEIVER();
	error IERC1155_NON_EXISTANT_TOKEN( uint256 id );
	error IERC1155_NULL_ADDRESS_TRANSFER();
	error NFT_ETHER_TRANSFER_FAIL( address recipient, uint256 amount );
	error NFT_INCORRECT_PRICE( uint256 amountSent, uint256 amountExpected );
	error NFT_INVALID_QTY();
	error NFT_MAX_BATCH( uint256 qty, uint256 maxBatch );
	error NFT_MAX_SUPPLY( uint256 qty, uint256 remainingSupply );
	error NFT_NO_ETHER_BALANCE();

	uint256 public constant MAX_BATCH = 10;
	uint256 public constant PASS_ID = 1;
	uint8 public constant CLAIM = 2;

	uint256 public publicPrice;
	uint256 public remainingSupply;
	string private _uri = "ipfs://QmXede8ghiap9hoppY2NVTFEXpshmcfPsDzxFE9ydVMXby";
	mapping( address => uint256 ) private _balances;
	mapping( address => mapping( address => bool ) ) private _operatorApprovals;

	constructor() {
		address _account_ = _msgSender();
		_initIOwnable( _account_ );
		_initERC2981Base( _account_, 500 );
		remainingSupply = 2000;
	}

	// **************************************
	// *****          MODIFIER          *****
	// **************************************
		/**
		* @dev Throws if sale state is not ``CLAIM``.
		*/
		modifier isClaim() {
			uint8 _currentState_ = getPauseState();
			if ( _currentState_ != CLAIM ) {
				revert IPausable_INCORRECT_STATE( _currentState_ );
			}
			_;
		}

		/**
		* @dev Ensures that `qty_` is higher than 0 and lesser than `remainingSupply`
		* 
		* @param qty_ : the amount to validate 
		*/
		modifier validateAmount( uint256 qty_ ) {
			if ( qty_ == 0 ) {
				revert NFT_INVALID_QTY();
			}
			if ( qty_ > remainingSupply ) {
				revert NFT_MAX_SUPPLY( qty_, remainingSupply );
			}
			_;
		}

		/**
		* @dev Ensures that `id_` is a valid series
		* 
		* @param id_ : the series id to validate 
		*/
		modifier isValidSeries( uint256 id_ ) {
			if ( id_ != PASS_ID ) {
				revert IERC1155_NON_EXISTANT_TOKEN( id_ );
			}
			_;
		}
	// **************************************

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function that checks if the receiver address is a smart contract able to handle batches of IERC1155 tokens.
		*/
		function _doSafeBatchTransferAcceptanceCheck( address operator_, address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_ ) private {
			uint256 _size_;
			assembly {
				_size_ := extcodesize( to_ )
			}
			if ( _size_ > 0 ) {
				try IERC1155Receiver( to_ ).onERC1155BatchReceived( operator_, from_, ids_, amounts_, data_ ) returns ( bytes4 response ) {
					if ( response != IERC1155Receiver.onERC1155BatchReceived.selector ) {
						revert IERC1155_REJECTED();
					}
				}
				catch ( bytes memory reason ) {
					if ( reason.length == 0 ) {
						revert IERC1155_REJECTED();
					}
					else {
						assembly {
							revert( add( 32, reason ), mload( reason ) )
						}
					}
				}
			}
		}

		/**
		* @dev Internal function that checks if the receiver address is a smart contract able to handle IERC1155 tokens.
		*/
		function _doSafeTransferAcceptanceCheck( address operator_, address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_ ) private {
			uint256 _size_;
			assembly {
				_size_ := extcodesize( to_ )
			}
			if ( _size_ > 0 ) {
				try IERC1155Receiver( to_ ).onERC1155Received( operator_, from_, id_, amount_, data_ ) returns ( bytes4 response ) {
					if ( response != IERC1155Receiver.onERC1155Received.selector ) {
						revert IERC1155_REJECTED();
					}
				}
				catch ( bytes memory reason ) {
					if ( reason.length == 0 ) {
						revert IERC1155_REJECTED();
					}
					else {
						assembly {
							revert( add( 32, reason ), mload( reason ) )
						}
					}
				}
			}
		}

		/**
		* @dev Internal function that checks if `operator_` is allowed to handle tokens on behalf of `owner_`
		*/
		function _isApprovedOrOwner( address owner_, address operator_ ) internal view returns ( bool ) {
			return owner_ == operator_ ||
						 isApprovedForAll( owner_, operator_ );
		}

		/**
		* @dev Internal function that mints `amount_` tokens from series `PASS_ID` into `account_`.
		*/
		function _mint( address account_, uint256 amount_ ) internal {
			unchecked {
				_balances[ account_ ] += amount_;
				remainingSupply -= amount_;
			}
			emit TransferSingle( account_, address( 0 ), account_, PASS_ID, amount_ );
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @notice Mints `qty_` amount of `PASS_ID` to the caller address.
		* 
		* @param qty_      Amount of tokens to mint
		* @param alloted_  Amount of tokens that caller is allowed to claim
		* @param proof_    Signature confirming that the caller is allowed to mint `alloeted_` number of tokens
		* 
		* Requirements:
		* 
		* - Contract state must be `CLAIM`
		* - Whitelist must be set 
		* - Caller must be allowed to mint `qty_` tokens
		*/
		function claimPass( uint256 qty_, uint256 alloted_, Proof memory proof_ ) external isClaim validateAmount( qty_ ) isWhitelisted( _msgSender(), CLAIM, alloted_, proof_, qty_ ) {
			address _account_ = _msgSender();
			_consumeWhitelist( _account_, CLAIM, qty_ );
			_mint( _account_, qty_ );
		}

		/**
		* @notice Mints `qty_` amount of `PASS_ID` to the caller address.
		* 
		* @param qty_  Amount of tokens to mint
		* 
		* Requirements:
		* 
		* - Contract state must be `OPEN`
		* - `qty_` must be lower than `MAX_BATCH`
		* - `qty_` must be lower or equal to `remainingSupply`
		* - Caller must send enough eth to pay for `qty_` tokens
		*/
		function mintPublic( uint256 qty_ ) external payable isOpen validateAmount( qty_ ) {
			if ( qty_ > MAX_BATCH ) {
				revert NFT_MAX_BATCH( qty_, MAX_BATCH );
			}

			uint256 _expected_ = qty_ * publicPrice;
			if ( _expected_ != msg.value ) {
				revert NFT_INCORRECT_PRICE( msg.value, _expected_ );
			}

			_mint( _msgSender(), qty_ );
		}

		/**
		* @notice Transfers `amounts_` amount(s) of `ids_` from the `from_` address to the `to_` address specified (with safety call).
		* 
		* @param from_     Source address
		* @param to_       Target address
		* @param ids_      IDs of each token type (order and length must match `amounts_` array)
		* @param amounts_  Transfer amounts per token type (order and length must match `ids_` array)
		* @param data_     Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to_`
		* 
		* Requirements:
		* 
		* - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
		* - MUST revert if `to_` is the zero address.
		* - MUST revert if length of `ids_` is not the same as length of `amounts_`.
		* - MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids_` is lower than the respective amount(s) in `amounts_` sent to the recipient.
		* - MUST revert on any other error.        
		* - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
		* - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_amounts[0] before ids_[1]/_amounts[1], etc).
		* - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
		*/
		function safeBatchTransferFrom( address from_, address to_, uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_ ) external override {
			if ( to_ == address( 0 ) ) {
				revert IERC1155_NULL_ADDRESS_TRANSFER();
			}

			uint256 _len_ = ids_.length;
			if ( amounts_.length != _len_ ) {
				revert IERC1155_ARRAY_LENGTH_MISMATCH();
			}

			address _operator_ = _msgSender();
			if ( ! _isApprovedOrOwner( from_, _operator_ ) ) {
				revert IERC1155_CALLER_NOT_APPROVED( from_, _operator_ );
			}

			for ( uint256 i; i < _len_; ) {
				if ( ids_[ i ] != PASS_ID ) {
					revert IERC1155_NON_EXISTANT_TOKEN( ids_[ i ] );
				}
				uint256 _balance_ = _balances[ from_ ];
				if ( _balance_ < amounts_[ i ] ) {
					revert IERC1155_INSUFFICIENT_BALANCE( from_, PASS_ID, _balance_ );
				}
				unchecked {
					_balances[ from_ ] = _balance_ - amounts_[ i ];
				}
				_balances[ to_ ] += amounts_[ i ];
				unchecked {
					++i;
				}
			}
			emit TransferBatch( _operator_, from_, to_, ids_, amounts_ );

			_doSafeBatchTransferAcceptanceCheck( _operator_, from_, to_, ids_, amounts_, data_ );
		}

		/**
		* @notice Transfers `amount_` amount of an `id_` from the `from_` address to the `to_` address specified (with safety call).
		* 
		* @param from_    Source address
		* @param to_      Target address
		* @param id_      ID of the token type
		* @param amount_  Transfer amount
		* @param data_    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to_`
		* 
		* Requirements:
		* 
		* - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
		* - MUST revert if `to_` is the zero address.
		* - MUST revert if balance of holder for token type `id_` is lower than the `amount_` sent.
		* - MUST revert on any other error.
		* - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
		* - After the above conditions are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).        
		*/
		function safeTransferFrom( address from_, address to_, uint256 id_, uint256 amount_, bytes calldata data_ ) external override isValidSeries( id_ ) {
			if ( to_ == address( 0 ) ) {
				revert IERC1155_NULL_ADDRESS_TRANSFER();
			}

			address _operator_ = _msgSender();
			if ( ! _isApprovedOrOwner( from_, _operator_ ) ) {
				revert IERC1155_CALLER_NOT_APPROVED( from_, _operator_ );
			}

			uint256 _balance_ = _balances[ from_ ];
			if ( _balance_ < amount_ ) {
				revert IERC1155_INSUFFICIENT_BALANCE( from_, id_, _balance_ );
			}
			unchecked {
				_balances[ from_ ] = _balance_ - amount_;
			}
			_balances[ to_ ] += amount_;
			emit TransferSingle( _operator_, from_, to_, id_, amount_ );

			_doSafeTransferAcceptanceCheck( _operator_, from_, to_, id_, amount_, data_ );
		}

		/**
		* @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
		* 
		* @param operator_  Address to add to the set of authorized operators
		* @param approved_  True if the operator is approved, false to revoke approval
		* 
		* Requirements:
		* 
		* - MUST emit the ApprovalForAll event on success.
		*/
		function setApprovalForAll( address operator_, bool approved_ ) external override {
			address _tokenOwner_ = _msgSender();
			if ( _tokenOwner_ == operator_ ) {
				revert IERC1155_APPROVE_CALLER();
			}

			_operatorApprovals[ _tokenOwner_ ][ operator_ ] = approved_;
			emit ApprovalForAll( _tokenOwner_, operator_, approved_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT OWNER       *****
	// **************************************
		/**
		* @notice Adds a proxy registry to the list of accepted proxy registries.
		* 
		* @param proxyRegistryAddress_  the address of the proxy registry to be added
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function addProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_addProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @notice Removes a proxy registry from the list of accepted proxy registries.
		* 
		* @param proxyRegistryAddress_  the address of the proxy registry to be removed
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function removeProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_removeProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @notice Sets the contract state to `newState_`.
		* 
		* @param newState_  the new sale state
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setPauseState( uint8 newState_ ) external onlyOwner {
			_setPauseState( newState_ );
		}

		/**
		* @notice Updates the royalty recipient and rate.
		* 
		* @param royaltyRecipient_  the new recipient of the royalties
		* @param royaltyRate_       the new royalty rate
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner
		* - `royaltyRate_` must be between 0 and 10,000
		*/
		function setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) external onlyOwner {
			_setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
		}

		/**
		* @notice Sets the public price of the tokens.
		* 
		* @param price_  The new public price of the tokens
		*/
		function setPublicPrice( uint256 price_ ) external onlyOwner {
			publicPrice = price_;
		}

		/**
		* @notice Sets the uri of the tokens.
		* 
		* @param uri_  The new uri of the tokens
		*/
		function setURI( string memory uri_ ) external onlyOwner {
			_uri = uri_;
			emit URI( uri_, PASS_ID );
		}

		/**
		* @notice Sets the whitelist signer.
		* 
		* @param adminSigner_  The address signing the whitelist permissions
		*/
		function setWhitelist( address adminSigner_ ) public onlyOwner {
			_setWhitelist( adminSigner_ );
		}

		/**
		* @notice Withdraws all the money stored in the contract and sends it to the caller.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - Contract must have a positive balance.
		*/
		function withdraw() public onlyOwner {
			uint256 _balance_ = address( this ).balance;
			if ( _balance_ == 0 ) {
				revert NFT_NO_ETHER_BALANCE();
			}

			address _recipient_ = payable( _msgSender() );
			( bool _success_, ) = _recipient_.call{ value: _balance_ }( "" );
			if ( ! _success_ ) {
				revert NFT_ETHER_TRANSFER_FAIL( _recipient_, _balance_ );
			}
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @notice Get the balance of an account's tokens.
		* 
		* @param owner_  The address of the token holder
		* @param id_     ID of the token type
		* @return        The owner_'s balance of the token type requested
		*/
		function balanceOf( address owner_, uint256 id_ ) public view override isValidSeries( id_ ) returns ( uint256 ) {
			return _balances[ owner_ ];
		}

		/**
		* @notice Get the balance of multiple account/token pairs
		* 
		* @param owners_  The addresses of the token holders
		* @param ids_     ID of the token types
		* @return         The owners_' balance of the token types requested (i.e. balance for each (owner, id) pair)
		*/
		function balanceOfBatch( address[] calldata owners_, uint256[] calldata ids_ ) public view override returns ( uint256[] memory ) {
			uint256 _len_ = owners_.length;
			if ( _len_ != ids_.length ) {
				revert IERC1155_ARRAY_LENGTH_MISMATCH();
			}

			uint256[] memory _balances_ = new uint256[]( _len_ );
			while ( _len_ > 0 ) {
				unchecked {
					--_len_;
				}
				if ( ids_[ _len_ ] != PASS_ID ) {
					revert IERC1155_NON_EXISTANT_TOKEN( ids_[ _len_ ] );
				}

				_balances_[ _len_ ] = _balances[ owners_[ _len_ ] ];
			}

			return _balances_;
		}

		/**
		* @notice Queries the approval status of an operator for a given owner.
		* 
		* @param owner_     The owner of the tokens
		* @param operator_  Address of authorized operator
		* @return           True if the operator is approved, false if not
		*/
		function isApprovedForAll( address owner_, address operator_ ) public view override returns ( bool ) {
			return _operatorApprovals[ owner_ ][ operator_ ] ||
						 _isRegisteredProxy( owner_, operator_ );
		}

		/**
		* @notice Query if a contract implements an interface.
		* 
		* @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
		* @param interfaceID_  The interface identifier, as specified in ERC-165
		* @return 						 `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
		*/
		function supportsInterface( bytes4 interfaceID_ ) public pure override returns ( bool ) {
			return interfaceID_ == type( IERC165 ).interfaceId ||
						 interfaceID_ == type( IERC1155 ).interfaceId ||
						 interfaceID_ == type( IERC1155MetadataURI ).interfaceId ||
						 interfaceID_ == type( IERC2981 ).interfaceId;
		}

		/**
		* @dev Returns the URI for token type `id`.
		*
		* If the `\{id\}` substring is present in the URI, it must be replaced by
		* clients with the actual token type ID.
		*/
		function uri( uint256 id_ ) external view isValidSeries( id_ ) returns ( string memory ) {
			return _uri;
		}
	// **************************************
}