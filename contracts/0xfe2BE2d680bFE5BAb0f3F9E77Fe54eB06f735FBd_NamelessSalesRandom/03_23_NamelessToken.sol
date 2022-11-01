// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';

import './INamelessToken.sol';
import './INamelessTokenData.sol';

contract NamelessToken is 
        INamelessToken, ERC165, IERC2981, ERC721Enumerable, AccessControl, Initializable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant REDEEM_ROLE = keccak256('REDEEM_ROLE');

  // Duplicate Token name for cloneability
  string private _name;
  // Duplicate Token symbol for cloneability
  string private _symbol;
  // informational support for external sites that respected Ownable
  address private _legacyOwner;

  address public tokenDataContract;

  function initialize (
    string memory name_,
    string memory symbol_,
    address tokenDataContract_,
    address initialAdmin
  ) public initializer override {
    _name = name_;
    _symbol = symbol_;
    _legacyOwner = initialAdmin;
    tokenDataContract = tokenDataContract_;
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
    emit OwnershipTransferred(address(0), initialAdmin);
  }

  constructor(
    string memory name_,
    string memory symbol_,
    address tokenDataContract_
  ) ERC721(name_, symbol_) {
    initialize(name_, symbol_, tokenDataContract_, msg.sender);
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * emulate Ownable for external applications that expect it
   */
  function owner() public view returns (address) {
    return _legacyOwner;
  }

  function transferLegacyOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(newOwner != address(0), 'new owner is null');
      _legacyOwner = newOwner;
      emit OwnershipTransferred(_legacyOwner, newOwner);
  }

  function royaltyInfo(uint256 tokenId, uint256 _salePrice)
      external
      view
      override
      returns (address receiver, uint256 royaltyAmount)
  {
      return INamelessTokenData(tokenDataContract).royaltyInfo(tokenId, _salePrice);
  }

  function getFeeRecipients(uint256 tokenId) public view returns (address payable[] memory) {
    return INamelessTokenData(tokenDataContract).getFeeRecipients(tokenId);
  }

  function getFeeBps(uint256 tokenId) public view returns (uint256[] memory) {
    return INamelessTokenData(tokenDataContract).getFeeBps(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'no such token');
    return INamelessTokenData(tokenDataContract).getTokenURI(tokenId, ownerOf(tokenId));
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);
    if (INamelessTokenData(tokenDataContract).beforeTokenTransfer(from, to, tokenId)) {
      emit TokenMetadataChanged(tokenId);
    }
  }

  function redeem(uint256 tokenId, uint256 timestamp, string calldata memo) public onlyRole(REDEEM_ROLE) {
    INamelessTokenData(tokenDataContract).redeem(tokenId);
    emit TokenRedeemed(tokenId, timestamp, memo);
  }

  function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(to, tokenId);
  }

  function mint(address creator, address recipient, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(creator, tokenId);
    _safeTransfer(creator, recipient, tokenId, '');
  }

  // @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override (AccessControl, ERC165, IERC165, ERC721Enumerable)
      returns (bool)
  {
      return
          interfaceId == type(IERC2981).interfaceId ||
          super.supportsInterface(interfaceId);
  }
}