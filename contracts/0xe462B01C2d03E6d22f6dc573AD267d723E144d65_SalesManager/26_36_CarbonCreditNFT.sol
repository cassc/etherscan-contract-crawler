// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./libraries/LibIMPT.sol";
import "./libraries/SigRecovery.sol";

import "../interfaces/ICarbonCreditNFT.sol";

contract CarbonCreditNFT is
  ICarbonCreditNFT,
  IERC1155MetadataURIUpgradeable,
  ERC1155Upgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  using StringsUpgradeable for uint256;

  IMarketplace public override MarketplaceContract;
  IInventory public override InventoryContract;
  ISoulboundToken public override SoulboundContract;
  IAccessManager public override AccessManager;

  string private _name;
  string private _symbol;

  modifier onlyMarketplace() {
    if (msg.sender != address(MarketplaceContract)) {
      revert TransferMethodDisabled();
    }
    _;
  }

  modifier onlyIMPTRole(bytes32 _role, IAccessManager _AccessManager) {
    LibIMPT._hasIMPTRole(_role, msg.sender, AccessManager);
    _;
  }

  function initialize(ConstructorParams memory _params) public initializer {
    __ERC1155_init(_formatBaseUri(_params.baseURI));
    __Pausable_init();
    __UUPSUpgradeable_init();

    LibIMPT._checkZeroAddress(address(_params.AccessManager));

    AccessManager = _params.AccessManager;

    _name = _params.name;
    _symbol = _params.symbol;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function uri(
    uint256 _id
  )
    public
    view
    override(
      ICarbonCreditNFT,
      ERC1155Upgradeable,
      IERC1155MetadataURIUpgradeable
    )
    returns (string memory)
  {
    return string.concat(super.uri(_id), "/", _id.toString());
  }

  /// @dev This function is to check that the upgrade functions in UUPSUpgradeable are being called by an address with the correct role
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {}

  function _verifyTransferRequest(
    TransferAuthorisationParams calldata _transferAuthParams,
    bytes calldata _transferAuthSignature
  ) internal view {
    bytes memory encodedTransferRequest = abi.encode(
      _transferAuthParams.expiry,
      _transferAuthParams.to
    );

    address recoveredAddress = SigRecovery.recoverAddressFromMessage(
      encodedTransferRequest,
      _transferAuthSignature
    );

    if (!AccessManager.hasRole(LibIMPT.IMPT_BACKEND_ROLE, recoveredAddress)) {
      revert LibIMPT.InvalidSignature();
    }

    if (_transferAuthParams.expiry < block.timestamp) {
      revert LibIMPT.SignatureExpired();
    }
  }

  function retire(uint256 _tokenId, uint256 _amount) external whenNotPaused {
    _burn(msg.sender, _tokenId, _amount);

    SoulboundContract.incrementRetireCount(msg.sender, _tokenId, _amount);
    InventoryContract.incrementBurnCount(_tokenId, _amount);
  }

  /// @dev The safeTransferFrom and safeBatchTransferFrom methods are disabled for users, this is because only KYCed user's can hold CarbonCreditNFT's. This KYC status is checked via a centralised backend and a signature is then generated that is validated by the contract. The methods transferFromBackendAuth and batchTransferFromBackendAuth allow this functionality.
  /// @dev Separately the safeTransferFrom and safeBatchTransferFrom are enabled for the MarketplaceContract as that contract will be handling the validation of sale orders and also has it's own checks for the backend signature auth
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  )
    public
    virtual
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    whenNotPaused
    onlyMarketplace
  {
    super.safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  )
    public
    virtual
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    whenNotPaused
    onlyMarketplace
  {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function transferFromBackendAuth(
    address from,
    uint256 id,
    uint256 amount,
    TransferAuthorisationParams calldata transferAuthParams,
    bytes calldata backendSignature
  ) public virtual override whenNotPaused {
    _verifyTransferRequest(transferAuthParams, backendSignature);

    super.safeTransferFrom(from, transferAuthParams.to, id, amount, "");
  }

  function batchTransferFromBackendAuth(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts,
    TransferAuthorisationParams calldata transferAuthParams,
    bytes calldata backendSignature
  ) public virtual override whenNotPaused {
    _verifyTransferRequest(transferAuthParams, backendSignature);

    super.safeBatchTransferFrom(from, transferAuthParams.to, ids, amounts, "");
  }

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  )
    external
    virtual
    override
    whenNotPaused
    onlyIMPTRole(LibIMPT.IMPT_MINTER_ROLE, AccessManager)
  {
    InventoryContract.updateTotalMinted(id, amount);
    _mint(to, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  )
    external
    virtual
    override
    whenNotPaused
    onlyIMPTRole(LibIMPT.IMPT_MINTER_ROLE, AccessManager)
  {
    for (uint8 i = 0; i < ids.length; i++) {
      InventoryContract.updateTotalMinted(ids[i], amounts[i]);
    }
    _mintBatch(to, ids, amounts, data);
  }

  /// @dev Concats the provided baseUri with the address of the contract in the following form: `${baseURL}/${address(this)}`
  /// @param _baseUri The base uri to use
  /// @return formattedBaseUri The formatted base uri
  function _formatBaseUri(
    string memory _baseUri
  ) internal view returns (string memory formattedBaseUri) {
    formattedBaseUri = string.concat(
      _baseUri,
      "/",
      StringsUpgradeable.toHexString(uint256(uint160(address(this))), 20)
    );
  }

  function setBaseUri(
    string calldata _baseUri
  ) external override onlyIMPTRole(LibIMPT.DEFAULT_ADMIN_ROLE, AccessManager) {
    string memory formattedBaseUri = _formatBaseUri(_baseUri);
    // Set the URI on the base ERC1155 contract and pull it from there using the uri() method when needed
    super._setURI(formattedBaseUri);

    emit BaseUriUpdated(formattedBaseUri);
  }

  function setMarketplaceContract(
    IMarketplace _marketplaceContract
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_marketplaceContract));

    MarketplaceContract = _marketplaceContract;

    emit MarketplaceContractChanged(_marketplaceContract);
  }

  function setSoulboundContract(
    ISoulboundToken _soulboundContract
  ) public override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_soulboundContract));

    SoulboundContract = _soulboundContract;

    emit SoulboundContractChanged(_soulboundContract);
  }

  function setInventoryContract(
    IInventory _inventoryContract
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_inventoryContract));

    InventoryContract = _inventoryContract;

    emit InventoryContractChanged(_inventoryContract);
  }

  function pause()
    external
    override
    onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager)
  {
    _pause();
  }

  function unpause()
    external
    override
    onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager)
  {
    _unpause();
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    returns (bool isOperator)
  {
    // This allows the marketplace contract to manage user's NFTs during sales without users having to approve their NFTs to the marketplace contract
    if (msg.sender == address(MarketplaceContract)) {
      return true;
    }

    // otherwise, use the default ERC1155.isApprovedForAll()
    return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC1155Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return ERC1155Upgradeable.supportsInterface(interfaceId);
  }
}