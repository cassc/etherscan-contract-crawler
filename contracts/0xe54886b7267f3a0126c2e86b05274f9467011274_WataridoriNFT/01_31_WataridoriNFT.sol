// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./WataridoriSBT.sol";

import "./dependencies/IERC4906.sol";
import "./dependencies/IGatewayProxy.sol";
import "./dependencies/IVWBLGateway.sol";
import "./dependencies/VWBLGateway.sol";
import "./interfaces/IWataridoriAccessControlChecker.sol";
import "./interfaces/IWataridoriSBT.sol";
import "./interfaces/IWataridoriTokenURIGetter.sol";
import "./interfaces/IWataridoriVwblToken.sol";

import "hardhat/console.sol";

contract WataridoriNFT is AccessControl, ERC721Enumerable, IERC2981, IERC4906, IWataridoriVwblToken, IWataridoriTokenURIGetter {
  using Strings for uint256;
  using Strings for uint8;

  struct TokenInfo {
    uint32 tokenMasterId;
    uint8 generationNum;
    bytes32 documentId;
  }

  struct TokenMaster {
    uint256 mintPriceWei;
    uint256 raisePriceWei;
    string metadataCid;
    uint16 maxAmount;
    uint8 maxGenerationNum;
    uint256 royaltiesPercentage; // if percentage is 3.5, royaltiesPercentage=3.5*10^2 (decimal is 2)
    bytes32[] documentIds;
    bool isSelfRaiseable;
    bool shouldMintSBT;
    bool isMintable;
  }

  struct MetadataStorageInfo {
    string basePath;
    string baseFileName;
  }

  mapping(uint256 => TokenInfo) public tokenIdToTokenInfo;
  mapping(uint32 =>  TokenMaster) public tokenMasterIdToTokenMaster;

  MetadataStorageInfo public metadataStorageInfo;

  uint256 public tokenCounter = 0;
  uint32 public tokenMasterCounter = 0;
  uint256 public constant INVERSE_BASIS_POINT = 10000;

  address public gatewayProxy;
  address public accessControlChecker;
  address public wataridoriSBT;

  address public recipient;
  address public keyRegister;

  string private signMessage;

  uint256 public pendingFee;
  uint256 public vwblFeePool;

  bytes32 public constant RECIPIENT_ROLE = keccak256("RECIPIENT_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  event accessControlCheckerChanged(address oldAccessControlChecker, address newAccessControlChecker);

  event tokenMasterAdded(uint32 indexed tokenMasterId);
  event raised(address user, uint256 indexed tokenId, uint32 indexed tokenMasterId, uint256 indexed toGenerationNum);

  // Events for tracing sales
  event minted(address user, uint256 indexed tokenId, uint32 indexed tokenMasterId);
  event raisedSelf(address user, uint256 indexed tokenId, uint32 indexed tokenMasterId);
  event transferred(address user, uint256 indexed tokenId, uint32 indexed tokenMasterId);

  event payVwblFeeFromPendingFee(bytes32 indexed documentId, address user, uint256 amount);
  event payVwblFeeFromFeePool(bytes32 indexed documentId, address user, uint256 amount);

  modifier onlyPermitted(bytes32 role) {
    require(
      hasRole(role, msg.sender),
      "WataridoriNFT: not permitted"
    );
    _;
  }

  constructor(
    address _gatewayProxy,
    address _accessControlChecker,
    string memory _signMessage,
    address _keyRegister,
    address _recipient,
    string memory _basePath,
    string memory _baseFileName
  ) ERC721("Wataridori Books", "Wataridori Books") {
    _setupRole(RECIPIENT_ROLE, _recipient);
    _setRoleAdmin(RECIPIENT_ROLE, RECIPIENT_ROLE);

    _setupRole(OPERATOR_ROLE, msg.sender);
    _setRoleAdmin(OPERATOR_ROLE, OPERATOR_ROLE);

    gatewayProxy = _gatewayProxy;
    accessControlChecker = _accessControlChecker;
    keyRegister = _keyRegister;
    signMessage = _signMessage;
    recipient = _recipient;

    metadataStorageInfo = MetadataStorageInfo(_basePath, _baseFileName);

    WataridoriSBT sbt = new WataridoriSBT(address(this));
    wataridoriSBT = address(sbt);
  }

  /**
   * @notice Get VWBL Gateway address
   */
  function getGatewayAddress() public view returns (address) {
    return IGatewayProxy(gatewayProxy).getGatewayAddress();
  }

  /**
   * @notice Get VWBL Fee
   */
  function getVWBLFee() public view returns (uint256) {
    return IVWBLGateway(getGatewayAddress()).feeWei();
  }


  /**
   * @notice Get Numbers of minted NFTs by tokenMasterId
   */
  function getMintedAmounts() public view returns (uint256[] memory) {
    uint256[] memory mintedAmounts = new uint256[](tokenMasterCounter);
    for(uint32 i = 0; i < tokenMasterCounter; i++) {
      mintedAmounts[i] = getMintedAmount(i + 1);
    }
    return mintedAmounts;
  }

  /**
   * @notice Get Number of minted NFTs by tokenMasterId
   * @param _tokenMasterId Id of tokenMaster
   */
  function getMintedAmount(uint32 _tokenMasterId) public view returns (uint256) {
    uint256 mintedAmount = 0;
    for(uint256 i = 1; i <= tokenCounter; i++) {
      if(tokenIdToTokenInfo[i].tokenMasterId == _tokenMasterId) {
        mintedAmount += 1;
      }
    }
    return mintedAmount;
  }

  /**
   * @notice Get Number of minted NFTs by tokenMasterId and generationNum
   * @param _tokenMasterId Id of tokenMaster
   */
  function getGenerationCounts(uint32 _tokenMasterId) public view returns(uint256[] memory) {
    uint256[] memory generationCounts = new uint256[](tokenMasterIdToTokenMaster[_tokenMasterId].maxGenerationNum);
    for(uint256 i = 1; i <= tokenCounter; i++) {
      if(tokenIdToTokenInfo[i].tokenMasterId == _tokenMasterId) {
        generationCounts[tokenIdToTokenInfo[i].generationNum - 1] += 1;
      }
    }
    return generationCounts;
  }

  /**
   * @notice Get MetadataCid of tokenMaster
   * @param _tokenMasterId Id of tokenMaster
   */
  function getMetadataCid(uint32 _tokenMasterId) public view returns (string memory) {
    return tokenMasterIdToTokenMaster[_tokenMasterId].metadataCid;
  }

  /**
   * @notice Get TokenCounter
   */
  function getTokenCounter() public view returns (uint256) {
    return tokenCounter;
  }

  function getAdditionalCheckAddress() public view returns (address) {
    return wataridoriSBT;
  }

  /**
   * @notice Get keyRegister address(Called from AccessController)
   */
  function getKeyRegister(uint256) public view returns (address) {
    return keyRegister;
  }

  /**
   * @notice Set address who send key to VWBL Netrowk
   * @param _keyRegister New keyRegister address
   */
  function setKeyRegister(address _keyRegister) public onlyPermitted(OPERATOR_ROLE) {
    require(_keyRegister != address(0), "WataridoriNFT: invalid address");
    require(_keyRegister != keyRegister, "WataridoriNFT: same address");
    keyRegister = _keyRegister;
  }

  /**
   * @notice Get message to sign
   */
  function getSignMessage() public view returns (string memory) {
    return signMessage;
  }

  /**
   * @notice Set message to sign
   * @param _signMessage New message to sign
   */
  function setSignMessage(string memory _signMessage) public onlyPermitted(OPERATOR_ROLE) {
    signMessage = _signMessage;
  }

  /**
   * @notice Set new recipient
   * @param _recipient New recipient address
   */
  function setRecipient(address _recipient) public onlyPermitted(RECIPIENT_ROLE) {
    require(_recipient != address(0), "WataridoriNFT: invalid address");
    require(_recipient != recipient, "WataridoriNFT: same address");

    grantRole(RECIPIENT_ROLE, _recipient);
    revokeRole(RECIPIENT_ROLE, recipient);
    recipient = _recipient;
  }

  /**
   * @notice Set new accessControlChecker
   * @param _accessControlChecker New accessControlChecker contract address
   */
  function setAccessControlChecker(address _accessControlChecker) public onlyPermitted(OPERATOR_ROLE) {
    require(_accessControlChecker != address(0), "WataridoriNFT: invalid address");
    require(_accessControlChecker != accessControlChecker, "WataridoriNFT: same address");
    address oldAccessControlChecker = accessControlChecker;
    accessControlChecker = _accessControlChecker;
    emit accessControlCheckerChanged(oldAccessControlChecker, _accessControlChecker);
  }

  /**
   * @notice Set New TokenMaster
   * @param _mintPriceWei price to mint
   * @param _raisePriceWei price to raise
   * @param _metadataCid directory cid of metadata url
   * @param _maxAmount max amount of mint
   * @param _maxGenerationNum max generation number of metadata
   * @param _royaltiesPercentage royalties percentage (if percentage is 3.5, _royaltiesPercentage=3.5*10^2 (decimal is 2))
   * @param _documentIds Array of document ids for generations
   */
  function setTokenMaster(
    uint256 _mintPriceWei,
    uint256 _raisePriceWei,
    string memory _metadataCid,
    uint16 _maxAmount,
    uint8 _maxGenerationNum,
    uint256 _royaltiesPercentage,
    bytes32[] memory _documentIds,
    bool _isSelfRaiseable,
    bool _shouldMintSBT
  ) external payable onlyPermitted(OPERATOR_ROLE) returns (uint32){
    require(_maxAmount > 0, "WataridoriNFT: invalid maxAmount");
    require(_maxGenerationNum > 0, "WataridoriNFT: invalid maxGenerationNum");
    require(_documentIds.length == _maxGenerationNum, "WataridoriNFT: invalid length of documentIds");

    uint256 vwblFee = getVWBLFee();
    require(msg.value == vwblFee * _maxGenerationNum, "WataridoriNFT: invalid value");

    uint32 tokenMasterId = ++tokenMasterCounter;

    tokenMasterIdToTokenMaster[tokenMasterId] = TokenMaster(
      _mintPriceWei,
      _raisePriceWei,
      _metadataCid,
      _maxAmount,
      _maxGenerationNum,
      _royaltiesPercentage,
      _documentIds,
      _isSelfRaiseable,
      _shouldMintSBT,
      true
    );

    emit tokenMasterAdded(tokenMasterId);

    for(uint256 i = 0; i < _documentIds.length; i++) {
      IVWBLGateway(getGatewayAddress()).grantAccessControl{ value: vwblFee }(
        _documentIds[i],
        accessControlChecker,
        keyRegister
      );
      IWataridoriAccessControlChecker(accessControlChecker).registerDocumentId(_documentIds[i], address(this));
    }

    return tokenMasterId;
  }

  function getDocumentIds(uint32 _tokenMasterId) public view returns (bytes32[] memory) {
    return tokenMasterIdToTokenMaster[_tokenMasterId].documentIds;
  }

  /**
   * @notice Set TokenMaster
   * @param _tokenMasterId tokenMasterId
   * @param _metadataCid directory cid of metadata url
   */
  function setTokenMasterCid(
    uint32 _tokenMasterId,
    string memory _metadataCid
  ) public onlyPermitted(OPERATOR_ROLE) {
    require(_tokenMasterId <= tokenMasterCounter, "WataridoriNFT: invalid tokenMasterId");
    tokenMasterIdToTokenMaster[_tokenMasterId].metadataCid = _metadataCid;

    for (uint256 i = 1; i <= tokenCounter; i++) {
      if (tokenIdToTokenInfo[i].tokenMasterId == _tokenMasterId) {
        emit MetadataUpdate(i);
      }
    }
  }

  /**
   * @notice Set TokenMaster mintable
   * @param _tokenMasterId tokenMasterId
   * @param _isMintable mintable or not
   */
  function setTokenMasterMintable(uint32 _tokenMasterId, bool _isMintable) public onlyPermitted(OPERATOR_ROLE) {
    require(_tokenMasterId <= tokenMasterCounter, "WataridoriNFT: invalid tokenMasterId");
    tokenMasterIdToTokenMaster[_tokenMasterId].isMintable = _isMintable;
  }

  /**
   * @notice Set metadataStorageInfo
   * @param _basePath base path of metadata url
   * @param _baseFileName base file name of metadata url
   */
  function setMetadataStorageInfo(string memory _basePath, string memory _baseFileName) public onlyPermitted(OPERATOR_ROLE) {
    metadataStorageInfo = MetadataStorageInfo(_basePath, _baseFileName);
  }

  /**
   * @notice Mint NFT and grant access control
   * @param _tokenMasterId Id of TokenMaster
   */
  function mint(
    uint32 _tokenMasterId
  ) public payable returns (uint256){
    TokenMaster memory tokenMaster = tokenMasterIdToTokenMaster[_tokenMasterId];
    require(tokenMaster.isMintable, "WataridoriNFT: not mintable");

    uint256 mintPrice = tokenMaster.mintPriceWei;
    require(msg.value == mintPrice, "WataridoriNFT: invalid value");

    uint256 mintedAmount = getMintedAmount(_tokenMasterId);
    require(mintedAmount < tokenMaster.maxAmount, "WataridoriNFT: max amount exceeded");

    pendingFee += msg.value;

    uint256 tokenId = _mint(_tokenMasterId);
    TokenInfo memory tokenInfo = tokenIdToTokenInfo[tokenId];

    emit minted(msg.sender, tokenId, tokenInfo.tokenMasterId);

    IWataridoriAccessControlChecker(accessControlChecker).registerToken(
      tokenInfo.documentId,
      address(this),
      tokenId
    );

    _payVwblFeeFromPendingFee(tokenInfo.documentId, msg.sender);

    return tokenId;
  }

  function _mint(
    uint32 _tokenMasterId
  ) internal returns (uint256) {
    uint256 tokenId = ++tokenCounter;
    bytes32 documentId = tokenMasterIdToTokenMaster[_tokenMasterId].documentIds[0];
    TokenInfo memory tokenInfo = TokenInfo(_tokenMasterId, 1, documentId);
    tokenIdToTokenInfo[tokenId] = tokenInfo;
    super._mint(msg.sender, tokenId);
    return tokenId;
  }

  /**
   * @notice Raise generation number of NFT
   * @param tokenId Id of NFT
   */
  function raiseGeneration(uint256 tokenId) public payable {
    require(msg.sender == ownerOf(tokenId), "WataridoriNFT: not owner");
    uint32 tokenMasterId = tokenIdToTokenInfo[tokenId].tokenMasterId;

    bool isSelfRaiseable = tokenMasterIdToTokenMaster[tokenMasterId].isSelfRaiseable;
    require(isSelfRaiseable, "WataridoriNFT: not self raiseable");

    uint256 generationNum = tokenIdToTokenInfo[tokenId].generationNum;
    require(generationNum < tokenMasterIdToTokenMaster[tokenMasterId].maxGenerationNum, "WataridoriNFT: max generation exceeded");

    uint256 raisePrice = tokenMasterIdToTokenMaster[tokenMasterId].raisePriceWei;
    require(msg.value == raisePrice, "WataridoriNFT: invalid value");

    _raiseGenerationNum(tokenId, ownerOf(tokenId));
    pendingFee += raisePrice;

    emit raisedSelf(msg.sender, tokenId, tokenMasterId);

    TokenInfo memory tokenInfo = tokenIdToTokenInfo[tokenId];
    _payVwblFeeFromPendingFee(tokenInfo.documentId, msg.sender);
  }

  function _raiseGenerationNum(uint256 tokenId, address originalOwner) internal {
    uint8 originalGenerationNum = tokenIdToTokenInfo[tokenId].generationNum;
    bytes32 originalDocumentId = tokenIdToTokenInfo[tokenId].documentId;

    TokenMaster memory tokenMaster = tokenMasterIdToTokenMaster[tokenIdToTokenInfo[tokenId].tokenMasterId];

    if(originalGenerationNum < tokenMaster.maxGenerationNum) {
      tokenIdToTokenInfo[tokenId].generationNum = originalGenerationNum + 1;
      tokenIdToTokenInfo[tokenId].documentId = tokenMaster.documentIds[tokenIdToTokenInfo[tokenId].generationNum - 1];

      uint8 generationNum = tokenIdToTokenInfo[tokenId].generationNum;
      uint32 tokenMasterId = tokenIdToTokenInfo[tokenId].tokenMasterId;

      emit raised(originalOwner, tokenId, tokenMasterId, generationNum);

      IWataridoriAccessControlChecker(accessControlChecker).registerToken(
        tokenIdToTokenInfo[tokenId].documentId,
        address(this),
        tokenId
      );

      emit MetadataUpdate(tokenId);

      if(tokenMaster.shouldMintSBT) {
        _mintSBT(originalOwner, originalDocumentId, tokenMasterId, originalGenerationNum);
      }
    }
  }

  function _mintSBT(address to, bytes32 documentId, uint32 tokenMasterId, uint8 generationNum) internal {
    IWataridoriSBT(wataridoriSBT).mint(to, documentId, tokenMasterId, generationNum);
    uint256 tokenId = IWataridoriVwblToken(wataridoriSBT).getTokenCounter();
    IWataridoriAccessControlChecker(accessControlChecker).registerToken(documentId, wataridoriSBT, tokenId);
  }

  function _transferEmit(address user, uint256 tokenId) internal {
    uint32 tokenMasterId = tokenIdToTokenInfo[tokenId].tokenMasterId;
    emit transferred(user, tokenId, tokenMasterId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
    if(msg.sender != ownerOf(tokenId)) {
      _raiseGenerationNum(tokenId, ownerOf(tokenId));
      _transferEmit(from, tokenId);
    }
    super.transferFrom(from, to, tokenId);

    _payVwblFeeFromVwblFeePool(tokenIdToTokenInfo[tokenId].documentId, to);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) {
    if(msg.sender != ownerOf(tokenId)) {
      _raiseGenerationNum(tokenId, ownerOf(tokenId));
      _transferEmit(from, tokenId);
    }
    super.safeTransferFrom(from, to, tokenId, data);

    _payVwblFeeFromVwblFeePool(tokenIdToTokenInfo[tokenId].documentId, to);
  }

  function isPaidUser(
    bytes32 documentId,
    address user
  ) public view returns (bool) {
    return VWBLGateway(getGatewayAddress()).paidUsers(documentId, user);
  }

  function payVwblFee(
    bytes32 documentId,
    address user
  ) public payable {
    uint256 vwblFee = getVWBLFee();
    require(msg.value <= vwblFee, "WataridoriNFT: Fee is too high");
    require(msg.value >= vwblFee, "WataridoriNFT: Fee is insufficient");

    require(!isPaidUser(documentId, user), "WataridoriNFT: Already paid");

    _payVwblFee(documentId, user, vwblFee);
  }

  function _payVwblFeeFromPendingFee(
    bytes32 documentId,
    address user
  ) internal {
    uint256 vwblFee = getVWBLFee();
    if(pendingFee >= vwblFee && !isPaidUser(documentId, user)) {
      pendingFee -= vwblFee;
      _payVwblFee(documentId, user, vwblFee);
      emit payVwblFeeFromPendingFee(documentId, user, vwblFee);
    } else {
      _payVwblFeeFromVwblFeePool(documentId, user);
    }
  }

  function _payVwblFeeFromVwblFeePool(
    bytes32 documentId,
    address user
  ) internal {
    uint256 vwblFee = getVWBLFee();
    if(vwblFeePool >= vwblFee && !isPaidUser(documentId, user)) {
      vwblFeePool -= vwblFee;
      _payVwblFee(documentId, user, vwblFee);
      emit payVwblFeeFromFeePool(documentId, user, vwblFee);
    }
  }

  function _payVwblFee(
    bytes32 documentId,
    address user,
    uint256 feeWei
  ) internal {
    IVWBLGateway(getGatewayAddress()).payFee{value: feeWei}(documentId, user);
  }

  /**
   * @notice Called with the sale price to determine how much royalty is owned and to whom
   * @param _tokenId The NFT asset queried for royalty information
   * @param _salePrice The sale price of the NFT asset specified by _tokenId
   * @return receiver Address of who should be sent the royalty payment
   * @return royaltyAmount The royalty payment amount for _salePrice
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    uint256 royaltiesPercentage = tokenMasterIdToTokenMaster[tokenIdToTokenInfo[_tokenId].tokenMasterId].royaltiesPercentage;
    uint256 _royaltyAmount = (_salePrice * royaltiesPercentage) / INVERSE_BASIS_POINT;
    return (recipient, _royaltyAmount);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "WataridoriNFT: invalid token ID");
    uint256 generationNum = tokenIdToTokenInfo[tokenId].generationNum;
    string memory cid = tokenMasterIdToTokenMaster[tokenIdToTokenInfo[tokenId].tokenMasterId].metadataCid;
    return string(abi.encodePacked(metadataStorageInfo.basePath, "/",cid, "/", metadataStorageInfo.baseFileName, generationNum.toString(), ".json"));
  }

  function getTokenURI(uint8 generationNum, uint32 tokenMasterId) public view returns (string memory) {
    string memory cid = tokenMasterIdToTokenMaster[tokenMasterId].metadataCid;
    return string(abi.encodePacked(metadataStorageInfo.basePath, "/", cid, "/", metadataStorageInfo.baseFileName, generationNum.toString(), ".json"));
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(IERC165, AccessControl, ERC721Enumerable) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function withdraw() public onlyPermitted(RECIPIENT_ROLE) {
    uint256 amount = pendingFee;
    require(amount > 0, "WataridoriNFT: no pending fee");
    pendingFee = 0;
    payable(msg.sender).transfer(amount);
  }

  function depositVwblFee() public payable {
    require(msg.value > 0, "WataridoriNFT: deposit amount must be greater than 0");
    vwblFeePool += msg.value;
  }

  function withdrawVwblFee() public onlyPermitted(OPERATOR_ROLE) {
    uint256 amount = vwblFeePool;
    require(amount > 0, "WataridoriNFT: no pending fee");
    vwblFeePool = 0;
    payable(msg.sender).transfer(amount);
  }
}