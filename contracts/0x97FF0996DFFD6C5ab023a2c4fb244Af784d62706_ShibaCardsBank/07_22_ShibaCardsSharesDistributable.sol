// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ShibaCardsAccessible.sol";

import "../interfaces/ISharesDistributer.sol";
import "../interfaces/IDividendsDistributer.sol";

abstract contract ShibaCardsSharesDistributable is ShibaCardsAccessible {
  ISharesDistributer public sharesDistributer;

  function setSharesDistributer(address distributer)
    public
    onlyAdmin
  {
    sharesDistributer = ISharesDistributer(distributer);
  }
}