// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface ISlicer is IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {
  function release(
    address account,
    address currency,
    bool withdraw
  ) external;

  function batchReleaseAccounts(
    address[] memory accounts,
    address currency,
    bool withdraw
  ) external;

  function unreleased(address account, address currency)
    external
    view
    returns (uint256 unreleasedAmount);

  function getFee() external view returns (uint256 fee);

  function getFeeForAccount(address account)
    external
    view
    returns (uint256 fee);

  function slicerInfo()
    external
    view
    returns (
      uint256 tokenId,
      uint256 minimumShares,
      address creator,
      bool isImmutable,
      bool currenciesControlled,
      bool productsControlled,
      bool acceptsAllCurrencies,
      address[] memory currencies
    );

  function isPayeeAllowed(address payee) external view returns (bool);

  function acceptsCurrency(address currency) external view returns (bool);

  function _updatePayees(
    address payable sender,
    address receiver,
    bool toRelease,
    uint256 senderShares,
    uint256 transferredShares
  ) external;

  function _updatePayeesReslice(
    address payable[] memory accounts,
    int32[] memory tokensDiffs,
    uint32 totalSupply
  ) external;

  function _setChildSlicer(uint256 id, bool addChildSlicerMode) external;

  function _setTotalShares(uint256 totalShares) external;

  function _addCurrencies(address[] memory currencies) external;

  function _setCustomFee(bool customFeeActive, uint256 customFee) external;

  function _releaseFromSliceCore(
    address account,
    address currency,
    uint256 accountSlices
  ) external;

  function _releaseFromFundsModule(address account, address currency)
    external
    returns (uint256 amount, uint256 protocolPayment);

  function _handle721Purchase(
    address buyer,
    address contractAddress,
    uint256 tokenId
  ) external;

  function _handle1155Purchase(
    address buyer,
    address contractAddress,
    uint256 quantity,
    uint256 tokenId
  ) external;
}