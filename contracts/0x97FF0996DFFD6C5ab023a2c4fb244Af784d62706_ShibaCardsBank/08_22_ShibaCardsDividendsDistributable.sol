// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ShibaCardsAccessible.sol";

import "../interfaces/ISharesDistributer.sol";
import "../interfaces/IDividendsDistributer.sol";

abstract contract ShibaCardsDividendsDistributable is ShibaCardsAccessible {
  IDividendsDistributer public dividendsDistributer;

  function setDividendsDistributer(address distributer)
    public
    onlyAdmin
  {
    dividendsDistributer = IDividendsDistributer(distributer);
  }
}