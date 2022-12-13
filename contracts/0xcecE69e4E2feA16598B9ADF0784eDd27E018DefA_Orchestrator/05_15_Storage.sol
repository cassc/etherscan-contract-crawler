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

pragma solidity ^0.8.13;

import "./interfaces/IOracle.sol";
import "./Assimilators.sol";

contract Storage {
    struct Curve {
        // Curve parameters
        int128 alpha;
        int128 beta;
        int128 delta;
        int128 epsilon;
        int128 lambda;
        int128[] weights;
        // Assets and their assimilators
        Assimilator[] assets;
        mapping(address => Assimilator) assimilators;
        // Oracles to determine the price
        // Note that 0'th index should always be USDC 1e18
        // Oracle's pricing should be denominated in Currency/USDC
        mapping(address => IOracle) oracles;
        // ERC20 Interface
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;

        // store how many lp tokens are minted & burnt to a wallet
        mapping (address => uint256) totalMinted;
    }

    struct Assimilator {
        address addr;
        uint8 ix;
    }

    // Curve parameters
    Curve public curve;

    // Ownable
    address public owner;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    address[] public derivatives;
    address[] public numeraires;
    address[] public reserves;

    // Curve operational state
    bool public frozen = false;
    bool public emergency = false;
    bool public whitelistingStage = true;
    bool internal notEntered = true;

    mapping(address => uint256) public whitelistedDeposited;
}