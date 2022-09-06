// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/***************************************
 * @author: 🍖 & Lambdalf the White     *
 * @team:   Asteria                     *
 ****************************************/

import "./libraries/Reg_ERC721Batch.sol";
import "./libraries/ERC2981Base.sol";
import "./libraries/IOwnable.sol";
import "./libraries/IPausable.sol";
import "./libraries/IWhitelistable.sol";

contract EZU is Reg_ERC721Batch, ERC2981Base, IOwnable, IPausable, IWhitelistable {
	// Errors
	error EZU_NOT_CROSSMINT();
	error EZU_INCORRECT_PRICE();
  error EZU_EXTERNAL_CONTRACT();
	error EZU_MAX_PER_TXN();
	error EZU_MAX_SUPPLY();
	error EZU_MAX_PRESALE_SUPPLY();
	error EZU_NO_ETHER_BALANCE();
	error EZU_TRANSFER_FAIL();

	// Presale mint price
	uint public PRESALE_MINT_PRICE = 0.2 ether;

	// Public mint price
	uint public PUBLIC_MINT_PRICE = 0.2 ether;

	// Max supply
	uint public immutable MAX_SUPPLY = 15_000;

	// Max presale supply
	uint public immutable MAX_SALE_SUPPLY = 10_420;

	// Max per txn
	uint public immutable MAX_PER_TXN = 2;

	// Max allowance
	uint public immutable MAX_ALLOWANCE = 1;

	// Crossmint contract address
	address public immutable CROSSMINT_ADDRESS = 0xdAb1a1854214684acE522439684a145E62505233;

	// Psychedelics Anonymous treasury address
	address public paTreasuryAddress = 0x218B622bbe4404c01f972F243952E3a1D2132Dec;

	// Magic Eden treasury address
	address public meTreasuryAddress = 0xA55c2F8Af10d603976dEcA0B61Cd87ba2F9C6492;

	// Switch between revealed or unrevealed baseURI
  bool public isRevealed = false;

  // Suffix to add to the end of tokenURI
  string public uriSuffix = "";

	constructor(
		uint256 royaltyRate_,
		address royaltyRecipient_,
		string memory name_,
		string memory symbol_,
    string memory uri_
	) {
		_initIOwnable( _msgSender() );
		_initERC2981Base( royaltyRecipient_, royaltyRate_ );
		_initERC721Metadata( name_, symbol_, uri_ );
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
  /**
  * @dev Replacement for Solidity's `transfer`: sends `amount_` wei to
  * `recipient_`, forwarding all available gas and reverting on errors.
  *
  * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
  * of certain opcodes, possibly making contracts go over the 2300 gas limit
  * imposed by `transfer`, making them unable to receive funds via
  * `transfer`. {sendValue} removes this limitation.
  *
  * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
  *
  * IMPORTANT: because control is transferred to `recipient`, care must be
  * taken to not create reentrancy vulnerabilities. Consider using
  * {ReentrancyGuard} or the
  * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
  */
  function _sendValue( address payable recipient_, uint256 amount_ ) internal {
    if ( address( this ).balance < amount_ ) {
      revert EZU_INCORRECT_PRICE();
    }
    ( bool _success_, ) = recipient_.call{ value: amount_ }( "" );
    if ( ! _success_ ) {
      revert EZU_TRANSFER_FAIL();
    }
  }
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
  /**
  * @dev Mints a token and transfers it to the caller.
  * 
  * Requirements:
  * 
  * - Sale state must be {SaleState.PRESALE}.
  * - There must be enough tokens left to mint outside of the reserve.
  * - Caller must send enough ether to pay for `qty_` tokens at presale price.
  * - Caller must be whitelisted.
  */
  function mintPreSale( uint256 qty_, bytes32[] memory proof_ ) external payable presaleOpen isWhitelisted( _msgSender(), proof_, MAX_ALLOWANCE, qty_ ) {
    if ( _totalSupply() + qty_ > MAX_SALE_SUPPLY ) {
      revert EZU_MAX_PRESALE_SUPPLY();
    }

    if ( PRESALE_MINT_PRICE * qty_ != msg.value ) {
      revert EZU_INCORRECT_PRICE();
    }

    address _account_    = _msgSender();
    _consumeWhitelist( _account_, qty_ );
    _mint( _account_, qty_ );
  }

    /**
    * @dev Mints `qty_` tokens and transfers them to the caller.
    * 
    * Requirements:
    * 
    * - Sale state must be {SaleState.SALE}.
    * - There must be enough tokens left to mint outside of the reserve.
    * - Caller must send enough ether to pay for `qty_` tokens at public sale price.
    */
  function mint( uint256 qty_ ) external payable saleOpen {
    if ( qty_ > MAX_PER_TXN ) {
      revert EZU_MAX_PER_TXN();
    }

    uint256 _endSupply_  = _totalSupply() + qty_;
    if ( _endSupply_ > MAX_SALE_SUPPLY ) {
      revert EZU_MAX_SUPPLY();
    }

    if ( qty_ * PUBLIC_MINT_PRICE != msg.value ) {
      revert EZU_INCORRECT_PRICE();
    }

    if ( _msgSender() != tx.origin ) {
      revert EZU_EXTERNAL_CONTRACT();
    }

    address _account_    = _msgSender();
    _mint( _account_, qty_ );
  }

  /**
  * @dev Mints a token and transfers it to the caller.
  * 
  * Requirements:
  * 
  * - Sale state must be {SaleState.PRESALE}.
  * - There must be enough tokens left to mint outside of the reserve.
  * - Caller must send enough ether to pay for `qty_` tokens at presale price.
  * - Caller must be whitelisted.
  */
  function crossmintPreSale( address to_, uint256 qty_, bytes32[] memory proof_ ) external payable presaleOpen isWhitelisted( to_, proof_, MAX_ALLOWANCE, qty_ ) {
    if ( _msgSender() != CROSSMINT_ADDRESS) {
      revert EZU_NOT_CROSSMINT();
    }

    if ( _totalSupply() + qty_ > MAX_SALE_SUPPLY ) {
      revert EZU_MAX_PRESALE_SUPPLY();
    }

    if ( PRESALE_MINT_PRICE * qty_ != msg.value ) {
      revert EZU_INCORRECT_PRICE();
    }

    _consumeWhitelist( to_, qty_ );
    _mint( to_, qty_ );
  }

  /**
   * @dev Mint 'qty_' tokens and transfer them to 'addr'.
   *
   * Requirements:
   *
   * - Caller must be crossmint.eth
   * - Sale state must be {SaleState.SALE}.
   * - There must be enough tokens left to mint outside of the reserve.
   * - Caller must send enough ether to pay for `qty_` tokens at public sale price.
   */
   function crossmint( address to_, uint256 qty_ ) external payable saleOpen {
    if ( _msgSender() != CROSSMINT_ADDRESS) {
      revert EZU_NOT_CROSSMINT();
    }

    if ( qty_ > MAX_PER_TXN ) {
      revert EZU_MAX_PER_TXN();
    }

    uint256 _endSupply_  = _totalSupply() + qty_;
    if ( _endSupply_ > MAX_SALE_SUPPLY ) {
      revert EZU_MAX_SUPPLY();
    }

    if ( qty_ * PUBLIC_MINT_PRICE != msg.value ) {
      revert EZU_INCORRECT_PRICE();
    }
    _mint( to_, qty_ );
  }
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
  /**
  * @dev Allows owner to mint 'qty_' tokens for future airdrops
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  * - Sale state must be {SaleState.SALE}.
  * - There must be enough tokens left to mint outside of the reserve.
  */
  function ownerMint( address _a, uint256 qty_ ) external onlyOwner {
    uint256 _endSupply_  = _totalSupply() + qty_;
    if ( _endSupply_ > MAX_SUPPLY ) {
      revert EZU_MAX_SUPPLY();
    }

    _mint( _a, qty_ );
  }

  /**
  * @dev Updates the royalty recipient and rate.
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  */
  function setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) external onlyOwner {
    _setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
  }

  /**
  * @dev See {IPausable-setSaleState}.
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  */
  function setSaleState( SaleState newState_ ) external onlyOwner {
    _setSaleState( newState_ );
  }

  /**
  * @dev Updates both 'PRESALE_MINT_PRICE' and 'PUBLIC_MINT_PRICE' to a new price
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  */
  function setSalePrices( uint256 newPresalePrice_, uint256 newPublicPrice_ ) external onlyOwner {
    PRESALE_MINT_PRICE = newPresalePrice_;
    PUBLIC_MINT_PRICE = newPublicPrice_;
  }

  /**
  * @dev Updates the baseURI
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  */
  function setBaseURI( string calldata uri_ ) external onlyOwner {
    _setBaseURI( uri_ );
  }

  /**
  * @dev Switchs 'isRevealed' to 'isRevealed_'
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  */
  function revealMetadata( string calldata uri_ ) external onlyOwner {
    _setBaseURI( uri_ );
    uriSuffix = ".json";
    isRevealed = true;
  }

  /**
  * @dev Switchs 'uriSuffix' to 'suffix_'
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  */
  function setUriSuffix( string calldata suffix_ ) external onlyOwner {
    uriSuffix = suffix_;
  }

  /**
  * @dev Updates the ME and PA treasuries
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  */
  function setTreasuries( address meTreasury_, address paTreasury_ ) external onlyOwner {
    paTreasuryAddress = paTreasury_;
    meTreasuryAddress = meTreasury_;	
  }

  /**
  * @dev See {IWhitelistable-setWhitelist}.
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  * - Sale state must be {SaleState.CLOSED}.
  */
  function setWhitelist( bytes32 root_ ) external onlyOwner saleClosed {
    _setWhitelist( root_ );
  }

  /**
  * @dev Withdraws '_amount' of ETH stored in the contract and sends 2.75% to ME treasury and the remainder to the PA treasury.
  * 
  * Requirements:
  * 
  * - Caller must be the contract owner.
  * - '_amount' must be
  */
  function withdraw(uint256 _amount) external onlyOwner {
    if (address(this).balance == 0) { revert EZU_NO_ETHER_BALANCE(); }
    
    uint256 me_percentage = 275; // 2.75%
    uint256 me_cut = (_amount * me_percentage) / 1e4;
    uint256 pa_cut = _amount - me_cut;
    
    _sendValue( payable( paTreasuryAddress ), pa_cut );
    _sendValue( payable( meTreasuryAddress ), me_cut );
  }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
  /**
  * @dev See {IERC2981-royaltyInfo}.
  *
  * Requirements:
  *
  * - `tokenId_` must exist.
  */
  function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) public view virtual override exists( tokenId_ ) returns ( address, uint256 ) {
    return super.royaltyInfo( tokenId_, salePrice_ );
  }

  /**
  * @dev See {IERC165-supportsInterface}.
  */
  function supportsInterface( bytes4 interfaceId_ ) public view virtual override(Reg_ERC721Batch, ERC2981Base) returns ( bool ) {
    return ERC2981Base.supportsInterface( interfaceId_ ) || Reg_ERC721Batch.supportsInterface( interfaceId_ );
  }

  /**
  * @dev returns an array of token ids owned by `_owner`
  */
  function tokensOfWalletOwner( address _owner ) public view returns ( uint256[] memory ) {
    uint256 tokenCount = _balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  /**
  * @dev returns either:
  * 'baseURI`
  * OR
  * 'baseURI' + 'tokenId' + 'uriSuffix'
  */
  function tokenURI( uint256 tokenId ) public view virtual override returns ( string memory ) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if (bytes( _baseURI ).length == 0) return "";
      if ( isRevealed ) return string(abi.encodePacked( _baseURI, _toString( tokenId ), uriSuffix));
      return string(abi.encodePacked( _baseURI ));
    }
	// **************************************
}