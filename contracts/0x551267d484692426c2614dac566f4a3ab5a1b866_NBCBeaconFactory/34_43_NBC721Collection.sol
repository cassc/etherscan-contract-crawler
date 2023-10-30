// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC721AUpgradeable, ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { ERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./NBCErrors.sol";
import "./NBCStructsAndEnums.sol";

contract NBC721Collection is 
  ERC721AQueryableUpgradeable, 
  ERC2981Upgradeable, 
  OwnableUpgradeable, 
  PaymentSplitterUpgradeable,
  ReentrancyGuardUpgradeable, 
  OperatorFilterer 
{
  using ECDSA for bytes32;

  uint256 public MAX_SUPPLY;
  bool public mintDisabled;

  mapping(uint256 => PresaleSettings) public presaleStages;
  mapping(address => mapping(uint256 => uint256)) private amountMintedForStage;

  SaleMode public publicStageMode;
  StandardSaleSettings public publicSaleStage;
  DutchAuctionSettings public publicAuctionStage;

  address private signer;
  mapping(bytes => bool) private _usedSignatures;
  bool public operatorFilteringEnabled;

  string public baseTokenURI;
  bool public revealed;
  uint256 public randomOffset;

  address[] public withdrawAddresses;

  uint256 internal constant _UNLIMITED_MAX_TOKEN_SUPPLY_FOR_STAGE = type(uint256).max;
  uint128 internal constant _PUBLIC_STAGE_INDEX = 0;
  uint128 internal constant _MAX_PRESALE_STAGES = 10;

  function initialize(
    string memory _name,
    string memory _symbol,
    Init721Params memory _initParams,
    address[] memory _paymentSplitterAddresses,
    uint256[] memory _paymentSplitterShares,
    address _initialOwner
  ) public initializer initializerERC721A {
    __ERC721A_init(_name, _symbol);
    __Ownable_init();
    __ERC2981_init();
    __PaymentSplitter_init(
      _paymentSplitterAddresses,
      _paymentSplitterShares
    );
    MAX_SUPPLY = _initParams.maxSupply;
    signer = _initParams.initSigner;
    baseTokenURI = _initParams.baseTokenURI;
    withdrawAddresses = _paymentSplitterAddresses;
    _registerForOperatorFiltering();
    if (_initParams.royaltyAmount == 0) {
      operatorFilteringEnabled = false;
    } else {
      operatorFilteringEnabled = true;
      _setDefaultRoyalty(_initParams.royaltyAddress, _initParams.royaltyAmount);
    }
    
    transferOwnership(_initialOwner);
  }

  modifier callerIsUser()  {
    if (tx.origin != msg.sender) {
      revert InvalidCaller();
    }
    _;
  }

  /** Airdrop **/

  function airdropMint(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
    if (receivers.length != amounts.length || receivers.length == 0) {
      revert InvalidAirdropParams();
    }
    for (uint256 i; i < receivers.length; ) {
      _mintWrapper(receivers[i], amounts[i]);
      unchecked {
        ++i;
      }
    }

    if (_totalMinted() > MAX_SUPPLY) {
      revert ExceedMaxSupply();
    }
  }

  /** Update Params **/
  function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
    if (totalSupply() > _maxSupply) {
      revert InvalidMaxSupply();
    }
    MAX_SUPPLY = _maxSupply;
  }

  function updateMintDisabled(bool _mintDisabled) external onlyOwner {
    mintDisabled = _mintDisabled;
  }

  function isSignerActive() external view returns (bool) {
    return signer != address(0);
  }

  function updateSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function updatePublicStageMode(SaleMode _saleMode) external onlyOwner {
    publicStageMode = _saleMode;
  }

  function configureFullSaleParams(
    InitPresaleParams[] memory _presaleStages,
    SaleMode _publicStageMode,
    StandardSaleSettings calldata _publicSaleParams, 
    DutchAuctionSettings calldata _publicAuctionParams
  ) external onlyOwner {
    if (_presaleStages.length > _MAX_PRESALE_STAGES) {
      revert InvalidPresaleStage();
    }

    for (uint256 i = 0; i < _presaleStages.length; ) {
      PresaleSettings memory setting;
      setting.price = _presaleStages[i].price;
      setting.maxSupply = _presaleStages[i].maxSupply;
      setting.startTime = _presaleStages[i].startTime;
      setting.endTime = _presaleStages[i].endTime;
      setting.maxPerWallet = _presaleStages[i].maxPerWallet;
      setting.merkleRoot = _presaleStages[i].merkleRoot;

      uint256 stageIndex = _presaleStages[i].stageIndex;
      PresaleSettings memory existingStage = presaleStages[stageIndex];
      uint32 existingAmountMinted = existingStage.amountMinted;
      presaleStages[stageIndex] = setting;
      presaleStages[stageIndex].amountMinted = existingAmountMinted;

      unchecked {
        ++i;
      }
    }

    publicStageMode = _publicStageMode;

    if (publicStageMode == SaleMode.Standard) {
      publicSaleStage = _publicSaleParams;
    }

    if (publicStageMode == SaleMode.Auction) {
      publicAuctionStage = _publicAuctionParams;
    }
  }

  function updatePresaleParams(uint256 _stageIndex, PresaleSettings calldata _saleParams) external onlyOwner {
    if (_stageIndex < 1 || _stageIndex > _MAX_PRESALE_STAGES) {
      revert InvalidPresaleStage();
    }

    PresaleSettings memory stage = presaleStages[_stageIndex];
    uint32 existingAmountMinted = stage.amountMinted;

    presaleStages[_stageIndex] = _saleParams;
    presaleStages[_stageIndex].amountMinted = existingAmountMinted;
  }

  function updatePublicSaleParams(StandardSaleSettings calldata _saleParams, bool _updateSaleMode) external onlyOwner {
    if (_updateSaleMode) {
      publicStageMode = SaleMode.Standard;
    }
    publicSaleStage = _saleParams;
  }

  function updatePublicAuctionParams(DutchAuctionSettings calldata _auctionParams, bool _updateSaleMode) external onlyOwner {
    if (_updateSaleMode) {
      publicStageMode = SaleMode.Auction;
    }
    publicAuctionStage = _auctionParams;
  }

  function updateBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  /** Mint **/

  function presaleMint(uint256 _stageIndex, uint256 _quantity, uint64 _nounce, bytes calldata _signature, bytes32[] calldata _proof) external payable callerIsUser {
    PresaleSettings memory stage = presaleStages[_stageIndex];

    _checkActive(stage.startTime, stage.endTime);
    _checkMintQuantity(
      msg.sender,
      _quantity, 
      _stageIndex,
      stage.maxSupply,
      stage.maxPerWallet, 
      0,
      stage.amountMinted
    );
    _checkCorrectPayment(_quantity, stage.price);
    _checkValidSignature(msg.sender, _nounce, _signature);

    if (!MerkleProof.verify(_proof, stage.merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
      revert NotInAllowlist();
    }

    unchecked {
      amountMintedForStage[msg.sender][_stageIndex] += _quantity;
      presaleStages[_stageIndex].amountMinted += uint32(_quantity);
    }
    _usedSignatures[_signature] = true;

    _mintWrapper(msg.sender, _quantity);
  }

  function publicSaleMint(uint256 _quantity, uint64 _nounce, bytes calldata _signature) external payable callerIsUser {
    if (publicStageMode != SaleMode.Standard) {
      revert InvalidSaleMode();
    }

    StandardSaleSettings memory stage = publicSaleStage;
    _checkActive(stage.startTime, stage.endTime);
    _checkMintQuantity(
      msg.sender,
      _quantity, 
      _PUBLIC_STAGE_INDEX,
      _UNLIMITED_MAX_TOKEN_SUPPLY_FOR_STAGE,
      stage.maxPerWallet, 
      stage.maxPerTx,
      _totalMinted()
    );
    _checkCorrectPayment(_quantity, stage.price);
    _checkValidSignature(msg.sender, _nounce, _signature);
    _usedSignatures[_signature] = true;

    _mintWrapper(msg.sender, _quantity);
  }

  function getAuctionPrice() public view returns (uint256) {
    DutchAuctionSettings memory stage = publicAuctionStage;
    if (block.timestamp < stage.startTime) {
      return stage.startPrice;
    }
    if (block.timestamp > stage.endTime) {
      return stage.restPrice;
    }
    uint256 steps = (block.timestamp - stage.startTime) / stage.dropInterval;
    uint256 price = stage.startPrice - (steps * stage.dropPrice);
    return price;
  }

  function publicAuctionMint(uint256 _quantity, uint64 _nounce, bytes calldata _signature) external payable callerIsUser {
    if (publicStageMode != SaleMode.Auction) {
      revert InvalidSaleMode();
    }

    DutchAuctionSettings memory stage = publicAuctionStage;
    _checkActive(stage.startTime, 0);
    _checkMintQuantity(
      msg.sender,
      _quantity, 
      _PUBLIC_STAGE_INDEX,
      _UNLIMITED_MAX_TOKEN_SUPPLY_FOR_STAGE,
      stage.maxPerWallet, 
      stage.maxPerTx,
      _totalMinted()
    );

    uint256 mintPrice = getAuctionPrice();
    uint256 priceTotal = _quantity * mintPrice;
    _checkCorrectPayment(_quantity, mintPrice);
    _checkValidSignature(msg.sender, _nounce, _signature);
    _usedSignatures[_signature] = true;
    _mintWrapper(msg.sender, _quantity);

    if (msg.value > priceTotal) {
      (bool sent, ) = msg.sender.call{value: msg.value - priceTotal}("");

      if (!sent) {
        revert RefundFailed();
      }
    }
  }

  function _mintWrapper(address to, uint256 amount) internal {
    uint256 numBatches = amount / 10;
    for (uint256 i; i < numBatches; ) {
      _mint(to, 10);
      unchecked {
        ++i;
      }
    }

    if (amount % 10 > 0) {
      _mint(to, amount % 10);
    }
  }

  function _checkActive(uint256 startTime, uint256 endTime) internal view {
    if (mintDisabled) {
      revert MintDisabled();
    }

    if (block.timestamp < startTime) {
      revert MintInactive(block.timestamp, startTime, endTime);
    }

    if (endTime > 0 && block.timestamp > endTime) {
      revert MintInactive(block.timestamp, startTime, endTime);
    }
  }

  function _checkCorrectPayment(uint256 quantity, uint256 mintPrice) internal view {
    if (mintPrice > 0 && msg.value != quantity * mintPrice) {
      revert InvalidPayment();
    }
  }

  function _checkMintQuantity(
    address mintTo,
    uint256 quantity,
    uint256 stageIndex,
    uint256 maxSupplyForStage,
    uint256 maxPerWallet,
    uint256 maxPerTx,
    uint256 amountMinted
  ) internal view {
    if (quantity == 0) {
      revert MintQuantityCannotBeZero();
    }

    if (quantity + amountMinted > MAX_SUPPLY) {
      revert ExceedMaxSupply();
    }

    if (stageIndex > _PUBLIC_STAGE_INDEX) {
      if (amountMinted + quantity > maxSupplyForStage) {
        revert ExceedPreMintSupply();
      }
    }
    
    if (maxPerTx > 0 && quantity > maxPerTx) {
      revert ExceedMaxPerTx();
    }

    if (stageIndex == _PUBLIC_STAGE_INDEX) {
      if (maxPerWallet > 0 && (_numberMinted(mintTo) + quantity) > maxPerWallet) {
        revert ExceedMaxPerWallet();
      }
    } else {
      uint256 userMintedAmount = amountMintedForStage[mintTo][stageIndex];
      if ((userMintedAmount + quantity) > maxPerWallet) {
        revert ExceedMaxPerWallet();
      }
    }
  }

  function _checkValidSignature(address _mintTo, uint64 _nounce, bytes memory _signature) internal view {
    if (signer != address(0)) {
      if (_usedSignatures[_signature]) {
        revert SignatureAlreadyUsed();
      }

      bytes32 hashMsg = keccak256(abi.encodePacked(_mintTo, _nounce));
      bytes32 ethSignedMsg = hashMsg.toEthSignedMessageHash();
      
      if (ethSignedMsg.recover(_signature) != signer) {
        revert InvalidSignature();
      }
    }
  }
  
  /** URI HANDLING **/

  function revealToken(string memory _baseTokenURI, bool _applyRandomReveal) external onlyOwner {
    if (_applyRandomReveal) {
      randomOffset = (block.timestamp + block.prevrandao) % MAX_SUPPLY;
    } else {
      randomOffset = 0;
    }

    baseTokenURI = _baseTokenURI;
    revealed = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function tokenURI(uint256 _tokenId) public view override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed) {
      uint256 shiftedTokenId = (_tokenId + randomOffset) % MAX_SUPPLY;
      return string(abi.encodePacked(baseTokenURI, _toString(shiftedTokenId)));
    } else {
      return string(abi.encodePacked(baseTokenURI, _toString(_tokenId)));
    }
  }

  /** WITHDRAW **/

  function withdraw() external onlyOwner nonReentrant {
    for (uint256 i = 0; i < withdrawAddresses.length;) {
      address payable withdrawAddress = payable(withdrawAddresses[i]);
      if (releasable(withdrawAddress) > 0) {
        release(withdrawAddress);
      }

      unchecked {
        ++i;
      }
    }
  }

  function supportsInterface(bytes4 interfaceId) public view override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable) returns (bool) {
    return ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
  }

  function setApprovalForAll(address operator, bool approved)
    public
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    payable
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setOperatorFilteringEnabled(bool enabled) public onlyOwner {
    operatorFilteringEnabled = enabled;
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }
}

// Contract generated by NextBlueChip.xyz