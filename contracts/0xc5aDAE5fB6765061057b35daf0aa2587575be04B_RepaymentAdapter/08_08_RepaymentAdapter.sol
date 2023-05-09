// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRepaymentAdapter.sol";

contract RepaymentAdapter is IRepaymentAdapter, Ownable {
    using SafeERC20 for IERC20;

    // 1. BendDAO
    // 2. X2Y2
    // 3. NFTFi
    mapping(address => int256) public permitLoanContract;

    constructor() {
        permitLoanContract[0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762] = 1;
        permitLoanContract[0xFa4D5258804D7723eb6A934c11b1bd423bC31623] = 2;
        permitLoanContract[0xE52Cec0E90115AbeB3304BaA36bc2655731f7934] = 3;
        // approve weth 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xFa4D5258804D7723eb6A934c11b1bd423bC31623);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xE52Cec0E90115AbeB3304BaA36bc2655731f7934);
        approve(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xeF887e8b1C06209F59E8Ae55D0e625C937344376);
        // approve usdc 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xFa4D5258804D7723eb6A934c11b1bd423bC31623);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xE52Cec0E90115AbeB3304BaA36bc2655731f7934);
        approve(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xeF887e8b1C06209F59E8Ae55D0e625C937344376);
        // approve dai 0x6B175474E89094C44Da98b954EedeAC495271d0F
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xFa4D5258804D7723eb6A934c11b1bd423bC31623);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xE52Cec0E90115AbeB3304BaA36bc2655731f7934);
        approve(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xeF887e8b1C06209F59E8Ae55D0e625C937344376);
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

    function batchRepayment(Repayment[] calldata repayment) public {
        for (uint256 i = 0; i < repayment.length;) {
            // todo use adapter contract or just keep it simple
            int256 flag = permitLoanContract[repayment[i].loanContract];
            bytes memory data;
            if (flag == 1) {
                require(isContract(repayment[i].collection), "Invalid collection address");
                require(repayment[i].tokenId > 0, "Invalid token id");
                require(repayment[i].amount > 0, "Invalid amount");
                data = abi.encodeWithSignature(
                    "repay(address,uint256,uint256)", repayment[i].collection, repayment[i].tokenId, repayment[i].amount
                );
            } else if (flag == 2) {
                require(repayment[i].loanId > 0, "Invalid loan id");
                data = abi.encodeWithSignature("repay(uint32)", repayment[i].loanId);
            } else if (flag == 3) {
                require(repayment[i].loanId > 0, "Invalid loan id");
                data = abi.encodeWithSignature("payBackLoan(uint32)", repayment[i].loanId);
            } else {
                revert InvalidLoanContractAddress();
            }
            uint256 preBalance = IERC20(repayment[i].currency).balanceOf(address(this));
            IERC20(repayment[i].currency).safeTransferFrom(msg.sender, address(this), repayment[i].amount);
            (bool success, bytes memory ret) = repayment[i].loanContract.call(data);
            if (!success) {
                revert InvalidContractCall(bytesToHex(ret));
            }
            uint256 postBalance = IERC20(repayment[i].currency).balanceOf(address(this));
            if (postBalance > preBalance) {
                // refund
                IERC20(repayment[i].currency).transfer(msg.sender, postBalance - preBalance);
            }

            unchecked {
                ++i;
            }
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function bytesToHex(bytes memory buffer) internal pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }
}