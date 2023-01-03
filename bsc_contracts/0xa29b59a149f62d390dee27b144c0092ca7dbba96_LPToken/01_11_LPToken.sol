/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "./02_11_ERC20Upgradeable.sol";
import "./03_11_AddressUpgradeable.sol";
import "./04_11_OwnableUpgradeable.sol";
import "./05_11_PausableUpgradeable.sol";
import {ILPToken} from "./06_11_ILPToken.sol";
import {Math} from "./07_11_Math.sol";

contract LPToken is ILPToken, OwnableUpgradeable, PausableUpgradeable, ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeLPToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC20_init(_name, _symbol);
        _setupDecimals(_decimals);
    }

    address public lpTokenMinter;
    address public lpTokenBurner;
    mapping(address => uint256) public burnWeightPH;
    mapping(address => uint256) public pendingBurnAmtPH;
    mapping(address => uint256) public burnableAmtPH;

    mapping(address => uint256) public rewardDebt;
    uint256 public totalSupplyCap;
    uint256 public perAccountCap;

    function setup(address _lpTokenMinter, address _lpTokenBurner) external onlyOwner {
        require(_lpTokenMinter != address(0), "S:1");
        lpTokenMinter = _lpTokenMinter;
        require(_lpTokenBurner != address(0), "S:2");
        lpTokenBurner = _lpTokenBurner;
    }

    function setupMintCap(uint256 _totalSupplyCap, uint256 _perAccountCap) external onlyOwner {
        totalSupplyCap = _totalSupplyCap;
        perAccountCap = _perAccountCap;
    }

    function setupDecimals(uint8 _decimals) external onlyOwner {
        _setupDecimals(_decimals);
    }

    function canMintPerTotalSupply(uint256 _amount) public view returns (uint256) {
        if (_amount.add(totalSupply()) <= totalSupplyCap) {
            return totalSupplyCap.sub(totalSupply());
        }
        return 0;
    }

    function canMintPerAccountCap(address _account, uint256 _amount) public view returns (uint256) {
        if (_amount.add(balanceOf(_account)) <= perAccountCap) {
            return perAccountCap.sub(balanceOf(_account));
        }
        return 0;
    }

    modifier onlyMinter() {
        require(lpTokenMinter == _msgSender(), "onlyMinter");
        _;
    }

    modifier onlyBurner() {
        require(lpTokenBurner == _msgSender(), "onlyBurner");
        _;
    }

    function rewardDebtOf(address _account) external view override returns (uint256) {
        return rewardDebt[_account];
    }

    function burnableAmtOf(address _account) external view override returns (uint256) {
        uint256 currentBlock = block.number;
        uint256 burableAmt = burnableAmtPH[_account];
        if (burnWeightPH[_account] <= currentBlock) {
            burableAmt = burnableAmtPH[_account].add(pendingBurnAmtPH[_account]);
        }
        return burableAmt;
    }

    function pauseAll() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPauseAll() external onlyOwner whenPaused {
        _unpause();
    }

    function mint(
        address _account,
        uint256 _amount,
        uint256 _poolRewardPerLPToken
    ) external override onlyMinter whenNotPaused {
        if (_amount != 0) {
            require(canMintPerTotalSupply(_amount) != 0, "mint:1");
            require(canMintPerAccountCap(_account, _amount) != 0, "mint:2");
            _mint(_account, _amount);
        }
        rewardDebt[_account] = _poolRewardPerLPToken.mul(balanceOf(_account)).div(1e18);
    }

    function burn(
        address _account,
        uint256 _amount,
        uint256 _poolRewardPerLPToken
    ) external override onlyBurner {
        uint256 currentBlock = block.number;
        if (burnWeightPH[_account] <= currentBlock) {
            burnWeightPH[_account] = 0;
            burnableAmtPH[_account] = burnableAmtPH[_account].add(pendingBurnAmtPH[_account]);
            pendingBurnAmtPH[_account] = 0;
        }
        require(_amount > 0 && _amount <= burnableAmtPH[_account], "B:1");
        _burn(_account, _amount);
        burnableAmtPH[_account] = burnableAmtPH[_account].sub(_amount);
        rewardDebt[_account] = _poolRewardPerLPToken.mul(balanceOf(_account)).div(1e18);
    }

    function proposeToBurn(
        address _account,
        uint256 _amount,
        uint256 _blockWeightDuration
    ) external override whenNotPaused onlyBurner {
        require(_amount > 0, "PTB:1");
        uint256 currentBlock = block.number;
        uint256 holdingAmt = balanceOf(_account);
        require(holdingAmt > 0, "PTB:2");
        require(holdingAmt.sub(pendingBurnAmtPH[_account]).sub(burnableAmtPH[_account]) >= _amount, "PTB:3");
        if (burnWeightPH[_account] <= currentBlock) {
            burnWeightPH[_account] = _blockWeightDuration.add(currentBlock);
            burnableAmtPH[_account] = burnableAmtPH[_account].add(pendingBurnAmtPH[_account]);
            pendingBurnAmtPH[_account] = _amount;
        } else {
            uint256 deltaBlk = burnWeightPH[_account].sub(currentBlock);
            uint256 newWeight = deltaBlk.mul(pendingBurnAmtPH[_account]).add(_amount.mul(_blockWeightDuration)).div(_amount.add(pendingBurnAmtPH[_account]));
            pendingBurnAmtPH[_account] = _amount.add(pendingBurnAmtPH[_account]);
            burnWeightPH[_account] = newWeight.add(currentBlock);
        }
    }

    event TokenMint(address indexed _from, address indexed _to, uint256 _amount);
    event TokenBurn(address indexed _from, address indexed _to, uint256 _amount);

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _amount);
        if (_msgSender() == lpTokenMinter && _from == address(0)) {
            emit TokenMint(_from, _to, _amount);
        } else if (_msgSender() == lpTokenBurner && _to == address(0)) {
            emit TokenBurn(_from, _to, _amount);
        } else if (_to == address(0)) {
            require(false, "LPToken: cannot burn");
        } else {
            require(false, "LPToken: no transfer");
        }
    }
}