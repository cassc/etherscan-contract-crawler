pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import '../../token_id/QuiddTokenIDv0.sol';
import './IERC2981.sol';

/**
 * @dev This abstract contract provides for configuration and calculation of royalties 
 * based on NFT data stored in the Token ID, according to the QuiddTokenIDv0 format.
 *
 * This implementation specifically uses a bitwise mask over the token ID to check for a match,
 * which works something like the example below (this is simplification just for illustration):
 * 110000011000 - Mask
 * 100000010000 - Match value
 * 10XXXXX10XXX - What the Token ID must look like in bits
 * 100110010110 - Token ID (match)
 * 101111010111 - Token ID (match)
 * 110110010110 - Token ID (not a match)
 *
 * This is done by doing a bitwise AND of the mask and the Token ID, then seeing if the result exactly matches the match value
 *
 * In practice, this means that distinct royalties can be configured for single attributes, or for multiple attributes ANDed together. E.g.
 * - Publisher ID = 120
 * - Set ID = 98293
 * - Product Type = Figure
 * - Item Type = Award
 * - Edition = 1
 * - Publisher ID = 120 and Product Type = Figure and Item Type = Award
 * - Edition = 1 and Number = 1
 * 
 * Not supported:
 * - Publisher ID = 120 or Item Type = Award (this could be supported with 2 separate entries)
 * - Print Number < 10
 * - Set ID != 2398
 * - Total Count = 1000 (this data isn’t stored in the Token ID)
 *
 * To reduce complexity and gas costs, the ordering of masks is FILO. 
 * Newer configurations are assumed to more likely to be used. This also allows an old configurations to be replaced without having to delete the previous entry.
 * As a best practice, more specific rules should be added after more general ones, since the algorithm returns the first match.
 *
 * Order of specificity (more specific to less) (in general - specific cases may vary):
 * - Print ID
 * - Shiny ID
 * - Print Number
 * - Quidd ID
 * - Set ID
 * - Channel ID
 * - Publisher ID
 * - Product Type
 * - Item Type
 * - Edition
 * - Token ID Version
 *
 * Note that ANDing two categories makes for a more specific rule (e.g. Channel ID AND Product Type)
 * Note also that due to hierarchical structure, it would be redundant to AND any of the following:
 * - Publisher ID -> Channel ID -> Set ID -> Quidd ID -> Shiny ID
 */
abstract contract ERC2981TokenIDMask is ERC165, IERC2981 {
  using QuiddTokenIDv0 for uint256;

  struct PaymentInfo {
    uint24 basisPoints;
    address payee;
  }

  struct RoyaltiesConfig {
    uint256 mask;
    uint256 value;
    PaymentInfo info;
  }
    
  PaymentInfo public _defaultRoyalties;
  RoyaltiesConfig[] public _royaltyConfigs;
  
  /**
   * The constructor does not set the baseURI, but rather leaves that up to subclasses
   */
  constructor(uint256 _basisPoints, address _payee) {
    _setDefaultRoyalties(_basisPoints, _payee);
  }

  /**
   * @inheritdoc IERC2981
   */
  function royaltyInfo(uint256 tokenId, uint256 value)
    external
    view
    override
    returns (address payee, uint256 royaltyAmount)
  {
    PaymentInfo memory royalties = _defaultRoyalties;
    RoyaltiesConfig memory config;

    // Find proper mask
    if (_royaltyConfigs.length > 0) {
      for (int i = int(_royaltyConfigs.length - 1); i >= 0; i--) {
        config = _royaltyConfigs[uint(i)];
	if ((tokenId & config.mask) == config.value) {
	  royalties = config.info;
	  break;
	}
      }
    }
    
    payee = royalties.payee;
    royaltyAmount = (value * royalties.basisPoints) / 10000;
  }

  /**
   * @dev Sets default token royalties
   * @param basisPoints the royalty percent in basis points (using 2 decimals: 10000 = 100, 0 = 0) - maximum 2000 (20%) allowed
   * @param payee recipient of the royalties
   */
  function _setDefaultRoyalties(
			       uint256 basisPoints,
			       address payee
			    )
    internal
  {
    require(basisPoints <= 2000, "Invalid royalty");
    require(payee != address(0), "Invalid payee");
    _defaultRoyalties = PaymentInfo(uint24(basisPoints), payee);
  }

  /**
   * @dev Adds an entry to the royalties configuration array
   * @param mask the bitwise mask to define which parameters to match on the token id
   * @param value the value to match on the token id
   * @param basisPoints the royalty percent in basis points (using 2 decimals: 10000 = 100, 0 = 0)
   * @param payee recipient of the royalties
   */
  function _addRoyaltyConfiguration(
			       uint256 mask,
			       uint256 value,
			       uint256 basisPoints,
			       address payee
			    )
    internal
  {
    _validateRoyaltyConfiguration(mask, value, basisPoints, payee);
    _royaltyConfigs.push(RoyaltiesConfig(
				mask,
				value,
				PaymentInfo(uint24(basisPoints), payee)
				));
  }

  /**
   * @dev Validates the data supplied for a royalty configuration
   * @param mask the bitwise mask to define which parameters to match on the token id
   * @param value the value to match on the token id
   * @param basisPoints the royalty percent in basis points (using 2 decimals: 10000 = 100, 0 = 0)
   * @param payee recipient of the royalties
   */
  function _validateRoyaltyConfiguration(
			       uint256 mask,
			       uint256 value,
			       uint256 basisPoints,
			       address payee
			    )
    internal
    pure
  {
    require(mask > 0, "Invalid mask");
    require(value <= mask, "Value incompatible with mask");
    require(basisPoints <= 2000, "Invalid royalty");
    require(payee != address(0), "Invalid payee");
  }
  
  /**
   * @dev Resets the configurations 
   * @param masks The list of bitwise mask to define which parameters to match on the token id
   * @param values The list of values to match on the token id
   * @param basisPoints The list of royalty percents in basis points (using 2 decimals: 10000 = 100, 0 = 0)
   * @param payees The list of recipients of the royalties
   */
  function _setRoyaltyConfigurations(
			       uint256[] memory masks,
			       uint256[] memory values,
			       uint256[] memory basisPoints,
			       address[] memory payees
			    )
    internal
  {
    require(masks.length == values.length, "Royalty masks don't match values");
    require(masks.length == basisPoints.length, "Royalty masks don't match basis points");
    require(masks.length == payees.length, "Royalty masks don't match payees");

    delete _royaltyConfigs;
    for (uint i=0; i < masks.length; i++) {
      _addRoyaltyConfiguration(masks[i], values[i], basisPoints[i], payees[i]);
    }
  }

  /**
   * @dev Returns the default royalty configuration
   * @return The PaymentInfo struct representing the default royalty configuration
   */
  function _getDefaultRoyalties()
    public
    view
    returns (PaymentInfo memory)
  {
    return _defaultRoyalties;
  }

  /**
   * @dev Returns the full list of custom royalty configurations, default not included
   * @return The complete list of RoyaltiesConfig elements
   */
  function _getRoyaltyConfigurations()
    internal
    view
    returns (RoyaltiesConfig[] memory) {
    return _royaltyConfigs;
  }

  /**
   * @inheritdoc ERC165
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }
  
}


contract TestERC2981TokenIDMask is ERC2981TokenIDMask {
  constructor(uint256 _basisPoints, address _payee) ERC2981TokenIDMask(_basisPoints, _payee) {
  }

  function setDefaultRoyalties(
			       uint256 basisPoints,
			       address payee
			       )
    public
  {
    _setDefaultRoyalties(basisPoints, payee);
  }

  function addRoyaltyConfiguration(
				   uint256 mask,
				   uint256 value,
				   uint256 basisPoints,
				   address payee
				   )
    public
  {
    _addRoyaltyConfiguration(mask, value, basisPoints, payee);
  }

  function setRoyaltyConfigurations(
				    uint256[] memory masks,
				    uint256[] memory values,
				    uint256[] memory basisPoints,
				    address[] memory payees
				    )
    public
  {
    _setRoyaltyConfigurations(masks, values, basisPoints, payees);
  }
  
  function getRoyaltyConfigurations()
    public
    view
    returns (RoyaltiesConfig[] memory)
  {
    return _getRoyaltyConfigurations();
  }

  function getDefaultRoyalties()
    public
    view
    returns (PaymentInfo memory)
  {
    return _getDefaultRoyalties();
  }
}