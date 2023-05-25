// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@cartesi/pos/contracts/IPoS.sol";

import "./utils/WadRayMath.sol";

contract StakingPoolData is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using WadRayMath for uint256;
    uint256 public shares; // total number of shares
    uint256 public amount; // amount of staked tokens (no matter where it is)
    uint256 public requiredLiquidity; // amount of required tokens for withdraw requests

    IPoS public pos;

    struct UserBalance {
        uint256 balance; // amount of free tokens belonging to this user
        uint256 shares; // amount of shares belonging to this user
        uint256 depositTimestamp; // timestamp of when user deposited for the last time
    }
    mapping(address => UserBalance) public userBalance;

    function amountToShares(uint256 _amount) public view returns (uint256) {
        if (amount == 0) {
            // no shares yet, return 1 to 1 ratio
            return _amount.wad2ray();
        }
        return _amount.wmul(shares).wdiv(amount);
    }

    function sharesToAmount(uint256 _shares) public view returns (uint256) {
        if (shares == 0) {
            // no shares yet, return 1 to 1 ratio
            return _shares.ray2wad();
        }
        return _shares.rmul(amount).rdiv(shares);
    }
}