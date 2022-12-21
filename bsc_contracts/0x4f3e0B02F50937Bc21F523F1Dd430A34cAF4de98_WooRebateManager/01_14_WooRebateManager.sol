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

import "./interfaces/IWooRebateManager.sol";
import "./interfaces/IWooAccessManager.sol";
import "./interfaces/IWooRouterV2.sol";

import "./libraries/TransferHelper.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract WooRebateManager is Ownable, ReentrancyGuard, IWooRebateManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Note: this is the percent rate of the total swap fee (not the swap volume)
    // decimal: 18; 1e16 = 1%, 1e15 = 0.1%, 1e14 = 0.01%
    //
    // e.g. suppose:
    //   rebateRate = 2e17 (20%), so the rebate amount is total_swap_fee * 20%.
    mapping(address => uint256) public override rebateRate;

    EnumerableSet.AddressSet private rebateAddressSet;

    // pending rebate amount in quote token
    mapping(address => uint256) public pendingRebate;

    IWooRouterV2 public wooRouter;

    address public immutable override quoteToken; // e.g. USDC or USDT
    address public rewardToken; // Any Token

    IWooAccessManager public accessManager;

    /* ----- Modifiers ----- */

    modifier onlyAdmin() {
        require(msg.sender == owner() || accessManager.isRebateAdmin(msg.sender), "WooRebateManager: !admin");
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

    function pendingRebateInQuote(address brokerAddr) external view override returns (uint256) {
        require(brokerAddr != address(0), "WooRebateManager: !brokerAddr");
        return pendingRebate[brokerAddr];
    }

    function pendingRebateInReward(address brokerAddr) external view override returns (uint256) {
        require(brokerAddr != address(0), "WooRebateManager: !brokerAddr");
        return
            rewardToken != quoteToken
                ? wooRouter.querySwap(quoteToken, rewardToken, pendingRebate[brokerAddr])
                : pendingRebate[brokerAddr];
    }

    function claimRebate() external override nonReentrant {
        if (pendingRebate[msg.sender] == 0) {
            return;
        }

        uint256 quoteAmount = pendingRebate[msg.sender];

        // Note: set the pending rebate early to make external interactions safe.
        pendingRebate[msg.sender] = 0;

        uint256 rewardAmount;
        if (rewardToken == quoteToken) {
            rewardAmount = quoteAmount;
            TransferHelper.safeTransfer(rewardToken, msg.sender, rewardAmount);
        } else {
            TransferHelper.safeApprove(quoteToken, address(wooRouter), quoteAmount);
            rewardAmount = wooRouter.swap(quoteToken, rewardToken, quoteAmount, 0, payable(msg.sender), address(0));
        }

        emit ClaimReward(msg.sender, rewardAmount);
    }

    function allRebateAddresses() external view returns (address[] memory) {
        address[] memory rebateAddresses = new address[](rebateAddressSet.length());
        unchecked {
            for (uint256 i = 0; i < rebateAddressSet.length(); ++i) {
                rebateAddresses[i] = rebateAddressSet.at(i);
            }
        }
        return rebateAddresses;
    }

    function allRebateAddressesLength() external view returns (uint256) {
        return rebateAddressSet.length();
    }

    /* ----- Admin Functions ----- */

    function addRebate(address brokerAddr, uint256 amountInUSDT) external override nonReentrant onlyAdmin {
        if (brokerAddr == address(0)) {
            return;
        }
        pendingRebate[brokerAddr] += amountInUSDT;
    }

    function setRebateRate(address brokerAddr, uint256 rate) external override onlyAdmin {
        require(brokerAddr != address(0), "WooRebateManager: brokerAddr_ZERO_ADDR");
        require(rate <= 1e18, "WooRebateManager: INVALID_USER_REWARD_RATE"); // rate <= 100%
        rebateRate[brokerAddr] = rate;
        if (rate == 0) {
            rebateAddressSet.remove(brokerAddr);
        } else {
            rebateAddressSet.add(brokerAddr);
        }
        emit RebateRateUpdated(brokerAddr, rate);
    }

    function setWooRouter(address _wooRouter) external onlyAdmin {
        wooRouter = IWooRouterV2(_wooRouter);
        require(wooRouter.wooPool().quoteToken() == quoteToken, "WooRebateManager: !wooRouter_quoteToken");
    }

    function setAccessManager(address _accessManager) external onlyOwner {
        require(_accessManager != address(0), "WooRebateManager: !_accessManager");
        accessManager = IWooAccessManager(_accessManager);
    }

    function setRewardToken(address _rewardToken) external onlyAdmin {
        require(_rewardToken != address(0), "WooRebateManager: !_rewardToken");
        rewardToken = _rewardToken;
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