// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

        ████████████
      ██            ██
    ██              ██▓▓
    ██            ████▓▓▓▓▓▓
    ██      ██████▓▓▒▒▓▓▓▓▓▓▓▓
    ████████▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒
    ██    ████████▓▓▒▒▒▒▒▒▒▒▒▒
    ██            ██▓▓▒▒▒▒▒▒▒▒
    ██              ██▓▓▓▓▓▓▓▓
    ██    ██      ██    ██       '||''|.                    ||           '||
    ██                  ██        ||   ||  ... ..   ....   ...  .. ...    || ...    ...   ... ... ...
      ██              ██          ||'''|.   ||' '' '' .||   ||   ||  ||   ||'  || .|  '|.  ||  ||  |
        ██          ██            ||    ||  ||     .|' ||   ||   ||  ||   ||    | ||   ||   ||| |||
          ██████████             .||...|'  .||.    '|..'|' .||. .||. ||.  '|...'   '|..|'    |   |

*/

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev An opinionated implementation of a general purpose PaymentSplitter.
 * Rather than letting each payee pull their funds on their own, a few convenience functions
 * let the owner flush all funds, Ether and Wrapped Ether, in one transaction.
 */
contract Splitter is PaymentSplitter, AccessControl {
  bytes32 public constant FLUSHWORTHY = keccak256("FLUSHWORTHY");

  address[] private _payees;

  IERC20 weth;

  constructor(
    address[] memory payees,
    uint256[] memory _shares,
    address _wethAddr
  ) PaymentSplitter(payees, _shares) {
    _payees = payees;

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(FLUSHWORTHY, _msgSender());

    for (uint256 i = 0; i < payees.length; i++) {
      _grantRole(FLUSHWORTHY, payees[i]);
    }

    weth = IERC20(_wethAddr);
  }

  function flush() public onlyRole(FLUSHWORTHY) {
    uint256 length = _payees.length;

    for (uint256 i = 0; i < length; i++) {
      address payee = _payees[i];
      release(payable(payee));
    }
  }

  function flushToken(IERC20 token) public onlyRole(FLUSHWORTHY) {
    uint256 length = _payees.length;

    for (uint256 i = 0; i < length; i++) {
      address payee = _payees[i];
      release(token, payable(payee));
    }
  }

  function flushCommon() public onlyRole(FLUSHWORTHY) {
    uint256 length = _payees.length;
    bool hasWeth = weth.balanceOf(address(this)) > 0;

    for (uint256 i = 0; i < length; i++) {
      address payable payee = payable(_payees[i]);
      release(payable(payee));
      if (hasWeth) release(weth, payable(payee));
    }
  }
}