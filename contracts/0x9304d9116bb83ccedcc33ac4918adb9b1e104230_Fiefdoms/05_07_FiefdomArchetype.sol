// SPDX-License-Identifier: MIT

/*
 ________  _____  ________  ________  ______      ___   ____    ____
|_   __  ||_   _||_   __  ||_   __  ||_   _ `.  .'   `.|_   \  /   _|
  | |_ \_|  | |    | |_ \_|  | |_ \_|  | | `. \/  .-.  \ |   \/   |
  |  _|     | |    |  _| _   |  _|     | |  | || |   | | | |\  /| |
 _| |_     _| |_  _| |__/ | _| |_     _| |_.' /\  `-'  /_| |_\/_| |_
|_____|   |_____||________||_____|   |______.'  `.___.'|_____||_____|
      _       _______      ______  ____  ____  ________  _________  ____  ____  _______  ________
     / \     |_   __ \   .' ___  ||_   ||   _||_   __  ||  _   _  ||_  _||_  _||_   __ \|_   __  |
    / _ \      | |__) | / .'   \_|  | |__| |    | |_ \_||_/ | | \_|  \ \  / /    | |__) | | |_ \_|
   / ___ \     |  __ /  | |         |  __  |    |  _| _     | |       \ \/ /     |  ___/  |  _| _
 _/ /   \ \_  _| |  \ \_\ `.___.'\ _| |  | |_  _| |__/ |   _| |_      _|  |_    _| |_    _| |__/ |
|____| |____||____| |___|`.____ .'|____||____||________|  |_____|    |______|  |_____|  |________|

by steviep.eth (2022)


All Fiefdom Proxy contracts inherit the behavior of the Fiefdom Archetype.

Upon publication, a fiefdom contract will set a placeholder name and symbol, record the timestamp
of its founding at, and will mint token #0 to itself.

Ownership over the Fiefdom will follow the owner of the corresponding Vassal token, which is manage by
the Fiefdom Kingdom contract.

At any point, the Vassal owner may choose to activate the Fiefdom. This will set the contract's name,
symbol, license, max supply of tokens, tokenURI contract, and hooks contract. While name and symbol are fixed, maxSupply
and tokenURIContract can be updated later. maxSupply and tokenURI can also be frozen by the Vassal owner. The passed hooks
contract address allows for the Vassal owner to define extra behavior that runs before transfers and approvals.

The Vassal owner will be the default minter of the contract, but can also set the minter to another
address. In practice, the minter will be a separate minting contract. The minter can mint tokens using
any of three methods: mint, mintBatch, and mintBatchTo.

If set to 0x0, tokenURI logic will default to the default token URI contract set at the kingdom level. Otherwise,
the Fiefdom may freely change its token URI contract.

*/

import "./DefaultTokenURI.sol";
import "./BaseTokenURI.sol";
import "./ERC721Hooks.sol";
import "./Dependencies.sol";
import "./Fiefdoms.sol";

pragma solidity ^0.8.17;

interface ITokenURI {
  function tokenURI(uint256 tokenId) external view returns (string memory uri);
}

/// @title Fiefdom Archetype
/// @author steviep.eth, julien.eth
/// @notice ERC721 collection contract controlled by the vassal that holds its corresponding fiefdom token
contract FiefdomArchetype is ERC721Burnable {
  using Strings for uint256;

  /// @notice Main Fiefdoms contract address
  Fiefdoms public kingdom;

  /// @notice Called when tokens are minted, transferred, burned, and when approvals are set
  /// @dev To use, extend the ERC721HooksBase contract, override the required virtual functions, deploy with this
  ///      fiefdom contract's address set as its parent, and pass its address to activate()
  IERC721Hooks public erc721Hooks;

  /// @notice True after activate() has been called
  bool public isActivated;

  /// @notice True when token URI contract can no longer be changed
  bool public tokenURIFrozen;

  /// @notice True when max supply can no longer change
  bool public maxSupplyFrozen;

  /// @notice Address that is allowed to mint tokens
  address public minter;

  /// @notice ID of this fiefdom
  uint256 public fiefdomId;

  /// @notice License of project
  string public license;

  /// @notice Max supply of collection
  uint256 public maxSupply;

  /// @notice Timestamp when this contract was created
  uint256 public foundedAt;

  string private _name;
  string private _symbol;
  uint256 private _totalSupply;
  bool private _isInitialized;
  address private _royaltyBeneficiary;
  uint16 private _royaltyBasisPoints;
  address private _tokenURIContract;

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

  /// @dev This is only called when the first archetype contract is initially published
  constructor() ERC721('', '') {
    initialize(msg.sender, 0);
  }

  /// @notice Initializes contract by minting token 0 to itself and setting a default name and symbol
  /// @param _kingdom Address of the main Fiefdoms contract
  /// @param _fiefdomId Token ID of this fiefdom
  /// @dev Called by the proxy contract immediately after a copy of this contract is published
  function initialize(address _kingdom, uint256 _fiefdomId) public {
    require(!_isInitialized, "Can't initialize more than once");
    _isInitialized = true;

    // Since constructor is not called (or called the first time with empty values)
    _name = string(abi.encodePacked('Fiefdom ', _fiefdomId.toString()));
    _symbol = string(abi.encodePacked('FIEF', _fiefdomId.toString()));
    kingdom = Fiefdoms(_kingdom);
    fiefdomId = _fiefdomId;
    foundedAt = block.timestamp;

    _totalSupply = 1;
    _mint(address(this), 0);
  }

  /// @notice Instantiates the collection beyond the 0th mint and sends the 0th token to the caller
  /// @param name_ Name to be set on collection
  /// @param symbol_ Symbol to be set on collection
  /// @param license_ License to be set on project
  /// @param maxSupply_ Max supply to be set on collection
  /// @param tokenURIContract_ Contract used to return metadata for each token (optional)
  /// @param erc721Hooks_ Contract called when tokens are minted, transferred, burned, and when approvals are set (optional)
  function activate(
    string memory name_,
    string memory symbol_,
    string memory license_,
    uint256 maxSupply_,
    address tokenURIContract_,
    address erc721Hooks_
  ) public onlyOwner {
    // Require that it can only be called once
    require(!isActivated, "Fiefdom has already been activated");

    // Set the name/symbol
    _name = name_;
    _symbol = symbol_;

    // Set the max token supply
    maxSupply = maxSupply_;

    // Set the defailt minter address + ERC2981 royalty beneficiary
    minter = msg.sender;
    _royaltyBeneficiary = msg.sender;
    _royaltyBasisPoints = 1000;

    // Set the tokenURI contract
    _tokenURIContract = tokenURIContract_;

    license = license_;
    isActivated = true;

    // Recover the 0th token
    _transfer(address(this), msg.sender, 0);
    emit MetadataUpdate(0);
    kingdom.activation(fiefdomId);

    // Set hooks if contract address provided
    if (address(erc721Hooks_) != address(0)) {
      erc721Hooks = IERC721Hooks(erc721Hooks_);
      require(erc721Hooks.parent() == address(this), "Passed ERC721Hooks contract is not configured for this Fiefdom");
    }
  }

  // HOOKS

  /// @notice Register calls to erc721Hooks on transfers (including mints and burns)
  /// @param from Address of sender (zero when being minted)
  /// @param to Address of receiver (zero when burning)
  /// @param tokenId ID of token being transferred (or minted or burned)
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    if (address(erc721Hooks) != address(0)) erc721Hooks.beforeTokenTransfer(from, to, tokenId);
  }

  /// @notice Register calls to erc721Hooks on token approvals
  /// @param to Address to be approved
  /// @param tokenId ID of token being approved of
  function approve(address to, uint256 tokenId) public virtual override {
    if (address(erc721Hooks) != address(0)) erc721Hooks.beforeApprove(to, tokenId);
    super.approve(to, tokenId);
  }

  /// @notice Register calls to erc721Hooks on operator approvals
  /// @param operator Address of operator
  /// @param approved True when operator is being approved, false when approval is being revoked
  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (address(erc721Hooks) != address(0)) erc721Hooks.beforeSetApprovalForAll(operator, approved);
    super.setApprovalForAll(operator, approved);
  }


  // OWNERSHIP

  /// @notice Emitted when fiefdom token is transferred to a new owner
  /// @param previousOwner Previous owner of fiefdom token
  /// @param newOwner New owner of fiefdom token
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @notice Contract owner
  /// @dev The owner of this contract is the owner of the corresponding fiefdom token
  function owner() public view virtual returns (address) {
    return kingdom.ownerOf(fiefdomId);
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  /// @notice Notes a transfer in contract ownership
  /// @param previousOwner Previous owner of fiefdom token
  /// @param newOwner New owner of fiefdom token
  /// @dev Called by Fiefdoms whenever the corresponding fiefdom token is traded
  function transferOwnership(address previousOwner, address newOwner) external {
    require(msg.sender == address(kingdom), 'Ownership can only be transferred by the kingdom');
    emit OwnershipTransferred(previousOwner, newOwner);
  }

  // VARIABLES

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

  /// @notice Name of collection
  /// @return Name
  function name() public view virtual override(ERC721) returns (string memory) {
   return  _name;
  }

  /// @notice Symbol of collection
  /// @return Symbol
  function symbol() public view virtual override(ERC721) returns (string memory) {
    return _symbol;
  }

  // MINTING

  /// @notice Mints a new token
  /// @param to Address to receive new token
  /// @param tokenId ID of new token
  function mint(address to, uint256 tokenId) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply < maxSupply, 'Cannot create more tokens');

    _mint(to, tokenId);
    _totalSupply += 1;
  }

  /// @notice Mints one new token to each provided address
  /// @param to Addresses to each receive one new token
  /// @param tokenIdStart ID of first new token
  function mintBatch(address[] calldata to, uint256 tokenIdStart) external {
    require(minter == msg.sender, 'Caller is not the minting address');

    uint256 amount = to.length;
    require(_totalSupply + amount <= maxSupply, 'Cannot create more tokens');

    for (uint256 i; i < amount; i++) {
      _mint(to[i], tokenIdStart + i);
      _totalSupply++;
    }
  }

  /// @notice Mints a batch of new tokens to a single address
  /// @param to Address to receive all new tokens
  /// @param amount Amount of tokens to mint
  /// @param tokenIdStart ID of first new token
  function mintBatchTo(address to, uint256 amount, uint256 tokenIdStart) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply + amount <= maxSupply, 'Cannot create more tokens');

    for (uint256 i; i < amount; i++) {
      _mint(to, tokenIdStart + i);
      _totalSupply++;
    }
  }

  /// @notice Token URI
  /// @param tokenId Token ID to look up URI of
  /// @return Token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return ITokenURI(tokenURIContract()).tokenURI(tokenId);
  }

  /// @notice Address of Token URI contract
  /// @return Address of custom Token URI contract if set, otherwise the Kingdom's default
  function tokenURIContract() public view returns (address) {
    return _tokenURIContract == address(0)
      ? kingdom.defaultTokenURIContract()
      : _tokenURIContract;
  }

  // Contract owner actions

  /// @notice Sets a custom Token URI contract
  /// @param tokenURIContract_ Address of Token URI contract to set
  function setTokenURIContract(address tokenURIContract_) external onlyOwner {
    require(!tokenURIFrozen, 'Token URI has been frozen');
    _tokenURIContract = tokenURIContract_;
    emit BatchMetadataUpdate(0, _totalSupply);
  }

  /// @notice Disallow changes to Token URI contract address
  function freezeTokenURI() external onlyOwner {
    require(isActivated, 'Fiefdom must be activated');
    tokenURIFrozen = true;
  }

  /// @notice Sets the max supply of the collection
  /// @param newMaxSupply Max supply to set
  function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
    require(isActivated, 'Fiefdom must be activated');
    require(newMaxSupply >= _totalSupply, 'maxSupply must be >= than totalSupply');
    require(!maxSupplyFrozen, 'maxSupply has been frozen');
    maxSupply = newMaxSupply;
  }

  /// @notice Disallow changes to max supply
  function freezeMaxSupply() external onlyOwner {
    require(isActivated, 'Fiefdom must be activated');
    maxSupplyFrozen = true;
  }

  /// @notice Sets the license of the project
  /// @param newLicense License
  function setLicense(string calldata newLicense) external onlyOwner {
    license = newLicense;
  }

  /// @notice Sets minter address
  /// @param newMinter Minter address to set
  function setMinter(address newMinter) external onlyOwner {
    minter = newMinter;
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

  // Events

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
