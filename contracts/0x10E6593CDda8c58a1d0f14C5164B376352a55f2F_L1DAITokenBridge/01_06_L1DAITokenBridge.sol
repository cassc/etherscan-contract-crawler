// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// @unsupported: ovm
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.7.6;

import {iOVM_L1ERC20Bridge} from "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L1ERC20Bridge.sol";
import {iOVM_L2ERC20Bridge} from "@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L2ERC20Bridge.sol";
import {OVM_CrossDomainEnabled} from "@eth-optimism/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

interface TokenLike {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

// Managed locked funds in L1Escrow and send / receive messages to L2DAITokenBridge counterpart
// Note: when bridge is closed it will still process in progress messages

contract L1DAITokenBridge is iOVM_L1ERC20Bridge, OVM_CrossDomainEnabled {
  // --- Auth ---
  mapping (address => uint256) public wards;
  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }
  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }
  modifier auth {
    require(wards[msg.sender] == 1, "L1DAITokenBridge/not-authorized");
    _;
  }

  event Rely(address indexed usr);
  event Deny(address indexed usr);

  address public immutable l1Token;
  address public immutable l2DAITokenBridge;
  address public immutable l2Token;
  address public immutable escrow;
  uint256 public isOpen = 1;

  event Closed();

  constructor(
    address _l1Token,
    address _l2DAITokenBridge,
    address _l2Token,
    address _l1messenger,
    address _escrow
  ) OVM_CrossDomainEnabled(_l1messenger) {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    l1Token = _l1Token;
    l2DAITokenBridge = _l2DAITokenBridge;
    l2Token = _l2Token;
    escrow = _escrow;
  }

  function close() external auth {
    isOpen = 0;

    emit Closed();
  }

  function depositERC20(
    address _l1Token,
    address _l2Token,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) external virtual override {
    // Used to stop deposits from contracts (avoid accidentally lost tokens)
    // Note: This check could be bypassed by a malicious contract via initcode, but it takes care of the user error we want to avoid.
    require(!Address.isContract(msg.sender), "L1DAITokenBridge/Sender-not-EOA");
    require(_l1Token == l1Token && _l2Token == l2Token, "L1DAITokenBridge/token-not-dai");

    _initiateERC20Deposit(msg.sender, msg.sender, _amount, _l2Gas, _data);
  }

  function depositERC20To(
    address _l1Token,
    address _l2Token,
    address _to,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) external virtual override {
    require(_l1Token == l1Token && _l2Token == l2Token, "L1DAITokenBridge/token-not-dai");

    _initiateERC20Deposit(msg.sender, _to, _amount, _l2Gas, _data);
  }

  function _initiateERC20Deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) internal {
    // do not allow initiating new xchain messages if bridge is closed
    require(isOpen == 1, "L1DAITokenBridge/closed");

    TokenLike(l1Token).transferFrom(_from, escrow, _amount);

    bytes memory message =
      abi.encodeWithSelector(iOVM_L2ERC20Bridge.finalizeDeposit.selector, l1Token, l2Token, _from, _to, _amount, _data);

    sendCrossDomainMessage(l2DAITokenBridge, _l2Gas, message);

    emit ERC20DepositInitiated(l1Token, l2Token, _from, _to, _amount, _data);
  }

  function finalizeERC20Withdrawal(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external override onlyFromCrossDomainAccount(l2DAITokenBridge) {
    require(_l1Token == l1Token && _l2Token == l2Token, "L1DAITokenBridge/token-not-dai");
    
    TokenLike(l1Token).transferFrom(escrow, _to, _amount);

    emit ERC20WithdrawalFinalized(l1Token, l2Token, _from, _to, _amount, _data);
  }
}