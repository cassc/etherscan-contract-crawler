// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "../interfaces/IChocoFactory.sol";

import "../utils/DeployLib.sol";
import "../utils/SecurityLib.sol";

import "./ChocoFactoryBase.sol";

contract ChocoFactory is IChocoFactory, ChocoFactoryBase {
  using AddressUpgradeable for address;
  using ClonesUpgradeable for address;

  constructor(string memory name, string memory version) {
    initialize(name, version);
  }

  function deploy(DeployLib.DeployData memory deployData, SignatureLib.SignatureData memory signatureData)
    external
    override
  {
    bytes32 deployHash = DeployLib.hashStruct(deployData);
    (bool isSignatureValid, string memory signatureErrorMessage) = _validateTx(
      deployData.deployer,
      deployHash,
      signatureData
    );
    require(isSignatureValid, signatureErrorMessage);
    _deploy(deployHash, deployData);
  }

  function predict(DeployLib.DeployData memory deployData) external view override returns (address) {
    bytes32 deployHash = DeployLib.hashStruct(deployData);
    return deployData.implementation.predictDeterministicAddress(deployHash, address(this));
  }

  function isDeployed(address contractAddress) external view override returns (bool) {
    return contractAddress.isContract();
  }

  function _deploy(bytes32 deployHash, DeployLib.DeployData memory deployData) internal {
    (bool isValid, string memory errorMessage) = _validate(deployData);
    require(isValid, errorMessage);
    _revokeHash(deployHash);
    address deployed = deployData.implementation.cloneDeterministic(deployHash);
    for (uint256 i = 0; i < deployData.data.length; i++) {
      AddressUpgradeable.functionCall(deployed, deployData.data[i]);
    }
    emit Deployed(deployHash);
  }

  function _validate(DeployLib.DeployData memory deployData) internal view returns (bool, string memory) {
    (bool isSecurityDataValid, string memory securityDataErrorMessage) = SecurityLib.validate(deployData.securityData);
    if (!isSecurityDataValid) {
      return (false, securityDataErrorMessage);
    }
    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}