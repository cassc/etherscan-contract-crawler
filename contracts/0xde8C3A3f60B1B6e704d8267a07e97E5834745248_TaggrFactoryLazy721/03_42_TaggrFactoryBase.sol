// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "../interfaces/ITaggrNft.sol";


contract TaggrFactoryBase is AccessControlEnumerableUpgradeable {
  using ClonesUpgradeable for address;

  event ContractReady(address indexed intializer);
  event DeployerSet(address indexed deployer);

  // Deployer should be set to Taggr.sol contract instance
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

  // Template Contract for creating NFT Contracts
  address internal _nftTemplate;

  function _initialize(address initiator) internal {
    __AccessControlEnumerable_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(DEPLOYER_ROLE, _msgSender());
    emit ContractReady(initiator);
  }

  function setDeployer(address deployer) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setupRole(DEPLOYER_ROLE, deployer);
    emit DeployerSet(deployer);
  }

  function deploy(
    address owner,
    address distributor,
    string memory name,
    string memory symbol,
    string memory baseTokenUri,
    uint256 maxSupply,
    uint96 royaltiesPct
  )
    external
    onlyRole(DEPLOYER_ROLE)
    returns (address)
  {
    address newContract = _nftTemplate.clone();
    ITaggrNft(newContract).initialize(owner, distributor, name, symbol, baseTokenUri, maxSupply, royaltiesPct);
    return newContract;
  }
}