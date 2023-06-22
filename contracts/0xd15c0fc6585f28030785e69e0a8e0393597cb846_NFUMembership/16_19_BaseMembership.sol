// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/INFTPriceResolver.sol';
import '../interfaces/IOperatorFilter.sol';
import './ERC721FU.sol';

enum TransferType {
  SOUL_BOUND,
  DEACTIVATE,
  STANDARD
}

/**
 * @notice This is a reduced implementation similar to BaseNFT but with limitations on token transfers. This functionality was originally described in https://github.com/tankbottoms/juice-interface-svelte/issues/752.
 */
abstract contract BaseMembership is ERC721FU, AccessControlEnumerable, ReentrancyGuard {
  using Strings for uint256;

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant REVEALER_ROLE = keccak256('REVEALER_ROLE');

  /**
   * @notice NFT provenance hash reassignment prohibited.
   */
  error PROVENANCE_REASSIGNMENT();

  /**
   * @notice Base URI assignment along with the "revealed" flag can only be done once.
   */
  error ALREADY_REVEALED();

  /**
   * @notice User mint allowance exhausted.
   */
  error ALLOWANCE_EXHAUSTED();

  /**
   * @notice mint() function received an incorrect payment, expected payment returned as argument.
   */
  error INCORRECT_PAYMENT(uint256);

  /**
   * @notice Token supply exhausted, all tokens have been minted.
   */
  error SUPPLY_EXHAUSTED();

  /**
   * @notice Various payment failures caused by incorrect contract condiguration.
   */
  error PAYMENT_FAILURE();

  error MINT_NOT_STARTED();
  error MINT_CONCLUDED();

  error INVALID_TOKEN();

  error INVALID_RATE();

  error MINTING_PAUSED();

  error CALLER_BLOCKED();

  /**
   * @notice This ERC721 implementation is soul-bound, transfers and approvals are disabled. Tokens can be minted subject to OperatorFilter is any and can be burned by priviliged users.
   */
  error TRANSFER_DISABLED();

  /**
   * @notice Prevents minting outside of the mint period if set. Can be set only to have a start or only and end date.
   */
  modifier onlyDuringMintPeriod() {
    uint256 start = mintPeriod >> 128;
    if (start != 0) {
      if (start > block.timestamp) {
        revert MINT_NOT_STARTED();
      }
    }

    uint256 end = uint128(mintPeriod);
    if (end != 0) {
      if (end < block.timestamp) {
        revert MINT_CONCLUDED();
      }
    }

    _;
  }
  /**
   * @notice Prevents minting by blocked addresses and contracts hashes.
   */
  modifier callerNotBlocked(address account) {
    if (address(operatorFilter) != address(0)) {
      if (!operatorFilter.mayTransfer(account)) {
        revert CALLER_BLOCKED();
      }
    }

    _;
  }

  uint256 public maxSupply;
  uint256 public unitPrice;

  /**
   * @notice Maximum number of NFTs a single address can own. For SOUL_BOUND configuration this number should be 1.
   */
  uint256 public mintAllowance;
  uint256 public mintPeriod;
  uint256 public totalSupply;

  string public baseUri;
  string public contractUri;
  string public provenanceHash;

  /**
   * @notice Revealed flag.
   *
   * @dev changes the way tokenUri(uint256) works.
   */
  bool public isRevealed;

  /**
   * @notice Pause minting flag
   */
  bool public isPaused;

  /**
   * @notice Address that receives payments from mint operations.
   */
  address payable public payoutReceiver;

  /**
   * @notice Address that receives payments from secondary sales.
   */
  address payable public royaltyReceiver;

  /**
   * @notice Royalty rate expressed in bps.
   */
  uint256 public royaltyRate;

  TransferType public transferType;

  mapping(uint256 => bool) public activeTokens;
  mapping(address => bool) public activeAddresses;

  INFTPriceResolver public priceResolver;
  IOperatorFilter public operatorFilter;

  //*********************************************************************//
  // ----------------------------- ERC721 ------------------------------ //
  //*********************************************************************//

  /**
   * @notice Apply transfer type condition.
   */
  function approve(address _spender, uint256 _id) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.approve(_spender, _id);
  }

  /**
   * @notice Apply transfer type condition.
   */
  function setApprovalForAll(address _operator, bool _approved) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.setApprovalForAll(_operator, _approved);
  }

  /**
   * @notice Apply transfer type condition.
   */
  function transferFrom(address _from, address _to, uint256 _id) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.transferFrom(_from, _to, _id);

    if (transferType == TransferType.DEACTIVATE) {
      activeTokens[_id] = false;
    }
  }

  /**
   * @notice Apply transfer type condition.
   */
  function safeTransferFrom(address _from, address _to, uint256 _id) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.safeTransferFrom(_from, _to, _id);

    if (transferType == TransferType.DEACTIVATE) {
      activeTokens[_id] = false;
    }
  }

  /**
   * @notice Apply transfer type condition.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    bytes calldata _data
  ) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.safeTransferFrom(_from, _to, _id, _data);

    if (transferType == TransferType.DEACTIVATE) {
      activeTokens[_id] = false;
    }
  }

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
   * @notice Get contract metadata to make OpenSea happy.
   */
  function contractURI() public view returns (string memory) {
    return contractUri;
  }

  /**
   * @dev If the token has been set as "revealed", returned uri will append the token id
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
    if (_ownerOf[_tokenId] == address(0)) {
      uri = '';
    } else {
      uri = !isRevealed ? baseUri : string(abi.encodePacked(baseUri, _tokenId.toString()));
    }
  }

  /**
   * @notice EIP2981 implementation for royalty distribution.
   *
   * @param _tokenId Token id.
   * @param _salePrice NFT sale price to derive royalty amount from.
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view virtual returns (address receiver, uint256 royaltyAmount) {
    if (_salePrice == 0 || _ownerOf[_tokenId] != address(0)) {
      receiver = address(0);
      royaltyAmount = 0;
    } else {
      receiver = royaltyReceiver == address(0) ? address(this) : royaltyReceiver;
      royaltyAmount = (_salePrice * royaltyRate) / 10_000;
    }
  }

  /**
   * @dev rari-capital version of ERC721 reverts when owner is address(0), usually that means it's not minted, this is problematic for several workflows. This function simply returns an address.
   */
  function ownerOf(uint256 _tokenId) public view override returns (address owner) {
    owner = _ownerOf[_tokenId];
  }

  function mintPeriodStart() external view returns (uint256 start) {
    start = mintPeriod >> 128;
  }

  function mintPeriodEnd() external view returns (uint256 end) {
    end = uint256(uint128(mintPeriod));
  }

  function getMintPrice(address _minter) external view returns (uint256) {
    // TODO: virtual
    if (address(priceResolver) == address(0)) {
      return unitPrice;
    }

    return priceResolver.getPriceWithParams(address(this), _minter, totalSupply + 1, '');
  }

  function isActive(uint256 _tokenId) external view returns (bool) {
    address tokenOwner = _ownerOf[_tokenId];
    if (tokenOwner == address(0)) {
      return false;
    }

    return activeAddresses[tokenOwner] || activeTokens[_tokenId];
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Mints a token to the calling account. Must be paid in Ether if price is non-zero.
   *
   * @dev Proceeds are forwarded to the default Juicebox terminal for the project id set in the constructor. Payment will fail if the terminal is not set in the jbx directory.
   */
  function mint()
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(msg.sender);
  }

  /**
   * @notice Mints a token to the provided account rather than the caller. Must be paid in Ether if price is non-zero.
   *
   * @dev Proceeds are forwarded to the default Juicebox terminal for the project id set in the constructor. Payment will fail if the terminal is not set in the jbx directory.
   */
  function mint(
    address _account
  )
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(_account);
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Privileged operation callable by accounts with MINTER_ROLE permission to mint the next NFT id to the provided address.
   *
   * @dev Note, this function is not subject to mintAllowance.
   */
  function mintFor(
    address _account
  ) external virtual onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    unchecked {
      ++totalSupply;
    }
    tokenId = totalSupply;
    _mint(_account, tokenId);
  }

  /**
   * @notice Privileged operation callable by accounts with MINTER_ROLE permission to burn a token.
   */
  function revoke(uint256 _tokenId) external virtual onlyRole(MINTER_ROLE) {
    _burn(_tokenId);
  }

  function setPause(bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isPaused = pause;
  }

  function addMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_ROLE, _account);
  }

  function removeMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(MINTER_ROLE, _account);
  }

  function addRevealer(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(REVEALER_ROLE, _account);
  }

  function removeRevealer(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(REVEALER_ROLE, _account);
  }

  /**
   * @notice Set provenance hash.
   *
   * @dev This operation can only be executed once.
   */
  function setProvenanceHash(string memory _provenanceHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (bytes(provenanceHash).length != 0) {
      revert PROVENANCE_REASSIGNMENT();
    }
    provenanceHash = _provenanceHash;
  }

  /**
    @notice Metadata URI for token details in OpenSea format.
   */
  function setContractURI(string memory _contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    contractUri = _contractUri;
  }

  /**
   * @notice Allows adjustment of minting period.
   *
   * @param _mintPeriodStart New minting period start.
   * @param _mintPeriodEnd New minting period end.
   */
  function updateMintPeriod(
    uint256 _mintPeriodStart,
    uint256 _mintPeriodEnd
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    mintPeriod = (_mintPeriodStart << 128) | _mintPeriodEnd;
  }

  function updateUnitPrice(uint256 _unitPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
    unitPrice = _unitPrice;
  }

  function updatePriceResolver(
    INFTPriceResolver _priceResolver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    priceResolver = _priceResolver;
  }

  function updateOperatorFilter(
    IOperatorFilter _operatorFilter
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    operatorFilter = _operatorFilter;
  }

  /**
   * @notice Set NFT metadata base URI.
   *
   * @dev URI must include the trailing slash.
   */
  function setBaseURI(string memory _baseUri, bool _reveal) external onlyRole(REVEALER_ROLE) {
    if (isRevealed && !_reveal) {
      revert ALREADY_REVEALED();
    }

    baseUri = _baseUri;
    isRevealed = _reveal;
  }

  /**
   * @notice Allows owner to transfer ERC20 balances.
   */
  function transferTokenBalance(
    IERC20 token,
    address to,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.transfer(to, amount);
  }

  function setPayoutReceiver(
    address payable _payoutReceiver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    payoutReceiver = _payoutReceiver;
  }

  /**
   * @notice Sets royalty info
   *
   * @param _royaltyReceiver Payable royalties receiver.
   * @param _royaltyRate Rate expressed in bps, can only be set once.
   */
  function setRoyalties(
    address _royaltyReceiver,
    uint16 _royaltyRate
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyReceiver = payable(_royaltyReceiver);

    if (_royaltyRate > 10_000) {
      revert INVALID_RATE();
    }

    if (royaltyRate == 0) {
      royaltyRate = _royaltyRate;
    }
  }

  function activateToken(uint256 _tokenId, bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_ownerOf[_tokenId] == address(0)) {
      revert INVALID_TOKEN();
    }

    activeTokens[_tokenId] = _active;
  }

  function activateAddress(address _account, bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    activeAddresses[_account] = _active;
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Accepts Ether payment and forwards it to the appropriate jbx terminal during the mint phase.
   *
   * @dev This version of the NFT does not directly accept Ether and will fail to process mint payment if there is no payoutReceiver set.
   *
   * @dev In case of multi-mint where the amount passed to the transaction is greater than the cost of a single mint, it would be up to the caller of this function to refund the difference. Here we'll take only the required amount to mint the tokens we're allowed to.
   */
  function processPayment() internal virtual returns (uint256 balance, uint256 refund) {
    uint256 accountBalance = _balanceOf[msg.sender];
    if (accountBalance == mintAllowance) {
      revert ALLOWANCE_EXHAUSTED();
    }

    uint256 expectedPrice = unitPrice;
    if (address(priceResolver) != address(0)) {
      expectedPrice = priceResolver.getPrice(address(this), msg.sender, 0);
    }

    uint256 mintCost = msg.value; // TODO: - platformMintFee;

    if (mintCost < expectedPrice) {
      revert INCORRECT_PAYMENT(expectedPrice);
    }

    if (mintCost == 0 || mintCost == expectedPrice) {
      balance = 1;
      refund = 0;
    } else if (mintCost > expectedPrice) {
      if (address(priceResolver) != address(0)) {
        // TODO: pending changes to INFTPriceResolver
        balance = 1;
        refund = mintCost - expectedPrice;
      } else {
        balance = mintCost / expectedPrice;

        if (totalSupply + balance > maxSupply) {
          // reduce to max supply
          balance -= totalSupply + balance - maxSupply;
        }

        if (accountBalance + balance > mintAllowance) {
          // reduce to mint allowance; since we're here, final balance shouuld be >= 1
          balance -= accountBalance + balance - mintAllowance;
        }

        refund = mintCost - (balance * expectedPrice);
      }
    }

    if (payoutReceiver != address(0)) {
      (bool success, ) = payoutReceiver.call{value: mintCost - refund}('');
      if (!success) {
        revert PAYMENT_FAILURE();
      }
    } else {
      revert PAYMENT_FAILURE();
    }

    // transfer platform fee
  }

  /**
   * @notice Function to consolidate functionality for external mint calls.
   *
   * @dev External calls should be validated by modifiers like `onlyDuringMintPeriod` and `callerNotBlocked`.
   *
   * @param _account Address to assign the new token to.
   */
  function mintActual(address _account) internal virtual returns (uint256 tokenId) {
    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    if (isPaused) {
      revert MINTING_PAUSED();
    }

    (uint256 balance, uint256 refund) = processPayment();

    for (; balance != 0; ) {
      unchecked {
        ++totalSupply;
      }
      tokenId = totalSupply;
      _mint(_account, tokenId);
      unchecked {
        --balance;
      }
    }

    if (refund != 0) {
      msg.sender.call{value: refund}('');
    }
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(AccessControlEnumerable, ERC721FU) returns (bool) {
    return
      interfaceId == type(IERC2981).interfaceId || // 0x2a55205a
      AccessControlEnumerable.supportsInterface(interfaceId) ||
      ERC721FU.supportsInterface(interfaceId);
  }
}