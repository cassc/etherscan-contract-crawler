// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "./interfaces/ITaggr.sol";
import "./interfaces/INftDistributor.sol";
import "./interfaces/ICustomerSettings.sol";
import "./lib/BlackholePrevention.sol";


contract CustomerSettings is
  ICustomerSettings,
  Initializable,
  AccessControlEnumerableUpgradeable,
  BlackholePrevention
{
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  ITaggr internal _taggr;
  INftDistributor internal _nftDistributor;

  mapping (bytes32 => uint256) internal _projectPurchaseFee;
  mapping (bytes32 => address) internal _projectPurchaseFeeToken;
  mapping (bytes32 => mapping(address => uint256)) internal _projectFreeMintAccounts;

  /***********************************|
  |          Initialization           |
  |__________________________________*/

  function initialize(address initiator) public initializer {
    __AccessControlEnumerable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(OWNER_ROLE, _msgSender());

    emit ContractReady(initiator);
  }


  /***********************************|
  |         Public Functions          |
  |__________________________________*/

  function getProjectPurchaseFee(string memory projectId) external view override returns (uint256) {
    return _projectPurchaseFee[_hash(projectId)];
  }

  function getProjectPurchaseFeeToken(string memory projectId) external view override returns (address) {
    return _projectPurchaseFeeToken[_hash(projectId)];
  }

  function getProjectFreeMintAmount(string memory projectId, address freeMinter) external view override returns (uint256) {
    return _projectFreeMintAccounts[_hash(projectId)][freeMinter];
  }


  /***********************************|
  |       Permissioned Controls       |
  |__________________________________*/

  function setProjectPurchaseFee(string memory projectId, address feeToken, uint256 fee) external onlyProjectManagerOrOwner(projectId) {
    require(feeToken != address(0), "CS:E-103");
    bytes32 projectHash = _hash(projectId);
    _projectPurchaseFeeToken[projectHash] = feeToken;
    _projectPurchaseFee[projectHash] = fee;
    emit ProjectPurchaseFeeSet(projectId, feeToken, fee);
  }

  function setProjectFreeMint(string memory projectId, address freeMinter, uint256 freeMintAmount) external onlyProjectManager(projectId) {
    require(freeMinter != address(0), "CS:E-103");
    _projectFreeMintAccounts[_hash(projectId)][freeMinter] = freeMintAmount;
    emit ProjectFreeMinterSet(projectId, freeMinter, freeMintAmount);
  }

  function decrementProjectFreeMint(string memory projectId, address freeMinter, uint256 amount) external override onlyDistributor {
    require(freeMinter != address(0), "CS:E-103");
    _projectFreeMintAccounts[_hash(projectId)][freeMinter] -= amount;
  }

  function setTaggr(address taggr) external onlyRole(OWNER_ROLE) {
    require(taggr != address(0), "CS:E-103");
    _taggr = ITaggr(taggr);
  }

  function setNftDistributor(address nftDistributor) external onlyRole(OWNER_ROLE) {
    require(nftDistributor != address(0), "CS:E-103");
    _nftDistributor = INftDistributor(nftDistributor);
  }


  /***********************************|
  |            Only Owner             |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyRole(OWNER_ROLE) {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }

  function withdrawERC1155(address payable receiver, address tokenAddress, uint256 tokenId, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
  }


  /***********************************|
  |         Private/Internal          |
  |__________________________________*/

  function _hash(string memory data) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(data));
  }


  modifier onlyProjectManager(string memory projectId) {
    require(_taggr.isProjectManager(projectId, _msgSender()), "CS:E-102");
    _;
  }

  modifier onlyProjectManagerOrOwner(string memory projectId) {
    require(hasRole(OWNER_ROLE, _msgSender()) || _taggr.isProjectManager(projectId, _msgSender()), "CS:E-102");
    _;
  }

  modifier onlyDistributor() {
    require(_msgSender() == address(_nftDistributor), "CS:E-102");
    _;
  }
}