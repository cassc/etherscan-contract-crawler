// SPDX-License-Identifier: MIT

/*
 ________  _____  ________  ________  ______      ___   ____    ____
|_   __  ||_   _||_   __  ||_   __  ||_   _ `.  .'   `.|_   \  /   _|
  | |_ \_|  | |    | |_ \_|  | |_ \_|  | | `. \/  .-.  \ |   \/   |
  |  _|     | |    |  _| _   |  _|     | |  | || |   | | | |\  /| |
 _| |_     _| |_  _| |__/ | _| |_     _| |_.' /\  `-'  /_| |_\/_| |_
|_____|   |_____||________||_____|   |______.'  `.___.'|_____||_____|
 ___  ____   _____  ____  _____   ______  ______      ___   ____    ____
|_  ||_  _| |_   _||_   \|_   _|.' ___  ||_   _ `.  .'   `.|_   \  /   _|
  | |_/ /     | |    |   \ | | / .'   \_|  | | `. \/  .-.  \ |   \/   |
  |  __'.     | |    | |\ \| | | |   ____  | |  | || |   | | | |\  /| |
 _| |  \ \_  _| |_  _| |_\   |_\ `.___]  |_| |_.' /\  `-'  /_| |_\/_| |_
|____||____||_____||_____|\____|`._____.'|______.'  `.___.'|_____||_____|

by steviep.eth (2022)


The Fiefdoms Kingdom is an ERC721 collection of 721 Vassal tokens.

Each Vassal token gives the token holder ownership over a separate, unique ERC721
contract (a "Fiefdom").

Transferring a Vassal token will also transfer ownership over that Fiefdom.

Minting a Vassal token will create a proxy contract, which inherits all of its behavior
from the Fiefdom Archetype.

Vassal #0 controls the domain of the Fiefdom Archetype directly.

Fiefdoms may collect own royalties without restriction on all tokens within their domain,
but Vassal tokens are subject to the strict trading rules of the broader kingdom.

*/

import "./Dependencies.sol";
import "./BaseTokenURI.sol";
import "./DefaultTokenURI.sol";
import "./FiefdomProxy.sol";
import "./FiefdomArchetype.sol";

pragma solidity ^0.8.17;

/// @title Fiefdoms
/// @author steviep.eth, julien.eth
/// @notice ERC721 collection contract where ownership of a token grants the tooken holder ownership over a Fiefdom contract
contract Fiefdoms is ERC721, Ownable {
  /// @notice License of Fiefdoms parent project - Does not pertain to the license of any tokens minted by Fiefdom contracts
  string public license = 'CC0';

  /// @notice Address that is permissioned to mint new tokens
  address public minter;

  /// @notice Address of the default tokenURI contract used by fiefdoms for mint 0
  address public fiefdomArchetype;

  /// @notice Address of the default tokenURI contract used by fiefdoms for mint 0
  address public defaultTokenURIContract;

  /// @notice True when only operators on the allow list may be approved
  bool public useOperatorAllowList = true;

  /// @notice Max supply of collection
  uint256 public constant maxSupply = 721;

  /// @notice Mapping from vassal's token id to fiefdom address
  mapping(uint256 => address) public tokenIdToFiefdom;

  /// @notice Allow lise of all operators allowed t
  mapping(address => bool) public operatorAllowList;

  BaseTokenURI private _tokenURIContract;
  uint256 private _totalSupply = 1;
  address private _royaltyBeneficiary;
  uint16 private _royaltyBasisPoints = 1000;

  /// @notice Arbitrary event emitted by contract owner
  /// @param poster Address of initiator
  /// @param eventType Type of event
  /// @param content Content of event
  event ProjectEvent(address indexed poster, string indexed eventType, string content);

  /// @notice Arbitrary event related to a specific token emitted by contract owner or token holder
  /// @param poster Address of initiator
  /// @param tokenId ID of token
  /// @param eventType Type of event
  /// @param content Content of event
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  /// @notice Emitted when a range of tokens has their metadata updated
  /// @param _fromTokenId The first ID of the token in the range
  /// @param _toTokenId The last ID of the token in the range
  /// @dev See EIP-4906: https://eips.ethereum.org/EIPS/eip-4906
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  /// @notice Emitted when a token's metadata is updated
  /// @param _tokenId The ID of the updated token
  /// @dev See EIP-4906: https://eips.ethereum.org/EIPS/eip-4906
  event MetadataUpdate(uint256 _tokenId);

  /// @notice Emitted when a fiefdom is first activated
  /// @param fiefdom The ID of the fiefdom being activated
  event Activation(uint256 fiefdom);

  // SETUP

  /// @dev Sets base variables, mints token #0 to the deployer, and publishes the FiefdomArchetype contract
  constructor() ERC721('Fiefdoms', 'FIEF') {
    minter = msg.sender;
    _royaltyBeneficiary = msg.sender;
    _tokenURIContract = new BaseTokenURI();
    defaultTokenURIContract = address(new DefaultTokenURI());

    // Publish an archetype contract. All proxy contracts will derive its functionality from this
    fiefdomArchetype = address(new FiefdomArchetype());

    // Token 0 will use the archetype contract directly instead of a proxy
    _mint(msg.sender, 0);

    tokenIdToFiefdom[0] = fiefdomArchetype;
  }


  // BASE FUNCTIONALITY

  /// @notice Current total supply of collection
  /// @return Total supply
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /// @notice Checks if given token ID exists
  /// @param tokenId Token to run existence check on
  /// @return True if token exists
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  /// @notice Alias of Fiefdoms contract owner
  function overlord() external view returns (address) {
    return owner();
  }

  /// @dev Override's the default _transfer function to also transfer ownership over the corresponding fiefdom
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    // When this token is transferred, also transfer ownership over its fiefdom
    FiefdomArchetype(tokenIdToFiefdom[tokenId]).transferOwnership(from, to);
    return super._transfer(from, to, tokenId);
  }

  /// @notice Emits Activation and MetadataUpdate events upon fiefdom activation
  /// @param tokenId Token Id of fiefdom being activated
  /// @dev This can only be called by the fiefdom upon its activation
  function activation(uint256 tokenId) external {
    require(tokenIdToFiefdom[tokenId] == msg.sender);
    emit MetadataUpdate(tokenId);
    emit Activation(tokenId);
  }

  // MINTING

  /// @notice Mints a new token
  /// @param to Address to receive new token
  function mint(address to) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply < maxSupply, 'Cannot create more fiefdoms');

    _mint(to, _totalSupply);

    // Publish a new proxy contract for this token
    FiefdomProxy proxy = new FiefdomProxy();
    tokenIdToFiefdom[_totalSupply] = address(proxy);

    _totalSupply += 1;
  }

  /// @notice Mints a batch of new tokens to a single address
  /// @param to Address to receive all new tokens
  /// @param amount Amount of tokens to mint
  function mintBatch(address to, uint256 amount) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply + amount <= maxSupply, 'Cannot create more fiefdoms');

    for (uint256 i; i < amount; i++) {
      _mint(to, _totalSupply);
      FiefdomProxy proxy = new FiefdomProxy();
      tokenIdToFiefdom[_totalSupply] = address(proxy);
      _totalSupply++;
    }
  }

  /// @notice Reassigns the minter permission
  /// @param newMinter Address of new minter
  function setMinter(address newMinter) external onlyOwner {
    minter = newMinter;
  }

  // ROYALTIES
  // Fiefdoms may collect their own royalties without restriction, but must follow the rules of the broader kingdom

  /// @notice Override the standard approve function to revert if approving an un-ALed operator
  /// @param to Address of operator
  /// @param tokenId Id of token to approve
  function approve(address to, uint256 tokenId) public virtual override {
    if (useOperatorAllowList) require(operatorAllowList[to], 'Operator must be on Allow List');
    super.approve(to, tokenId);
  }

  /// @notice Override the standard setApprovalForAll function to revert if approving an un-ALed operator
  /// @param operator Address of operator
  /// @param approved Approval status of operator
  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (useOperatorAllowList && approved) require(operatorAllowList[operator], 'Operator must be on Allow List');
    super.setApprovalForAll(operator, approved);
  }

  /// @notice Override the standard getApproved function to return false for un-ALed operators
  /// @param tokenId Id of token
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    address operator = super.getApproved(tokenId);
    if (useOperatorAllowList) {
      return operatorAllowList[operator] ? operator : address(0);
    } else {
      return operator;
    }
  }

  /// @notice Override the standard isApprovedForAll function to return false for un-ALed operators
  /// @param owner Address of owner
  /// @param operator Address of operator
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    if (useOperatorAllowList && !operatorAllowList[operator]) {
      return false;
    } else {
      return super.isApprovedForAll(owner, operator);
    }
  }

  /// @notice Denotes whether an operator allow list should be used
  /// @param _useOperatorAllowList New useOperatorAllowList value
  function updateUseOperatorAllowList(bool _useOperatorAllowList) external onlyOwner {
    useOperatorAllowList = _useOperatorAllowList;
  }

  /// @notice Update the allow list status of a single operator
  /// @param operator Address of operator
  /// @param allowListStatus New allow list status
  function updateOperatorAllowList(address operator, bool allowListStatus) external onlyOwner {
    operatorAllowList[operator] = allowListStatus;
  }

  /// @notice Sets royalty info for the collection
  /// @param royaltyBeneficiary Address to receive royalties
  /// @param royaltyBasisPoints Basis points of royalty commission
  /// @dev See EIP-2981: https://eips.ethereum.org/EIPS/eip-2981
  function setRoyaltyInfo(
    address royaltyBeneficiary,
    uint16 royaltyBasisPoints
  ) external onlyOwner {
    _royaltyBeneficiary = royaltyBeneficiary;
    _royaltyBasisPoints = royaltyBasisPoints;
  }

  /// @notice Called with the sale price to determine how much royalty is owed and to whom.
  /// @param (unused)
  /// @param _salePrice The sale price of the NFT asset specified by _tokenId
  /// @return receiver Address of who should be sent the royalty payment
  /// @return royaltyAmount The royalty payment amount for _salePrice
  /// @dev See EIP-2981: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (_royaltyBeneficiary, _salePrice * _royaltyBasisPoints / 10000);
  }

  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @return `true` if the contract implements `interfaceId` and
  ///         `interfaceId` is not 0xffffffff, `false` otherwise
  /// @dev Interface identification is specified in ERC-165. This function
  ///      uses less than 30,000 gas. See: https://eips.ethereum.org/EIPS/eip-165
  ///      See EIP-2981: https://eips.ethereum.org/EIPS/eip-2981
  ///      See EIP-4906: https://eips.ethereum.org/EIPS/eip-4906
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    // ERC2981 & ERC4906
    return interfaceId == bytes4(0x2a55205a) || interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }


  // TOKEN URI

  /// @notice Token URI
  /// @param tokenId Token ID to look up URI of
  /// @return Token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return _tokenURIContract.tokenURI(tokenId);
  }

  /// @notice Set the Token URI contract for Vassal tokens
  /// @param _tokenURIAddress New address of Token URI contract
  function setTokenURIContract(address _tokenURIAddress) external onlyOwner {
    _tokenURIContract = BaseTokenURI(_tokenURIAddress);
    emit BatchMetadataUpdate(0, _totalSupply);
  }

  /// @notice Set the default Token URI contract for all Fiefdoms in the Kingdom
  /// @param newDefault Address of the new default Token URI contract
  function setDefaultTokenURIContract(address newDefault) external onlyOwner {
    defaultTokenURIContract = newDefault;
  }

  /// @notice Address of Token URI contract
  /// @return Address of the Token URI contract
  function tokenURIContract() external view returns (address) {
    return address(_tokenURIContract);
  }

  // EVENTS

  /// @notice Emit an arbitrary event related to a token
  /// @param tokenId ID of the token this event is related to
  /// @param eventType Type of event to emit
  /// @param content Text to be included in event
  /// @dev Can be called either by contract owner or token holder
  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      owner() == msg.sender || ERC721.ownerOf(tokenId) == msg.sender,
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(msg.sender, tokenId, eventType, content);
  }

  /// @notice Emit an arbitrary event related to the project
  /// @param eventType Type of event to emit
  /// @param content Text to be included in event
  /// @dev Can only be called either by contract owner
  function emitProjectEvent(string calldata eventType, string calldata content) external onlyOwner {
    emit ProjectEvent(msg.sender, eventType, content);
  }
}

