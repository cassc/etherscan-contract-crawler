// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;

import './interfaces/IOracle.sol';
import './Assimilators.sol';
import '@balancer-labs/v2-vault/contracts/interfaces/IVault.sol';

contract Storage {
    struct Curve {
        // Curve parameters
        int128 alpha;
        int128 beta;
        int128 delta;
        int128 epsilon;
        int128 lambda;
        int128[] weights;
        uint256 cap;
        // Assets and their assimilators
        Assimilator[] assets;
        mapping(address => Assimilator) assimilators;
        // Oracles to determine the price
        // Note that 0'th index should always be USDC 1e18
        // Oracle's pricing should be denominated in Currency/USDC
        mapping(address => IOracle) oracles;
        // ERC20 Interface
        uint256 totalSupply;
        //   mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        // Vault reference
        IVault vault;
        bytes32 poolId;
    }

    struct Assimilator {
        address addr;
        uint8 ix;
    }

    // Curve parameters
    Curve public curve;

    address[] public derivatives;
    address[] public numeraires;
    address[] public reserves;

    // Curve operational state
    bool public emergency = false;
}