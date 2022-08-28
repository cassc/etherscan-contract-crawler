// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./interfaces/ISignerVaultFactoryV1.sol";
import "./library/AddressArrayHelper.sol";
import "./library/TransferHelper.sol";
import "./proxy/SignerVaultProxy.sol";

contract SignerVaultFactoryV1 is ISignerVaultFactoryV1 {
  using AddressArrayHelper for address[];

  string constant private IDENTIFIER = "SignerVaultFactory";
  uint constant private VERSION = 1;

  address private immutable _deployer;
  Dependency[] _dependencies;

  address private _contractDeployer;
  address private _feeCollector;
  address private _vault;
  address private _signerVault;

  mapping(address => bool) _vaults;
  address[] private _vaultsArray;
  mapping(address => address[]) private _vaultsOf;

  bool private _locked;

  constructor() {
    _deployer = msg.sender;
    _dependencies.push(Dependency("ContractDeployer", 1));
    _dependencies.push(Dependency("FeeCollector", 1));
    _dependencies.push(Dependency("Vault", 1));
    _dependencies.push(Dependency("SignerVault", 1));
  }

  receive() external payable { TransferHelper.safeTransferETH(_feeCollector, msg.value); }
  fallback() external payable { TransferHelper.safeTransferETH(_feeCollector, msg.value); }

  modifier lock() {
    require(!_locked, "SignerVaultFactory: reentrancy");
    _locked = true;
    _;
    _locked = false;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, "SignerVaultFactory: caller must be the deployer");
    _;
  }

  function onlyVaults() private view {
    require(_vaults[msg.sender], "SignerVaultFactory: caller must be a vault");
  }

  function identifier() external pure returns (string memory) {
    return IDENTIFIER;
  }

  function version() external pure returns (uint) {
    return VERSION;
  }

  function dependencies() external view returns (Dependency[] memory) {
    return _dependencies;
  }

  function updateDependencies(Dependency[] calldata dependencies_) external onlyDeployer {
    delete _dependencies;
    for (uint index = 0; index < dependencies_.length; index++)
      _dependencies.push(dependencies_[index]);
  }

  function deployer() external view returns (address) {
    return _deployer;
  }

  function initialize(bytes calldata data) external onlyDeployer {
    address[] memory addresses = abi.decode(data, (address[]));
    address contractDeployer_ = addresses[0];
    address feeCollector_ = addresses[1];
    address vault_ = addresses[2];
    address signerVault_ = addresses[3];

    _contractDeployer = contractDeployer_;
    _feeCollector = feeCollector_;
    _vault = vault_;
    _signerVault = signerVault_;
  }

  function contractDeployer() external view returns (address) {
    return _contractDeployer;
  }

  function feeCollector() external view returns (address) {
    return _feeCollector;
  }

  function vault() external view returns (address) {
    return _vault;
  }

  function signerVault() external view returns (address) {
    return _signerVault;
  }

  function contains(address vault_) external view returns (bool) {
    return _vaults[vault_];
  }

  function vaults() external view returns (address[] memory) {
    return _vaultsArray;
  }

  function vaultsLength() external view returns (uint) {
    return _vaultsArray.length;
  }

  function getVault(uint index) external view returns (address) {
    require(index < _vaultsArray.length, "SignerVaultFactory: index out of range");
    return _vaultsArray[index];
  }

  function vaultsOf(address signer) external view returns (address[] memory) {
    return _vaultsOf[signer];
  }

  function vaultsLengthOf(address signer) external view returns (uint) {
    return _vaultsOf[signer].length;
  }

  function getVaultOf(address signer, uint index) external view returns (address) {
    require(index < _vaultsOf[signer].length, "SignerVaultFactory: index out of range");
    return _vaultsOf[signer][index];
  }

  function createVault(address signer) external lock returns (address) {
    require(msg.sender == signer || msg.sender == _vault, "SignerVaultFactory: caller is nor the signer neither the vault");
    bytes memory bytecode = type(SignerVaultProxy).creationCode;
    bytes32 salt = keccak256(abi.encodePacked("SignerVaultFactory", VERSION, "SignerVaultProxy", "Signer", signer, "Index", _vaultsOf[signer].length));

    address payable vault_;
    assembly {
      vault_ := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    bytes memory initializationData = abi.encodeWithSelector(0xed4fd7a0, address(this), signer);
    SignerVaultProxy(vault_).upgradeToAndCall(_signerVault, initializationData);

    _vaultsArray.push(vault_);
    _vaults[vault_] = true;
    _vaultsOf[signer].push(vault_);
    emit VaultCreated(signer, vault_, _vaultsArray.length, _vaultsOf[signer].length);

    return vault_;
  }

  function addLinking(address newSigner) external lock {
    onlyVaults();
    _vaultsOf[newSigner].push(msg.sender);
  }

  function removeLinking(address oldSigner) external lock {
    onlyVaults();
    _vaultsOf[oldSigner].remove(msg.sender);
  }
}