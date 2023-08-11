//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../main/MentaportMint.sol";
/**                                            
      
            ___           ___           ___                         ___           ___         ___           ___                   
    /\  \         /\__\         /\  \                       /\  \         /\  \       /\  \         /\  \                  
  |::\  \       /:/ _/_        \:\  \         ___         /::\  \       /::\  \     /::\  \       /::\  \         ___     
  |:|:\  \     /:/ /\__\        \:\  \       /\__\       /:/\:\  \     /:/\:\__\   /:/\:\  \     /:/\:\__\       /\__\    
__|:|\:\  \   /:/ /:/ _/_   _____\:\  \     /:/  /      /:/ /::\  \   /:/ /:/  /  /:/  \:\  \   /:/ /:/  /      /:/  /    
/::::|_\:\__\ /:/_/:/ /\__\ /::::::::\__\   /:/__/      /:/_/:/\:\__\ /:/_/:/  /  /:/__/ \:\__\ /:/_/:/__/___   /:/__/     
\:\~~\  \/__/ \:\/:/ /:/  / \:\~~\~~\/__/  /::\  \      \:\/:/  \/__/ \:\/:/  /   \:\  \ /:/  / \:\/:::::/  /  /::\  \     
\:\  \        \::/_/:/  /   \:\  \       /:/\:\  \      \::/__/       \::/__/     \:\  /:/  /   \::/~~/~~~~  /:/\:\  \    
  \:\  \        \:\/:/  /     \:\  \      \/__\:\  \      \:\  \        \:\  \      \:\/:/  /     \:\~~\      \/__\:\  \   
  \:\__\        \::/  /       \:\__\          \:\__\      \:\__\        \:\__\      \::/  /       \:\__\          \:\__\  
    \/__/         \/__/         \/__/           \/__/       \/__/         \/__/       \/__/         \/__/           \/__/  
      
      
                      
                                                                  
**/

/**
* @title EnsembleArt
* @dev Extending MentaportDynamic
*
*  Adds functionality to have dynamic state upgrades of NFT tokens with defined location rules.
*/
contract EnsembleArt is MentaportMint {

  struct LocationRule {
      uint256 locationRuleId;
      uint256 locationRuleIndex;
  }
  struct LocationProp {
      uint8 colorSelection;
      uint8 shapeSelection;
      uint256 numberOfShapes;
  }

  uint256 public constant MAX_MINT_AMOUNT = 10;
  uint256 public maxLocationRules = 100;
  mapping(uint256 => LocationProp[]) internal _usedLocationRules;
  mapping(uint256 => LocationRule) internal _tokenIdLocationRules;
  mapping(uint256 => bool) internal _activeLocationRules;
  mapping(uint256 => string[]) internal _colorsRules;
  mapping(uint256 => string[]) internal _shapesRules;

  constructor(
      string memory _name,
      string memory _symbol,
      uint256 _maxSupply,
      address _admin,
      address _minter,
      address _signer,
      uint256 _locationRule1,
      uint256 _locationRule2,
      uint256 _locationRule3
  ) MentaportMint(_name, _symbol, _maxSupply, _admin, _minter, _signer)
  {
    maxMintAmount = MAX_MINT_AMOUNT;
    _activeLocationRules[_locationRule1] = true;
    _activeLocationRules[_locationRule2] = true;
    _activeLocationRules[_locationRule3] = true;

    _colorsRules[_locationRule1] = ['Mastic','Rouge','Lavande','Indigo', 'Dore'];
    _colorsRules[_locationRule2] = ['Ambre','Orange brulee','Mastic','Bourgogne','Dore'];
    _colorsRules[_locationRule3] = ['Turquoise','Bleu sarcelle','Lavande','Mastic','Dore'];
    
    _shapesRules[_locationRule1] = ['Pixel','Petit fleur','Fleur'];
    _shapesRules[_locationRule2] = ['Pixel','Petit crane', 'Crane'];
    _shapesRules[_locationRule3] = ['Pixel','Petit aile','Aile'];
  }

  function mintLocation( MintRequest calldata _mintRequest)
    override
    external
    payable
    nonReentrant
    whenNotPaused()
    mintCompliance(_mintRequest.receiver, msg.value, 1)
    onlyValidSigner(_mintRequest.receiver, _mintRequest.timestamp, _mintRequest.locationRuleId, _mintRequest.signature)
    returns (uint256)
  {
    //TODO: we dont want people usin this method. only mintWithLocationProps
    require(false, "Failed function not active, use mintWithLocationProps.");
    return 0;
  }

  function mintWithLocationProps(
    LocationProp calldata locationProp,
    MintRequest calldata _mintRequest
  )
  virtual
  external
  payable
  nonReentrant
  whenNotPaused()
  mintCompliance(_mintRequest.receiver, msg.value, 1)
  onlyValidSigner(_mintRequest.receiver, _mintRequest.timestamp, _mintRequest.locationRuleId, _mintRequest.signature)
  {
    require(_checkMintSignature(_mintRequest.signature), "Signature already used, not valid anymore.");
    require(_activeLocationRules[_mintRequest.locationRuleId], "locationRuleId passed not active");

    _mint(locationProp, _mintRequest);
  }

  function mintForAddress(
    LocationProp calldata locationProp,
    MintRequest calldata _mintRequest
  )
  external
  nonReentrant
  mintCompliance(_mintRequest.receiver, cost,1)
  onlyMinter {
      _mint(locationProp, _mintRequest);
  }

  function setMaxLocationRules(uint256 _maxLocationRules) public onlyOwner {
    maxLocationRules = _maxLocationRules;
  }

  function getTokenLocationRule(uint256 tokenId)
  public
  view
  returns(uint256 locationRuleId, uint256 locationRuleIndex) {
    return _getLocationFromTokenId(tokenId);
  }

  function getLocationRuleSize(uint256 locationRuleId)
  public
  view
  returns(uint256) {
    return _usedLocationRules[locationRuleId].length;
  }

  function getLocationPropByIndex(uint256 locationRuleId, uint256 locationRuleIndex)
  public
  view
  returns(LocationProp memory locationProp) {
    locationProp = _usedLocationRules[locationRuleId][locationRuleIndex];
    return locationProp;
  }

 function getLocationPropByTokenId(uint256 tokenId)
  public
  view
  returns(LocationProp memory locationProp) {
   (uint256 locationRuleId,uint256 locationRuleIndex ) = _getLocationFromTokenId(tokenId);
    locationProp = _usedLocationRules[locationRuleId][locationRuleIndex];
    return locationProp;
  }

  function getLocationPropValuesByTokenId(uint256 tokenId)
  public
  view
  returns(string memory colorName, string memory shapeName) {
   (uint256 locationRuleId, uint256 locationRuleIndex ) = _getLocationFromTokenId(tokenId);
    LocationProp memory locationProp = _usedLocationRules[locationRuleId][locationRuleIndex];
    colorName = _colorsRules[locationRuleId][locationProp.colorSelection];
    shapeName = _shapesRules[locationRuleId][locationProp.shapeSelection];
    return (colorName,shapeName);
  }

  function _setTokenIdLocation(
    uint256 _tokenId,
    uint256 _locationRuleId,
    uint256 _locationRuleIndex
  ) internal  {
    _tokenIdLocationRules[_tokenId] = LocationRule({
      locationRuleId : _locationRuleId,
      locationRuleIndex : _locationRuleIndex
    });
  }

  function _getLocationFromTokenId(uint256 tokenId) internal view returns(
    uint256 _locationRuleId, uint256 _locationRuleIndex
  ) {
    LocationRule memory locationRule = _tokenIdLocationRules[tokenId];
    return (locationRule.locationRuleId, locationRule.locationRuleIndex);
  }

  function _mint(
    LocationProp calldata locationProp,
    MintRequest calldata _mintRequest
  ) internal {
    uint256 length = _usedLocationRules[_mintRequest.locationRuleId].length;
    require(length < maxLocationRules, "All locations exhausted");
    require(locationProp.colorSelection < _colorsRules[_mintRequest.locationRuleId].length, "Color index out of bound");
    require(locationProp.shapeSelection < _shapesRules[_mintRequest.locationRuleId].length, "Shape index out of bound");

    _usedLocationRules[_mintRequest.locationRuleId].push(locationProp);
    uint256 tokenId = _mintNFT(_mintRequest.receiver, _mintRequest.tokenURI);
    _setTokenIdLocation(tokenId, _mintRequest.locationRuleId, length);
  }
}