// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import './erc721a/ERC721A.sol';
import './interfaces/IMetadataRenderer.sol';
import './interfaces/IFeeManager.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './interfaces/ITokenWithBalance.sol';
import './storage/EditionConfig.sol';
import './storage/MetadataConfig.sol';
import './storage/DCNT721AStorage.sol';
import './utils/Splits.sol';
import './utils/Version.sol';
import './utils/OperatorFilterer.sol';

/// @title template NFT contract
contract DCNT721A is
  ERC721A,
  AccessControl,
  OperatorFilterer,
  DCNT721AStorage,
  Initializable,
  Ownable,
  Version(8),
  Splits
{
  struct Edition {
    bool hasAdjustableCap;      // Slot 1: X------------------------------- 1  byte
    bool isSoulbound;           // Slot 1: -X------------------------------ 1  byte
    uint32 maxTokens;           // Slot 1: --XXXX-------------------------- 4  bytes (max: 4,294,967,295)
    uint32 maxTokenPurchase;    // Slot 1: ------XXXX---------------------- 4  bytes (max: 4,294,967,295)
    uint32 presaleStart;        // Slot 1: ----------XXXX------------------ 4  bytes (max: Feburary 7th, 2106)
    uint32 presaleEnd;          // Slot 1: --------------XXXX-------------- 4  bytes (max: Feburary 7th, 2106)
    uint32 saleStart;           // Slot 1: ------------------XXXX---------- 4  bytes (max: Feburary 7th, 2106)
    uint32 saleEnd;             // Slot 1: ----------------------XXXX------ 4  bytes (max: Feburary 7th, 2106)
    uint16 royaltyBPS;          // Slot 1: --------------------------XX---- 2  bytes (max: 65,535)
    uint96 tokenPrice;          // Slot 2: XXXXXXXXXXXX-------------------- 12 bytes (max: 79,228,162,514 ETH)
    address payoutAddress;      // Slot 2: ------------XXXXXXXXXXXXXXXXXXXX 20 bytes
    bytes32 presaleMerkleRoot;  // Slot 3: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 32 bytes
  }

  Edition public edition;

  string public baseURI;
  string internal _contractURI;
  address public metadataRenderer;
  bool public saleIsPaused;

  address public parentIP;

  address public feeManager;

  /// ============ Events ============

  /// @notice Emitted after a successful token claim
  /// @param sender recipient of NFT mint
  /// @param tokenId_ of token minted
  event Minted(address sender, uint256 tokenId_);

  /// ========== Modifier =============
  /// @notice verifies caller has minimum balance to pass through token gate
  modifier verifyTokenGate(bool isPresale) {
    if (tokenGateConfig.tokenAddress != address(0)
      && (tokenGateConfig.saleType == SaleType.ALL ||
          isPresale && tokenGateConfig.saleType == SaleType.PRESALE) ||
          !isPresale && tokenGateConfig.saleType == SaleType.PRIMARY) {
            require(ITokenWithBalance(tokenGateConfig.tokenAddress).balanceOf(msg.sender) >= tokenGateConfig.minBalance, 'do not own required token');
    }

    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "onlyAdmin");

    _;
  }

  error FeeTransferFailed();

  /// ============ Constructor ============

  function initialize(
    address _owner,
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig,
    TokenGateConfig memory _tokenGateConfig,
    address _metadataRenderer
  ) public initializer {
    _transferOwnership(_owner);
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _name = _editionConfig.name;
    _symbol = _editionConfig.symbol;
    _currentIndex = _startTokenId();

    feeManager = _editionConfig.feeManager;
    parentIP = _metadataConfig.parentIP;
    tokenGateConfig = _tokenGateConfig;

    edition = Edition({
      hasAdjustableCap: _editionConfig.hasAdjustableCap,
      isSoulbound: _editionConfig.isSoulbound,
      maxTokens: _editionConfig.maxTokens,
      tokenPrice: _editionConfig.tokenPrice,
      maxTokenPurchase: _editionConfig.maxTokenPurchase,
      presaleMerkleRoot: _editionConfig.presaleMerkleRoot,
      presaleStart: _editionConfig.presaleStart,
      presaleEnd: _editionConfig.presaleEnd,
      saleStart: _editionConfig.saleStart,
      saleEnd: _editionConfig.saleEnd,
      royaltyBPS: _editionConfig.royaltyBPS,
      payoutAddress: _editionConfig.payoutAddress
    });

    if (
      _metadataRenderer != address(0) &&
      _metadataConfig.metadataRendererInit.length > 0
    ) {
      metadataRenderer = _metadataRenderer;
      IMetadataRenderer(_metadataRenderer).initializeWithData(
        _metadataConfig.metadataRendererInit
      );
    } else {
      _contractURI = _metadataConfig.contractURI;
      baseURI = _metadataConfig.metadataURI;
    }
  }

  /**
   * @dev Gets the current minting fee for the specified token.
   * @param quantity The quantity of tokens used to calculate the minting fee.
   * @return fee The current fee for minting the specified token.
   */
  function mintFee(uint256 quantity) external view returns (uint256 fee) {
    if ( feeManager != address(0) ) {
      (fee, ) = IFeeManager(feeManager).calculateFees(edition.tokenPrice, quantity);
    }
  }

  /// @notice purchase nft
  function mint(address to, uint256 numberOfTokens)
    external
    payable
    verifyTokenGate(false)
  {
    uint256 mintIndex = _nextTokenId();
    require(block.timestamp >= edition.saleStart && block.timestamp <= edition.saleEnd, "Sales are not active.");
    require(!saleIsPaused, "Sale must be active to mint");
    require(
      mintIndex + numberOfTokens <= edition.maxTokens,
      "Purchase would exceed max supply"
    );
    require(mintIndex <= edition.maxTokens, "SOLD OUT");

    uint256 fee;
    uint256 commission;

    if ( feeManager != address(0) ) {
      (fee, commission) = IFeeManager(feeManager).calculateFees(edition.tokenPrice, numberOfTokens);
    }

    uint256 totalPrice = (edition.tokenPrice * numberOfTokens) + fee;
    require(msg.value >= totalPrice, "Insufficient funds");

    if ( edition.maxTokenPurchase != 0 ) {
      require(numberOfTokens <= edition.maxTokenPurchase, "Exceeded max number per mint");
    }

    _safeMint(to, numberOfTokens);
    unchecked {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        emit Minted(to, mintIndex++);
      }
    }

    _transferFees(fee + commission);
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

  /// @notice allows the owner to "airdrop" users an NFT
  function mintAirdrop(address[] calldata recipients) external onlyAdmin {
    uint256 atId = _nextTokenId();
    uint256 startAt = atId;
    require(atId + recipients.length <= edition.maxTokens,
      "Purchase would exceed max supply"
    );

    unchecked {
      for (
        uint256 endAt = atId + recipients.length;
        atId < endAt;
        atId++
      ) {
        _safeMint(recipients[atId - startAt], 1);
        emit Minted(recipients[atId - startAt], atId);
      }
    }
  }

  /// @notice presale mint function
  function mintPresale(
    address to,
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  )
    external
    payable
    verifyTokenGate(true)
  {
    require (block.timestamp >= edition.presaleStart && block.timestamp <= edition.presaleEnd, 'not presale');
    uint256 mintIndex = _nextTokenId();
    require(!saleIsPaused, "Sale must be active to mint");
    require(
      mintIndex + quantity <= edition.maxTokens,
      "Purchase would exceed max supply"
    );
    require (MerkleProof.verify(
        merkleProof,
        edition.presaleMerkleRoot,
        keccak256(
          // address, uint256, uint256
          abi.encodePacked(to,maxQuantity,pricePerToken)
        )
      ), 'not approved');

    require(msg.value >= (pricePerToken * quantity), "Insufficient funds");
    require(balanceOf(to) + quantity <= maxQuantity, 'minted too many');
    _safeMint(to, quantity);
    unchecked {
      for (uint256 i = 0; i < quantity; i++) {
        emit Minted(to, mintIndex++);
      }
    }
  }

  function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot) external onlyAdmin {
    edition.presaleMerkleRoot = _presaleMerkleRoot;
  }

  /// @notice pause or unpause sale
  function flipSaleState() external onlyAdmin {
    saleIsPaused = !saleIsPaused;
  }

  /// @notice is the current sale active
  function saleIsActive() external view returns(bool _saleIsActive) {
    _saleIsActive = (block.timestamp >= edition.saleStart && block.timestamp <= edition.saleEnd) && (!saleIsPaused);
  }

  function MAX_TOKENS() external view returns (uint32) {
    return edition.maxTokens;
  }

  function tokenPrice() external view returns (uint96) {
    return edition.tokenPrice;
  }

  function maxTokenPurchase() external view returns (uint32) {
    return edition.maxTokenPurchase;
  }

  function hasAdjustableCap() external view returns (bool) {
    return edition.hasAdjustableCap;
  }

  function isSoulbound() external view returns (bool) {
    return edition.isSoulbound;
  }

  function royaltyBPS() external view returns (uint16) {
    return edition.royaltyBPS;
  }

  function payoutAddress() external view returns (address) {
    return edition.payoutAddress;
  }

  function presaleMerkleRoot() external view returns (bytes32) {
    return edition.presaleMerkleRoot;
  }

  function presaleStart() external view returns (uint32) {
    return edition.presaleStart;
  }

  function presaleEnd() external view returns (uint32) {
    return edition.presaleEnd;
  }

  function saleStart() external view returns (uint32) {
    return edition.saleStart;
  }

  function saleEnd() external view returns (uint32) {
    return edition.saleEnd;
  }

  function setTokenGate(TokenGateConfig calldata _tokenGateConfig) external onlyAdmin {
    tokenGateConfig = _tokenGateConfig;
  }

  ///change maximum number of tokens available to mint
  function adjustCap(uint32 newCap) external onlyAdmin {
    require(edition.hasAdjustableCap, 'cannot adjust size of this collection');
    require(_nextTokenId() <= newCap, 'cannot decrease cap');
    edition.maxTokens = newCap;
  }

  /// @notice set the payout address, zero address defaults to owner
  function setPayoutAddress(address _payoutAddress) external onlyAdmin {
    edition.payoutAddress = _payoutAddress;
  }

  /// @notice withdraw funds from contract to seller funds recipient
  function withdraw() external {
    require(
      splitWallet == address(0),
      "Cannot withdraw with an active split"
    );

    address to = edition.payoutAddress != address(0) ? edition.payoutAddress : owner();
    (bool success, ) = payable(to).call{value: address(this).balance}("");
    require(success, "Could not withdraw");
  }

  function setBaseURI(string memory uri) external onlyAdmin {
    baseURI = uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setMetadataRenderer(address _metadataRenderer) external onlyAdmin {
    metadataRenderer = _metadataRenderer;
  }

  /// @notice update the contract URI
  function setContractURI(string memory uri) external onlyAdmin {
    _contractURI = uri;
  }

  /// @notice view the current contract URI
  function contractURI()
    public
    view
    virtual
    returns (string memory)
  {
    return (metadataRenderer != address(0))
      ? IMetadataRenderer(metadataRenderer).contractURI()
      : _contractURI;
  }

  /// @notice view the token URI for a given tokenId
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    if (metadataRenderer != address(0)) {
      return IMetadataRenderer(metadataRenderer).tokenURI(tokenId);
    }
    return super.tokenURI(tokenId);
  }

  /// @notice save some for creator
  function reserveDCNT(uint256 numReserved) external onlyAdmin {
    uint256 supply = _nextTokenId();
    require(
      supply + numReserved < edition.maxTokens,
      "Purchase would exceed max supply"
    );
    for (uint256 i = 0; i < numReserved; i++) {
      _safeMint(msg.sender, supply + i + 1);
    }
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");

    if (splitWallet != address(0)) {
      receiver = splitWallet;
    } else if ( edition.payoutAddress != address(0) ) {
      receiver = edition.payoutAddress;
    } else {
      receiver = owner();
    }

    uint256 royaltyPayment = (salePrice * edition.royaltyBPS) / 10_000;

    return (receiver, royaltyPayment);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, AccessControl)
    returns (bool)
  {
    return
      interfaceId == 0x2a55205a || // ERC2981 interface ID for ERC2981.
      AccessControl.supportsInterface(interfaceId) ||
      ERC721A.supportsInterface(interfaceId) ||
      super.supportsInterface(interfaceId);
  }

  /// @notice update the public sale start time
  function updateSaleStartEnd(uint32 newStart, uint32 newEnd) external onlyAdmin {
    edition.saleStart = newStart;
    edition.saleEnd = newEnd;
  }

  /// @notice update the public sale start time
  function updatePresaleStartEnd(uint32 newStart, uint32 newEnd) external onlyAdmin {
    edition.presaleStart = newStart;
    edition.presaleEnd = newEnd;
  }

  /// @notice update the registration with the operator filter registry
  /// @param enable whether or not to enable the operator filter
  /// @param operatorFilter the address for the operator filter subscription
  function updateOperatorFilter(bool enable, address operatorFilter) external onlyAdmin {
    address self = address(this);
    if (!operatorFilterRegistry.isRegistered(self) && enable) {
      operatorFilterRegistry.registerAndSubscribe(self, operatorFilter);
    } else if (enable) {
      operatorFilterRegistry.subscribe(self, operatorFilter);
    } else {
      operatorFilterRegistry.unsubscribe(self, false);
      operatorFilterRegistry.unregister(self);
    }
  }

  /// @dev Use ERC721A token hook and OperatorFilterer modifier to restrict transfers
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 , // startTokenId
    uint256   // quantity
  ) internal virtual override onlyAllowedOperator(from) {
    require (!edition.isSoulbound || (from == address(0) || to == address(0)), 'soulbound');
  }

  /// @dev Use OperatorFilterer modifier to restrict approvals
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /// @dev Use OperatorFilterer modifier to restrict approvals
  function approve(
    address operator,
    uint256 tokenId
  ) public virtual override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }
}