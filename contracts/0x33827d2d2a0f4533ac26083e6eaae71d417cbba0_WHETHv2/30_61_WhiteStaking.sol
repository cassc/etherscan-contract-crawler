/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2020 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import "../Interfaces/IWhiteStakingERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity 0.6.12;


abstract
contract WhiteStaking is ERC20, IWhiteStaking {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 public immutable WHITE;
    uint internal constant ACCURACY = 1e30;
    address payable public immutable FALLBACK_RECIPIENT;

    uint public totalProfit = 0;
    mapping(address => uint) internal lastProfit;
    mapping(address => uint) internal savedProfit;

    uint256 public lockupPeriod = 1 days;
    mapping(address => uint256) public lastStakeTimestamp;
    mapping(address => bool) public _revertTransfersInLockUpPeriod;

    constructor(ERC20 _token, string memory name, string memory short)
        public ERC20(name, short)
    {
        WHITE = _token;
        FALLBACK_RECIPIENT = msg.sender;
    }

    function claimProfit() external override returns (uint profit) {
        profit = saveProfit(msg.sender);
        require(profit > 0, "Zero profit");
        savedProfit[msg.sender] = 0;
        _transferProfit(profit);
        emit Claim(msg.sender, profit);
    }

    function deposit(uint amount) external override {
       lastStakeTimestamp[msg.sender] = block.timestamp;
        require(amount > 0, "!amount");
        WHITE.safeTransferFrom(msg.sender, address(this), amount);

        _mint(msg.sender, amount); 
    }

    function withdraw(uint amount) external lockupFree override {
        _burn(msg.sender, amount);

        WHITE.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Used for ...
     */
    function revertTransfersInLockUpPeriod(bool value) external {
        _revertTransfersInLockUpPeriod[msg.sender] = value;
    }

    function profitOf(address account) external view override returns (uint) {
        return savedProfit[account].add(getUnsaved(account));
    }

    function getUnsaved(address account) internal view returns (uint profit) {
        return totalProfit.sub(lastProfit[account]).mul(balanceOf(account)).div(ACCURACY);
    }

    function saveProfit(address account) internal returns (uint profit) {
        uint unsaved = getUnsaved(account);
        lastProfit[account] = totalProfit;
        profit = savedProfit[account].add(unsaved);
        savedProfit[account] = profit;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (from != address(0)) saveProfit(from);
        if (to != address(0)) saveProfit(to);
        if (
            lastStakeTimestamp[from].add(lockupPeriod) > block.timestamp &&
            lastStakeTimestamp[from] > lastStakeTimestamp[to]
        ) {
            require(
                !_revertTransfersInLockUpPeriod[to],
                "the recipient does not accept blocked funds"
            );
            lastStakeTimestamp[to] = lastStakeTimestamp[from];
        }
    }

    function _transferProfit(uint amount) internal virtual;

    modifier lockupFree {
        require(
            lastStakeTimestamp[msg.sender].add(lockupPeriod) <= block.timestamp,
            "Action suspended due to lockup"
        );
        _;
    }
}