// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/IBNFT.sol";
import "./ILendPoolAddressesProvider.sol";
import "./ILendPoolLoan.sol";
import "./IStakeManager.sol";

import "./IUserFlashclaimRegistryV3.sol";

import "./AirdropFlashLoanReceiverV3.sol";

contract UserFlashclaimRegistryV3 is OwnableUpgradeable, ReentrancyGuardUpgradeable, IUserFlashclaimRegistryV3 {
  using ClonesUpgradeable for address;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  uint256 public constant VERSION = 3;

  address public bnftRegistry;
  mapping(address => address) public userReceiversV3;
  mapping(address => bool) public allReceiversV3;
  address public receiverV3Implemention;
  mapping(address => EnumerableSetUpgradeable.AddressSet) private _airdropContractWhiteList;
  address public addressProvider;
  address public stakeManager;

  event ReceiverV3ImplementionUpdated(address indexed receiverV3Implemention);
  event AirdropContractWhiteListChanged(address indexed nftAsset, address indexed airdropContract, bool flag);
  event ReceiverCreated(address indexed user, address indexed receiver, uint256 version);

  function initialize(
    address bnftRegistry_,
    address addressProvider_,
    address stakeManager_,
    address receiverV3Implemention_
  ) public initializer {
    __Ownable_init();

    bnftRegistry = bnftRegistry_;
    addressProvider = addressProvider_;
    stakeManager = stakeManager_;

    receiverV3Implemention = receiverV3Implemention_;
  }

  function setReceiverV3Implemention(address receiverV3Implemention_) public onlyOwner {
    receiverV3Implemention = receiverV3Implemention_;

    emit ReceiverV3ImplementionUpdated(receiverV3Implemention_);
  }

  function setAirdropContractWhiteList(
    address nftAsset,
    address airdropContract,
    bool flag
  ) public onlyOwner {
    if (flag) {
      _airdropContractWhiteList[nftAsset].add(airdropContract);
    } else {
      _airdropContractWhiteList[nftAsset].remove(airdropContract);
    }

    emit AirdropContractWhiteListChanged(nftAsset, airdropContract, flag);
  }

  /**
   * @dev Allows user create receiver.
   *
   * Requirements:
   *  - Receiver not exist for the `caller`.
   *
   */
  function createReceiver() public override nonReentrant {
    require(userReceiversV3[msg.sender] == address(0), "user already has a receiver");
    _createReceiver();
  }

  /**
   * @dev Allows user receiver to access the tokens within one transaction, as long as the tokens taken is returned.
   *
   * Requirements:
   *  - `nftTokenIds` must exist.
   *
   * @param nftAsset The address of the underlying asset
   * @param nftTokenIds token ids of the underlying asset
   * @param params Variadic packed params to pass to the receiver as extra information
   */
  function flashLoan(
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) public override nonReentrant {
    address lendPoolLoan = ILendPoolAddressesProvider(addressProvider).getLendPoolLoan();

    (address bnftProxy, ) = IBNFTRegistry(bnftRegistry).getBNFTAddresses(nftAsset);
    require(bnftProxy != address(0), "invalid nft asset");

    address receiverAddress = getUserReceiver(msg.sender);
    require(receiverAddress != address(0), "empty user receiver");

    // check airdrop contract MUST in the whitelist
    _checkValidAirdropContract(nftAsset, params);

    // check owner and set locking flag
    for (uint256 i = 0; i < nftTokenIds.length; i++) {
      require(IERC721Upgradeable(bnftProxy).ownerOf(nftTokenIds[i]) == msg.sender, "invalid token owner");

      address minterAddr = IBNFT(bnftProxy).minterOf(nftTokenIds[i]);
      address[] memory lockers = IBNFT(bnftProxy).getFlashLoanLocked(nftTokenIds[i], minterAddr);
      require(lockers.length > 0, "flash loan not locked");

      if (minterAddr == lendPoolLoan) {
        ILendPoolLoan(lendPoolLoan).setFlashLoanLocking(nftAsset, nftTokenIds[i], true);
      } else if (minterAddr == stakeManager) {
        IStakeManager(stakeManager).setFlashLoanLocking(nftAsset, nftTokenIds[i], true);
      }
    }

    // doing flash loan
    IBNFT(bnftProxy).flashLoan(receiverAddress, nftTokenIds, params);

    // clear locking flag
    for (uint256 i = 0; i < nftTokenIds.length; i++) {
      address minterAddr = IBNFT(bnftProxy).minterOf(nftTokenIds[i]);
      if (minterAddr == lendPoolLoan) {
        ILendPoolLoan(lendPoolLoan).setFlashLoanLocking(nftAsset, nftTokenIds[i], false);
      } else if (minterAddr == stakeManager) {
        IStakeManager(stakeManager).setFlashLoanLocking(nftAsset, nftTokenIds[i], false);
      }
    }
  }

  /**
   * @dev Query user receiver, only compatable with v2.
   */
  function userReceivers(address user) public view returns (address) {
    return getUserReceiver(user);
  }

  /**
   * @dev Query user receiver, current in used.
   */
  function getUserReceiver(address user) public view override returns (address) {
    return userReceiversV3[user];
  }

  /**
   * @dev Query user receiver, latest version.
   */
  function getUserReceiverLatestVersion(address user) public view override returns (uint256, address) {
    address receiverV3 = userReceiversV3[user];
    if (receiverV3 != address(0)) {
      return (VERSION, receiverV3);
    }

    return (0, address(0));
  }

  /**
   * @dev Query user receiver, all versions.
   */
  function getUserReceiverAllVersions(address user) public view override returns (uint256[] memory, address[] memory) {
    uint256 length;
    uint256[3] memory versions;
    address[3] memory addresses;

    address receiverV3 = userReceiversV3[user];
    if (receiverV3 != address(0)) {
      versions[length] = VERSION;
      addresses[length] = receiverV3;
      length++;
    }

    uint256[] memory retVersions = new uint256[](length);
    address[] memory retAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      retVersions[i] = versions[i];
      retAddresses[i] = addresses[i];
    }

    return (retVersions, retAddresses);
  }

  function isAirdropContractInWhiteList(address nftAsset, address airdropContract) public view returns (bool) {
    return _airdropContractWhiteList[nftAsset].contains(airdropContract);
  }

  function _createReceiver() internal {
    address payable receiverV3 = payable(receiverV3Implemention.clone());
    AirdropFlashLoanReceiverV3(receiverV3).initialize(msg.sender, bnftRegistry);

    userReceiversV3[msg.sender] = address(receiverV3);
    allReceiversV3[receiverV3] = true;

    emit ReceiverCreated(msg.sender, address(receiverV3), VERSION);
  }

  function _checkValidAirdropContract(address nftAsset, bytes calldata params) internal view {
    // decode parameters
    (, , , address airdropContract, , ) = abi.decode(
      params,
      (uint256[], address[], uint256[], address, bytes, uint256)
    );
    require(isAirdropContractInWhiteList(nftAsset, airdropContract) == true, "invalid airdrop contract");
  }
}