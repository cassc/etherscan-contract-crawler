// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721AUpgradeable, IERC721AUpgradeable, ERC721A__IERC721ReceiverUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./IONFT721CoreUpgradeable.sol";
import "./ONFT721CoreUpgradeable.sol";

contract ONFT721AUpgradeable is
  Initializable,
  ONFT721CoreUpgradeable,
  ERC721AQueryableUpgradeable,
  ERC721A__IERC721ReceiverUpgradeable,
  ERC2981Upgradeable,
  OperatorFilterer
{
  using StringsUpgradeable for uint;

  /// @notice Base uri
  string public baseURI;

  /// @notice Operator filter toggle switch
  bool private operatorFilteringEnabled;

  /// @notice Delegation registry
  address public delegationRegistryAddress;

  function __ONFT721AUpgradeable_init(
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    uint _minGasToTransferAndStore,
    address _lzEndpoint
  ) internal initializerERC721A onlyInitializing {
    __ERC721A_init_unchained(_name, _symbol);
    __ERC2981_init_unchained();
    __ONFT721CoreUpgradeable_init(_minGasToTransferAndStore, _lzEndpoint);

    baseURI = _baseURI;

    // Setup filter registry
    _registerForOperatorFiltering();
    operatorFilteringEnabled = true;

    // Setup royalties to 5% (default denominator is 10000)
    _setDefaultRoyalty(_msgSender(), 500);
  }

  function __ONFT721AUpgradeable_init_unchained() internal onlyInitializing {}

  function _startTokenId() internal view virtual override returns (uint) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(
      ONFT721CoreUpgradeable,
      IERC721AUpgradeable,
      ERC721AUpgradeable,
      ERC2981Upgradeable
    )
    returns (bool)
  {
    return
      interfaceId == type(IONFT721CoreUpgradeable).interfaceId ||
      ERC721AUpgradeable.supportsInterface(interfaceId) ||
      ERC2981Upgradeable.supportsInterface(interfaceId);
  }

  function _debitFrom(
    address _from,
    uint16,
    bytes memory,
    uint _tokenId
  ) internal virtual override(ONFT721CoreUpgradeable) {
    safeTransferFrom(_from, address(this), _tokenId);
  }

  function _creditTo(
    uint16,
    address _toAddress,
    uint _tokenId
  ) internal virtual override(ONFT721CoreUpgradeable) {
    require(
      _exists(_tokenId) && ERC721AUpgradeable.ownerOf(_tokenId) == address(this)
    );
    safeTransferFrom(address(this), _toAddress, _tokenId);
  }

  function onERC721Received(
    address,
    address,
    uint,
    bytes memory
  ) public virtual override returns (bytes4) {
    return ERC721A__IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  function setApprovalForAll(address operator, bool approved)
    public
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint tokenId)
    public
    payable
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint tokenId
  )
    public
    payable
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint tokenId
  )
    public
    payable
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint tokenId,
    bytes memory data
  )
    public
    payable
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
   * @notice Token uri
   * @param tokenId The token id
   */
  function tokenURI(uint tokenId)
    public
    view
    virtual
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    returns (string memory)
  {
    require(_exists(tokenId), "!exists");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @notice Sets the base uri for the token metadata
   * @param _baseURI The base uri
   */
  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  /**
   * @notice Set default royalty
   * @param receiver The royalty receiver address
   * @param feeNumerator A number for 10k basis
   */
  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    external
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @notice Sets whether the operator filter is enabled or disabled
   * @param operatorFilteringEnabled_ A boolean value for the operator filter
   */
  function setOperatorFilteringEnabled(bool operatorFilteringEnabled_)
    public
    onlyOwner
  {
    operatorFilteringEnabled = operatorFilteringEnabled_;
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }

  function _isPriorityOperator(address operator)
    internal
    pure
    override
    returns (bool)
  {
    // OpenSea Seaport Conduit:
    // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
  }
}