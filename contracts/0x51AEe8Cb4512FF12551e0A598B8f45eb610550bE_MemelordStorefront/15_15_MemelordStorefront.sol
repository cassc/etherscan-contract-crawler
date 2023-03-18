// SPDX-License-Identifier: MIT
/// @title: Rekt Memelords Storefront
/// @author: Nathan Drake <[email protected]>
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import './IDelegationRegistry.sol';

interface IMldContract {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function burn(uint256 tokenId) external;

  function totalSupply() external view returns (uint256 totalSupply);
}

interface ITokenContract {
  function initializeEdition(
    uint256 id,
    uint256 maxSupply,
    string memory uri
  ) external;

  function mint(address to, uint256 id, uint256 amount) external;

  function currentSupply(uint256 id) external returns (uint256 supply);

  function maxSupply(uint256 id) external returns (uint256 supply);

  function balanceOf(
    address account,
    uint256 id
  ) external returns (uint256 balance);
}

error MaxTokensPerTransactionExceeded(uint256 requested, uint256 maximum);
error InsufficientPayment(uint256 sent, uint256 required);
error TotalSupplyExceeded(uint256 id, uint256 requested, uint256 maxSupply);
error DelegateNotValid(address delegate);
error NotOwnerOfMldToken(address requester, uint256 tokenId);
error NotOwnerOfEdition(address requester, uint256 id);
error TokenClaimed(uint256 tokenId);
error MintClosed();
error MintNotFree();

contract MemelordStorefront is Pausable, AccessControl, PaymentSplitter {
  // roles
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  // state
  address public tokenAddress;
  uint256 public mintPrice = 0.042 ether;
  uint256 public mintPerMld = 1;
  uint256 public currentEdition = 0;
  uint256 public mintStart = 1690000000;
  uint256 public mintEnd = 1690000001;
  uint16[] public requiredOwnerOf = [0];

  // create mapping of token ids used to claim
  mapping(uint256 => bool) public claimed;

  // delegate cash, mld, token contract
  IDelegationRegistry dc;
  IMldContract mld;
  ITokenContract token;

  // private vars
  address private _mldAddress;

  constructor(
    address delegateAddress,
    address mldAddress,
    address tokenAddress_,
    address[] memory payees,
    uint256[] memory paymentShares,
    address devWallet,
    address hmooreWallet,
    address saintWallet
  ) PaymentSplitter(payees, paymentShares) {
    tokenAddress = tokenAddress_;
    _mldAddress = mldAddress;

    dc = IDelegationRegistry(delegateAddress);
    mld = IMldContract(mldAddress);
    token = ITokenContract(tokenAddress);

    _grantRole(DEFAULT_ADMIN_ROLE, hmooreWallet);
    _grantRole(ADMIN_ROLE, devWallet);
    _grantRole(ADMIN_ROLE, hmooreWallet);
    _grantRole(ADMIN_ROLE, saintWallet);
  }

  function pause() public onlyRole(ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(ADMIN_ROLE) {
    _unpause();
  }

  function isMintOpen() public view returns (bool) {
    return block.timestamp >= mintStart && block.timestamp <= mintEnd;
  }

  // Setters
  /// @param tokenAddress_ - new token address
  function setTokenAddress(
    address tokenAddress_
  ) external onlyRole(ADMIN_ROLE) {
    tokenAddress = tokenAddress_;
    token = ITokenContract(tokenAddress);
  }

  /// @param newPrice - new mint price in wei
  function setMintPrice(uint256 newPrice) external onlyRole(ADMIN_ROLE) {
    mintPrice = newPrice;
  }

  /// @param id - set current edition id to mint on token contract
  function setCurrentEditionId(uint256 id) external onlyRole(ADMIN_ROLE) {
    currentEdition = id;
  }

  /// @param mintStart_ - set mint start unix timestamp
  function setMintStart(uint256 mintStart_) external onlyRole(ADMIN_ROLE) {
    mintStart = mintStart_;
  }

  /// @param mintEnd_ - set mint end unix timestamp
  function setMintEnd(uint256 mintEnd_) external onlyRole(ADMIN_ROLE) {
    mintEnd = mintEnd_;
  }

  /// @param mintPerMld_ - set mint per mld token
  function setMintPerMld(uint256 mintPerMld_) external onlyRole(ADMIN_ROLE) {
    mintPerMld = mintPerMld_;
  }

  /// @notice - manually set claimed status for token id
  function setClaimed(uint256 id) external onlyRole(ADMIN_ROLE) {
    claimed[id] = true;
  }

  // resetters
  /// @notice - manually reset claimed status for token id
  function resetClaimed(uint256 id) external onlyRole(ADMIN_ROLE) {
    claimed[id] = false;
  }

  /// @notice - reset claimed status for all token ids, not recommended
  function resetClaimedList() external onlyRole(ADMIN_ROLE) {
    uint256 _mldMaxToken = mld.totalSupply();

    for (uint256 i = 0; i < _mldMaxToken; i++) {
      claimed[i] = false;
    }
  }

  /**
   * @notice - setup mint on storefront contract, and initialize edition on token contract
   * @param id - ERC1155 edition id for token contract
   * @param maxSupply - max supply for edition
   * @param startTime_ - unix timestamp for start of mint
   * @param endTime_ - unix timestamp for end of mint
   * @param uri - uri for edition
   */
  function setupMint(
    uint256 id,
    uint256 maxSupply,
    uint256 startTime_,
    uint256 endTime_,
    string calldata uri,
    uint16[] calldata requiredOwnerOf_
  ) external onlyRole(ADMIN_ROLE) {
    token.initializeEdition(id, maxSupply, uri);
    currentEdition = id;
    mintStart = startTime_;
    mintEnd = endTime_;
    requiredOwnerOf = requiredOwnerOf_;
  }

  modifier whenSufficientValue(uint256 numberOfTokens) {
    uint256 totalSale = mintPrice * numberOfTokens;

    if (msg.value < totalSale) {
      revert InsufficientPayment({sent: msg.value, required: totalSale});
    }
    _;
  }

  modifier whenTotalSupplyNotReached(uint256 numberOfTokens) {
    uint256 totalSupply = token.currentSupply(currentEdition);
    uint256 maxSupply = token.maxSupply(currentEdition);

    if (totalSupply + numberOfTokens > maxSupply) {
      revert TotalSupplyExceeded({
        id: currentEdition,
        requested: numberOfTokens,
        maxSupply: maxSupply
      });
    }
    _;
  }

  modifier whenMintOpen() {
    if (!isMintOpen()) {
      revert MintClosed();
    }
    _;
  }

  function _mintCount(
    uint16[] calldata mldClaimTokenIds
  ) internal view returns (uint256) {
    return mintPerMld * mldClaimTokenIds.length;
  }

  /**
   *
   * @param to - address to send tokens to
   * @param mldClaimTokenIds - array of MLD token ids using to claim, must be 1:1 with numberOfTokens, and must be owner or delegate of those tokens
   * @param _vault - optional vault address for delegate.cash
   */
  function claim(
    address to,
    uint16[] calldata mldClaimTokenIds,
    address _vault
  )
    external
    payable
    whenNotPaused
    whenMintOpen
    whenSufficientValue(_mintCount(mldClaimTokenIds))
    whenTotalSupplyNotReached(_mintCount(mldClaimTokenIds))
  {
    address requester = msg.sender;

    if (_vault != address(0)) {
      bool isDelegateValid = dc.checkDelegateForContract(
        requester,
        _vault,
        _mldAddress
      );

      if (!isDelegateValid) {
        revert DelegateNotValid({delegate: requester});
      }

      requester = _vault;
    }

    uint256 numberOfClaims = mldClaimTokenIds.length;
    uint256 numberOfTokens = _mintCount(mldClaimTokenIds);

    for (uint256 i = 0; i < numberOfClaims; i++) {
      uint256 tokenId = mldClaimTokenIds[i];

      if (claimed[tokenId]) {
        revert TokenClaimed({tokenId: tokenId});
      }

      if (mld.ownerOf(tokenId) != requester) {
        revert NotOwnerOfMldToken({requester: requester, tokenId: tokenId});
      }
    }

    token.mint(to, currentEdition, numberOfTokens);

    for (uint256 i = 0; i < numberOfClaims; i++) {
      uint256 tokenId = mldClaimTokenIds[i];
      claimed[tokenId] = true;
    }
  }

  /**
   *
   * @param mldBurnTokenIds - array of MLD token ids using to claim, must be 1:1 with numberOfTokens, and must be owner or delegate of those tokens
   */
  function burnAndClaim(
    uint16[] calldata mldBurnTokenIds
  )
    external
    whenNotPaused
    whenMintOpen
    whenTotalSupplyNotReached(_mintCount(mldBurnTokenIds))
  {
    uint256 numberOfBurns = mldBurnTokenIds.length;
    uint256 numberOfTokens = _mintCount(mldBurnTokenIds);

    for (uint256 i = 0; i < numberOfBurns; i++) {
      uint256 tokenId = mldBurnTokenIds[i];

      require(!claimed[tokenId], 'Token already claimed');

      require(mld.ownerOf(tokenId) == msg.sender, 'Not owner of MLD token');
    }

    for (uint256 i = 0; i < numberOfBurns; i++) {
      uint256 tokenId = mldBurnTokenIds[i];
      mld.burn(tokenId);
    }

    token.mint(msg.sender, currentEdition, numberOfTokens);

    for (uint256 i = 0; i < numberOfBurns; i++) {
      uint256 tokenId = mldBurnTokenIds[i];
      claimed[tokenId] = true;
    }
  }

  modifier whenMintIsFree() {
    if (mintPrice > 0) {
      revert MintNotFree();
    }
    _;
  }

  /**
   *
   * @param to - address to send tokens to
   * @param mldClaimTokenIds - array of MLD token ids using to claim, must be 1:1 with numberOfTokens, and must be owner or delegate of those tokens
   * @param _vault - optional vault address for delegate.cash
   */
  function freeClaim(
    address to,
    uint16[] calldata mldClaimTokenIds,
    address _vault
  )
    external
    whenNotPaused
    whenMintOpen
    whenMintIsFree
    whenTotalSupplyNotReached(_mintCount(mldClaimTokenIds))
  {
    address requester = msg.sender;

    if (_vault != address(0)) {
      bool isDelegateValid = dc.checkDelegateForContract(
        requester,
        _vault,
        _mldAddress
      );

      if (!isDelegateValid) {
        revert DelegateNotValid({delegate: requester});
      }

      requester = _vault;
    }

    // check if the requesters owns all required tokens
    for (uint16 i = 0; i < requiredOwnerOf.length; i++) {
      uint16 tokenId = requiredOwnerOf[i];
      bool isOwnerOf = token.balanceOf(requester, tokenId) > 0;
      if (!isOwnerOf)
        revert NotOwnerOfEdition({requester: requester, id: tokenId});
    }

    uint256 numberOfClaims = mldClaimTokenIds.length;
    uint256 numberOfTokens = _mintCount(mldClaimTokenIds);

    for (uint256 i = 0; i < numberOfClaims; i++) {
      uint256 tokenId = mldClaimTokenIds[i];

      if (claimed[tokenId]) {
        revert TokenClaimed({tokenId: tokenId});
      }

      if (mld.ownerOf(tokenId) != requester) {
        revert NotOwnerOfMldToken({requester: requester, tokenId: tokenId});
      }
    }

    token.mint(to, currentEdition, numberOfTokens);

    for (uint256 i = 0; i < numberOfClaims; i++) {
      uint256 tokenId = mldClaimTokenIds[i];
      claimed[tokenId] = true;
    }
  }
}