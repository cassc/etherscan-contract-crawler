// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/DeployLib.sol";
import "../utils/SignatureLib.sol";

interface IChocoFactory {
  event Deployed(bytes32 indexed deployHash);

  function deploy(DeployLib.DeployData memory deployData, SignatureLib.SignatureData memory signatureData) external;

  function predict(DeployLib.DeployData memory deployData) external view returns (address);

  function isDeployed(address contractAddress) external view returns (bool);
}