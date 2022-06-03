//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKaratDistributor {
  event Claimed(address indexed account, uint256 indexed amount);
  event CampaignStopped(address indexed account);
  event BaseInfoURIUpdated(
    address indexed account,
    string indexed newBaseInfoURI
  );

  function baseInfoURI() external view returns (string memory);

  function frozenInfoURI() external view returns (string memory);

  function isActive() external view returns (bool);

  function owner() external view returns (address);

  function merkleRoot() external view returns (bytes32);

  function reach() external view returns (uint256);

  function claimedNum() external view returns (uint256);

  function claimed(address account) external view returns (bool);

  function stopCampaign() external;

  function updateBaseInfoURI(string calldata _baseInfoURI) external;

  function claim(
    address account,
    uint256 amount,
    bytes32[] memory merkleProof
  ) external;
}