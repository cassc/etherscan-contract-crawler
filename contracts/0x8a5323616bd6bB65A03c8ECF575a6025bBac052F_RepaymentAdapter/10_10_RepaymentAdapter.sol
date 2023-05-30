// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRepaymentAdapter.sol";
import {IWETH9} from "./IWETH9.sol";
import {IBlurPool} from "./IBlurPool.sol";

contract RepaymentAdapter is IRepaymentAdapter, Ownable {
    event Received(address, uint256);

    using SafeERC20 for IERC20;

    IWETH9 public constant WETH9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBlurPool public constant BlurPool = IBlurPool(0x0000000000A39bb272e79075ade125fd351887Ac);

    // 1. BendDAO
    // 2. X2Y2
    // 3. NFTFi
    // 4. X2Y2 V3
    // 5. Blend
    // 6. NFTFi private
    mapping(address => int256) public permitLoanContract;

    constructor() {
        permitLoanContract[0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762] = 1;
        permitLoanContract[0xFa4D5258804D7723eb6A934c11b1bd423bC31623] = 2;
        permitLoanContract[0xE52Cec0E90115AbeB3304BaA36bc2655731f7934] = 3;
        permitLoanContract[0xB81965DdFdDA3923f292a47A1be83ba3A36B5133] = 4;
        permitLoanContract[0x29469395eAf6f95920E59F858042f0e28D98a20B] = 5;
        permitLoanContract[0x8252Df1d8b29057d1Afe3062bf5a64D503152BC8] = 6;

        // approve weth 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xFa4D5258804D7723eb6A934c11b1bd423bC31623);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xE52Cec0E90115AbeB3304BaA36bc2655731f7934);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xB81965DdFdDA3923f292a47A1be83ba3A36B5133);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x29469395eAf6f95920E59F858042f0e28D98a20B);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x8252Df1d8b29057d1Afe3062bf5a64D503152BC8);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xeF887e8b1C06209F59E8Ae55D0e625C937344376);

        // approve usdc 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xFa4D5258804D7723eb6A934c11b1bd423bC31623);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xE52Cec0E90115AbeB3304BaA36bc2655731f7934);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xB81965DdFdDA3923f292a47A1be83ba3A36B5133);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x29469395eAf6f95920E59F858042f0e28D98a20B);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x8252Df1d8b29057d1Afe3062bf5a64D503152BC8);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xeF887e8b1C06209F59E8Ae55D0e625C937344376);

        // approve dai 0x6B175474E89094C44Da98b954EedeAC495271d0F
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xFa4D5258804D7723eb6A934c11b1bd423bC31623);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xE52Cec0E90115AbeB3304BaA36bc2655731f7934);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xB81965DdFdDA3923f292a47A1be83ba3A36B5133);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x29469395eAf6f95920E59F858042f0e28D98a20B);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x8252Df1d8b29057d1Afe3062bf5a64D503152BC8);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xeF887e8b1C06209F59E8Ae55D0e625C937344376);
    }

    function addPermitLoanContract(address loanContract, int256 index) public onlyOwner {
        permitLoanContract[loanContract] = index;
    }

    function approve(address currency, address operator) public onlyOwner {
        if (!isContract(currency)) {
            revert InvalidCurrencyAddress();
        }

        IERC20(currency).approve(operator, type(uint256).max);
    }

    function batchApprove(address[] calldata currencies, address operator) public onlyOwner {
        for (uint256 i = 0; i < currencies.length;) {
            approve(currencies[i], operator);
            unchecked {
                ++i;
            }
        }
    }

    function revoke(address currency, address operator) public onlyOwner {
        if (!isContract(currency)) {
            revert InvalidCurrencyAddress();
        }

        IERC20(currency).approve(operator, 0);
    }

    function batchRevoke(address[] calldata currencies, address operator) public onlyOwner {
        for (uint256 i = 0; i < currencies.length;) {
            revoke(currencies[i], operator);
            unchecked {
                ++i;
            }
        }
    }

    function withdraw(address currency, uint256 amount) public onlyOwner {
        if (currency == 0x0000000000000000000000000000000000000000) {
            (bool sent,) = msg.sender.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20(currency).transfer(msg.sender, amount);
        }
    }

    function batchRepayment(BatchRepayment[] calldata batchRepayment) public payable {
        for (uint256 i = 0; i < batchRepayment.length;) {
            int256 loanContractIndex = permitLoanContract[batchRepayment[i].loanContract];
            require(loanContractIndex > 0, "invalid loan contract");

            if (loanContractIndex != 5) {
                // if it is not blend, convert eth to weth for users
                if (msg.value > 0) {
                    WETH9.deposit{value: msg.value}();
                    WETH9.transfer(msg.sender, msg.value);
                }
                uint256 preBalance = IERC20(batchRepayment[i].currency).balanceOf(address(this));
                IERC20(batchRepayment[i].currency).safeTransferFrom(msg.sender, address(this), batchRepayment[i].amount);
                (bool success, bytes memory ret) = batchRepayment[i].loanContract.call(batchRepayment[i].data);
                if (!success) {
                    revert InvalidContractCall();
                }
                uint256 postBalance = IERC20(batchRepayment[i].currency).balanceOf(address(this));
                require(postBalance >= preBalance, "invalid amount");
                if (postBalance > preBalance) {
                    // refund
                    IERC20(batchRepayment[i].currency).transfer(msg.sender, postBalance - preBalance);
                }
            } else {
                // if it is blend, convert eth, weth to beth
                uint256 preBalance = BlurPool.balanceOf(address(this));
                if (batchRepayment[i].amount > 0) {
                    IERC20(batchRepayment[i].currency).safeTransferFrom(
                        msg.sender, address(this), batchRepayment[i].amount
                    );
                    WETH9.withdraw(batchRepayment[i].amount);
                }

                BlurPool.deposit{value: batchRepayment[i].amount + msg.value}();
                (bool success, bytes memory ret) = batchRepayment[i].loanContract.call(batchRepayment[i].data);
                if (!success) {
                    revert InvalidContractCall();
                }
                uint256 postBalance = BlurPool.balanceOf(address(this));
                require(postBalance >= preBalance, "invalid amount");
                if (postBalance > preBalance) {
                    // withdraw beth and refund
                    uint256 toWithdraw = postBalance - preBalance;
                    BlurPool.withdraw(toWithdraw);
                    payable(msg.sender).transfer(toWithdraw);
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdrawWETH(uint256 amount) public onlyOwner {
        WETH9.withdraw(amount);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}