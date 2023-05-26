pragma solidity ^0.8.4;

import './QuiddTokenIDv0.sol';

/**
 * @dev This abstract contract adds a constraint for Quidd Mintables regarding which items can be minted to the contract
 * based on NFT data stored in the Token ID, according to the QuiddTokenIDv0 format.
 *
 * This implementation specifically uses a bitwise mask over the token ID to check for a match,
 * which works something like the example below (this is a simplification just for illustration):
 * 110000011000 - Mask
 * 100000010000 - Match value
 * 10XXXXX10XXX - What the Token ID must look like in bits
 * 100110010110 - Token ID (match)
 * 101111010111 - Token ID (match)
 * 110110010110 - Token ID (not a match)
 *
 * This is done by doing a bitwise AND of the mask and the Token ID, then seeing if the result exactly matches the match value
 *
 * Only token IDs that match one of the masks can be minted to the contract.
 * Match rules can be configured for single attributes, or for multiple attributes ANDed together. E.g.
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
 * Note that due to hierarchical structure, it would be redundant to AND any of the following:
 * - Publisher ID -> Channel ID -> Set ID -> Quidd ID -> Shiny ID
 */
abstract contract TokenIDMaskRestrictor {
  using QuiddTokenIDv0 for uint256;

  struct AllowedTokenIDConfig {
    uint256 mask;
    uint256 value;
  }
    
  AllowedTokenIDConfig[] public _allowedTokenIDConfigs;
  
  /**
   * The constructor does not 
   */
  constructor(
	      uint256[] memory masks,
	      uint256[] memory values
	      )
      {
	  _setAllowedTokenIDConfigurations(masks, values);
      }
  
  /**
   * @dev Utility method to check if the contract should allow the token ID to be minted to this contract. Should be called by the mint/safemint methods.
   * @param tokenId the token id to be verified against the allow configurations
   */
  function _tokenIDAllowed(uint256 tokenId)
      internal
      view
      returns (bool)
  {
      // Find proper mask
      if (_allowedTokenIDConfigs.length > 0) {
	  for (uint i = 0; i < _allowedTokenIDConfigs.length; i++) {
	      AllowedTokenIDConfig memory config = _allowedTokenIDConfigs[i];
	      if ((tokenId & config.mask) == config.value) {
		  return true;
	      }
	  }
      } else {
	  return true;
      }    
      return false;
  }
  
  /**
   * @dev Adds an entry to the allowed token IDs
   * @param mask the bitwise mask to define which parameters to match on the token id
   * @param value the value to match on the token id
   */
  function _addAllowedTokenIDConfiguration(
				    uint256 mask,
				    uint256 value
				    )
      internal
  {
      require(_allowedTokenIDConfigs.length < 100, "Reached max configurations");
      _validateAllowedTokenIDConfiguration(mask, value);
      _allowedTokenIDConfigs.push(AllowedTokenIDConfig(
						       mask,
						       value
						       ));
  }

  /**
   * @dev Validates the data supplied for a token ID mask configuration
   * @param mask the bitwise mask to define which parameters to match on the token id
   * @param value the value to match on the token id
   */
  function _validateAllowedTokenIDConfiguration(
						uint256 mask,
						uint256 value
						)
      internal
      pure
  {
      require(mask > 0, "Mask can't be zero");
      require(value <= mask, "Value incompatible with mask");
  }
  
  /**
   * @dev Resets the configurations 
   * @param masks The list of bitwise mask to define which parameters to match on the token id
   * @param values The list of values to match on the token id
   */
  function _setAllowedTokenIDConfigurations(
				     uint256[] memory masks,
				     uint256[] memory values
				     )
      internal
  {
      require(masks.length == values.length, "Masks don't match values");
      require(masks.length <= 100, "Too many configurations");
      
      delete _allowedTokenIDConfigs;
      for (uint i=0; i < masks.length; i++) {
	  _addAllowedTokenIDConfiguration(masks[i], values[i]);
      }
  }
  
  /**
   * @dev Returns the full list of allowed token ID configurations
   * @return The complete list of AllowedTokenIDConfig elements
   */
  function _getAllowedTokenIDConfigurations()
    internal
    view
    returns (AllowedTokenIDConfig[] memory) {
    return _allowedTokenIDConfigs;
  }
}


contract TestTokenIDMaskRestrictor is TokenIDMaskRestrictor {
    constructor(
		uint256[] memory masks,
		uint256[] memory values
		)
	TokenIDMaskRestrictor(masks, values) {
    }
    
    function addAllowedTokenIDConfiguration(
					    uint256 mask,
					    uint256 value
					    )
	public
    {
	_addAllowedTokenIDConfiguration(mask, value);
    }

    function setAllowedTokenIDConfigurations(
				      uint256[] memory masks,
				      uint256[] memory values
				      )
	public
    {
	_setAllowedTokenIDConfigurations(masks, values);
    }
    
    function getAllowedTokenIDConfigurations()
	public
	view
	returns (AllowedTokenIDConfig[] memory)
    {
	return _getAllowedTokenIDConfigurations();
    }

    function tokenIDAllowed(uint256 tokenId)
	public
	view
	returns (bool)
    {
	return _tokenIDAllowed(tokenId);
    }
}