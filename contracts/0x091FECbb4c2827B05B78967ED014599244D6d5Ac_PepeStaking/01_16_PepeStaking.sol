// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./CollaborativeOwnable.sol";
import "./IFliesToken.sol";

contract PepeStaking is Pausable, IERC721Receiver, CollaborativeOwnable {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  address public pepeContractAddress = address(0);
  address public fliesContractAddress = address(0);

  uint256 public totalStaked = 0;

  struct WalletInfo {
    uint256[] stakedTokenIds;
  }

  mapping(address => WalletInfo) internal walletInfo;

  constructor() {
    _pause();
  }

  function stake(uint256[] calldata _tokenIds) external {
    require(!paused(), "paused");
    require(pepeContractAddress != address(0), "contract");

    WalletInfo storage wallet = walletInfo[_msgSender()];

    for (uint32 i = 0; i < _tokenIds.length; i++) {
      wallet.stakedTokenIds.push(_tokenIds[i]);
    }

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IERC721(pepeContractAddress).transferFrom(_msgSender(), address(this), _tokenIds[i]);
    }

    totalStaked += _tokenIds.length;

    onStake(_msgSender(), _tokenIds);
  }

  function unstake(uint256[] calldata _tokenIds) external {
    require(!paused(), "paused");
    require(pepeContractAddress != address(0), "contract");

    WalletInfo storage wallet = walletInfo[_msgSender()];

    for (uint32 i = 0; i < _tokenIds.length; i++) {
      uint256 index = arrayIndexOf(wallet.stakedTokenIds, _tokenIds[i]);
      require(index < wallet.stakedTokenIds.length, "owner");

      wallet.stakedTokenIds[index] = wallet.stakedTokenIds[wallet.stakedTokenIds.length - 1];
      wallet.stakedTokenIds.pop();
    }

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IERC721(pepeContractAddress).transferFrom(address(this), _msgSender(), _tokenIds[i]);
    }

    totalStaked -= _tokenIds.length;

    onUnstake(_msgSender(), _tokenIds);
  }

  function stakedTokensOfOwner(address owner) external view returns (uint256[] memory) {
    uint256[] memory stakedGenesis = walletInfo[owner].stakedTokenIds;
    return stakedGenesis;
  }

  /// For Collab.land to give a role based on staking status
  function balanceOf(address _ownerowner) public view returns (uint256) {
    uint256[] memory stakedTokenIds = walletInfo[_ownerowner].stakedTokenIds;
    return stakedTokenIds.length;
  }

  // Override ERC721
  function onERC721Received(
    address operator,
    address from,
    uint256 id,
    bytes calldata data
  ) external returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  //
  // Internal
  //

  function onStake(address _owner, uint256[] memory _tokenIds) internal {
    if (fliesContractAddress != address(0)) {
      IFliesToken(fliesContractAddress).onStakeEvent(_owner, _tokenIds);
    }
  }

  function onUnstake(address _owner, uint256[] memory _tokenIds) internal {
    if (fliesContractAddress != address(0)) {
      IFliesToken(fliesContractAddress).onUnstakeEvent(_owner, _tokenIds);
    }
  }

  function arrayIndexOf(uint256[] memory _array, uint256 _item) pure internal returns (uint256) {
    for (uint256 i = 0; i < _array.length; i++) {
      if (_array[i] == _item) {
        return i;
      }
    }
    return _array.length;
  }

  //
  // Collaborator Access
  //

  function setPepeContractAddress(address _pepeContractAddress) external onlyCollaborator {
    pepeContractAddress = _pepeContractAddress;
  }

  function setFliesContractAddress(address _fliesContractAddress) external onlyCollaborator {
    fliesContractAddress = _fliesContractAddress;
  }

  function pause() external onlyCollaborator {
    _pause();
  }

  function unpause() external onlyCollaborator {
    _unpause();
  }

  function emergencyUnstake(address _owner, bool _suppressMessage) external onlyCollaborator {
    WalletInfo storage wallet = walletInfo[_owner];

    for (uint256 i = 0; i < wallet.stakedTokenIds.length; i++) {
      IERC721(pepeContractAddress).transferFrom(address(this), _owner, wallet.stakedTokenIds[i]);
    }

    if (!_suppressMessage) {
      onUnstake(_owner, wallet.stakedTokenIds);
    }

    totalStaked -= wallet.stakedTokenIds.length;

    while (wallet.stakedTokenIds.length > 0) {
      wallet.stakedTokenIds.pop();
    }
  }

  //
  // Owner Access
  //

  function emergencyTransfer(address _owner, uint256[] calldata _tokenIds) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IERC721(pepeContractAddress).transferFrom(address(this), _owner, _tokenIds[i]);
    }
  }

  function updateWalletInfo(address _addr, uint256[] calldata _stakedTokenIds) external onlyOwner {
    WalletInfo storage wallet = walletInfo[_addr];
    wallet.stakedTokenIds = _stakedTokenIds;
  }
}