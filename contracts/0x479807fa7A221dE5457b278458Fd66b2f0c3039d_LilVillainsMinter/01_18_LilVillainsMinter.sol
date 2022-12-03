// SPDX-License-Identifier: CC-BY-NC-ND-4.0
// By interacting with this smart contract you agree to the terms located at https://lilheroes.io/tos, https://lilheroes.io/privacy).

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@gm2/blockchain/src/contracts/GMVRFConsumer.sol';
import './interfaces/ILilCollection.sol';
import './LilVillainsBaseAttributes.sol';
import { Stage } from './structs/LilVillainsStructs.sol';

contract LilVillainsMinter is GMVRFConsumer, LilVillainsBaseAttributes, Pausable {
  string private constant SIGNING_DOMAIN = 'NFTClaimedAmount';
  string private constant SIGNATURE_VERSION = '1';
  uint32 private constant TOTAL_SUPPLY = 7777;
  bytes32 private constant GIVEAWAY = keccak256('giveaway');
  bytes32 private constant PRESALE = keccak256('presale');
  bytes32 private constant OPENSALE = keccak256('opensale');

  // INFO: Stage variables
  string private currentStageName;
  mapping(string => Stage) private stages;
  uint32 private currentSupply = 0;

  constructor(
    uint64 chainLinkSubsId_,
    address vrfCoordinator,
    bytes32 chainLinkKeyHash_
  )
    LilVillainsBaseAttributes(SIGNING_DOMAIN, SIGNATURE_VERSION)
    GMVRFConsumer(chainLinkSubsId_, vrfCoordinator, chainLinkKeyHash_)
  {}

  event BatchMintExecuted(address owner, uint256[] tokenIds, string stage);

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setStage(
    string calldata name,
    uint256 price,
    uint32 maxAmount,
    bytes32 merkleRoot
  ) external onlyOwner onlySeedNumberIsSet {
    require(_lilVillainsAddress != address(0), 'Minting collection was not set'); //Collection required
    require(!isEmpty(name), 'Invalid Stage name');

    Stage storage newStage = stages[name];
    newStage.name = name;
    newStage.price = price;
    newStage.maxAmount = maxAmount;
    newStage.root = merkleRoot;

    bytes32 nameInBytes32 = keccak256(bytes(name));
    if (GIVEAWAY == nameInBytes32) newStage.beforeMint = beforeMintGiveaway;
    else if (PRESALE == nameInBytes32) newStage.beforeMint = beforeMintPresale;
    else if (OPENSALE == nameInBytes32) newStage.beforeMint = beforeMintOpensale;
    else newStage.beforeMint = defaultBeforeMint;

    currentStageName = name;
  }

  function setLilCollection(address lilVillainsAddress) external onlyOwner {
    require(
      IERC165(lilVillainsAddress).supportsInterface(type(ILilCollection).interfaceId),
      'Address not supports batch mint'
    );
    _lilVillainsAddress = lilVillainsAddress;
  }

  function mint(
    uint32 selectedAmountToMint,
    uint32 signedAmount,
    bytes32[] calldata proofs,
    bytes calldata signature
  ) external payable whenNotPaused {
    require(!isEmpty(currentStageName), 'Stage not set'); //Stage required => collection required + _chainLinkSeedNumber required
    require(selectedAmountToMint + currentSupply <= TOTAL_SUPPLY, 'Request minted amount unavailable');

    Stage storage stage = getCurrentStage();
    require((stage.price * selectedAmountToMint) == msg.value, 'Invalid payment amount');

    stage.beforeMint(selectedAmountToMint, signedAmount, proofs, signature);

    updateMintedAmountOnStage(stage, selectedAmountToMint);

    uint256[] memory tokenIDsToMint = getTokenIds(selectedAmountToMint);

    ILilCollection(_lilVillainsAddress).batchMint(msg.sender, tokenIDsToMint);

    emit BatchMintExecuted(msg.sender, tokenIDsToMint, stage.name);
  }

  function defaultBeforeMint(
    uint32,
    uint32,
    bytes32[] calldata,
    bytes calldata
  ) internal pure {
    revert('beforeMint must be set');
  }

  function beforeMintGiveaway(
    uint32 selectedAmountToMint,
    uint32 signedAmount,
    bytes32[] calldata proofs,
    bytes calldata signature
  ) internal view {
    Stage storage stage = getCurrentStage();
    require(ECDSA.recover(hashMintingSignature(signedAmount), signature) == owner(), 'Invalid signature');
    uint32 remainingAmount = signedAmount - stage.minters[msg.sender];
    require(
      isLessThanOrEqual(selectedAmountToMint, remainingAmount) &&
        isLessThanOrEqual(selectedAmountToMint, stage.maxAmount),
      'Invalid request amount to mint'
    );
    validateIfSenderIsInWhitelist(stage, proofs);
  }

  function beforeMintPresale(
    uint32 selectedAmountToMint,
    uint32,
    bytes32[] calldata proofs,
    bytes calldata
  ) internal {
    Stage storage stage = getCurrentStage();
    validateRemainingAmount(stage, selectedAmountToMint);
    validateIfSenderIsInWhitelist(stage, proofs);
    payable(owner()).transfer(msg.value);
  }

  function beforeMintOpensale(
    uint32 selectedAmountToMint,
    uint32,
    bytes32[] calldata,
    bytes calldata
  ) internal {
    Stage storage stage = getCurrentStage();
    validateRemainingAmount(stage, selectedAmountToMint);
    payable(owner()).transfer(msg.value);
  }

  function isLessThanOrEqual(uint32 a, uint32 b) private pure returns (bool) {
    return a <= b;
  }

  function getTokenIds(uint32 size) private returns (uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](size);
    for (uint32 i = 0; i < size; i = increment(i)) {
      tokenIds[i] = (((97 * (i + currentSupply)) + _chainLinkSeedNumber) % TOTAL_SUPPLY) + 1;
    }
    currentSupply = currentSupply + size;
    return tokenIds;
  }

  function isEmpty(string memory value) private pure returns (bool) {
    return bytes(value).length == 0;
  }

  function getCurrentStage() private view returns (Stage storage) {
    return stages[currentStageName];
  }

  function increment(uint32 i) private pure returns (uint32) {
    return i = i + 1;
  }

  function hashMintingSignature(uint32 amount) private view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(abi.encode(keccak256('NFTClaimedAmount(uint32 amount,address holder)'), amount, msg.sender))
      );
  }

  function validateIfSenderIsInWhitelist(Stage storage stage, bytes32[] calldata proofs) private view {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(proofs, stage.root, leaf), 'Address is not in whitelist');
  }

  function validateRemainingAmount(Stage storage stage, uint32 selectedAmountToMint) private view {
    uint32 remainingAmount = stage.maxAmount - stage.minters[msg.sender];
    require(isLessThanOrEqual(selectedAmountToMint, remainingAmount), 'Invalid request amount to mint');
  }

  function updateMintedAmountOnStage(Stage storage stage, uint32 selectedAmountToMint) private {
    stage.minters[msg.sender] = stage.minters[msg.sender] + selectedAmountToMint;
  }
}