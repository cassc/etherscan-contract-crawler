// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
* Author: Lambdalf the White
*/

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
* @dev Required interface of an ERC721 compliant contract.
*/
abstract contract Reg_ERC721Batch is Context, IERC721Metadata, IERC721Enumerable {
	// Errors
	error IERC721_CALLER_NOT_APPROVED( address tokenOwner, address operator, uint256 tokenId );
	error IERC721_NONEXISTANT_TOKEN( uint256 tokenId );
	error IERC721_NON_ERC721_RECEIVER( address receiver );
	error IERC721_INVALID_APPROVAL( address operator );
	error IERC721_INVALID_TRANSFER( address recipient );
	error IERC721Enumerable_INDEX_OUT_OF_BOUNDS( uint256 index );
	error IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( address tokenOwner, uint256 index );
  error IERC721_INVALID_TRANSFER_FROM();
  error IERC721_NFT_INVALID_QTY();

	uint256 private _nextId = 1;
	string  public  name;
	string  public  symbol;

	// Mapping from token ID to approved address
	mapping( uint256 => address ) public getApproved;

	// Mapping from owner to operator approvals
	mapping( address => mapping( address => bool ) ) private _operatorApprovals;

	// List of owner addresses
	mapping( uint256 => address ) private _owners;

	// Token Base URI
	string  internal _baseURI;

	/**
	* @dev Ensures the token exist. 
	* A token exists if it has been minted and is not owned by the null address.
	* 
	* @param tokenId_ uint256 ID of the token to verify
	*/
	modifier exists( uint256 tokenId_ ) {
		if ( ! _exists( tokenId_ ) ) {
			revert IERC721_NONEXISTANT_TOKEN( tokenId_ );
		}
		_;
	}


	/**
	* @dev Ensures that 'qty_' is greater than 0. 
	* 
	* @param qty_ uint256 ID of the token to verify
	*/
  modifier validateAmount( uint256 qty_ ) {
    if ( qty_ == 0 ) {
      revert IERC721_NFT_INVALID_QTY();
    }
    _;
  }

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
  /**
  * @dev Internal function returning the number of tokens in `tokenOwner_`'s account.
  */
  function _balanceOf( address tokenOwner_ ) internal view virtual returns ( uint256 ) {
    if ( tokenOwner_ == address( 0 ) ) {
      return 0;
    }

    uint256 _count_ = 0;
    address _currentTokenOwner_;
    for ( uint256 i = 1; i < _nextId; ++ i ) {
      if ( _exists( i ) ) {
        if ( _owners[ i ] != address( 0 ) ) {
          _currentTokenOwner_ = _owners[ i ];
        }
        if ( tokenOwner_ == _currentTokenOwner_ ) {
          _count_++;
        }
      }
    }
    return _count_;
  }

  /**
  * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
  * The call is not executed if the target address is not a contract.
  *
  * @param from_ address representing the previous owner of the given token ID
  * @param to_ target address that will receive the tokens
  * @param tokenId_ uint256 ID of the token to be transferred
  * @param data_ bytes optional data to send along with the call
  * @return bool whether the call correctly returned the expected magic value
  */
  function _checkOnERC721Received( address from_, address to_, uint256 tokenId_, bytes memory data_ ) internal virtual returns ( bool ) {
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
      _size_ := extcodesize( to_ )
    }

    // If address is a contract, check that it is aware of how to handle ERC721 tokens
    if ( _size_ > 0 ) {
      try IERC721Receiver( to_ ).onERC721Received( _msgSender(), from_, tokenId_, data_ ) returns ( bytes4 retval ) {
        return retval == IERC721Receiver.onERC721Received.selector;
      }
      catch ( bytes memory reason ) {
        if ( reason.length == 0 ) {
          revert IERC721_NON_ERC721_RECEIVER( to_ );
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
  * @param tokenId_ uint256 ID of the token to verify
  * 
  * @return bool whether the token exists
  */
  function _exists( uint256 tokenId_ ) internal view virtual returns ( bool ) {
    if ( tokenId_ == 0 ) {
      return false;
    }
    return tokenId_ < _nextId;
  }

  /**
  * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
  */
  function _initERC721Metadata( string memory name_, string memory symbol_, string memory baseURI_ ) internal {
    name     = name_;
    symbol   = symbol_;
    _baseURI = baseURI_;
  }

  /**
  * @dev Internal function returning whether `operator_` is allowed 
  * to manage tokens on behalf of `tokenOwner_`.
  * 
  * @param tokenOwner_ address that owns tokens
  * @param operator_ address that tries to manage tokens
  * 
  * @return bool whether `operator_` is allowed to handle the token
  */
  function _isApprovedForAll( address tokenOwner_, address operator_ ) internal view virtual returns ( bool ) {
    return _operatorApprovals[ tokenOwner_ ][ operator_ ];
  }

  /**
  * @dev Internal function returning whether `operator_` is allowed to handle `tokenId_`
  * 
  * Note: To avoid multiple checks for the same data, it is assumed that existence of `tokeId_` 
  * has been verified prior via {_exists}
  * If it hasn't been verified, this function might panic
  * 
  * @param operator_ address that tries to handle the token
  * @param tokenId_ uint256 ID of the token to be handled
  * 
  * @return bool whether `operator_` is allowed to handle the token
  */
  function _isApprovedOrOwner( address tokenOwner_, address operator_, uint256 tokenId_ ) internal view virtual returns ( bool ) {
    bool _isApproved_ = operator_ == tokenOwner_ ||
                        operator_ == getApproved[ tokenId_ ] ||
                        _isApprovedForAll( tokenOwner_, operator_ );
    return _isApproved_;
  }

  /**
  * @dev Mints `qty_` tokens and transfers them to `to_`.
  * 
  * This internal function can be used to perform token minting.
  * 
  * Emits one or more {Transfer} event.
  */
  function _mint( address to_, uint256 qty_ ) internal virtual validateAmount( qty_ ) {
    uint256 _firstToken_ = _nextId;
    uint256 _nextStart_ = _firstToken_ + qty_;
    uint256 _lastToken_ = _nextStart_ - 1;

    _owners[ _firstToken_ ] = to_;
    if ( _lastToken_ > _firstToken_ ) {
      _owners[ _lastToken_ ] = to_;
    }
    _nextId = _nextStart_;

    if ( ! _checkOnERC721Received( address( 0 ), to_, _firstToken_, "" ) ) {
      revert IERC721_NON_ERC721_RECEIVER( to_ );
    }

    for ( uint256 i = _firstToken_; i < _nextStart_; ++i ) {
      emit Transfer( address( 0 ), to_, i );
    }
  }

  /**
  * @dev Internal function returning the owner of the `tokenId_` token.
  * 
  * @param tokenId_ uint256 ID of the token to verify
  * 
  * @return address the address of the token owner
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
  * @dev Internal function used to set the base URI of the collection.
  */
  function _setBaseURI( string memory baseURI_ ) internal virtual {
    _baseURI = baseURI_;
  }

  /**
  * @dev Internal function returning the total supply.
  */
  function _totalSupply() internal view virtual returns ( uint256 ) {
    return supplyMinted();
  }

  /**
  * @dev Converts a `uint256` to its ASCII `string` decimal representation.
  */
  function _toString( uint256 value ) internal pure returns ( string memory ) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    if ( value == 0 ) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while ( temp != 0 ) {
      digits ++;
      temp /= 10;
    }
    bytes memory buffer = new bytes( digits );
    while ( value != 0 ) {
      digits -= 1;
      buffer[ digits ] = bytes1( uint8( 48 + uint256( value % 10 ) ) );
      value /= 10;
    }
    return string( buffer );
  }

  /**
  * @dev Transfers `tokenId_` from `from_` to `to_`.
  *
  * This internal function can be used to implement alternative mechanisms to perform 
  * token transfer, such as signature-based, or token burning.
  * 
  * Emits a {Transfer} event.
  */
  function _transfer( address from_, address to_, uint256 tokenId_ ) internal virtual {
    getApproved[ tokenId_ ] = address( 0 );
    uint256 _previousId_ = tokenId_ > 1 ? tokenId_ - 1 : 1;
    uint256 _nextId_     = tokenId_ + 1;
    bool _previousShouldUpdate_ = _previousId_ < tokenId_ &&
                                  _exists( _previousId_ ) &&
                                  _owners[ _previousId_ ] == address( 0 );
    bool _nextShouldUpdate_ = _exists( _nextId_ ) &&
                              _owners[ _nextId_ ] == address( 0 );

    if ( _previousShouldUpdate_ ) {
      _owners[ _previousId_ ] = from_;
    }

    if ( _nextShouldUpdate_ ) {
      _owners[ _nextId_ ] = from_;
    }

    _owners[ tokenId_ ] = to_;

    emit Transfer( from_, to_, tokenId_ );
  }
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
  /**
  * @dev See {IERC721-approve}.
  */
  function approve( address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) {
    address _operator_ = _msgSender();
    address _tokenOwner_ = _ownerOf( tokenId_ );
    bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

    if ( ! _isApproved_ ) {
      revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
    }

    if ( to_ == _tokenOwner_ ) {
      revert IERC721_INVALID_APPROVAL( to_ );
    }

    getApproved[ tokenId_ ] = to_;
    emit Approval( _tokenOwner_, to_, tokenId_ );
  }

  /**
  * @dev See {IERC721-safeTransferFrom}.
  */
  function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) {
    address _operator_ = _msgSender();
    address _tokenOwner_ = _ownerOf( tokenId_ );
    if ( from_ != _tokenOwner_ ) {
      revert IERC721_INVALID_TRANSFER_FROM();
    }
    bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

    if ( ! _isApproved_ ) {
      revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
    }

    if ( to_ == address( 0 ) ) {
      revert IERC721_INVALID_TRANSFER( to_ );
    }

    _transfer( _tokenOwner_, to_, tokenId_ );

    if ( ! _checkOnERC721Received( _tokenOwner_, to_, tokenId_, "" ) ) {
      revert IERC721_NON_ERC721_RECEIVER( to_ );
    }
  }

  /**
  * @dev See {IERC721-safeTransferFrom}.
  */
  function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes calldata data_ ) public virtual exists( tokenId_ ) {
    address _operator_ = _msgSender();
    address _tokenOwner_ = _ownerOf( tokenId_ );
    if ( from_ != _tokenOwner_ ) {
      revert IERC721_INVALID_TRANSFER_FROM();
    }
    bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

    if ( ! _isApproved_ ) {
      revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
    }

    if ( to_ == address( 0 ) ) {
      revert IERC721_INVALID_TRANSFER( to_ );
    }

    _transfer( _tokenOwner_, to_, tokenId_ );

    if ( ! _checkOnERC721Received( _tokenOwner_, to_, tokenId_, data_ ) ) {
      revert IERC721_NON_ERC721_RECEIVER( to_ );
    }
  }

  /**
  * @dev See {IERC721-setApprovalForAll}.
  */
  function setApprovalForAll( address operator_, bool approved_ ) public virtual override {
    address _account_ = _msgSender();
    if ( operator_ == _account_ ) {
      revert IERC721_INVALID_APPROVAL( operator_ );
    }

    _operatorApprovals[ _account_ ][ operator_ ] = approved_;
    emit ApprovalForAll( _account_, operator_, approved_ );
  }

  /**
  * @dev See {IERC721-transferFrom}.
  */
  function transferFrom( address from_, address to_, uint256 tokenId_ ) public virtual exists( tokenId_ ) {
    address _operator_ = _msgSender();
    address _tokenOwner_ = _ownerOf( tokenId_ );
    if ( from_ != _tokenOwner_ ) {
      revert IERC721_INVALID_TRANSFER_FROM();
    }
    bool _isApproved_ = _isApprovedOrOwner( _tokenOwner_, _operator_, tokenId_ );

    if ( ! _isApproved_ ) {
      revert IERC721_CALLER_NOT_APPROVED( _tokenOwner_, _operator_, tokenId_ );
    }

    if ( to_ == address( 0 ) ) {
      revert IERC721_INVALID_TRANSFER( to_ );
    }

    _transfer( _tokenOwner_, to_, tokenId_ );
  }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
  /**
  * @dev Returns the number of tokens in `tokenOwner_`'s account.
  */
  function balanceOf( address tokenOwner_ ) public view virtual returns ( uint256 ) {
    return _balanceOf( tokenOwner_ );
  }

  /**
  * @dev Returns if the `operator_` is allowed to manage all of the assets of `tokenOwner_`.
  *
  * See {setApprovalForAll}
  */
  function isApprovedForAll( address tokenOwner_, address operator_ ) public view virtual returns ( bool ) {
    return _isApprovedForAll( tokenOwner_, operator_ );
  }

  /**
  * @dev Returns the owner of the `tokenId_` token.
  *
  * Requirements:
  *
  * - `tokenId_` must exist.
  */
  function ownerOf( uint256 tokenId_ ) public view virtual exists( tokenId_ ) returns ( address ) {
    return _ownerOf( tokenId_ );
  }

  /**
  * @dev Returns the total number of tokens minted
  * 
  * @return uint256 the number of tokens that have been minted so far
  */
  function supplyMinted() public view virtual returns ( uint256 ) {
    return _nextId - 1;
  }

  /**
  * @dev See {IERC165-supportsInterface}.
  */
  function supportsInterface( bytes4 interfaceId_ ) public view virtual override returns ( bool ) {
    return 
      interfaceId_ == type( IERC721Enumerable ).interfaceId ||
      interfaceId_ == type( IERC721Metadata ).interfaceId ||
      interfaceId_ == type( IERC721 ).interfaceId ||
      interfaceId_ == type( IERC165 ).interfaceId;
  }

  /**
  * @dev See {IERC721Enumerable-tokenByIndex}.
  */
  function tokenByIndex( uint256 index_ ) public view virtual override returns ( uint256 ) {
    if ( index_ >= supplyMinted() ) {
      revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS( index_ );
    }
    return index_;
  }

  /**
  * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
  */
  function tokenOfOwnerByIndex( address tokenOwner_, uint256 index_ ) public view virtual override returns ( uint256 tokenId ) {
    if ( index_ >= _balanceOf( tokenOwner_ ) ) {
      revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( tokenOwner_, index_ );
    }

    uint256 _count_ = 0;
    for ( uint256 i = 1; i < _nextId; i++ ) {
      if ( _exists( i ) && tokenOwner_ == _ownerOf( i ) ) {
        if ( index_ == _count_ ) {
          return i;
        }
        _count_++;
      }
    }
  }

  /**
  * @dev See {IERC721Metadata-tokenURI}.
  */
  function tokenURI( uint256 tokenId_ ) public view virtual override exists( tokenId_ ) returns ( string memory ) {
    return bytes( _baseURI ).length > 0 ? string( abi.encodePacked( _baseURI, _toString( tokenId_ ) ) ) : _toString( tokenId_ );
  }

  /**
  * @dev See {IERC721Enumerable-totalSupply}.
  */
  function totalSupply() public view virtual override returns ( uint256 ) {
    return _totalSupply();
  }
	// **************************************
}