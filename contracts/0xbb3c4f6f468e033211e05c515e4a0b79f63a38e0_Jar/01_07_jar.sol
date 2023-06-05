// SPDX-License-Identifier: AGPL-3.0-or-later

/// jar.sol -- Davos distribution farming

// Copyright (C) 2022
//
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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/*
   "Put rewards in the jar and close it".
   This contract lets you deposit DAVOSs from davos.sol and earn
   DAVOS rewards. The DAVOS rewards are deposited into this contract
   and distributed over a timeline. Users can redeem rewards
   after exit delay.
*/

contract Jar is Initializable, ReentrancyGuardUpgradeable {
    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Jar/not-authorized");
        _;
    }

    // --- Derivative ---
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    // --- Reward Data ---
    uint public spread;          // Distribution time     [sec]
    uint public endTime;         // Time "now" + spread   [sec]
    uint public rate;            // Emission per second   [wad]
    uint public tps;             // DAVOS tokens per share  [wad]
    uint public lastUpdate;      // Last tps update       [sec]
    uint public exitDelay;       // User unstake delay    [sec]
    uint public flashLoanDelay;  // Anti flash loan time  [sec]
    address public DAVOS;        // The DAVOS Stable Coin

    mapping(address => uint) public tpsPaid;      // DAVOS per share paid
    mapping(address => uint) public rewards;      // Accumulated rewards
    mapping(address => uint) public withdrawn;    // Capital withdrawn
    mapping(address => uint) public unstakeTime;  // Time of Unstake
    mapping(address => uint) public stakeTime;    // Time of Stake

    mapping(address => uint) public operators;  // Operators of contract

    uint    public live;     // Active Flag

    // --- Events ---
    event Replenished(uint reward);
    event SpreadUpdated(uint newDuration);
    event ExitDelayUpdated(uint exitDelay);
    event OperatorSet(address operator);
    event OperatorUnset(address operator);
    event Join(address indexed user, uint indexed amount);
    event Exit(address indexed user, uint indexed amount);
    event Redeem(address[] indexed user);
    event Cage();
    event UnCage();
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(string memory _name, string memory _symbol, address _davosToken, uint _spread, uint _exitDelay, uint _flashLoanDelay) external initializer {
        __ReentrancyGuard_init();
        wards[msg.sender] = 1;
        decimals = 18;
        name = _name;
        symbol = _symbol;
        DAVOS = _davosToken;
        spread = _spread;
        exitDelay = _exitDelay;
        flashLoanDelay = _flashLoanDelay;
        live = 1;
    }

    // --- Math ---
    function _min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    // --- Mods ---
    modifier update(address account) {
        tps = tokensPerShare();
        lastUpdate = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            tpsPaid[account] = tps;
        }
        _;
    }
    modifier authOrOperator {
        require(operators[msg.sender] == 1 || wards[msg.sender] == 1, "Jar/not-auth-or-operator");
        _;
    }

    // --- Views ---
    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(block.timestamp, endTime);
    }
    function tokensPerShare() public view returns (uint) {
        if (totalSupply <= 0 || block.timestamp <= lastUpdate) {
            return tps;
        }
        uint latest = lastTimeRewardApplicable();
        return tps + (((latest - lastUpdate) * rate * 1e18) / totalSupply);
    }
    function earned(address account) public view returns (uint) {
        uint perToken = tokensPerShare() - tpsPaid[account];
        return ((balanceOf[account] * perToken) / 1e18) + rewards[account];
    }

    // --- Administration --
    function replenish(uint wad, bool newSpread) external authOrOperator update(address(0)) {
        uint timeline = spread;
        if (block.timestamp >= endTime) {
            rate = wad / timeline;
        } else {
            uint remaining = endTime - block.timestamp;
            uint leftover = remaining * rate;
            timeline = newSpread ? spread : remaining;
            rate = (wad + leftover) / timeline;
        }
        lastUpdate = block.timestamp;
        endTime = block.timestamp + timeline;

        IERC20Upgradeable(DAVOS).safeTransferFrom(msg.sender, address(this), wad);
        emit Replenished(wad);
    }
    function setSpread(uint _spread) external authOrOperator {
        require(_spread > 0, "Jar/duration-non-zero");
        spread = _spread;
        emit SpreadUpdated(_spread);
    }
    function setExitDelay(uint _exitDelay) external authOrOperator {
        exitDelay = _exitDelay;
        emit ExitDelayUpdated(_exitDelay);
    }
    function addOperator(address _operator) external auth {
        operators[_operator] = 1;
        emit OperatorSet(_operator);
    }
    function removeOperator(address _operator) external auth {
        operators[_operator] = 0;
        emit OperatorUnset(_operator);
    }
    function extractDust() external auth {
        require(block.timestamp >= endTime, "Jar/in-distribution");
        uint dust = IERC20Upgradeable(DAVOS).balanceOf(address(this)) - totalSupply;
        if (dust != 0) {
            IERC20Upgradeable(DAVOS).safeTransfer(msg.sender, dust);
        }
    }
    function cage() external auth {
        live = 0;
        emit Cage();
    }

    function uncage() external auth {
        live = 1;
        emit UnCage();
    }

    // --- User ---
    function join(uint256 wad) external update(msg.sender) nonReentrant {
        require(live == 1, "Jar/not-live");

        balanceOf[msg.sender] += wad;
        totalSupply += wad;
        stakeTime[msg.sender] = block.timestamp + flashLoanDelay;

        IERC20Upgradeable(DAVOS).safeTransferFrom(msg.sender, address(this), wad);
        emit Join(msg.sender, wad);
    }
    function exit(uint256 wad) external update(msg.sender) nonReentrant {
        require(live == 1, "Jar/not-live");
        require(block.timestamp > stakeTime[msg.sender], "Jar/flash-loan-delay");

        if (wad > 0) {
            balanceOf[msg.sender] -= wad;        
            totalSupply -= wad;
            withdrawn[msg.sender] += wad;
        }
        if (exitDelay <= 0) {
            // Immediate claim
            address[] memory accounts = new address[](1);
            accounts[0] = msg.sender;
            _redeemHelper(accounts);
        } else {
            unstakeTime[msg.sender] = block.timestamp + exitDelay;
        }
        
        emit Exit(msg.sender, wad);
    }
    function redeemBatch(address[] memory accounts) external nonReentrant {
        // Allow direct and on-behalf redemption
        require(live == 1, "Jar/not-live");
        _redeemHelper(accounts);
    }
    function _redeemHelper(address[] memory accounts) private {
        for (uint i = 0; i < accounts.length; i++) {
            if (block.timestamp < unstakeTime[accounts[i]] && unstakeTime[accounts[i]] != 0 && exitDelay != 0)
                continue;
            
            uint _amount = rewards[accounts[i]] + withdrawn[accounts[i]];
            if (_amount > 0) {
                rewards[accounts[i]] = 0;
                withdrawn[accounts[i]] = 0;
                IERC20Upgradeable(DAVOS).safeTransfer(accounts[i], _amount);
            }
        }
       
        emit Redeem(accounts);
    }
}