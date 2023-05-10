// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import './interfaces/IDCNTSeries.sol';
import './interfaces/IFeeManager.sol';
import './extensions/ERC1155Hooks.sol';
import './utils/Splits.sol';
import './utils/OperatorFilterer.sol';
import './utils/Pausable.sol';
import './interfaces/ITokenWithBalance.sol';
import './utils/Version.sol';

/**
 * @title DCNTSeries
 * @author Zev Nevo. Will Kantaros.
 * @dev An implementation of the ERC1155 multi-token standard.
 */
contract DCNTSeries is
  IDCNTSeries,
  ERC1155Hooks,
  Initializable,
  Ownable,
  AccessControl,
  Pausable,
  Splits,
  OperatorFilterer,
  Version(2)
{
  /*
   * @dev The name of the ERC-1155 contract.
   */
  string private _name;

  /*
   * @dev The symbol of the ERC-1155 contract.
   */
  string private _symbol;

  /*
   * @dev The packed range of valid token IDs.
   */
  uint256 private _packedTokenRange;

  /*
   * @dev The base URI used to generate the URI for individual tokens.
   */
  string private _uri;

  /*
   * @dev The URI for the contract metadata.
   */
  string private _contractURI;

  /*
   * @dev The royalty fee in basis points (1/100th of a percent).
   */
  uint16 public royaltyBPS;

  /*
   * @dev The address that will receive payouts when withdrawing funds.
   * Use 0x0 to default to the contract owner.
   */
  address public payoutAddress;

  /*
   * @dev Whether the tokens are soulbound and cannot be transferred.
   */
  bool public isSoulbound;

  /*
   * @dev Whether the caps on token supplies are able to be increased.
   */
  bool public hasAdjustableCaps;

  /**
   * @dev Mapping of token IDs to drop IDs.
   */
  mapping(uint256 => uint256) public tokenDropIds;

  /**
   * @dev Mapping of drop IDs to drop configurations.
   */
  mapping(uint256 => Drop) private _drops;

  /*
   * @dev Mapping of token ID to the total number of tokens in circulation for that ID.
   */
  mapping(uint256 => uint256) public totalSupply;

  /*
   * @dev The address of the fee manager used to calculate minting fees and commissions.
   */
  address public feeManager;

  /*
   * @dev The address of the ChainLink price feed oracle to convert native currency to USD.
   */
  AggregatorV3Interface public currencyOracle;

  /**
   * @dev Checks whether the caller has the required minimum balance to pass through token gate.
   * @param tokenId The ID of the token to check.
   * @param isPresale A boolean indicating whether the sale type for is presale or primary sale.
   */
  modifier verifyTokenGate(uint256 tokenId, bool isPresale) {
    _verifyTokenGate(tokenId, isPresale);
    _;
  }

  /**
   * @dev Checks whether the caller has the required minimum balance to pass through token gate.
   * @param tokenId The ID of the token to check.
   * @param isPresale A boolean indicating whether the sale type for is presale or primary sale.
   */
  function _verifyTokenGate(uint tokenId, bool isPresale) internal {
    uint256 dropId = tokenDropIds[tokenId];
    TokenGateConfig memory tokenGate = _drops[dropId].tokenGate;
    if (
        tokenGate.tokenAddress != address(0)
        && (
          tokenGate.saleType == SaleType.ALL
          || (isPresale && tokenGate.saleType == SaleType.PRESALE)
          || (!isPresale && tokenGate.saleType == SaleType.PRIMARY)
        )
    ) {
      if ( ITokenWithBalance(tokenGate.tokenAddress).balanceOf(msg.sender) < tokenGate.minBalance ) {
        revert TokenGateDenied();
      }
    }
  }

  /**
   * @dev Checks if a given token ID is within the valid range for this contract.
   * @param tokenId The token ID to check.
  */
  modifier validTokenId(uint256 tokenId) {
    _checkValidTokenId(tokenId);
    _;
  }

  /**
   * @dev Checks if a given token ID is within the valid range for this contract.
   * @param tokenId The token ID to check.
  */
  function _checkValidTokenId(uint256 tokenId) internal view {
    (uint128 startTokenId, uint128 endTokenId) = _getUnpackedTokenRange();
    if ( startTokenId > tokenId || tokenId > endTokenId ) {
      revert NonexistentToken();
    }
  }

  /**
   * @dev Restricts access to only addresses with the DEFAULT_ADMIN_ROLE.
   */
  modifier onlyAdmin() {
    if ( ! hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ) {
      revert OnlyAdmin();
    }
    _;
  }

  /**
   * @dev Initializes the contract with the specified parameters.
   * @param _owner The owner of the contract.
   * @param _config The configuration for the contract.
   * @param _defaultDrop The default drop configuration for all tokens.
   * @param _dropOverrides Optional mapping of custom drop configurations.
   */
  function initialize(
    address _owner,
    SeriesConfig calldata _config,
    Drop calldata _defaultDrop,
    DropMap calldata _dropOverrides
  ) public initializer {
    _transferOwnership(_owner);
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _name = _config.name;
    _symbol = _config.symbol;
    _uri = _config.metadataURI;
    _contractURI = _config.contractURI;
    _setRoyaltyBPS(_config.royaltyBPS);
    payoutAddress = _config.payoutAddress;
    hasAdjustableCaps = _config.hasAdjustableCaps;
    isSoulbound = _config.isSoulbound;
    feeManager = _config.feeManager;
    currencyOracle = AggregatorV3Interface(_config.currencyOracle);
    _setPackedTokenRange(_config.startTokenId, _config.endTokenId);
    _drops[0] = _defaultDrop;
    _setDropMap(_dropOverrides);
  }

  /**
   * @dev Returns the name of the contract.
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the contract.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the URI for a given token ID.
   * A single URI is returned for all token types as defined in EIP-1155's token type ID substitution mechanism.
   * Clients should replace `{id}` with the actual token type ID when calling the function.
   * @dev unused @param tokenId ID of the token to retrieve the URI for.
   */
  function uri(uint256) public view override(IDCNTSeries, ERC1155) returns (string memory) {
    return _uri;
  }

  /**
   * @dev Internal function to set the URI for all token IDs.
   * @param uri_ The URI for token all token IDs.
   */
  function _setURI(string memory uri_) private {
    _uri = uri_;
  }

  /**
   * @dev Set the URI for all token IDs.
   * @param uri_ The URI for token all token IDs.
   */
  function setURI(string memory uri_) external onlyAdmin {
    _uri = uri_;

    (uint128 startTokenId, uint128 endTokenId) = _getUnpackedTokenRange();
    unchecked {
      for (uint256 i = startTokenId; i <= endTokenId; i++) {
        emit URI(_uri, i);
      }
    }
  }

  /**
   * @dev Returns the URI of the contract metadata.
   */
  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Sets the URI of the contract metadata.
   * @param contractURI_ The URI of the contract metadata.
   */
  function setContractURI(string memory contractURI_) external onlyAdmin {
    _contractURI = contractURI_;
  }

  /**
   * @dev Returns the range of token IDs that are valid for this contract.
   * @return startTokenId The starting token ID for this contract.
   * @return endTokenId The ending token ID for this contract.
   */
  function tokenRange() external view returns (uint128 startTokenId, uint128 endTokenId) {
    return _getUnpackedTokenRange();
  }

  /**
   * @dev Sets the packed range of token IDs that are valid for this contract.
   * @param startTokenId The starting token ID for this contract.
   * @param endTokenId The ending token ID for this contract.
  */
  function _setPackedTokenRange(uint128 startTokenId, uint128 endTokenId) internal {
    if ( startTokenId > endTokenId ) {
      revert InvalidTokenRange();
    }

    _packedTokenRange = uint256(startTokenId) << 128 | uint256(endTokenId);
  }

  /**
   * @dev Returns the unpacked range of token IDs that are valid for this contract.
   * @return startTokenId The starting token ID for this contract.
   * @return endTokenId The ending token ID for this contract.
  */
  function _getUnpackedTokenRange() internal view returns (uint128, uint128) {
    uint128 endTokenId = uint128(_packedTokenRange & type(uint128).max);
    uint128 startTokenId = uint128(_packedTokenRange >> 128);
    return (startTokenId, endTokenId);
  }

  /**
   * @dev Sets the drop configurations for the specified token IDs.
   * @param dropMap A parameter object mapping token IDs, drop IDs, and drops.
   */
  function _setDropMap(DropMap calldata dropMap) internal {
    uint256 numberOfTokens = dropMap.tokenIds.length;
    uint256 numberOfDrops = dropMap.dropIds.length;

    if (
        numberOfTokens != dropMap.tokenIdDropIds.length
        || numberOfDrops != dropMap.drops.length
    ) {
      revert ArrayLengthMismatch();
    }

    unchecked {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        uint256 tokenId = dropMap.tokenIds[i];
        uint256 dropId = dropMap.tokenIdDropIds[i];
        _checkValidTokenId(tokenId);
        _checkValidTokenId(dropId);
        tokenDropIds[tokenId] = dropId;
      }

      for (uint256 i = 0; i < numberOfDrops; i++) {
        uint256 dropId = dropMap.dropIds[i];
        Drop calldata drop = dropMap.drops[i];
        _checkValidTokenId(dropId);
        _drops[dropId] = drop;
      }
    }
  }

  /**
   * @dev Returns the drop configuration for the specified token ID.
   * @param tokenId The ID of the token to retrieve the drop configuration for.
   * @return drop The drop configuration mapped to the specified token ID.
   */
  function tokenDrop(uint128 tokenId) external view returns (Drop memory) {
    return _drops[tokenDropIds[tokenId]];
  }

  /**
   * @dev Creates new tokens and updates drop configurations for specified token IDs.
   * @param newTokens Optional number of new token IDs to add to the existing token range.
   * @param dropMap Optional parameter object mapping token IDs, drop IDs, and drops.
   */
  function setTokenDrops(uint128 newTokens, DropMap calldata dropMap) external onlyAdmin {
    if ( newTokens > 0 ) {
      (uint128 startTokenId, uint128 endTokenId) = _getUnpackedTokenRange();
      _setPackedTokenRange(startTokenId, endTokenId + newTokens);
    }

    uint256 numberOfTokens = dropMap.tokenIds.length;
    uint256 numberOfDrops = dropMap.dropIds.length;

    if (
        numberOfTokens != dropMap.tokenIdDropIds.length
        || numberOfDrops != dropMap.drops.length
    ) {
      revert ArrayLengthMismatch();
    }

    unchecked {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        uint256 tokenId = dropMap.tokenIds[i];
        uint256 dropId = dropMap.tokenIdDropIds[i];
        _checkValidTokenId(tokenId);
        _checkValidTokenId(dropId);

        if ( totalSupply[tokenId] > _drops[dropId].maxTokens ) {
          revert CannotDecreaseCap();
        }

        tokenDropIds[tokenId] = dropId;
      }

      for (uint256 i = 0; i < numberOfDrops; i++) {
        uint256 dropId = dropMap.dropIds[i];

        if ( dropId != 0 ) {
          _checkValidTokenId(dropId);
        }

        Drop calldata _drop = dropMap.drops[i];
        Drop storage drop = _drops[dropId];

        if ( drop.maxTokens != _drop.maxTokens ) {
          if ( ! hasAdjustableCaps ) {
            revert CapsAreLocked();
          }
          if ( _drop.maxTokens < drop.maxTokens ) {
            revert CannotDecreaseCap();
          }
        }

        drop.maxTokens = _drop.maxTokens;
        drop.tokenPrice = _drop.tokenPrice;
        drop.maxTokensPerOwner = _drop.maxTokensPerOwner;
        drop.presaleMerkleRoot = _drop.presaleMerkleRoot;
        drop.presaleStart = _drop.presaleStart;
        drop.presaleEnd = _drop.presaleEnd;
        drop.saleStart = _drop.saleStart;
        drop.saleEnd = _drop.saleEnd;
      }
    }
  }

  /**
   * @dev Gets the current price for the specified token. If a currency oracle is set,
   * the price is calculated in native currency using the oracle exchange rate.
   * @param tokenId The ID of the token to get the price for.
   * @return The current price of the specified token.
   */
  function tokenPrice(uint256 tokenId) public view validTokenId(tokenId) returns (uint256) {
    return _tokenPrice(tokenId);
  }

  /**
   * @dev Internal function to get the current price for the specified token. If a currency oracle is set,
   * the price is calculated in native currency using the oracle exchange rate.
   * @param tokenId The ID of the token to get the price for.
   * @return The current price of the specified token.
   */
  function _tokenPrice(uint256 tokenId) internal view returns (uint256) {
    if ( address(currencyOracle) != address(0) ) {
      uint256 decimals = currencyOracle.decimals();
      (
          /* uint80 roundID */,
          int price,
          /*uint startedAt*/,
          /*uint timeStamp*/,
          /*uint80 answeredInRound*/
      ) = currencyOracle.latestRoundData();

      uint256 exchangeRate = decimals <= 18
        ? uint256(price) * (10 ** (18 - decimals))
        : uint256(price) / (10 ** (decimals - 18));

      return uint256(_drops[tokenDropIds[tokenId]].tokenPrice) * (10 ** 18) / exchangeRate;
    }

    return _drops[tokenDropIds[tokenId]].tokenPrice;
  }

  /**
   * @dev Gets the current minting fee for the specified token.
   * @param tokenId The ID of the token to get the minting fee for.
   * @param quantity The quantity of tokens used to calculate the minting fee.
   * @return fee The current fee for minting the specified token.
   */
  function mintFee(uint256 tokenId, uint256 quantity) external view validTokenId(tokenId) returns (uint256 fee) {
    if ( feeManager != address(0) ) {
      (fee, ) = IFeeManager(feeManager).calculateFees(tokenPrice(tokenId), quantity);
    }
  }

  /**
   * @dev Mints a specified number of tokens to a specified address.
   * @param tokenId The ID of the token to mint.
   * @param to The address to which the minted tokens will be sent.
   * @param quantity The quantity of tokens to mint.
   */
  function mint(uint256 tokenId, address to, uint256 quantity)
    external
    payable
    verifyTokenGate(tokenId, false)
    whenNotPaused
  {
    _checkMintable(to, tokenId, quantity);
    uint256 price = tokenPrice(tokenId);
    uint256 fee;
    uint256 commission;

    if ( feeManager != address(0) ) {
      (fee, commission) = IFeeManager(feeManager).calculateFees(price, quantity);
    }

    uint256 totalPrice = (price * quantity) + fee;

    if ( msg.value < totalPrice ) {
      revert InsufficientFunds();
    }

    _mint(to, tokenId, quantity, '');
    totalSupply[tokenId] += quantity;
    _transferFees(fee + commission);
    _transferRefund(msg.value - totalPrice);
  }

  /**
   * @dev Mints a batch of tokens to a specified address.
   * @param tokenIds The IDs of the tokens to mint.
   * @param to The address to which the minted tokens will be sent.
   * @param quantities The quantities to mint of each token.
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
  )
    external
    payable
    whenNotPaused
  {
    uint256 numberOfTokens = tokenIds.length;
    uint256 tokenId;
    uint256 quantity;
    uint256 price;
    uint256 fee;
    uint256 commission;
    uint256 totalPrice;
    uint256 totalFee;
    uint256 totalCommission;

    unchecked {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        tokenId = tokenIds[i];
        quantity = quantities[i];
        _verifyTokenGate(tokenId, false);
        _checkMintable(to, tokenId, quantity);
        price = _tokenPrice(tokenId);

        if ( feeManager != address(0) ) {
          (fee, commission) = IFeeManager(feeManager).calculateFees(price, quantity);
          totalFee += fee;
          totalCommission += commission;
        }

        totalPrice += (price * quantity) + fee;
        totalSupply[tokenId] += quantity;
      }
    }

    if ( msg.value < totalPrice ) {
      revert InsufficientFunds();
    }

    _batchMint(to, tokenIds, quantities, '');
    _transferFees(totalFee + totalCommission);
    _transferRefund(msg.value - totalPrice);
  }

  /**
   * @dev Internal function to check if a drop can be minted.
   * @param to The address to which the minted tokens will be sent.
   * @param tokenId The ID of the token to mint.
   * @param quantity The quantity of tokens to mint.
   */
  function _checkMintable(
    address to,
    uint256 tokenId,
    uint256 quantity
  )
    internal
    view
  {
    _checkValidTokenId(tokenId);
    uint256 dropId = tokenDropIds[tokenId];
    Drop memory drop = _drops[dropId];
    uint256 supply = totalSupply[tokenId];

    if ( block.timestamp < drop.saleStart || block.timestamp > drop.saleEnd ) {
      revert SaleNotActive();
    }

    if ( supply + quantity > drop.maxTokens ) {
      revert MintExceedsMaxSupply();
    }

    if ( balanceOf[to][tokenId] + quantity > drop.maxTokensPerOwner ) {
      revert MintExceedsMaxTokensPerOwner();
    }
  }

  /**
   * @dev Internal function to transfer fees to the fee manager.
   * @param fees The amount of funds to transfer.
   */
  function _transferFees(uint256 fees) internal {
    if ( fees > 0 ) {
      (bool success, ) = payable(IFeeManager(feeManager).recipient()).call{value: fees}("");
      if ( ! success ) {
        revert FeeTransferFailed();
      }
    }
  }

  /**
   * @dev Internal function to transfer excess funds to the caller.
   * @param refund The amount of funds to transfer.
   */
  function _transferRefund(uint256 refund) internal {
    if ( refund > 0 ) {
      (bool success, ) = payable(msg.sender).call{value: refund}("");
      if ( ! success ) {
        revert RefundFailed();
      }
    }
  }

  /**
   * @dev Burns a specified quantity of tokens from the caller's account.
   * @param tokenId The ID of the token to burn.
   * @param quantity The quantity of tokens to burn.
   */
  function burn(uint256 tokenId, uint256 quantity) external {
    if ( balanceOf[msg.sender][tokenId] < quantity ) {
      revert BurnExceedsOwnedTokens();
    }
    _burn(msg.sender, tokenId, quantity);
    totalSupply[tokenId] -= quantity;
  }

  /**
   * @dev Mints specified tokens to multiple recipients as part of an airdrop.
   * @param tokenIds The IDs of the tokens to mint.
   * @param recipients The list of addresses to receive the minted tokens.
   */
  function mintAirdrop(uint256[] calldata tokenIds, address[] calldata recipients) external onlyAdmin {
    uint256 numberOfTokens = tokenIds.length;

    unchecked {
      for (uint i = 0; i < numberOfTokens; i++) {
        _mintAirdrop(tokenIds[i], recipients);
      }
    }
  }

  /**
   * @dev Internal function to mint a specified token to multiple recipients as part of an airdrop.
   * @param tokenId The ID of the token to mint.
   * @param recipients The list of addresses to receive the minted tokens.
   */
  function _mintAirdrop(uint256 tokenId, address[] memory recipients) internal {
    _checkValidTokenId(tokenId);
    uint256 numberOfRecipients = recipients.length;

    if ( totalSupply[tokenId] + numberOfRecipients > _drops[tokenDropIds[tokenId]].maxTokens ) {
      revert AirdropExceedsMaxSupply();
    }

    unchecked {
      for (uint i = 0; i < numberOfRecipients; i++) {
        address to = recipients[i];
        _mint(to, tokenId, 1, '');
      }
      totalSupply[tokenId] += numberOfRecipients;
    }
  }

  /**
   * @dev Mints a specified number of tokens to the presale buyer address.
   * @param to The address to which the minted tokens will be sent.
   * @param tokenId The ID of the token to mint.
   * @param quantity The quantity of tokens to mint.
   * @param maxQuantity The maximum quantity of tokens that can be minted.
   * @param pricePerToken The price per token in wei.
   * @param merkleProof The Merkle proof verifying that the presale buyer is eligible to mint tokens.
   */
  function mintPresale(
    address to,
    uint256 tokenId,
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  )
    external
    payable
    verifyTokenGate(tokenId, true)
    validTokenId(tokenId)
    whenNotPaused
  {
    _checkPresaleMintable(
      to,
      tokenId,
      quantity,
      maxQuantity,
      pricePerToken,
      merkleProof
    );

    uint256 fee;
    uint256 commission;

    if ( feeManager != address(0) ) {
      (fee, commission) = IFeeManager(feeManager).calculateFees(pricePerToken, quantity);
    }

    uint256 totalPrice = (pricePerToken * quantity) + fee;

    if ( msg.value < totalPrice ) {
      revert InsufficientFunds();
    }

    uint256 ownerBalance = balanceOf[to][tokenId];

    if ( ownerBalance + quantity > maxQuantity ) {
      revert MintExceedsMaxTokensPerOwner();
    }

    _mint(to, tokenId, quantity, '');
    _transferFees(fee + commission);
    _transferRefund(msg.value - totalPrice);
  }

  /**
   * @dev Internal function to check if a drop can be presale minted.
   * @param tokenId The ID of the token to mint.
   * @param quantity The quantity of tokens to mint.
   * @param maxQuantity The maximum quantity of tokens that can be minted.
   * @param pricePerToken The price per token in wei.
   * @param merkleProof The Merkle proof verifying that the presale buyer is eligible to mint tokens.
   */
  function _checkPresaleMintable(
    address to,
    uint256 tokenId,
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  )
    internal
    view
  {
    Drop memory drop = _drops[tokenDropIds[tokenId]];

    if ( block.timestamp < drop.presaleStart || block.timestamp > drop.presaleEnd ) {
      revert PresaleNotActive();
    }

    if ( totalSupply[tokenId] + quantity > drop.maxTokens ) {
      revert MintExceedsMaxSupply();
    }

    bool presaleVerification = MerkleProof.verify(
      merkleProof,
      drop.presaleMerkleRoot,
      keccak256(
        abi.encodePacked(
          to,
          maxQuantity,
          pricePerToken
        )
      )
    );

    if ( ! presaleVerification ) {
      revert PresaleVerificationFailed();
    }
  }

  /**
   * @dev Pauses public minting.
   */
  function pause() external whenNotPaused onlyAdmin {
    _pause();
  }

  /**
   * @dev Unpauses public minting.
   */
  function unpause() external whenPaused onlyAdmin {
    _unpause();
  }

  /**
   * @dev Sets the payout address to the specified address.
   * Use 0x0 to default to the contract owner.
   * @param _payoutAddress The address to set as the payout address.
   */
  function setPayoutAddress(address _payoutAddress) external onlyAdmin {
    payoutAddress = _payoutAddress;
  }

  /**
   * @dev Withdraws the balance of the contract to the payout address or the contract owner.
  */
  function withdraw() external {
    if ( splitWallet != address(0) ) {
      revert SplitsAreActive();
    }
    address to = payoutAddress != address(0) ? payoutAddress : owner();
    (bool success, ) = payable(to).call{value: address(this).balance}("");
    if ( ! success ) {
      revert  WithdrawFailed();
    }
  }

  /**
   * @dev Internal function to set the royalty fee.
   * @param _royaltyBPS The royalty fee in basis points. (1/100th of a percent)
   */
  function _setRoyaltyBPS(uint16 _royaltyBPS) internal {
    if ( _royaltyBPS > 100_00 ) {
      revert InvalidBPS();
    }
    royaltyBPS = _royaltyBPS;
  }

  /**
   * @dev Sets the royalty fee (ERC-2981: NFT Royalty Standard).
   * @param _royaltyBPS The royalty fee in basis points. (1/100th of a percent)
   */
  function setRoyaltyBPS(uint16 _royaltyBPS) external onlyAdmin {
    _setRoyaltyBPS(_royaltyBPS);
  }

  /**
   * @dev Returns the royalty recipient and amount for a given sale price.
   * @param tokenId The ID of the token being sold.
   * @param salePrice The sale price of the token.
   * @return receiver The address of the royalty recipient.
   * @return royaltyAmount The amount to be paid to the royalty recipient.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    _checkValidTokenId(tokenId);

    if ( splitWallet != address(0) ) {
      receiver = splitWallet;
    } else if ( payoutAddress != address(0) ) {
      receiver = payoutAddress;
    } else {
      receiver = owner();
    }

    uint256 royaltyPayment = (salePrice * royaltyBPS) / 100_00;

    return (receiver, royaltyPayment);
  }

  /**
   * @dev Returns true if the contract supports the given interface (ERC2981 or ERC1155),
   * as specified by interfaceId, false otherwise.
   * @param interfaceId The interface identifier, as specified in ERC-165.
   * @return True if the contract supports interfaceId, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IDCNTSeries, ERC1155, AccessControl)
    returns (bool)
  {
    return
      interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981.
      AccessControl.supportsInterface(interfaceId) ||
      ERC1155.supportsInterface(interfaceId);
  }

  /**
   * @dev Updates the operator filter registry with the specified subscription.
   * @param enable If true, enables the operator filter, if false, disables it.
   * @param operatorFilter The address of the operator filter subscription.
   */
  function updateOperatorFilter(bool enable, address operatorFilter) external onlyAdmin {
    address self = address(this);
    if ( ! operatorFilterRegistry.isRegistered(self) && enable ) {
      operatorFilterRegistry.registerAndSubscribe(self, operatorFilter);
    } else if ( enable ) {
      operatorFilterRegistry.subscribe(self, operatorFilter);
    } else {
      operatorFilterRegistry.unsubscribe(self, false);
      operatorFilterRegistry.unregister(self);
    }
  }

  /**
   * @dev Hook that is called before any token transfer, including minting and burning.
   * It checks if the operator is allowed and enforces the "soulbound" rule if enabled.
   * @param from The address from which the tokens are being transferred (or 0x0 if minting).
   * @param to The address to which the tokens are being transferred (or 0x0 if burning).
   * @dev unused @param ids An array containing the identifiers of the tokens being transferred.
   * @dev unused @param amounts An array containing the amounts of tokens being transferred.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256[] memory,
    uint256[] memory
  ) internal virtual override onlyAllowedOperator(from) {
    if ( isSoulbound && from != address(0) && to != address(0) ) {
      revert CannotTransferSoulbound();
    }
  }

  /**
   * @dev Sets or revokes approval for a third party ("operator") to manage all of the caller's tokens.
   * @param operator The address of the operator to grant or revoke approval.
   * @param approved True to grant approval, false to revoke it.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override(IDCNTSeries, ERC1155) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }
}