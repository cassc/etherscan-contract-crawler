// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./interfaces/LPoolInterface.sol";
import "./libraries/TransferHelper.sol";
import "./common/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library OPBorrowingLib {
    using TransferHelper for IERC20;

    function transferIn(address from, IERC20 token, address weth, uint amount) internal returns (uint) {
        if (address(token) == weth) {
            IWETH(weth).deposit{ value: msg.value }();
            return msg.value;
        } else {
            return token.safeTransferFrom(from, address(this), amount);
        }
    }

    function doTransferOut(address to, IERC20 token, address weth, uint amount) internal {
        if (address(token) == weth) {
            IWETH(weth).withdraw(amount);
            (bool success, ) = to.call{ value: amount }("");
            require(success, "Transfer failed");
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function borrowBehalf(LPoolInterface pool, address token, address account, uint amount) internal returns (uint) {
        uint balance = balanceOf(IERC20(token));
        pool.borrowBehalf(account, amount);
        return balanceOf(IERC20(token)) - (balance);
    }

    function borrowCurrent(LPoolInterface pool, address account) internal view returns (uint256) {
        return pool.borrowBalanceCurrent(account);
    }

    function borrowStored(LPoolInterface pool, address account) internal view returns (uint256) {
        return pool.borrowBalanceStored(account);
    }

    function repay(LPoolInterface pool, address account, uint amount) internal {
        pool.repayBorrowBehalf(account, amount);
    }

    function balanceOf(IERC20 token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function decimals(address token) internal view returns (uint256) {
        return ERC20(token).decimals();
    }

    function safeApprove(IERC20 token, address spender, uint256 amount) internal {
        token.safeApprove(spender, amount);
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        token.safeTransfer(to, amount);
    }

    function amountToShare(uint amount, uint totalShare, uint reserve) internal pure returns (uint share) {
        share = totalShare > 0 && reserve > 0 ? (totalShare * amount) / reserve : amount;
    }

    function shareToAmount(uint share, uint totalShare, uint reserve) internal pure returns (uint amount) {
        if (totalShare > 0 && reserve > 0) {
            amount = (reserve * share) / totalShare;
        }
    }

    function uint32ToBytes(uint32 u) internal pure returns (bytes memory) {
        if (u < 256) {
            return abi.encodePacked(uint8(u));
        }
        return abi.encodePacked(u);
    }
}