// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//                                           ......
//                                 .';codxOO00KKKK00Okxdoc;'.
//                             .,lkKNWMMMMMMMMMMMMMMMMMMMMWNKkl,.
//                           ,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o'
//                         'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx'
//                       .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.
//                      .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.
//                      cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc
//                     .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.
//                     :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//                     lWMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXNWMMMNl
//                     'lolc:;,,,:lxKWMMMMMMMMMMMMMMMMMMMW0d:'....',:lol'
//                                  .:xXWMMMMMMMMMMMMMMXx;.
//                                     .oKMMMMMMMMMMMNx'
//                                       'xNMMMMMMMMXl.
//                       :Od:'.        ..;dXMMMMWMMMXd;..        .'cdx,
//                       oWMWNK0kxxxxkOKNWMMMXdccdXMMMWNKOkxxxxk0KNWMX:
//                       oWMMMMMMMMMMMMMMMMWk,    ,kWMMMMMMMMMMMMMMMMX;
//                       ;KMMMMMMMMMMMMMMMNd.      .dNMMMMMMMMMMMMMMMO.
//                        'ok0KXNNNWWMMMMMK,        ,KMMMMMWWNNNNXKOd'
//                           ...''',dNMMMMNd'      'dNMMMMNd,'''...
//                                  :NMMMMMWXkollokXWMMMMMN:
//                                  cNMMMMMMMMMMMMMMMMMMMMNc
//                                  lNMNOkXMMMNXNWMMWKkKWMNl
//                                  oWM0'.dWMNo,;kMMX: :XMWo
//                                  oWMx. lWMX; .oWM0' '0MWo
//                                  'cl,  ;0Xk.  :0Xd.  ,ll,
//                                         ...    ...
//        ________                 __  .__   __________.__                        __
//        \______ \   ____ _____ _/  |_|  |__\______   \  | _____    ____   _____/  |_
//         |    |  \_/ __ \\__  \\   __\  |  \|     ___/  | \__  \  /    \_/ __ \   __\
//         |    `   \  ___/ / __ \|  | |   Y  \    |   |  |__/ __ \|   |  \  ___/|  |
//        /_______  /\___  >____  /__| |___|  /____|   |____(____  /___|  /\___  >__|
//                \/     \/     \/          \/                   \/     \/     \/
//

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

error StakingPaused();
error CollectionNotSupported();
error StakingInvalidSignature();
error StakingInvalidTokenOwner();
error StakingNotStaked();
error InsufficientSoulz();
error TransferPaused();
error TransferToZeroAddress();

contract DeathPlanet is AccessControl {
  using EnumerableSet for EnumerableSet.UintSet;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
  bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

  uint256 public constant YIELD_INTERVAL = 24 hours;

  struct TokenOwnership {
    address addr;
    uint64 yieldRate;
  }

  struct EarthlingData {
    uint64 accumulatedSoulz;
    uint64 lastAccumulatedTimestamp;
    uint64 spentSoulz;
    uint64 yieldRate;
  }

  bool public stakingActive;
  bool public transferActive;

  mapping(address => uint256) internal _collections;
  mapping(address => mapping(uint256 => TokenOwnership)) internal _ownerships;
  mapping(address => EarthlingData) internal _earthlingData;

  event Staked(address indexed account, address indexed contractAddress, uint256 indexed tokenId);
  event Unstaked(address indexed account, address indexed contractAddress, uint256 indexed tokenId);
  event SoulzSpent(address indexed account, uint256 amount);
  event SoulzTransfered(address indexed from, address indexed to, uint256 amount);
  event SoulzMinted(address indexed to, uint256 amount);

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function ownerOf(address contractAddress, uint256 tokenId) public view returns (address) {
    return _ownerships[contractAddress][tokenId].addr;
  }

  function soulzBalanceOf(address owner) public view returns (uint256) {
    EarthlingData memory earthling = _earthlingData[owner];
    return
      uint256(earthling.accumulatedSoulz) +
      _unaccumulatedSoulz(earthling.lastAccumulatedTimestamp, earthling.yieldRate) -
      earthling.spentSoulz;
  }

  function soulzYieldOf(address owner) public view returns (uint256) {
    return _earthlingData[owner].yieldRate;
  }

  function soulzSpentOf(address owner) public view returns (uint256) {
    return _earthlingData[owner].spentSoulz;
  }

  function earthlingDataOf(address owner) public view returns (EarthlingData memory) {
    return _earthlingData[owner];
  }

  function tokenSoulzYieldOf(address contractAddress, uint256 tokenId) public view returns (uint256) {
    uint256 tokenYield = _ownerships[contractAddress][tokenId].yieldRate;
    if (tokenYield == 0) {
      tokenYield = _collections[contractAddress];
    }
    return tokenYield;
  }

  function stake(
    address contractAddress,
    uint256[] calldata tokenIds,
    uint256[] calldata tokenYields,
    bytes calldata signature
  ) external {
    if (!stakingActive) revert StakingPaused();

    uint64 collectionRate = uint64(_collections[contractAddress]);
    if (collectionRate == 0) revert CollectionNotSupported();

    if (tokenYields.length > 0) {
      if (!_validateSignature(signature, contractAddress, tokenIds, tokenYields)) revert StakingInvalidSignature();
    }

    mapping(uint256 => TokenOwnership) storage ownership = _ownerships[contractAddress];
    EarthlingData storage earthling = _earthlingData[_msgSender()];

    uint64 newYield = earthling.yieldRate;

    for (uint256 i; i < tokenIds.length; i++) {
      if (IERC721(contractAddress).ownerOf(tokenIds[i]) != _msgSender()) revert StakingInvalidTokenOwner();
      IERC721(contractAddress).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

      ownership[tokenIds[i]].addr = _msgSender();
      if (tokenYields.length > i) {
        ownership[tokenIds[i]].yieldRate = uint32(tokenYields[i]);
        newYield += uint64(tokenYields[i]);
      } else {
        ownership[tokenIds[i]].yieldRate = collectionRate;
        newYield += collectionRate;
      }

      emit Staked(_msgSender(), contractAddress, tokenIds[i]);
    }

    earthling.accumulatedSoulz += uint64(_unaccumulatedSoulz(earthling.lastAccumulatedTimestamp, earthling.yieldRate));
    earthling.lastAccumulatedTimestamp = uint64(block.timestamp);
    earthling.yieldRate = newYield;
  }

  function unstake(address contractAddress, uint256[] calldata tokenIds) external {
    EarthlingData storage earthling = _earthlingData[_msgSender()];
    uint64 newYield = earthling.yieldRate;

    for (uint256 i; i < tokenIds.length; i++) {
      if (IERC721(contractAddress).ownerOf(tokenIds[i]) != address(this)) revert StakingNotStaked();
      if (_ownerships[contractAddress][tokenIds[i]].addr != _msgSender()) revert StakingInvalidTokenOwner();

      IERC721(contractAddress).safeTransferFrom(address(this), _msgSender(), tokenIds[i]);

      _ownerships[contractAddress][tokenIds[i]].addr = address(0);
      newYield -= _ownerships[contractAddress][tokenIds[i]].yieldRate;

      emit Unstaked(_msgSender(), contractAddress, tokenIds[i]);
    }

    earthling.accumulatedSoulz += uint64(_unaccumulatedSoulz(earthling.lastAccumulatedTimestamp, earthling.yieldRate));
    earthling.lastAccumulatedTimestamp = uint64(block.timestamp);
    earthling.yieldRate = newYield;
  }

  function transferSoulz(address to, uint256 amount) external {
    if (!transferActive) revert TransferPaused();
    if (to == address(0)) revert TransferToZeroAddress();

    uint256 accountBalance = soulzBalanceOf(_msgSender());
    if (accountBalance < amount) revert InsufficientSoulz();

    _earthlingData[_msgSender()].accumulatedSoulz -= uint64(amount);
    _earthlingData[to].accumulatedSoulz += uint64(amount);

    emit SoulzTransfered(_msgSender(), to, amount);
  }

  function mintSoulz(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
    _earthlingData[account].accumulatedSoulz += uint64(amount);

    emit SoulzMinted(account, amount);
  }

  function spendSoulz(address account, uint256 amount) external onlyRole(TREASURY_ROLE) {
    uint256 accountBalance = soulzBalanceOf(account);
    if (accountBalance < amount) revert InsufficientSoulz();
    _earthlingData[account].spentSoulz += uint64(amount);

    emit SoulzSpent(account, amount);
  }

  function setStakingActive(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    stakingActive = active;
  }

  function setTransferActive(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    transferActive = active;
  }

  function setSupportedCollection(address contractAddress, uint256 yield) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _collections[contractAddress] = uint256(yield);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tId,
    bytes calldata data
  ) external pure returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function _validateSignature(
    bytes calldata signature,
    address contractAddress,
    uint256[] memory tokenIds,
    uint256[] memory tokenYields
  ) internal view returns (bool) {
    bytes32 dataHash = keccak256(abi.encodePacked(contractAddress, tokenIds, tokenYields));
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

    address signer = ECDSA.recover(message, signature);
    return hasRole(SIGNER_ROLE, signer);
  }

  function _unaccumulatedSoulz(uint256 lastAccumulatedTimestamp, uint256 yieldRate) internal view returns (uint256) {
    if (lastAccumulatedTimestamp == 0) {
      return 0;
    }
    return ((block.timestamp - lastAccumulatedTimestamp) * yieldRate) / YIELD_INTERVAL;
  }
}