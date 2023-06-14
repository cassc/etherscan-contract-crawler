// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGuildAsset is IERC721 {
    function getTotalVolume(uint16 _guildType) external view returns (uint256);
    function isValidGuildStock(uint256 _guildTokenId) external view;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function getGuildType(uint256 _guildTokenId) external view returns (uint16);
    function getShareRateWithDecimal(uint256 _guildTokenId) external view returns (uint256, uint256);
}

contract CSPLGuildPoolV2 is Ownable, Pausable, ReentrancyGuard {

  IGuildAsset public guildAsset;

  // mapping(guildType => totalAmount)
  mapping(uint16 => uint256) private guildTypeToTotalAmount;
  // mapping(guildTokenId => withdrawnAmount)
  mapping(uint256 => uint256) private guildStockToWithdrawnAmount;
  // mapping(allowedAddresses => bool)
  mapping(address => bool) private allowedAddresses;

  event EthAddedToPool(
    uint16 indexed guildType,
    address txSender,
    address indexed purchaseBy,
    uint256 value,
    uint256 at
  );

  event WithdrawEther(
    uint256 indexed guildTokenId,
    address indexed owner,
    uint256 value,
    uint256 at
  );

  event AllowedAddressSet(
    address allowedAddress,
    bool allowedStatus
  );

  constructor(address _guildAssetAddress) {
    setGuildAssetAddress(_guildAssetAddress);
  }

  function setGuildAssetAddress(address _guildAssetAddress) public onlyOwner() {
    guildAsset = IGuildAsset(_guildAssetAddress);
  }

  // getter setter
  function getAllowedAddress(address _address) public view returns (bool) {
    return allowedAddresses[_address];
  }

  function setAllowedAddress(address _address, bool desired) external onlyOwner() {
    allowedAddresses[_address] = desired;
  }

  function getGuildStockWithdrawnAmount(uint256 _guildTokenId) public view returns (uint256) {
    return guildStockToWithdrawnAmount[_guildTokenId];
  }

  function getGuildTypeToTotalAmount(uint16 _guildType) public view returns (uint256) {
    return guildTypeToTotalAmount[_guildType];
  }

  // poolに追加 execute from buySPL
  function addEthToGuildPool(uint16 _guildType, address _purchaseBy) external payable whenNotPaused() nonReentrant() {
    require(guildAsset.getTotalVolume(_guildType) > 0);
    require(allowedAddresses[msg.sender]);
    guildTypeToTotalAmount[_guildType] += msg.value;

    emit EthAddedToPool(
      _guildType,
      msg.sender,
      _purchaseBy,
      msg.value,
      block.timestamp
    );
  }

  function withdrawMyAllRewards() external whenNotPaused() nonReentrant() {
    uint256 withdrawValue;
    uint256 balance = guildAsset.balanceOf(msg.sender);

    for (uint256 i=balance; i > 0; i--) {
      uint256 guildStock = guildAsset.tokenOfOwnerByIndex(msg.sender, i-1);
      uint256 tmpAmount = getGuildStockWithdrawableBalance(guildStock);
      withdrawValue += tmpAmount;
      guildStockToWithdrawnAmount[guildStock] += tmpAmount;

      emit WithdrawEther(
        guildStock,
        msg.sender,
        tmpAmount,
        block.timestamp
      );
    }

    require(withdrawValue > 0, "no withdrawable balances left");

    payable(msg.sender).transfer(withdrawValue);
  }

  function withdrawMyReward(uint256 _guildTokenId) external whenNotPaused() nonReentrant() {
    require(guildAsset.ownerOf(_guildTokenId) == msg.sender);
    uint256 withdrawableAmount = getGuildStockWithdrawableBalance(_guildTokenId);
    require(withdrawableAmount > 0);

    guildStockToWithdrawnAmount[_guildTokenId] += withdrawableAmount;
    payable(msg.sender).transfer(withdrawableAmount);

    emit WithdrawEther(
      _guildTokenId,
      msg.sender,
      withdrawableAmount,
      block.timestamp
    );
  }

  function withdrawMyRewards(uint[] calldata _guildTokenId) external whenNotPaused() nonReentrant() {
    uint256 withdrawValue;

    for (uint8 i = 0; i < _guildTokenId.length; i++) {
        require(guildAsset.ownerOf(_guildTokenId[i]) == msg.sender);
        uint256 tmpAmount = getGuildStockWithdrawableBalance(_guildTokenId[i]);

        guildStockToWithdrawnAmount[_guildTokenId[i]] += tmpAmount;

        emit WithdrawEther(
            _guildTokenId[i],
            msg.sender,
            tmpAmount,
            block.timestamp
        );
        withdrawValue += tmpAmount;
    }

    require(withdrawValue > 0, "no withdrawable balances left");

    payable(msg.sender).transfer(withdrawValue);
  }

  // ギルドトークンごとの引き出し可能な量
  // 全体の総和×割合-これまで引き出した量
  function getGuildStockWithdrawableBalance(uint256 _guildTokenId) public view returns (uint256) {
    guildAsset.isValidGuildStock(_guildTokenId);

    uint16 _guildType = guildAsset.getGuildType(_guildTokenId);
    (uint256 shareRate, uint256 decimal) = guildAsset.getShareRateWithDecimal(_guildTokenId);
    uint256 maxAmount = guildTypeToTotalAmount[_guildType] * shareRate / decimal;
    return maxAmount - guildStockToWithdrawnAmount[_guildTokenId];
  }

  function getWithdrawableBalance(address _ownerAddress) public view returns (uint256) {
    uint256 balance = guildAsset.balanceOf(_ownerAddress);
    uint256 withdrawableAmount;

    for (uint256 i=balance; i > 0; i--) {
      uint256 guildTokenId = guildAsset.tokenOfOwnerByIndex(_ownerAddress, i-1);
      withdrawableAmount += getGuildStockWithdrawableBalance(guildTokenId);
    }

    return withdrawableAmount;
  }

  function getGuildStockWithdrawableBalances(uint[] calldata _guildTokenId) public view returns (uint256) {
    uint256 withdrawableAmount;

    for (uint8 i = 0; i < _guildTokenId.length; i++) {
      withdrawableAmount += getGuildStockWithdrawableBalance(_guildTokenId[i]);
    }

    return withdrawableAmount;
  }

}