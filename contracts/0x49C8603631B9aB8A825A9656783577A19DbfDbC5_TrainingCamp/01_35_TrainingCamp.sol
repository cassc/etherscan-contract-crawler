// SPDX-License-Identifier: CC-BY-NC-ND-4.0
// By interacting with this smart contract you agree to the terms located at https://lilheroes.io/tos, https://lilheroes.io/privacy).

pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@gm2/blockchain/src/contracts/GM721Staking.sol';
import '@gm2/blockchain/src/contracts/GMAttributesController.sol';
import '@gm2/blockchain/src/contracts/GMTransferController.sol';
import './interfaces/ILilCollection.sol';
import { NFTBaseAttributes, NFTBaseAttributesRequest } from './structs/LilVillainsStructs.sol';
import './structs/TrainingCampStructs.sol';
import './errors/TrainingCampErrors.sol';
import './errors/CommonErrors.sol';

contract TrainingCamp is
  Initializable,
  PausableUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  GM721Staking,
  GMAttributesController,
  GMTransferController,
  ERC721Holder,
  EIP712Upgradeable
{
  using Strings for uint256;

  string _badgePropertyName;
  address _lilHeroesAddress;
  address _lilVillainsAddress;
  Badge[] _badges;
  mapping(address => mapping(uint256 => bool)) _legendariesByCollection;
  mapping(bytes32 => bool) _trainingPairs;
  uint256[128] __gap;

  event SetBaseAttributes(bytes signature);
  event BatchTraining(address whoTraining, uint256[2][] pairs, uint256 trainingAt);
  event BatchUnTraining(address whoTraining, uint256[2][] pairs);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string calldata domainName,
    string calldata version,
    address heroesAddress,
    address lilVillainsAddress,
    address proxyController,
    string calldata badgeName,
    Badge[] calldata badges
  ) public initializer {
    __Ownable_init();
    __Pausable_init();
    __EIP712_init(domainName, version);
    __GMTransferController_init(msg.sender, proxyController);
    __ReentrancyGuard_init();
    _lilHeroesAddress = heroesAddress;
    _lilVillainsAddress = lilVillainsAddress;
    _badgePropertyName = badgeName;
    _setBadges(badges);
  }

  modifier onlyTokenOwner(address collection, uint256 tokenId) {
    if (tokenId > 0 && IERC721(collection).ownerOf(tokenId) != msg.sender)
      revert CallerIsNotOwner(msg.sender, collection, tokenId);
    _;
  }

  function setBadges(Badge[] calldata values) external onlyOwner {
    _setBadges(values);
  }

  function setBadgePropertyName(string calldata value) external onlyOwner {
    _badgePropertyName = value;
  }

  function batchTrainingHeroesAndVillains(uint256[2][] calldata pairs) public whenNotPaused {
    for (uint256 i = 0; i < pairs.length; ) {
      _validateTrainingPair(pairs[i]);
      _trainHeroAndVillain(pairs[i][0], pairs[i][1], 0);
      _registerPair(pairs[i]);
      unchecked {
        i++;
      }
    }
    emit BatchTraining(msg.sender, pairs, block.timestamp);
  }

  function batchTrainingHeroesAndVillainsSigned(
    uint256[2][] calldata pairs,
    NFTBaseAttributesRequest calldata nFTBaseAttributesRequest,
    bytes calldata signature
  ) external whenNotPaused {
    batchTrainingHeroesAndVillains(pairs);
    require(
      ECDSAUpgradeable.recover(_hashTypedDataV4(_hashNFTBaseAttributesRequest(nFTBaseAttributesRequest)), signature) ==
        owner(),
      'Invalid signature'
    );
    ILilCollection(_lilVillainsAddress).setBaseAttributes(nFTBaseAttributesRequest.nFTsBaseAttributes);
    emit SetBaseAttributes(signature);
  }

  function batchUnTrainingHeroesAndVillains(uint256[2][] calldata pairs) external whenNotPaused {
    for (uint256 i = 0; i < pairs.length; ) {
      _validateUnTrainingPair(pairs[i]);
      _unTrainHeroeAndVillain(pairs[i][0], pairs[i][1]);
      _unRegisterPair(pairs[i]);
      unchecked {
        i++;
      }
    }
    emit BatchUnTraining(msg.sender, pairs);
  }

  //INFO: _badges variable needs to have a NONE badge as a first item
  function _getBadge(uint256 stakingValue) internal view returns (string memory badgeName) {
    uint256 trainingDays = stakingValue / 1 days;
    uint32 currentBadgeIdx;
    for (uint32 i; i < _badges.length; ) {
      if (trainingDays < _badges[i].requiredDays) break;
      currentBadgeIdx = i;
      unchecked {
        i++;
      }
    }
    return _badges[currentBadgeIdx].name;
  }

  function getDynamicAttributes(
    address collection,
    uint256 tokenId
  ) external view override returns (Attribute[] memory attributes) {
    StakedNFT storage nFTtrainingData = _stakedNFTs[collection][tokenId];
    uint256 currentTrainingValue = nFTtrainingData.totalStakedTime;
    if (_isInStaking(nFTtrainingData))
      currentTrainingValue += (block.timestamp - nFTtrainingData.lastStartedStakedTime);

    Attribute[] memory dynamicAttributes = new Attribute[](1);
    Attribute memory newAttribute = Attribute('', _badgePropertyName, _getBadge(currentTrainingValue));
    dynamicAttributes[0] = newAttribute;
    return dynamicAttributes;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(GMAttributesController, GMTransferController) returns (bool) {
    return GMAttributesController.supportsInterface(interfaceId) || GMTransferController.supportsInterface(interfaceId);
  }

  function setLegendaries(address collection, uint256[] calldata tokenIds) public onlyOwner {
    //INFO: this method only add new legendaries
    for (uint256 index = 0; index < tokenIds.length; index++) {
      _legendariesByCollection[collection][tokenIds[index]] = true;
    }
  }

  function _isLegendary(address collection, uint256 tokenId) internal view returns (bool) {
    return _legendariesByCollection[collection][tokenId];
  }

  function _validateTrainingPair(uint256[2] calldata pair) internal view {
    bool hasLegendaryHero = _isLegendary(_lilHeroesAddress, pair[0]);
    bool hasLegendaryVillain = _isLegendary(_lilVillainsAddress, pair[1]);
    if (
      (pair[0] == 0 && !hasLegendaryVillain) ||
      (pair[1] == 0 && !hasLegendaryHero) ||
      (pair[0] > 0 && hasLegendaryVillain) ||
      (pair[1] > 0 && hasLegendaryHero) ||
      _areTraining(pair)
    ) revert InvalidPair(pair[0], pair[1]);
  }

  function _validateUnTrainingPair(uint256[2] calldata pair) internal view {
    if (!_areTraining(pair) || (pair[0] == 0 && pair[1] == 0)) revert InvalidPair(pair[0], pair[1]);
  }

  function _trainHeroAndVillain(
    uint256 lilHeroeId,
    uint256 lilVillainId,
    uint256 offset
  )
    internal
    onlyTokenOwner(_lilHeroesAddress, lilHeroeId)
    onlyTokenOwner(_lilVillainsAddress, lilVillainId)
    nonReentrant
  {
    if (lilHeroeId > 0) {
      IERC721(_lilHeroesAddress).safeTransferFrom(msg.sender, address(this), lilHeroeId);
      _stake(_lilHeroesAddress, lilHeroeId, offset);
    }
    if (lilVillainId > 0) {
      _stake(_lilVillainsAddress, lilVillainId, offset);
      _blockTokenId(_lilVillainsAddress, lilVillainId);
    }
  }

  function _areTraining(uint256[2] calldata pair) internal view returns (bool) {
    return _trainingPairs[_getKeyForPair(pair)];
  }

  function _getKeyForPair(uint256[2] calldata pair) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(pair));
  }

  function _setBadges(Badge[] calldata values) internal {
    delete _badges;
    for (uint256 i = 0; i < values.length; ) {
      _badges.push(values[i]);
      unchecked {
        i++;
      }
    }
  }

  function _registerPair(uint256[2] calldata pair) internal {
    _trainingPairs[_getKeyForPair(pair)] = true;
  }

  function _unRegisterPair(uint256[2] calldata pair) internal {
    delete _trainingPairs[_getKeyForPair(pair)];
  }

  function _unTrainHeroeAndVillain(
    uint256 lilHeroeId,
    uint256 lilVillainId
  ) internal onlyTokenOwner(_lilVillainsAddress, lilVillainId) nonReentrant {
    if (lilHeroeId > 0) {
      if (_stakedNFTs[_lilHeroesAddress][lilHeroeId].whoStake != msg.sender) revert('Caller is not the token owner');
      IERC721(_lilHeroesAddress).safeTransferFrom(address(this), msg.sender, lilHeroeId);
      _unStake(_lilHeroesAddress, lilHeroeId);
    }
    if (lilVillainId > 0) {
      _unStake(_lilVillainsAddress, lilVillainId);
      _unBlockTokenId(_lilVillainsAddress, lilVillainId);
    }
  }

  function _hashNFTBaseAttributesRequest(
    NFTBaseAttributesRequest calldata nFTBaseAttributesRequest
  ) internal pure returns (bytes32) {
    bytes32[] memory nFTsBaseAttributesHashes = new bytes32[](nFTBaseAttributesRequest.nFTsBaseAttributes.length);
    for (uint256 i = 0; i < nFTBaseAttributesRequest.nFTsBaseAttributes.length; ) {
      nFTsBaseAttributesHashes[i] = _hashNFTBaseAttributes(nFTBaseAttributesRequest.nFTsBaseAttributes[i]);
      unchecked {
        i++;
      }
    }
    return
      keccak256(
        abi.encode(
          keccak256(
            abi.encodePacked(
              'NFTBaseAttributesRequest(NFTBaseAttributes[] nFTsBaseAttributes)',
              'NFTBaseAttributes(uint256 id,string[] values)'
            )
          ),
          keccak256(abi.encodePacked(nFTsBaseAttributesHashes))
        )
      );
  }

  function _hashStringArray(string[] calldata stringArray) internal pure returns (bytes32) {
    bytes32[] memory hashedItems = new bytes32[](stringArray.length);
    for (uint256 i = 0; i < stringArray.length; ) {
      hashedItems[i] = keccak256(bytes(stringArray[i]));
      unchecked {
        i++;
      }
    }
    return keccak256(abi.encodePacked(hashedItems));
  }

  function _hashNFTBaseAttributes(NFTBaseAttributes calldata nFTsBaseAttributes) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256('NFTBaseAttributes(uint256 id,string[] values)'),
          nFTsBaseAttributes.id,
          _hashStringArray(nFTsBaseAttributes.values)
        )
      );
  }
}