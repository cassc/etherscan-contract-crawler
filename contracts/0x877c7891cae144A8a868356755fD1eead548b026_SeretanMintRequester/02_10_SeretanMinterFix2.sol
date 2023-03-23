// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/PullPayment.sol";
import "./ISeretanMinter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./SeretanMintableFix.sol";

contract SeretanMinterFix2 is PullPayment, ISeretanMinter {
  mapping(address => Phase[]) private phaseList;

  mapping(address => uint256) private numberOfMinted;

  mapping(address => mapping(uint256 => mapping(address => uint256))) private numberOfMintedTo;

  mapping(address => uint256) private nextTokenId;

  function setPhaseList(
    address collection,
    Phase[] calldata phaseList_
  )
    public
  {
    require(msg.sender == collection || msg.sender == SeretanMintableFix(collection).owner());

    _setPhaseList(collection, phaseList_);
  }

  function _setPhaseList(
    address collection,
    Phase[] calldata phaseList_
  )
    internal
  {
    uint256 i;
    for (i = 0; i < phaseList[collection].length && i < phaseList_.length; i++) {
      phaseList[collection][i] = phaseList_[i];
    }
    for (uint256 j = i; j < phaseList_.length; j++) {
      phaseList[collection].push(phaseList_[j]);
    }
    for (uint256 j = phaseList[collection].length; j > phaseList_.length; j--) {
      phaseList[collection].pop();
    }
  }


  function mint(
    address collection,
    address to,
    uint256 currentPhaseNumber,
    bytes32[] calldata allowlistProof,
    uint256 maxNumberOfMintedToDest
  )
    public
    payable
  {
    require(0 <= currentPhaseNumber && currentPhaseNumber < phaseList[collection].length, "Invalid currentPhaseNumber");
    require(phaseList[collection][currentPhaseNumber].startTime <= block.timestamp, "Invalid currentPhaseNumber");
    require(currentPhaseNumber+1 == phaseList[collection].length || phaseList[collection][currentPhaseNumber+1].startTime > block.timestamp, "Invalid currentPhaseNumber");

    if (phaseList[collection][currentPhaseNumber].allowlistRoot != 0) {
      bytes32 allowlistLeaf = keccak256(bytes.concat(keccak256(abi.encode(to, maxNumberOfMintedToDest))));
      require(MerkleProof.verifyCalldata(allowlistProof, phaseList[collection][currentPhaseNumber].allowlistRoot, allowlistLeaf), "Not listed on allowlist");
    }

    require(phaseList[collection][currentPhaseNumber].maxNumberOfMinted > numberOfMinted[collection], "Unable to mint anymore");

    require(maxNumberOfMintedToDest > numberOfMintedTo[collection][currentPhaseNumber][to], "Unable to mint anymore");

    require(msg.value >= phaseList[collection][currentPhaseNumber].price, "Not enough money");

    _mint(collection, to, currentPhaseNumber);
  }

  function _mint(
    address collection,
    address to,
    uint256 currentPhaseNumber
  )
    internal
  {
    numberOfMinted[collection]++;

    numberOfMintedTo[collection][currentPhaseNumber][to]++;

    _asyncTransfer(SeretanMintableFix(collection).owner(), msg.value);

    uint256 tokenId = nextTokenId[collection];
    nextTokenId[collection]++;

    SeretanMintableFix(collection).safeMint(to, tokenId);
  }
}