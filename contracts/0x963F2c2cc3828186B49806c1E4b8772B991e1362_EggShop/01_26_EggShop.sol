// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import './interfaces/IEggShop.sol';
import './interfaces/IEGGToken.sol';
import './libs/ERC2981ContractWideRoyalties.sol';
import { NFTDescriptor } from './libs/NFTDescriptor.sol';

import { DefaultOperatorFilterer } from './external/OpenSea/DefaultOperatorFilterer.sol';

contract EggShop is IEggShop, ERC1155, Ownable, ERC2981ContractWideRoyalties, DefaultOperatorFilterer {
  // Events
  event EggShopMint(uint256 indexed typeId, address indexed owner, uint256 quantity);
  event EggShopBurn(uint256 indexed typeId, address indexed owner, uint256 quantity);
  event UpdateTypeSupplyExchange(uint256 indexed typeId, uint256 maxSupply, uint256 eggMintAmt, uint256 eggBurnAmt);
  event TypeNameUpdated(uint256 indexed typeId, string name);
  event InitializedContract(address thisContract);

  // EggShop Color Palettes (Index => Hex Colors)
  mapping(uint8 => string[]) private palettes;

  // EggShop Accessories (Custom RLE)
  // Storage of each image data
  struct EggShopImage {
    string name;
    bytes rlePNG;
  }

  mapping(uint256 => EggShopImage) private traitRLEData;

  // Common description that shows in all tokenUri
  string private metadataDescription =
    'Specialty Eggs & items can be bought from the Egg Shop. Fabled to hold special properties, only Season 1 Farm Game holders will know what they hold.'
    ' All images and metadata is generated and stored 100% on-chain. No IPFS, No API. Just the blockchain. https://thefarm.game';

  mapping(uint256 => TypeInfo) private typeInfo;

  // Reference to the $EGG contract for minting $EGG earnings
  IEGGToken public eggToken;

  // address => allowedToCallFunctions
  mapping(address => bool) private controllers;

  /** MODIFIERS */

  /**
   * @dev Modifer to require msg.sender to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[msg.sender], 'Only controllers');
  }

  constructor(IEGGToken _eggToken) ERC1155('') {
    eggToken = _eggToken;
    controllers[msg.sender] = true;
    emit InitializedContract(address(this));
  }

  /**
   *  ███    ███ ██ ███    ██ ████████
   *  ████  ████ ██ ████   ██    ██
   *  ██ ████ ██ ██ ██ ██  ██    ██
   *  ██  ██  ██ ██ ██  ██ ██    ██
   *  ██      ██ ██ ██   ████    ██
   */

  /**
   * @notice Mint a token - game logic should be handled in the game contract
   * @dev Only callable by a controller
   * @param typeId the TypeID of the NFT to mint
   * @param quantity the number of NFTs to mint
   * @param recipient the address to recieve the minted NFTs
   * @param eggAmt this is the quantity of EGG to purchase. If 0, then use typeInfo.eggMintAmt.
   * 	This allows for dynamic pricing as needed for Apple Pie and must be calculated in calling contract
   */
  function mint(
    uint256 typeId,
    uint16 quantity,
    address recipient,
    uint256 eggAmt
  ) external override onlyController {
    require(typeInfo[typeId].maxSupply > 0, 'Invalid type');
    require(
      typeInfo[typeId].mints - typeInfo[typeId].burns + quantity <= typeInfo[typeId].maxSupply,
      'All tokens minted'
    );

    // If the ERC1155 is swapped for $EGG, transfer the EGG to this contract in case the swap back is desired.
    if (eggAmt > 0) {
      eggToken.transferFrom(tx.origin, address(this), eggAmt);
    } else if (typeInfo[typeId].eggMintAmt > 0) {
      eggToken.transferFrom(tx.origin, address(this), typeInfo[typeId].eggMintAmt * quantity);
    }
    typeInfo[typeId].mints += quantity;
    _mint(recipient, typeId, quantity, '');
    emit EggShopMint(typeId, recipient, quantity);
  }

  /**
   * @notice Mint a free token
   * @dev Only callable by a controller
   * @param typeId the TypeID of the NFT to mint
   * @param quantity the number of NFTs to mint
   * @param recipient the address to recieve the minted NFTs
   */
  function mintFree(
    uint256 typeId,
    uint16 quantity,
    address recipient
  ) external onlyController {
    require(typeInfo[typeId].maxSupply > 0, 'Invalid type');
    require(
      typeInfo[typeId].mints - typeInfo[typeId].burns + quantity <= typeInfo[typeId].maxSupply,
      'All tokens minted'
    );

    typeInfo[typeId].mints += quantity;
    _mint(recipient, typeId, quantity, '');
    emit EggShopMint(typeId, recipient, quantity);
  }

  /**
   * @notice Burn a token - any payment / game logic should be handled in the game contract
   * @dev Only callable by a controller
   * @param typeId the TypeID of the NFT to burn
   * @param quantity the number of NFTs to burn
   * @param burnFrom the address to burn the NFTs from
   * * @param eggAmt this is the quantity of EGG to refund. If 0, then use typeInfo.eggBurnAmt.
   * 	This allows for dynamic refund as needed for Apple Pie and must be calculated in calling contract
   */
  function burn(
    uint256 typeId,
    uint16 quantity,
    address burnFrom,
    uint256 eggAmt
  ) external override onlyController {
    require(typeInfo[typeId].mints > 0, 'None minted');
    // If the ERC1155 was swapped from $EGG, transfer the EGG from this contract back to whoever owns this token now.
    if (eggAmt > 0) {
      eggToken.transferFrom(address(this), tx.origin, eggAmt);
    } else if (typeInfo[typeId].eggBurnAmt > 0) {
      eggToken.transferFrom(address(this), tx.origin, typeInfo[typeId].eggBurnAmt * quantity);
    }
    typeInfo[typeId].burns += quantity;
    _burn(burnFrom, typeId, quantity);
    emit EggShopBurn(typeId, msg.sender, quantity);
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override(ERC1155, IEggShop) onlyAllowedOperator {
    // allow controller contracts to be send without approval
    if (!controllers[msg.sender]) {
      require((from == msg.sender) || isApprovedForAll(from, msg.sender), 'Caller is not owner nor approved');
    }
    super.safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override(ERC1155, IERC1155) onlyAllowedOperator {
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      'ERC1155: caller is not token owner nor approved'
    );
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /**
   * @notice Add a single color to a color palette
   * @param _paletteIndex index for current color
   * @param _color 6 character hex code for color
   */
  function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
    require(bytes(_color).length == 6 || bytes(_color).length == 0, 'Wrong length');
    palettes[_paletteIndex].push(_color);
  }

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice Transfer ETH and return the success status.
   * @dev This function only forwards 30,000 gas to the callee.
   * @param to Address for ETH to be send to
   * @param value Amount of ETH to send
   */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
    return success;
  }

  /**
   * @notice Set Type exchange amount for EggShop types
   * @dev Only callable by an existing controller
   * @param typeId the typeID of the NFT
   * @param maxSupply max supply for type
   * @param eggMintAmt egg mint amount for type
   * @param eggBurnAmt egg burn amount for type
   */

  function _setSupplyExchangeAmt(
    uint256 typeId,
    uint16 maxSupply,
    uint256 eggMintAmt,
    uint256 eggBurnAmt
  ) internal {
    typeInfo[typeId].maxSupply = maxSupply;
    typeInfo[typeId].eggMintAmt = eggMintAmt * 10**18;
    typeInfo[typeId].eggBurnAmt = eggBurnAmt * 10**18;

    emit UpdateTypeSupplyExchange(typeId, maxSupply, eggMintAmt * 10**18, eggBurnAmt * 10**18);
  }

  /**
   * @notice Upload a single image
   * @dev Only callable internally
   * @param typeId the typeID of the NFT
   * @param image calldata for image {name / RLE image rlePNG}
   */
  function _uploadRLEImage(uint256 typeId, EggShopImage calldata image) internal {
    traitRLEData[typeId] = EggShopImage(image.name, image.rlePNG);
    emit TypeNameUpdated(typeId, image.name);
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @notice returns info about a Type
   * @param typeId the typeId to return info for
   */

  function getInfoForType(uint256 typeId) public view returns (TypeInfo memory) {
    require(typeInfo[typeId].maxSupply > 0, 'Invalid type');
    return typeInfo[typeId];
  }

  /**
   * @notice returns info about a Type with Name
   * @param typeId the typeId to return info for
   */

  function getInfoForTypeName(uint256 typeId) public view returns (DetailedTypeInfo memory) {
    require(typeInfo[typeId].maxSupply > 0, 'Invalid type');

    DetailedTypeInfo memory detailedTypeInfo = DetailedTypeInfo({
      name: traitRLEData[typeId].name,
      mints: typeInfo[typeId].mints,
      burns: typeInfo[typeId].burns,
      maxSupply: typeInfo[typeId].maxSupply,
      eggMintAmt: typeInfo[typeId].eggMintAmt,
      eggBurnAmt: typeInfo[typeId].eggBurnAmt
    });

    return detailedTypeInfo;
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override(ERC1155, IERC1155)
    returns (bool)
  {
    if (controllers[owner] || controllers[operator]) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function uri(uint256 typeId) public view override returns (string memory) {
    require(typeInfo[typeId].maxSupply > 0, 'Invalid type or Max Supply not set');
    return _dataURI(typeId);
  }

  /**
   * @notice Given a typeId, construct a base64 encoded data URI for an EggShop NFT.
   */
  function _dataURI(uint256 typeId) internal view returns (string memory) {
    string memory name = string(abi.encodePacked(traitRLEData[typeId].name));

    return _genericDataURI(name, metadataDescription, typeId);
  }

  /**
   * @notice Given a name, description, and typeId, construct a base64 encoded data URI
   */
  function _genericDataURI(
    string memory name,
    string memory description,
    uint256 typeId
  ) internal view returns (string memory) {
    NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
      name: name,
      description: description,
      background: '------',
      elements: _getElementsForTypeId(typeId),
      attributes: '',
      advantage: 0,
      width: uint8(32),
      height: uint8(32)
    });

    return NFTDescriptor.constructTokenURI(params, palettes);
  }

  /**
   * @notice Get all TheFarm elements for the passed `seed`.
   * @param typeId Seed string
   */
  function _getElementsForTypeId(uint256 typeId) internal view returns (bytes[] memory) {
    bytes[] memory _elements = new bytes[](1);
    _elements[0] = traitRLEData[typeId].rlePNG;
    return _elements;
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by an existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by an existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  // Royalty settings

  /**
   * @notice Set the _collectionName
   * @dev Only callable by an existing controller
   * @param _newName the NFT collection name
   * @param _newDesc the NFT collection description
   * @param _newImageUri the NFT collection impage URL (ipfs://folder/to/cid)
   * @param _newFee set the NFT royalty fee 10% max percentage (using 2 decimals - 10000 = 100, 0 = 0)
   * @param _newRecipient set the address of the royalty fee recipient
   */
  function setCollectionInfo(
    string memory _newName,
    string memory _newDesc,
    string memory _newImageUri,
    string memory _newExtLink,
    uint16 _newFee,
    address _newRecipient
  ) external onlyOwner {
    _collectionName = _newName;
    _collectionDescription = _newDesc;
    _imageUri = _newImageUri;
    _externalLink = _newExtLink;
    _sellerRoyaltyFee = _newFee;
    _recipient = _newRecipient;
    _setRoyalties(_newRecipient, _newFee);
  }

  /**
   * @notice Add a single color to a color palette
   * @dev Only callable by an existing controller
   * @param _paletteIndex index for current color
   * @param _color 6 character hex code for color
   */
  function addColorToPalette(uint8 _paletteIndex, string calldata _color) external onlyController {
    require(palettes[_paletteIndex].length < 256, 'Palettes can only hold 256 colors');
    _addColorToPalette(_paletteIndex, _color);
  }

  /**
   * @notice Add colors to a color palette
   * @dev Only callable by an existing controller
   * @param _paletteIndex index for colors
   * @param _colors Array of 6 character hex code for colors
   */
  function addManyColorsToPalette(uint8 _paletteIndex, string[] calldata _colors) external onlyController {
    require(palettes[_paletteIndex].length + _colors.length <= 256, 'Palettes can only hold 256 colors');
    for (uint256 i = 0; i < _colors.length; i++) {
      _addColorToPalette(_paletteIndex, _colors[i]);
    }
  }

  /**
   * @notice Set contract address
   * @dev Only callable by an existing controller
   * @param _address Address of eggToken contract
   */

  function setEggToken(address _address) external onlyController {
    eggToken = IEGGToken(_address);
  }

  /**
   * @notice Set Type maxSupply for EggShop types
   * @dev Only callable by an existing controller
   * @param typeId the typeID of the NFT
   * @param maxSupply max supply for type
   */
  function setType(uint256 typeId, uint16 maxSupply) external onlyController {
    require(typeInfo[typeId].mints <= maxSupply, 'Max supply too low');
    typeInfo[typeId].maxSupply = maxSupply;
  }

  /**
   * @notice Set Type supply and mint/burn amounts for EggShop types
   * @dev Only callable by an existing controller
   * @param typeId the typeID of the NFT
   * @param maxSupply max supply for type
   * @param eggMintAmt egg mint amount for type
   * @param eggBurnAmt egg burn amount for type
   */
  function setSupplyExchangeAmt(
    uint256 typeId,
    uint16 maxSupply,
    uint256 eggMintAmt,
    uint256 eggBurnAmt
  ) external onlyController {
    require(typeInfo[typeId].mints <= maxSupply, 'Max supply too low');
    _setSupplyExchangeAmt(typeId, maxSupply, eggMintAmt, eggBurnAmt);
  }

  /**
   * @notice Set Type exchange amount for EggShop types
   * @dev Only callable by an existing controller
   * @param startTypeId the starting typeID of the NFT + 1 will be added for each array element
   * @param typeData max supply for type
   */
  struct TypeInfoTemp {
    uint16 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
  }

  /**
   * @notice Set Many Type exchange amount for EggShop types
   * @dev Only callable by an existing controller
   * @param startTypeId the start typeID of the NFT
   * @param typeInfoTemp Type Info Temp datas to set EggShop Type
   */

  function setManySupplyExchangeAmt(uint256 startTypeId, TypeInfoTemp[] calldata typeInfoTemp) external onlyController {
    for (uint256 i = 0; i < typeInfoTemp.length; i++) {
      require(typeInfo[i].mints <= typeInfoTemp[i].maxSupply, 'Max supply too low');
      _setSupplyExchangeAmt(
        startTypeId + i,
        typeInfoTemp[i].maxSupply,
        typeInfoTemp[i].eggMintAmt,
        typeInfoTemp[i].eggBurnAmt
      );
    }
  }

  /**
   * @notice Update the metadata description
   * @dev Only callable by the controller
   * @param _desc New description
   */

  function updateMetaDesc(string memory _desc) external onlyController {
    metadataDescription = _desc;
  }

  /**
   * @notice Upload a single EggShop type
   * @dev Only callable by an existing controller
   * @param typeId the typeID of the NFT
   * @param image calldata for image {name / base64 base64PNG}
   */
  function uploadRLEImage(uint256 typeId, EggShopImage calldata image) external onlyController {
    _uploadRLEImage(typeId, image);
  }

  /**
   * @notice Upload multiple EggShop types
   * @dev Only callable by an existing controller
   * @param startTypeId the starting typeID of the NFT + 1 will be added for each array element
   * @param _images calldata for image {name / base64 base64PNG}
   */
  function uploadManyRLEImages(uint256 startTypeId, EggShopImage[] calldata _images) external onlyController {
    for (uint256 i = 0; i < _images.length; i++) {
      _uploadRLEImage(startTypeId + i, _images[i]);
    }
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, IERC165, ERC2981Base)
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165
      interfaceId == 0x0e89341c || // ERC165 interface ID for ERC1155
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981
      super.supportsInterface(interfaceId);
  }
}