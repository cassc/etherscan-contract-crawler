/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "AccessControl.sol";
import "ERC20Votes.sol";

string constant NAME = "StarkNet Token";
string constant SYMBOL = "STRK";

contract StarkNetToken is ERC20Votes, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20Permit(NAME) ERC20(NAME, SYMBOL) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) returns (bool) {
        _mint(account, amount);
        return true;
    }
}