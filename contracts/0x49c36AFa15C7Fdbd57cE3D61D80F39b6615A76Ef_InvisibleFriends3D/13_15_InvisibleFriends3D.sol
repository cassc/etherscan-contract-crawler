// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
                              ..............               ascii art by community member
                        ..::....          ....::..                           rqueue#4071
                    ..::..                        ::..
                  ::..                              ..--..
                ::..                  ....::..............::::..
              ::                ..::::..                      ..::..
            ....            ::::..                                ::::
            ..        ..::..                                        ..::
          ::      ..::..                                              ....
        ....  ..::::                                                    ::
        ::  ..  ..                                                        ::
        ....    ::                                ....::::::::::..        ::
        --::......                    ..::==--::::....          ..::..    ....
      ::::  ..                  ..--..  [email protected]@++                      ::      ..
      ::                    ..------      ++..                        ..    ..
    ::                  ..::--------::  ::..    ::------..            ::::==++--..
  ....                ::----------------    ..**%%##****##==        --######++**##==
  ..              ::----------------..    ..####++..    --**++    ::####++::    --##==
....          ..----------------..        **##**          --##--::**##++..        --##::
..        ..--------------++==----------**####--          ..**++..::##++----::::::::****
..    ::==------------++##############%%######..            ++**    **++++++------==**##
::  ::------------++**::..............::**####..            ++**..::##..          ..++##
::....::--------++##..                  ::####::          ::****++####..          ..**++
..::  ::--==--==%%--                      **##++        ..--##++::####==          --##--
  ::..::----  ::==                        --####--..    ::**##..  ==%%##::      ::****
  ::      ::                                **####++--==####::      **%%##==--==####::
    ::    ..::..                    ....::::..--########++..          ==**######++..
      ::      ..::::::::::::::::::....      ..::::....                    ....
        ::::..                      ....::....
            ..::::::::::::::::::::....

 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IDelegationRegistry.sol";
import "closedsea/src/OperatorFilterer.sol";

contract InvisibleFriends3D is ERC721A, ERC2981, OperatorFilterer, Ownable {
  using Strings for uint256;

  error ExceedsMaxSupplyError();
  error IncorrectAmountError();
  error SaleStateClosedError();
  // Token mint
  error NotDelegatedError();
  error NotOwnerError(uint256);
  error TokenBasedMintDisabledError();
  error TokenIdAlreadyMintedError(uint256);
  // List mint
  error InsufficientListAmountError();
  error InvalidProofError();
  error ListDisabledError();
  error UnknownListError();

  string public PROVENANCE_HASH;
  uint256 constant MAX_SUPPLY = 5000;
  uint256 constant price = 0.07 ether;

  string public baseURI;

  IERC721 public invisibleFriends;
  IDelegationRegistry public delegationRegistry;

  enum SaleState {
    Closed,
    Private,
    Public
  }
  SaleState public saleState = SaleState.Closed;

  mapping(uint256 => bool) private _mintedIFTokenIDs;
  bool private _tokenBasedDisabled;

  mapping(string => bytes32) private _lists;
  mapping(string => bool) private _listDisabled;
  mapping(bytes32 => uint256) private _alreadyListMinted;

  bool public operatorFilteringEnabled = true;

  constructor(
    string memory initialBaseURI,
    address invisibleFriendsAddress,
    address delegationRegistryAddress,
    address payable royaltiesReceiver
  ) ERC721A("Invisible Friends 3D", "INVSBLE3D") {
    baseURI = initialBaseURI;
    invisibleFriends = IERC721(invisibleFriendsAddress);
    delegationRegistry = IDelegationRegistry(delegationRegistryAddress);
    setRoyaltyInfo(royaltiesReceiver, 500);

    _registerForOperatorFiltering(address(0), false);
  }

  function withdraw(address payable destination) external onlyOwner {
    destination.transfer(address(this).balance);
  }

  // Accessors

  function setProvenanceHash(string calldata hash) external onlyOwner {
    PROVENANCE_HASH = hash;
  }

  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setSaleState(SaleState _saleState) external onlyOwner {
    saleState = _saleState;
  }

  function setListRoot(string calldata list, bytes32 root) external onlyOwner {
    _lists[list] = root;
  }

  function setTokenBasedDisabled(bool disabled) external onlyOwner {
    _tokenBasedDisabled = disabled;
  }

  function setListDisabled(string calldata list, bool disabled) external onlyOwner {
    _listDisabled[list] = disabled;
  }

  // Modifiers

  modifier verifySaleState(SaleState requiredState) {
    if (saleState != requiredState) revert SaleStateClosedError();
    _;
  }

  modifier verifyAmount(uint256 amount) {
    if (msg.value != price * amount) revert IncorrectAmountError();
    _;
  }

  modifier verifyAvailableSupply(uint256 amount) {
    if (totalSupply() + amount > MAX_SUPPLY) revert ExceedsMaxSupplyError();
    _;
  }

  modifier verifyTokenBasedMintEnabled() {
    if (_tokenBasedDisabled) revert TokenBasedMintDisabledError();
    _;
  }

  modifier verifyListExists(string calldata list) {
    if (_lists[list] == "") revert UnknownListError();
    _;
  }

  // Minting

  function alreadyMintedIFIDs(uint256[] calldata tokenId) external view returns (bool[] memory) {
    bool[] memory states = new bool[](tokenId.length);
    for (uint256 i = 0; i < tokenId.length; i++) {
      states[i] = _mintedIFTokenIDs[tokenId[i]];
    }
    return states;
  }

  function alreadyListMinted(string calldata list, address account) external view returns (uint256) {
    return _alreadyListMinted[_listMintCountKey(list, account)];
  }

  function mintForInvisibleFriends(
    uint256[] calldata originalIds
  )
    external
    payable
    verifySaleState(SaleState.Private)
    verifyTokenBasedMintEnabled
    verifyAmount(originalIds.length)
    verifyAvailableSupply(originalIds.length)
  {
    _checkOwnershipAndMarkIDsMinted(originalIds, _msgSender());
    _mint(_msgSender(), originalIds.length);
  }

  function delegatedMintForInvisibleFriends(
    address vault,
    uint256[] calldata originalIds
  )
    external
    payable
    verifySaleState(SaleState.Private)
    verifyTokenBasedMintEnabled
    verifyAmount(originalIds.length)
    verifyAvailableSupply(originalIds.length)
  {
    if (!delegationRegistry.checkDelegateForContract(_msgSender(), vault, address(this))) revert NotDelegatedError();

    _checkOwnershipAndMarkIDsMinted(originalIds, vault);
    _mint(_msgSender(), originalIds.length);
  }

  function mintListed(
    string calldata list,
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 maxAmount
  )
    external
    payable
    verifySaleState(SaleState.Private)
    verifyAmount(amount)
    verifyAvailableSupply(amount)
    verifyListExists(list)
  {
    if (_listDisabled[list]) revert ListDisabledError();
    if (!_verifyMerkleProof(list, merkleProof, _msgSender(), maxAmount)) revert InvalidProofError();

    bytes32 listKey = _listMintCountKey(list, _msgSender());
    if (amount > maxAmount - _alreadyListMinted[listKey]) revert InsufficientListAmountError();

    _alreadyListMinted[listKey] += amount;
    _mint(_msgSender(), amount);
  }

  function mintPublic(
    uint256 amount
  ) external payable verifySaleState(SaleState.Public) verifyAmount(amount) verifyAvailableSupply(amount) {
    _mint(_msgSender(), amount);
  }

  function ownerMint(address to, uint256 amount) external onlyOwner verifyAvailableSupply(amount) {
    _mint(to, amount);
  }

  function _checkOwnershipAndMarkIDsMinted(uint256[] calldata originalIds, address proposedOwner) private {
    uint256 tokenId;
    for (uint256 i = 0; i < originalIds.length; i++) {
      tokenId = originalIds[i];
      if (invisibleFriends.ownerOf(tokenId) != proposedOwner) revert NotOwnerError(tokenId);
      if (_mintedIFTokenIDs[tokenId]) revert TokenIdAlreadyMintedError(tokenId);

      _mintedIFTokenIDs[tokenId] = true;
    }
  }

  function _verifyMerkleProof(
    string calldata list,
    bytes32[] calldata merkleProof,
    address sender,
    uint256 maxAmount
  ) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
    return MerkleProof.verify(merkleProof, _lists[list], leaf);
  }

  function _listMintCountKey(string calldata list, address account) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(list, account));
  }

  // ERC721A

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // OperatorFilterer

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function _operatorFilteringEnabled() internal view virtual override returns (bool) {
    return operatorFilteringEnabled;
  }

  // IERC2981

  function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
    _setDefaultRoyalty(receiver, numerator);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}