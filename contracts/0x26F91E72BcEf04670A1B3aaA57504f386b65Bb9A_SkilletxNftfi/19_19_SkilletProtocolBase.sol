//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../interfaces/ConduitInterface.sol";

interface ISkilletRegistry {
  function conduitAddress() external view returns (address);
}

contract SkilletProtocolBase is ERC721Holder {
  using SafeERC20 for IERC20;
  uint256 MAX_UINT_256 = 2**256 - 1;

  address public skilletRegistryAddress;

  constructor(address _skilletRegistryAddress) {
    skilletRegistryAddress = _skilletRegistryAddress;
  }

  /**
   * @dev Get Conduit Address
   * @return conduitAddress address of the approved conduit
   */
   function getConduitAddress() public view returns (address conduitAddress) {
    conduitAddress = ISkilletRegistry(skilletRegistryAddress).conduitAddress();
   }

  /**
   * @dev Transfer asset from sender to reciever
   * @param sender address of the sender
   * @param receiver address of the receiver
   * @param collectionAddress address of the ERC721 collection
   * @param tokenId token identifier in collection
   */
  function transferERC721(
    address sender,
    address receiver,
    address collectionAddress,
    uint256 tokenId
  ) public 
  {
    IERC721 collection = IERC721(collectionAddress);
    collection.safeTransferFrom(sender, receiver, tokenId);
  }

  /**
   * @dev Transfers amout of currency from sender to recevier
   * @param receiver address of the receiver
   * @param sender address of the sender
   * @param currencyAddress address of the currency being transferred
   * @param paymentAmount amount of currency to be sent to receiver
   */
  function transferERC20 (
    address sender,
    address receiver,
    address currencyAddress,
    uint256 paymentAmount
  ) public
  {
    IERC20 currency = IERC20(currencyAddress);
    if (sender == address(this)) {
      currency.transfer(receiver, paymentAmount);
      return;
    }

    currency.transferFrom(sender, receiver, paymentAmount);
  }

  function approveOperatorForERC721(
    address operator,
    address collectionAddress
  ) public
  {
    IERC721 collection = IERC721(collectionAddress);
    collection.setApprovalForAll(operator, true);
  }

  function checkAndSetOperatorApprovalForERC721(
    address operator,
    address collectionAddress
  ) public
  {
    IERC721 collection = IERC721(collectionAddress);
    bool approved = collection.isApprovedForAll(address(this), operator);
    if (!approved) collection.setApprovalForAll(operator, true);
  }

  function approveOperatorForERC20(
    address operator,
    address currencyAddress
  ) public
  {
    IERC20 currency = IERC20(currencyAddress);
    currency.approve(operator, MAX_UINT_256);
  }

  function checkAndSetOperatorApprovalForERC20(
    address operator,
    address currencyAddress
  ) public
  {
    IERC20 currency = IERC20(currencyAddress);
    uint256 allowance = currency.allowance(address(this), operator);
    if (!(allowance == MAX_UINT_256)) currency.approve(operator, MAX_UINT_256);
  }

  function conduitTransferERC721(
    address collectionAddress,
    address from,
    address to,
    uint256 tokenId
  ) public
  {
    ConduitTransfer[] memory transfers = new ConduitTransfer[](1);
    transfers[0] = ConduitTransfer({
      itemType: ConduitItemType.ERC721,
      token: collectionAddress,
      from: from,
      to: to,
      identifier: tokenId,
      amount: 1
    });

    ConduitInterface(getConduitAddress()).execute(transfers);
  }

  function conduitTransferERC20(
    address currencyAddress,
    address from,
    address to,
    uint256 amount
  ) public
  {
    ConduitTransfer[] memory paymentTransfers = new ConduitTransfer[](1);
    paymentTransfers[0] = ConduitTransfer({
      itemType: ConduitItemType.ERC20,
      token: currencyAddress,
      from: from,
      to: to,
      identifier: 0,
      amount: amount
    });

    ConduitInterface(getConduitAddress()).execute(paymentTransfers);
  }
}