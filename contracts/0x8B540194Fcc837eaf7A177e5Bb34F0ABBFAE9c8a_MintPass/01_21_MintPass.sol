// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error TokenNonexistent();
error NotEnoughEther();
error InputLengthsNotMatching();
error AmountCannotBeZero();
error ExceededMaxSupply();
error ExceededMaxPurchaseable();
error InvalidMerkleProof();
error PresaleActive();
error PresaleInactive();
error ExceededPresaleLimit();

struct MintPassInfo {
  uint256 maxSupply;
  uint256 currentSupply;
  uint256 mintPrice;
  uint256 mintLimit; // mint limit per tx. 0 works as pause.
  bytes32 presaleMerkleRoot;
}

contract MintPass is
  ERC1155,
  ERC1155Burnable,
  ERC1155Supply,
  AccessControl,
  PaymentSplitter,
  Ownable,
  ReentrancyGuard
{
  uint256 public immutable maxPresaleMinting;
  string public name;
  string public symbol;

  string internal _baseURI;
  uint256 private _tokenIdCounter = 1;
  bool private _isPresale = true;

  mapping(uint256 => MintPassInfo) public mintPasses;
  mapping(address => mapping(uint256 => uint256)) public numClaimed;

  uint256 private _numberOfPayees;

  constructor(
    address[] memory payees,
    uint256[] memory shares,
    address owner_,
    string memory name_,
    string memory symbol_,
    string memory baseUri,
    uint256 maxPresaleMinting_
  ) ERC1155("") PaymentSplitter(payees, shares) {
    _transferOwnership(owner_);
    _grantRole(DEFAULT_ADMIN_ROLE, owner_);

    _numberOfPayees = payees.length;

    name = name_;
    symbol = symbol_;

    _baseURI = baseUri;

    maxPresaleMinting = maxPresaleMinting_;
  }

  modifier whenPresaleActive() {
    if (!_isPresale) {
      revert PresaleInactive();
    }
    _;
  }

  modifier whenTokenExists(uint256 id) {
    if (id >= _tokenIdCounter) {
      revert TokenNonexistent();
    }
    _;
  }

  modifier whenNotZero(uint256 amount) {
    if (amount == 0) {
      revert AmountCannotBeZero();
    }
    _;
  }

  modifier whenMainSaleActive() {
    if (_isPresale) {
      revert PresaleActive();
    }
    _;
  }

  modifier whenNotExceededMaxPurchaseable(uint256 id, uint256 amount) {
    MintPassInfo storage mintPassInfo = mintPasses[id];
    // can only mint up to mint limit set per tier of NFT per tx
    // admin can mint more than limit per tx
    if (
      amount > mintPassInfo.mintLimit &&
      !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())
    ) {
      revert ExceededMaxPurchaseable();
    }

    _;
  }

  modifier whenHasEnoughEther(uint256 id, uint256 amount) {
    MintPassInfo storage mintPassInfo = mintPasses[id];
    if (msg.value < mintPassInfo.mintPrice * amount) {
      revert NotEnoughEther();
    }

    _;
  }

  modifier whenNotExceededMaxSupply(uint256 id, uint256 amount) {
    MintPassInfo storage mintPassInfo = mintPasses[id];
    uint256 newSupply = mintPassInfo.currentSupply + amount;
    if (newSupply > mintPassInfo.maxSupply) {
      revert ExceededMaxSupply();
    }

    mintPassInfo.currentSupply = newSupply;
    _;
  }

  /*** Presale ***/

  /// @notice Sets `presaleMerkleRoot` of `tokenIds`. Admin only.
  /// @param tokenIds The tokenIds of the merkle root you want to update
  /// @param _presaleMerkleRoot New presaleMerkleRoot
  function setPresaleMerkleRoot(
    uint256[] calldata tokenIds,
    bytes32[] calldata _presaleMerkleRoot
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      tokenIds.length == _presaleMerkleRoot.length,
      "input array lengths must be the same"
    );
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (tokenId >= _tokenIdCounter) {
        revert TokenNonexistent();
      }

      mintPasses[tokenId].presaleMerkleRoot = _presaleMerkleRoot[i];
    }
  }

  function endPresale() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_isPresale, "Presale already ended");
    _isPresale = false;
  }

  function isPresale() external view virtual returns (bool) {
    return _isPresale;
  }

  /*** Minting ***/

  /**
   * @notice Adds new mint pass.
   */
  function addMintPass(
    uint256[] calldata maxSupplies,
    uint256[] calldata mintPrices
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (maxSupplies.length != mintPrices.length) {
      revert InputLengthsNotMatching();
    }

    for (uint256 i = 0; i < maxSupplies.length; i++) {
      uint256 tokenId = _tokenIdCounter;
      unchecked {
        ++_tokenIdCounter;
      }

      mintPasses[tokenId] = MintPassInfo({
        maxSupply: maxSupplies[i],
        currentSupply: 0,
        mintPrice: mintPrices[i],
        mintLimit: 0, // default to 0 or pause state
        presaleMerkleRoot: 0
      });
    }
  }

  /**
   * @notice Sets `mintLimit` of `tokenIds`.
   *
   * Setting `mintLimit` from 0 is equivalent to pausing mint for specified token ID.
   */
  function setMintLimit(
    uint256[] calldata tokenIds,
    uint256[] calldata mintLimits
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      tokenIds.length == mintLimits.length,
      "input array lengths must be the same"
    );

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (tokenId >= _tokenIdCounter) {
        revert TokenNonexistent();
      }

      mintPasses[tokenId].mintLimit = mintLimits[i];
    }
  }

  /**
   * @notice Mints ignoring the mint limit and price.
   */
  function devMint(
    address account,
    uint256 id,
    uint256 amount
  ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (id >= _tokenIdCounter) {
      revert TokenNonexistent();
    }

    MintPassInfo storage mintPassInfo = mintPasses[id];
    uint256 newSupply = mintPassInfo.currentSupply + amount;

    if (newSupply > mintPassInfo.maxSupply) {
      revert ExceededMaxSupply();
    }

    mintPassInfo.currentSupply = newSupply;

    _mint(account, id, amount, "");
  }

  /// @notice Presale mint the given number of NFTs to the msg.sender
  /// @param account The account to mint to
  /// @param id The id of the mintpass you want to mint
  /// @param amount The number of NFTs to be minted
  /// @param proof Merkle proof showing that recipient is on the whitelist
  function presaleMint(
    address account,
    uint256 id,
    uint256 amount,
    bytes32[] calldata proof
  )
    public
    payable
    whenPresaleActive
    nonReentrant
    whenNotZero(amount)
    whenTokenExists(id)
    whenNotExceededMaxPurchaseable(id, amount)
    whenHasEnoughEther(id, amount)
    whenNotExceededMaxSupply(id, amount)
  {
    numClaimed[account][id] += amount;

    if (numClaimed[account][id] > maxPresaleMinting) {
      revert ExceededPresaleLimit();
    }

    if (
      !MerkleProof.verify(
        proof,
        mintPasses[id].presaleMerkleRoot,
        keccak256(abi.encodePacked(account))
      )
    ) {
      revert InvalidMerkleProof();
    }

    _mint(account, id, amount, "");
  }

  /**
   * @dev Mint Passes.
   */
  function mint(
    address account,
    uint256 id,
    uint256 amount
  )
    external
    payable
    nonReentrant
    whenNotZero(amount)
    whenTokenExists(id)
    whenMainSaleActive
    whenNotExceededMaxPurchaseable(id, amount)
    whenHasEnoughEther(id, amount)
    whenNotExceededMaxSupply(id, amount)
  {
    _mint(account, id, amount, "");
  }

  /*** Token URI setter and getter ***/

  function setURI(string memory newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _baseURI = newuri;
  }

  function baseURI() external view virtual returns (string memory) {
    return _baseURI;
  }

  function uri(uint256 _id) public view override returns (string memory) {
    require(_id < _tokenIdCounter, "Nonexistent token");

    return string(abi.encodePacked(_baseURI, Strings.toString(_id)));
  }

  /*** The following functions are overrides required by Solidity ***/

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /// @notice Withdraw the contract's fund and split the payment amongst the list of payees.
  /// @dev Loops through all of the payees and release funding based on the payee's share
  function withdraw() external {
    for (uint256 i = 0; i < _numberOfPayees; i++) {
      release(payable(payee(i)));
    }
  }

  receive() external payable override(PaymentSplitter) {
    emit PaymentReceived(_msgSender(), msg.value);
  }
}