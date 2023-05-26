pragma solidity ^0.8.4;

import './QuiddMintablesBase.sol';
import './roles/AdminRole.sol';
import './roles/MinterRole.sol';
import './roles/UnminterRole.sol';
import './royalties/ERC2981/ERC2981TokenIDMask.sol';
import './token_id/TokenIDMaskRestrictor.sol';

// Generic contract for any Ethereum Mainnet contract with no central directory contract
contract QuiddMintables is QuiddMintablesBase, TokenIDMaskRestrictor, ERC2981TokenIDMask, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant UNMINTER_ROLE = keccak256("UNMINTER_ROLE");

  // Base URI
  string private _theBaseURI;
  
  // Sets the base URI for all tokens managed by the contract
  constructor(
	      string memory _name,
	      string memory _symbol,
	      string memory baseURI_,
	      uint256[] memory _allowedMasks,
	      uint256[] memory _allowedValues,
	      uint256 _basisPoints,
	      address _payee)
      QuiddMintablesBase(_name, _symbol)
      TokenIDMaskRestrictor(_allowedMasks, _allowedValues)
      ERC2981TokenIDMask(_basisPoints, _payee) {
    _setBaseURI(baseURI_);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(UNMINTER_ROLE, _msgSender());
  }
  
  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function _baseURI() internal view virtual override returns (string memory) {
      return _theBaseURI;
  }
  
  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function _setBaseURI(string memory baseURI_) internal virtual {
    _theBaseURI = baseURI_;
  }
    
  /**
   * @dev Mints a token to an address with a tokenURI. Less gas than safeMint, but should only be called for user wallets as _to.
   * @param _to address of the future owner of the token
   * @param _tokenId the ID of the print as registered with Quidd
   */
  function mint(address _to, uint256 _tokenId) public override {
      require(hasRole(MINTER_ROLE, _msgSender()), "Not a Minter");
      require(_tokenIDAllowed(_tokenId), "Token ID not allowed");
      super.mint(_to, _tokenId);
  }
  
  /**
   * @dev Safe Mints a token to an address with a tokenURI.
   * @param _to address of the future owner of the token
   * @param _tokenId the ID of the print as registered with Quidd
   * TODO: Implement custom indexing of tokens to save gas
   */
  function safeMint(address _to, uint256 _tokenId) public override {
      require(hasRole(MINTER_ROLE, _msgSender()), "Not a Minter");
      require(_tokenIDAllowed(_tokenId), "Token ID not allowed");
      super.safeMint(_to, _tokenId);
  }
  
  /**
   * @dev Moves token ownership to the contract address, making it unminted
   * @param _tokenId the Token ID, formatted according to the QuiddTokenID standard
   *
   * TODO: Make unmint an interface!
   */
  function unmint(uint256 _tokenId) public override {
      require(hasRole(UNMINTER_ROLE, _msgSender()), "Not an Unminter");
      super.unmint(_tokenId);
  }
  
  // TokenIDMaskRestrictor functions
  
  /**
   * @dev Adds an entry to the allowed token IDs
   * @param mask the bitwise mask to define which parameters to match on the token id
   * @param value the value to match on the token id
   */
  function addAllowedTokenIDConfiguration(
					  uint256 mask,
					  uint256 value
					  )
      public
  {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not an Admin");
      _addAllowedTokenIDConfiguration(mask, value);
  }
  
  /**
   * @dev Resets the configurations of token IDs permitted for minting
   * @param masks The list of bitwise mask to define which parameters to match on the token id
   * @param values The list of values to match on the token id
   */
  function setAllowedTokenIDConfigurations(
					   uint256[] memory masks,
					   uint256[] memory values
					   )
      public
  {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not an Admin");
      _setAllowedTokenIDConfigurations(masks, values);
  }
  
  /**
   * @dev Returns the full list of allowed token ID configurations
   * @return The complete list of AllowedTokenIDConfig elements
   */
  function getAllowedTokenIDConfigurations()
      public
      view
      returns (AllowedTokenIDConfig[] memory)
  {
      return _getAllowedTokenIDConfigurations();
  }
  
  // ERC2981TokenIDMask functions

  /**
   * @dev Sets default token royalties
   * @param basisPoints the royalty percent in basis points (using 2 decimals: 10000 = 100, 0 = 0)
   * @param payee recipient of the royalties
   */
  function setDefaultRoyalties(
			       uint256 basisPoints,
			       address payee
			       )
    public
  {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not an Admin");
    _setDefaultRoyalties(basisPoints, payee);
  }

  /**
   * @dev Adds an entry to the royalties configuration array
   * @param mask the bitwise mask to define which parameters to match on the token id
   * @param value the value to match on the token id
   * @param basisPoints the royalty percent in basis points (using 2 decimals: 10000 = 100, 0 = 0)
   * @param payee recipient of the royalties
   */
  function addRoyaltyConfiguration(
				   uint256 mask,
				   uint256 value,
				   uint256 basisPoints,
				   address payee
				   )
    public
  {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not an Admin");
    _addRoyaltyConfiguration(mask, value, basisPoints, payee);
  }

  /**
   * @dev Resets the configurations 
   * @param masks The list of bitwise mask to define which parameters to match on the token id
   * @param values The list of values to match on the token id
   * @param basisPoints The list of royalty percents in basis points (using 2 decimals: 10000 = 100, 0 = 0)
   * @param payees The list of recipients of the royalties
   */
  function setRoyaltyConfigurations(
				    uint256[] memory masks,
				    uint256[] memory values,
				    uint256[] memory basisPoints,
				    address[] memory payees
				    )
    public
  {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not an Admin");
    _setRoyaltyConfigurations(masks, values, basisPoints, payees);
  }
  
  /**
   * @dev Returns the default royalty configuration
   * @return The PaymentInfo struct representing the default royalty configuration
   */
  function getRoyaltyConfigurations()
    public
    view
    returns (RoyaltiesConfig[] memory)
  {
    return _getRoyaltyConfigurations();
  }

  /**
   * @dev Returns the full list of custom royalty configurations, default not included
   * @return The complete list of RoyaltiesConfig elements
   */
  function getDefaultRoyalties()
    public
    view
    returns (PaymentInfo memory)
  {
    return _getDefaultRoyalties();
  }
  
  /**
   * @inheritdoc ERC165
   */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(QuiddMintablesBase, ERC2981TokenIDMask, AccessControl)
      returns (bool)
  {
      return QuiddMintablesBase.supportsInterface(interfaceId) ||
	  ERC2981TokenIDMask.supportsInterface(interfaceId) ||
	  AccessControl.supportsInterface(interfaceId);
  }
}