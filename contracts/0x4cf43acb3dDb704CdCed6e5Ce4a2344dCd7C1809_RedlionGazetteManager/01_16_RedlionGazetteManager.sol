// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../libraries/interfaces/IRedlionGazette.sol';
import '../libraries/interfaces/IRedlionLegendaryGazette.sol';
import '../libraries/interfaces/IRedlionArtdrops.sol';
import '../libraries/interfaces/IRedlionGazetteManager.sol';
import '../libraries/interfaces/ISubscriptionsManager.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '../libraries/interfaces/ISubscriptions.sol';

/**
 * Proxy contract to manage gazettes publishing, minting and claiming.
 * @title Redlion Gazette Manager
 * @author Gui "Qruz" Rodrigues (0xQruz)
 * @dev This contract is upgradeable and the logic can be changed at any given time.
 */
contract RedlionGazetteManager is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable,
  IRedlionGazetteManager
{
  using Strings for uint256;
  using ECDSA for bytes32;

  address SUBS; // Redlion Subscriptions Manager
  address RLGA; // Redlion Gazette
  address RLLGA; // Redlion Legendary Gazette
  address AD; // Redlion ArtDrop
  address REDA; // Red subscriptions address
  address COURIER; // COURIER ADDRESS
  address SIGNER; // SIGNER ADDRESS

  mapping(uint => mapping(bytes => bool)) CLAIMS;
  mapping(uint => mapping(bytes => bool)) DELIVERIES;

  uint public GAZETTE_PRICE;

  function initialize(
    address _SUBS,
    address _RLGA,
    address _RLLGA,
    address _AD,
    address _SIGNER,
    address _REDA,
    address _COURIER
  ) public initializer {
    SUBS = _SUBS;
    RLGA = _RLGA;
    AD = _AD;
    RLLGA = _RLLGA;
    SIGNER = _SIGNER;
    REDA = _REDA;
    COURIER = _COURIER;
    GAZETTE_PRICE = 2500;
    __Ownable_init();
    __Pausable_init();
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function launchIssue(
    uint256 _issue,
    uint256 _saleSize,
    string memory _uri,
    uint256 _reserve,
    string memory _legendaryUri
  ) external onlyOwner {
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    IRedlionLegendaryGazette RLLG = IRedlionLegendaryGazette(RLLGA);
    RLG.launchIssue(_issue, _saleSize, _uri);
    RLLG.launchAuction(_issue, _reserve, _legendaryUri);
  }

  function mint(
    uint256 _issue,
    uint256 _amount,
    uint256 timestamp,
    bytes memory _signature
  ) external payable whenNotPaused {
    require(block.timestamp < timestamp + 5 minutes, 'INVALID_TIMESTAMP');
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        address(this),
        _issue,
        _amount,
        msg.value,
        timestamp
      )
    );
    require(_validSignature(_signature, inputHash), 'BAD_SIGNATURE');
    IRedlionGazette RLG = getRLG();
    uint[] memory mintedIds = RLG.mint(msg.sender, _issue, _amount, false);
    for (uint i = 0; i < mintedIds.length; i++) {
      emit IssueMinted(_issue, mintedIds[i], msg.sender);
    }
  }

  function claim(uint256 _issue) external whenNotPaused {
    require(canClaim(_issue, msg.sender), 'CANNOT_CLAIM');
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      msg.sender
    );
    CLAIMS[_issue][subInfo.subId] = true;
    uint[] memory mintedIds = RLG.mint(msg.sender, _issue, 1, true);

    for (uint i = 0; i < mintedIds.length; i++) {
      emit IssueClaimed(_issue, mintedIds[i], msg.sender);
    }
  }

  function claimArtdrop(uint[] calldata _tokenIds) external whenNotPaused {
    IRedlionArtdrops ADC = IRedlionArtdrops(AD);
    for (uint i = 0; i < _tokenIds.length; i++) {
      uint tId = _tokenIds[i];
      ADC.mint(msg.sender, tId);
      emit ArtdropClaimed(getRLG().tokenToIssue(tId), tId, msg.sender);
    }
  }

  function deliverIssues() external onlyCourier returns (DeliveryState memory)  {
    ISubscriptions REDC = ISubscriptions(REDA);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    uint delivered = 0;
    uint total = 0;
    uint received = 0;
    address[] memory subsList = REDC.subscribers();

    for (uint i = 0; i < subsList.length; i++) {
      address target = address(subsList[i]);
      if (target != address(0)) {
        bytes memory subId = REDC.subscriptionId(target);
        uint[] memory issueList = RLG.issueList();
        for (uint z = 0; z < issueList.length; z++) {
          uint issueId = issueList[z];
          if (!DELIVERIES[issueId][subId]) {
            if (delivered < 10) {
              DELIVERIES[issueId][subId] = true;
              delivered++;
              uint[] memory mintedIds = RLG.mint(target, issueId, 1, true);

              for (uint y = 0; y < mintedIds.length; y++) {
                emit IssueDelivered(issueId, mintedIds[y], target);
              }
            }
          } else {
            received++;
          }
          total++;
        }
      }
    }

    return DeliveryState(delivered, received, total);
  }

  /*///////////////////////////////////////////////////////////////
                             UTILITY
  ///////////////////////////////////////////////////////////////*/

  function canClaim(
    uint256 _issue,
    address _target
  ) public view returns (bool) {
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      _target
    );

    if (!subInfo.subscribed) return false;

    if (subInfo.subType == ISubscriptionsManager.SubType.SUPER) return false;

    if (CLAIMS[_issue][subInfo.subId]) return false;

    if (!RLG.isIssueLaunched(_issue)) return false;

    return RLG.timeToIssue(subInfo.timestamp).issue <= _issue;
  }

  function canDeliver(uint _issue, address _target) public view returns (bool) {
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      _target
    );
    if (!RLG.isIssueLaunched(_issue)) return false;

    if (!subInfo.subscribed) return false;

    if (subInfo.subType != ISubscriptionsManager.SubType.SUPER) return false;

    return !DELIVERIES[_issue][subInfo.subId];
  }

  function claimableIssues(
    address _target
  ) public view returns (bool[] memory) {
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      _target
    );
    IRedlionGazette.Issue memory currentIssue = RLG.timeToIssue(
      block.timestamp
    );

    bool[] memory claimable = new bool[](currentIssue.issue + 1);

    if (!subInfo.subscribed) return claimable;

    for (uint i = currentIssue.issue; i > 120; i--) {
      bool claimability = canClaim(i, _target);
      claimable[i] = claimability;
    }

    return claimable;
  }

  function deliverableIssues(
    address _target
  ) public view returns (bool[] memory) {
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      _target
    );
    IRedlionGazette.Issue memory currentIssue = RLG.timeToIssue(
      block.timestamp
    );

    bool[] memory deliverable = new bool[](currentIssue.issue + 1);

    if (!subInfo.subscribed) return deliverable;

    for (uint i = currentIssue.issue; i > 120; i--) {
      bool claimability = canDeliver(i, _target);
      deliverable[i] = claimability;
    }

    return deliverable;
  }

  /*///////////////////////////////////////////////////////////////
                              OWNER
  ///////////////////////////////////////////////////////////////*/

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /*///////////////////////////////////////////////////////////////
                             SETTERS
  ///////////////////////////////////////////////////////////////*/

  function setSUBS(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, SUBS);
    SUBS = _address;
  }

  function setPrice(uint _price) external onlyOwner {
    GAZETTE_PRICE = _price;
  }

  function setRLGA(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, RLGA);
    RLGA = _address;
  }

  function setRLLGA(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, RLLGA);
    RLLGA = _address;
  }

  function setREDA(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, REDA);
    REDA = _address;
  }

  function setCOURIER(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, COURIER);
    COURIER = _address;
  }

  function setSIGNER(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, SIGNER);
    SIGNER = _address;
  }

  function setAD(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, AD);
    AD = _address;
  }

  function getRLG()
    public
    view
    override(IRedlionGazetteManager)
    returns (IRedlionGazette)
  {
    return IRedlionGazette(RLGA);
  }

  function getRLLG()
    public
    view
    override(IRedlionGazetteManager)
    returns (IRedlionLegendaryGazette)
  {
    return IRedlionLegendaryGazette(RLLGA);
  }

  /*///////////////////////////////////////////////////////////////
                             INTERNALS
  ///////////////////////////////////////////////////////////////*/

  modifier onlyCourier() {
    require(msg.sender == COURIER, 'CALLER_NOT_COURIER');
    _;
  }

  function _requireValidSetterAddress(
    address _address,
    address variable
  ) internal pure {
    require(_address != address(0), 'ZERO_ADDRESS_NOT_ALLOWED');
    require(_address != variable, 'ADDRESS_UNCHANGED');
  }

  function _validSignature(
    bytes memory signature,
    bytes32 msgHash
  ) internal view returns (bool) {
    return msgHash.toEthSignedMessageHash().recover(signature) == SIGNER;
  }
}