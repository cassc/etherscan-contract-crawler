// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import "./interfaces/IWooRouterV2.sol";
import "./interfaces/IWooVaultManager.sol";
import "./interfaces/IWooAccessManager.sol";

import "./libraries/TransferHelper.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract WooVaultManager is Ownable, ReentrancyGuard, IWooVaultManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) public override vaultWeight;
    uint256 public totalWeight;

    IWooRouterV2 private wooRouter;

    address public immutable override quoteToken; // USDT
    address public immutable rewardToken; // WOO

    EnumerableSet.AddressSet private vaultSet;

    IWooAccessManager public accessManager;

    modifier onlyAdmin() {
        require(msg.sender == owner() || accessManager.isVaultAdmin(msg.sender), "WooVaultManager: !admin");
        _;
    }

    constructor(
        address _quoteToken,
        address _rewardToken,
        address _accessManager
    ) {
        quoteToken = _quoteToken;
        rewardToken = _rewardToken;
        accessManager = IWooAccessManager(_accessManager);
    }

    function allVaults() external view override returns (address[] memory) {
        address[] memory vaults = new address[](vaultSet.length());
        unchecked {
            for (uint256 i = 0; i < vaultSet.length(); ++i) {
                vaults[i] = vaultSet.at(i);
            }
        }
        return vaults;
    }

    function addReward(uint256 amount) external override nonReentrant {
        TransferHelper.safeTransferFrom(quoteToken, msg.sender, address(this), amount);
    }

    function pendingReward(address vaultAddr) external view override returns (uint256) {
        require(vaultAddr != address(0), "WooVaultManager: !vaultAddr");
        uint256 totalReward = IERC20(quoteToken).balanceOf(address(this));
        return (totalReward * vaultWeight[vaultAddr]) / totalWeight;
    }

    function pendingAllReward() external view override returns (uint256) {
        return IERC20(quoteToken).balanceOf(address(this));
    }

    function setVaultWeight(address vaultAddr, uint256 weight) external override onlyAdmin {
        require(vaultAddr != address(0), "WooVaultManager: !vaultAddr");

        // NOTE: First clear all the pending reward if > 1u to keep the things fair
        if (IERC20(quoteToken).balanceOf(address(this)) >= 10**IERC20Metadata(quoteToken).decimals()) {
            distributeAllReward();
        }

        uint256 prevWeight = vaultWeight[vaultAddr];
        vaultWeight[vaultAddr] = weight;
        totalWeight = totalWeight + weight - prevWeight;

        if (weight == 0) {
            vaultSet.remove(vaultAddr);
        } else {
            vaultSet.add(vaultAddr);
        }

        emit VaultWeightUpdated(vaultAddr, weight);
    }

    function distributeAllReward() public override onlyAdmin {
        uint256 totalRewardInQuote = IERC20(quoteToken).balanceOf(address(this));
        if (totalRewardInQuote == 0 || totalWeight == 0) {
            return;
        }

        TransferHelper.safeApprove(quoteToken, address(wooRouter), totalRewardInQuote);
        uint256 wooAmount = wooRouter.swap(
            quoteToken,
            rewardToken,
            totalRewardInQuote,
            0,
            payable(address(this)),
            address(0)
        );

        for (uint256 i = 0; i < vaultSet.length(); ++i) {
            address vaultAddr = vaultSet.at(i);
            uint256 vaultAmount = (wooAmount * vaultWeight[vaultAddr]) / totalWeight;
            if (vaultAmount > 0) {
                TransferHelper.safeTransfer(rewardToken, vaultAddr, vaultAmount);
            }
            emit RewardDistributed(vaultAddr, vaultAmount);
        }
    }

    function setWooRouter(address _wooRouter) external onlyAdmin {
        wooRouter = IWooRouterV2(_wooRouter);
        require(wooRouter.wooPool().quoteToken() == quoteToken, "WooVaultManager: !wooRouter_quoteToken");
    }

    function setAccessManager(address _accessManager) external onlyOwner {
        accessManager = IWooAccessManager(_accessManager);
    }

    function inCaseTokenGotStuck(address stuckToken) external onlyOwner {
        if (stuckToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        } else {
            uint256 amount = IERC20(stuckToken).balanceOf(address(this));
            TransferHelper.safeTransfer(stuckToken, msg.sender, amount);
        }
    }
}