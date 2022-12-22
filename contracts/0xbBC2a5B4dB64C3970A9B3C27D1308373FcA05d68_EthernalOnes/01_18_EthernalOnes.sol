// SPDX-License-Identifier: MIT

/**
* @team   : Asteria Labs
* @author : Lambdalf the White
*/

pragma solidity 0.8.17;

import 'EthereumContracts/contracts/interfaces/IArrayErrors.sol';
import 'EthereumContracts/contracts/interfaces/IEtherErrors.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Errors.sol';
import 'EthereumContracts/contracts/interfaces/INFTSupplyErrors.sol';
import 'EthereumContracts/contracts/interfaces/IERC165.sol';
import 'EthereumContracts/contracts/interfaces/IERC721.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Metadata.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Enumerable.sol';
import 'EthereumContracts/contracts/interfaces/IERC721Receiver.sol';
import 'EthereumContracts/contracts/utils/ERC173.sol';
import 'EthereumContracts/contracts/utils/ContractState.sol';
import 'EthereumContracts/contracts/utils/Whitelist_ECDSA.sol';
import 'EthereumContracts/contracts/utils/ERC2981.sol';
import 'operator-filter-registry/src/UpdatableOperatorFilterer.sol';

contract EthernalOnes is 
IArrayErrors, IEtherErrors, IERC721Errors, INFTSupplyErrors,
IERC165, IERC721, IERC721Metadata, IERC721Enumerable,
ERC173, ContractState, Whitelist_ECDSA, ERC2981, UpdatableOperatorFilterer {
  // Errors
  error EO_PHASE_DEPLETED( uint8 currentPhase );

  // Constants
  uint8 public constant PHASE1_SALE = 1;
  uint8 public constant PHASE2_SALE = 2;
  uint8 public constant PUBLIC_SALE = 3;
  address public constant DEFAULT_SUBSCRIPTION = address( 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6 );
  address public constant DEFAULT_OPERATOR_FILTER_REGISTRY = address( 0x000000000000AAeB6D7670E522A718067333cd4E );
  string public constant name = "Ethernal Ones - The Awakening";
  string public constant symbol = "EONFT";
  uint256 public constant MAX_BATCH = 2;

  // Private variables
  uint256 public maxSupply = 6666;
  uint256 private _nextId = 1;
  uint256 private _reserve = 50;
  address private _treasury;
  string  private _baseURI = "ipfs://QmPcyrBaY65ZVWReFwkPXUQHGUjq4skCVhk5HfSx1FJoi7";

  // Mapping from token ID to approved address
  mapping( uint256 => address ) private _approvals;

  // Mapping from owner to operator approvals
  mapping( address => mapping( address => bool ) ) private _operatorApprovals;

  // List of owner addresses
  mapping( uint256 => address ) private _owners;

  // Mapping from phase to sale price
  mapping( uint8 => uint256 ) private _salePrice;

  // Mapping from phase to max supply
  mapping( uint8 => uint256 ) private _maxPhase;

  constructor() UpdatableOperatorFilterer( DEFAULT_OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true ) {
    _salePrice[ PHASE1_SALE ] = 59000000000000000; // 0.059 ether
    _salePrice[ PHASE2_SALE ] = 79000000000000000; // 0.079 ether
    _salePrice[ PUBLIC_SALE ] = 89000000000000000; // 0.089 ether
    _maxPhase[ PHASE1_SALE ] = 2999;
    _maxPhase[ PHASE2_SALE ] = 5665;
    _treasury = 0x2b1076BF95DA326441e5bf81A1d0357b10bDb933;
    _setOwner( msg.sender );
    _setRoyaltyInfo( 0x4F440081A1c6a94cA5Fa5fEcc31bceC5bba62691, 500 );
    _setWhitelist( 0x7df36A44FcA36F05A6fbF74B7cBdd9B43349e37F );
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures the token exist. 
    * A token exists if it has been minted and is not owned by the null address.
    * 
    * @param tokenId_ : identifier of the NFT being referenced
    */
    modifier exists( uint256 tokenId_ ) {
      if ( ! _exists( tokenId_ ) ) {
        revert IERC721_NONEXISTANT_TOKEN( tokenId_ );
      }
      _;
    }

    /**
    * @dev Ensures that `qty_` is higher than 0
    * 
    * @param qty_ : the amount to validate 
    */
    modifier validateAmount( uint256 qty_ ) {
      if ( qty_ == 0 ) {
        revert NFT_INVALID_QTY();
      }
      _;
    }

    /**
    * @dev Ensures that contract state is {PHASE1_SALE} or {PHASE2_SALE}
    */
    modifier isWhitelist() {
      uint8 _currentState_ = getContractState();
      if ( _currentState_ != PHASE1_SALE &&
           _currentState_ != PHASE2_SALE ) {
        revert ContractState_INCORRECT_STATE( _currentState_ );
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    // ***********
    // * IERC721 *
    // ***********
      /**
      * @dev Internal function returning the number of tokens in `userAddress_`'s account.
      * 
      * @param userAddress_ : address that may own tokens
      * 
      * @return uint256 : the number of tokens owned by `userAddress_`
      */
      function _balanceOf( address userAddress_ ) internal view virtual returns ( uint256 ) {
        if ( userAddress_ == address( 0 ) ) {
          return 0;
        }

        uint256 _count_;
        address _currentTokenOwner_;
        uint256 _index_ = 1;
        while ( _index_ < _nextId ) {
          if ( _exists( _index_ ) ) {
            if ( _owners[ _index_ ] != address( 0 ) ) {
              _currentTokenOwner_ = _owners[ _index_ ];
            }
            if ( userAddress_ == _currentTokenOwner_ ) {
              unchecked {
                ++_count_;
              }
            }
          }
          unchecked {
            ++_index_;
          }
        }
        return _count_;
      }

      /**
      * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
      * The call is not executed if the target address is not a contract.
      *
      * @param fromAddress_ : previous owner of the NFT
      * @param toAddress_   : new owner of the NFT
      * @param tokenId_     : identifier of the NFT being transferred
      * @param data_        : optional data to send along with the call

      * @return bool : whether the call correctly returned the expected value (IERC721Receiver.onERC721Received.selector)
      */
      function _checkOnERC721Received( address fromAddress_, address toAddress_, uint256 tokenId_, bytes memory data_ ) internal virtual returns ( bool ) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        // 
        // IMPORTANT
        // It is unsafe to assume that an address not flagged by this method
        // is an externally-owned account (EOA) and not a contract.
        //
        // Among others, the following types of addresses will not be flagged:
        //
        //  - an externally-owned account
        //  - a contract in construction
        //  - an address where a contract will be created
        //  - an address where a contract lived, but was destroyed
        uint256 _size_;
        assembly {
          _size_ := extcodesize( toAddress_ )
        }

        // If address is a contract, check that it is aware of how to handle ERC721 tokens
        if ( _size_ > 0 ) {
          try IERC721Receiver( toAddress_ ).onERC721Received( msg.sender, fromAddress_, tokenId_, data_ ) returns ( bytes4 retval ) {
            return retval == IERC721Receiver.onERC721Received.selector;
          }
          catch ( bytes memory reason ) {
            if ( reason.length == 0 ) {
              revert IERC721_NON_ERC721_RECEIVER( toAddress_ );
            }
            else {
              assembly {
                revert( add( 32, reason ), mload( reason ) )
              }
            }
          }
        }
        else {
          return true;
        }
      }

      /**
      * @dev Internal function returning whether a token exists. 
      * A token exists if it has been minted and is not owned by the null address.
      * 
      * @param tokenId_ : identifier of the NFT to verify
      * 
      * @return bool : whether the NFT exists
      */
      function _exists( uint256 tokenId_ ) internal view virtual returns ( bool ) {
        if ( tokenId_ == 0 ) {
          return false;
        }
        return tokenId_ < _nextId;
      }

      /**
      * @dev Internal function returning whether `operator_` is allowed 
      * to manage tokens on behalf of `tokenOwner_`.
      * 
      * @param tokenOwner_ : address that owns tokens
      * @param operator_   : address that tries to manage tokens
      * 
      * @return bool : whether `operator_` is allowed to handle the token
      */
      function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual returns ( bool ) {
        return _operatorApprovals[ tokenOwner_ ][ operator_ ];
      }

      /**
      * @dev Internal function returning whether `operator_` is allowed to handle `tokenId_`
      * 
      * Note: To avoid multiple checks for the same data, it is assumed that existence of `tokenId_` 
      * has been verified prior via {_exists}
      * If it hasn't been verified, this function might panic
      * 
      * @param tokenOwner_ : address that owns tokens
      * @param operator_   : address that tries to handle the token
      * @param tokenId_    : identifier of the NFT
      * 
      * @return bool whether `operator_` is allowed to handle the token
      */
      function _isApprovedOrOwner( address tokenOwner_, address operator_, uint256 tokenId_ ) internal view virtual returns ( bool ) {
        bool _isApproved_ = operator_ == tokenOwner_ ||
                            operator_ == _approvals[ tokenId_ ] ||
                            _isApprovedForAll( tokenOwner_, operator_ );
        return _isApproved_;
      }

      /**
      * @dev Mints `qty_` tokens and transfers them to `toAddress_`.
      * 
      * This internal function can be used to perform token minting.
      * 
      * Emits one or more {Transfer} event.
      * 
      * @param toAddress_ : address receiving the NFTs
      * @param qty_       : number of NFTs being minted
      */
      function _mint( address toAddress_, uint256 qty_ ) internal virtual {
        uint256 _firstToken_ = _nextId;
        uint256 _nextStart_ = _firstToken_ + qty_;
        uint256 _lastToken_ = _nextStart_ - 1;

        _owners[ _firstToken_ ] = toAddress_;
        if ( _lastToken_ > _firstToken_ ) {
          _owners[ _lastToken_ ] = toAddress_;
        }
        _nextId = _nextStart_;

        if ( ! _checkOnERC721Received( address( 0 ), toAddress_, _firstToken_, "" ) ) {
          revert IERC721_NON_ERC721_RECEIVER( toAddress_ );
        }

        while ( _firstToken_ < _nextStart_ ) {
          emit Transfer( address( 0 ), toAddress_, _firstToken_ );
          unchecked {
            _firstToken_ ++;
          }
        }
      }

      /**
      * @dev Internal function returning the owner of the `tokenId_` token.
      * 
      * @param tokenId_ : identifier of the NFT
      * 
      * @return : address that owns the NFT
      */
      function _ownerOf( uint256 tokenId_ ) internal view virtual returns ( address ) {
        uint256 _tokenId_ = tokenId_;
        address _tokenOwner_ = _owners[ _tokenId_ ];
        while ( _tokenOwner_ == address( 0 ) ) {
          _tokenId_ --;
          _tokenOwner_ = _owners[ _tokenId_ ];
        }

        return _tokenOwner_;
      }

      /**
      * @dev Transfers `tokenId_` from `fromAddress_` to `toAddress_`.
      *
      * This internal function can be used to implement alternative mechanisms to perform 
      * token transfer, such as signature-based, or token burning.
      * 
      * @param fromAddress_ : previous owner of the NFT
      * @param toAddress_   : new owner of the NFT
      * @param tokenId_     : identifier of the NFT being transferred
      * 
      * Emits a {Transfer} event.
      */
      function _transfer( address fromAddress_, address toAddress_, uint256 tokenId_ ) internal virtual {
        _approvals[ tokenId_ ] = address( 0 );
        uint256 _previousId_ = tokenId_ > 1 ? tokenId_ - 1 : 1;
        uint256 _nextId_     = tokenId_ + 1;
        bool _previousShouldUpdate_ = _previousId_ < tokenId_ &&
                                      _exists( _previousId_ ) &&
                                      _owners[ _previousId_ ] == address( 0 );
        bool _nextShouldUpdate_ = _exists( _nextId_ ) &&
                                  _owners[ _nextId_ ] == address( 0 );

        if ( _previousShouldUpdate_ ) {
          _owners[ _previousId_ ] = fromAddress_;
        }

        if ( _nextShouldUpdate_ ) {
          _owners[ _nextId_ ] = fromAddress_;
        }

        _owners[ tokenId_ ] = toAddress_;

        emit Transfer( fromAddress_, toAddress_, tokenId_ );
      }
    // ***********

    // *********************
    // * IERC721Enumerable *
    // *********************
      /**
      * @dev See {IERC721Enumerable-totalSupply}.
      */
      function _totalSupply() internal view virtual returns ( uint256 ) {
        uint256 _supplyMinted_ = supplyMinted();
        uint256 _count_ = _supplyMinted_;
        uint256 _index_ = _supplyMinted_;

        while ( _index_ > 0 ) {
          if ( ! _exists( _index_ ) ) {
            unchecked {
              _count_ --;
            }
          }
          unchecked {
            _index_ --;
          }
        }
        return _count_;
      }
    // *********************

    // *******************
    // * IERC721Metadata *
    // *******************
      /**
      * @dev Converts a `uint256` to its ASCII `string` decimal representation.
      */
      function _toString( uint256 value_ ) internal pure virtual returns ( string memory str ) {
        assembly {
          // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
          // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
          // We will need 1 word for the trailing zeros padding, 1 word for the length,
          // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
          let m := add( mload( 0x40 ), 0xa0 )
          // Update the free memory pointer to allocate.
          mstore( 0x40, m )
          // Assign the `str` to the end.
          str := sub( m, 0x20 )
          // Zeroize the slot after the string.
          mstore( str, 0 )

          // Cache the end of the memory to calculate the length later.
          let end := str

          // We write the string from rightmost digit to leftmost digit.
          // The following is essentially a do-while loop that also handles the zero case.
          // prettier-ignore
          for { let temp := value_ } 1 {} {
            str := sub( str, 1 )
            // Write the character to the pointer.
            // The ASCII index of the '0' character is 48.
            mstore8( str, add( 48, mod( temp, 10 ) ) )
            // Keep dividing `temp` until zero.
            temp := div( temp, 10 )
            // prettier-ignore
            if iszero( temp ) { break }
          }

          let length := sub( end, str )
          // Move the pointer 32 bytes leftwards to make room for the length.
          str := sub( str, 0x20 )
          // Store the length.
          mstore( str, length )
        }
      }
    // *******************
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_           : the amount of tokens to be minted
    * @param alloted_       : the maximum alloted for that user
    * @param proof_         : the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - Sale state must be {PHASE1_SALE or PHASE2_SALE}.
    * - Caller must send enough ether to pay for `qty_` tokens at private sale price.
    */
    function mintPrivate( uint256 qty_, uint256 alloted_, Proof memory proof_ ) public payable validateAmount( qty_ ) isWhitelist isWhitelisted( msg.sender, PHASE1_SALE, alloted_, proof_, qty_ ) {
      uint8 _currentState_ = getContractState();
      if ( qty_ + supplyMinted() > _maxPhase[ _currentState_ ] ) {
        revert EO_PHASE_DEPLETED( _currentState_ );
      }

      uint256 _expected_ = qty_ * _salePrice[ _currentState_ ];
      if ( _expected_ != msg.value ) {
        revert ETHER_INCORRECT_PRICE( msg.value, _expected_ );
      }

      _mint( msg.sender, qty_ );
      _consumeWhitelist( msg.sender, PHASE1_SALE, qty_ );
    }

    /**
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_ : the amount of tokens to be minted
    * 
    * Requirements:
    * 
    * - Sale state must be {PUBLIC_SALE}.
    * - There must be enough tokens left to mint outside of the reserve.
    * - Caller must send enough ether to pay for `qty_` tokens at public sale price.
    */
    function mintPublic( uint256 qty_ ) public payable validateAmount( qty_ ) isState( PUBLIC_SALE ) {
      if ( qty_ > MAX_BATCH ) {
        revert NFT_MAX_BATCH( qty_, MAX_BATCH );
      }

      uint256 _remainingSupply_ = maxSupply - _reserve - supplyMinted();
      if ( qty_ > _remainingSupply_ ) {
        revert NFT_MAX_SUPPLY( qty_, _remainingSupply_ );
      }

      uint256 _expected_ = qty_ * _salePrice[ PUBLIC_SALE ];
      if ( _expected_ != msg.value ) {
        revert ETHER_INCORRECT_PRICE( msg.value, _expected_ );
      }

      _mint( msg.sender, qty_ );
    }

    // ***********
    // * IERC721 *
    // ***********
      /**
      * @dev See {IERC721-approve}.
      */
      function approve( address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) onlyAllowedOperatorApproval( msg.sender ) {
        address _operator_ = msg.sender;
        address _tokenOwner_ = _ownerOf( tokenId_ );
        if ( to_ == _tokenOwner_ ) {
          revert IERC721_INVALID_APPROVAL( to_ );
        }

        bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );
        if ( ! _isApproved_ ) {
          revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
        }

        _approvals[ tokenId_ ] = to_;
        emit Approval( _tokenOwner_, to_, tokenId_ );
      }

      /**
      * @dev See {IERC721-safeTransferFrom}.
      * 
      * Note: We can ignore `from_` as we can compare everything to the actual token owner, 
      * but we cannot remove this parameter to stay in conformity with IERC721
      */
      function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) public virtual override {
        safeTransferFrom( from_, to_, tokenId_, "" );
      }

      /**
      * @dev See {IERC721-safeTransferFrom}.
      * 
      * Note: We can ignore `from_` as we can compare everything to the actual token owner, 
      * but we cannot remove this parameter to stay in conformity with IERC721
      */
      function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes memory data_ ) public virtual override {
        transferFrom( from_, to_, tokenId_ );
        if ( ! _checkOnERC721Received( from_, to_, tokenId_, data_ ) ) {
          revert IERC721_NON_ERC721_RECEIVER( to_ );
        }
      }

      /**
      * @dev See {IERC721-setApprovalForAll}.
      */
      function setApprovalForAll( address operator_, bool approved_ ) public virtual override onlyAllowedOperatorApproval( msg.sender ) {
        address _account_ = msg.sender;
        if ( operator_ == _account_ ) {
          revert IERC721_INVALID_APPROVAL( operator_ );
        }

        _operatorApprovals[ _account_ ][ operator_ ] = approved_;
        emit ApprovalForAll( _account_, operator_, approved_ );
      }

      /**
      * @dev See {IERC721-transferFrom}.
      */
      function transferFrom( address from_, address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) onlyAllowedOperator( msg.sender ) {
        if ( to_ == address( 0 ) ) {
          revert IERC721_INVALID_TRANSFER();
        }

        address _operator_ = msg.sender;
        address _tokenOwner_ = _ownerOf( tokenId_ );
        if ( from_ != _tokenOwner_ ) {
          revert IERC721_INVALID_TRANSFER_FROM( _tokenOwner_, from_, tokenId_ );
        }

        bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );
        if ( ! _isApproved_ ) {
          revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
        }

        _transfer( _tokenOwner_, to_, tokenId_ );
      }
    // ***********
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
    /**
    * @notice Mints `amounts_` tokens and transfers them to `accounts_`.
    * 
    * @param accounts_ : the list of accounts that will receive airdropped tokens
    * @param amounts_  : the amount of tokens each account will receive
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `accounts_` and `amounts_` must have the same length.
    * - There must be enough tokens left in the reserve.
    */
    function airdrop( address[] memory accounts_, uint256[] memory amounts_ ) public onlyOwner {
      uint256 _count_ = accounts_.length;
      if ( _count_ != amounts_.length ) {
        revert ARRAY_LENGTH_MISMATCH();
      }

      uint256 _totalQty_;
      while ( _count_ > 0 ) {
        unchecked {
          --_count_;
        }
        _totalQty_ += amounts_[ _count_ ];
        _mint( accounts_[ _count_ ], amounts_[ _count_ ] );
      }
      if ( _totalQty_ > _reserve ) {
        revert NFT_MAX_RESERVE( _totalQty_, _reserve );
      }
      unchecked {
        _reserve -= _totalQty_;
      }
    }

    /**
    * @notice Reduces the max supply.
    * 
    * @param newMaxSupply_ : the new max supply
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newMaxSupply_` must be lower than `maxSupply`.
    * - `newMaxSupply_` must be higher than `_nextId`.
    */
    function reduceSupply( uint256 newMaxSupply_ ) public onlyOwner {
      if ( newMaxSupply_ > maxSupply || newMaxSupply_ < _nextId + _reserve ) {
        revert NFT_INVALID_SUPPLY();
      }
      maxSupply = newMaxSupply_;
    }

    /**
    * @notice Updates the baseURI for the tokens.
    * 
    * @param newBaseURI_ : the new baseURI for the tokens
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setBaseURI( string memory newBaseURI_ ) public onlyOwner {
      _baseURI = newBaseURI_;
    }

    /**
    * @notice Updates the contract state.
    * 
    * @param newState_ : the new sale state
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newState_` must be a valid state.
    */
    function setContractState( uint8 newState_ ) external onlyOwner {
      if ( newState_ > PUBLIC_SALE ) {
        revert ContractState_INVALID_STATE( newState_ );
      }
      _setContractState( newState_ );
    }

    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newRoyaltyRecipient_ : the new recipient of the royalties
    * @param newRoyaltyRate_      : the new royalty rate
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newRoyaltyRate_` cannot be higher than 10,000.
    */
    function setRoyaltyInfo( address newRoyaltyRecipient_, uint256 newRoyaltyRate_ ) external onlyOwner {
      _setRoyaltyInfo( newRoyaltyRecipient_, newRoyaltyRate_ );
    }

    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newPhase1Price_ : the new phase 1 price
    * @param newPhase2Price_ : the new phase 2 price
    * @param newPublicPrice_ : the new public price
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setPrices( uint256 newPhase1Price_, uint256 newPhase2Price_, uint256 newPublicPrice_ ) external onlyOwner {
      _salePrice[ PHASE1_SALE ] = newPhase1Price_;
      _salePrice[ PHASE2_SALE ] = newPhase2Price_;
      _salePrice[ PUBLIC_SALE ] = newPublicPrice_;
    }

    /**
    * @notice Updates the contract treasury.
    * 
    * @param newTreasury_ : the new trasury
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setTreasury( address newTreasury_ ) external onlyOwner {
      _treasury = newTreasury_;
    }

    /**
    * @notice Updates the whitelist signer.
    * 
    * @param newAdminSigner_ : the new whitelist signer
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setWhitelist( address newAdminSigner_ ) external onlyOwner {
      _setWhitelist( newAdminSigner_ );
    }

    /**
    * @notice Withdraws all the money stored in the contract and sends it to the treasury.
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `_treasury` must be able to receive the funds.
    * - Contract must have a positive balance.
    */
    function withdraw() public onlyOwner {
      uint256 _balance_ = address( this ).balance;
      if ( _balance_ == 0 ) {
        revert ETHER_NO_BALANCE();
      }

      address _recipient_ = payable( _treasury );
      ( bool _success_, ) = _recipient_.call{ value: _balance_ }( "" );
      if ( ! _success_ ) {
        revert ETHER_TRANSFER_FAIL( _recipient_, _balance_ );
      }
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @notice Returns the current sale price
    * 
    * @return uint256 the current sale price
    */
    function salePrice() public view returns ( uint256 ) {
      return _salePrice[ getContractState() ];
    }

    /**
    * @notice Returns the total number of tokens minted
    * 
    * @return uint256 the number of tokens that have been minted so far
    */
    function supplyMinted() public view returns ( uint256 ) {
      return _nextId - 1;
    }

    // ***********
    // * IERC721 *
    // ***********
      /**
      * @dev See {IERC721-balanceOf}.
      */
      function balanceOf( address tokenOwner_ ) public view virtual returns ( uint256 ) {
        return _balanceOf( tokenOwner_ );
      }

      /**
      * @dev See {IERC721-getApproved}.
      */
      function getApproved( uint256 tokenId_ ) public view virtual exists( tokenId_ ) returns ( address ) {
        return _approvals[ tokenId_ ];
      }

      /**
      * @dev See {IERC721-isApprovedForAll}.
      */
      function isApprovedForAll( address tokenOwner_, address operator_ ) public view virtual returns ( bool ) {
        return _isApprovedForAll( tokenOwner_, operator_ );
      }

      /**
      * @dev See {IERC721-ownerOf}.
      */
      function ownerOf( uint256 tokenId_ ) public view virtual exists( tokenId_ ) returns ( address ) {
        return _ownerOf( tokenId_ );
      }
    // ***********

    // *********************
    // * IERC721Enumerable *
    // *********************
      /**
      * @dev See {IERC721Enumerable-tokenByIndex}.
      */
      function tokenByIndex( uint256 index_ ) public view virtual override returns ( uint256 ) {
        if ( index_ >= supplyMinted() ) {
          revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS( index_ );
        }
        return index_ + 1;
      }

      /**
      * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
      */
      function tokenOfOwnerByIndex( address tokenOwner_, uint256 index_ ) public view virtual override returns ( uint256 tokenId ) {
        if ( index_ >= _balanceOf( tokenOwner_ ) ) {
          revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( tokenOwner_, index_ );
        }

        uint256 _count_ = 0;
        uint256 _nextId_ = supplyMinted();
        for ( uint256 i = 1; i < _nextId_; i++ ) {
          if ( _exists( i ) && tokenOwner_ == _ownerOf( i ) ) {
            if ( index_ == _count_ ) {
              return i;
            }
            _count_++;
          }
        }
      }

      /**
      * @dev See {IERC721Enumerable-totalSupply}.
      */
      function totalSupply() public view virtual override returns ( uint256 ) {
        return _totalSupply();
      }
    // *********************

    // *******************
    // * IERC721Metadata *
    // *******************
      /**
      * @dev See {IERC721Metadata-tokenURI}.
      */
      function tokenURI( uint256 tokenId_ ) public view virtual override exists( tokenId_ ) returns ( string memory ) {
        if ( bytes( _baseURI ).length > 0 ) {
          if ( supplyMinted() == maxSupply ) {
            return string( abi.encodePacked( _baseURI, _toString( tokenId_ ) ) );
          }
          else {
            return _baseURI;
          }
        }
        return _toString( tokenId_ );
      }
    // *******************

    // ***********
    // * IERC165 *
    // ***********
      /**
      * @dev See {IERC165-supportsInterface}.
      */
      function supportsInterface( bytes4 interfaceId_ ) public view override returns ( bool ) {
        return 
          interfaceId_ == type( IERC721 ).interfaceId ||
          interfaceId_ == type( IERC721Enumerable ).interfaceId ||
          interfaceId_ == type( IERC721Metadata ).interfaceId ||
          interfaceId_ == type( IERC173 ).interfaceId ||
          interfaceId_ == type( IERC165 ).interfaceId ||
          interfaceId_ == type( IERC2981 ).interfaceId;
      }
    // ***********

    // ***********
    // * IERC173 *
    // ***********
      function owner() public view override(ERC173, UpdatableOperatorFilterer) returns ( address ) {
        return ERC173.owner();
      }
    // ***********
}