// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./IWETH.sol";
import "../IExchange.sol";
import "../OrderLib.sol";
import "../TWAP.sol";

/**
 * Helper contract for TWAP takers
 * optionally swaps fee is to native token (ex ETH, MATIC) at fill
 */
contract Taker is Ownable {
    using SafeERC20 for ERC20;

    TWAP public immutable twap;
    address public immutable weth;

    constructor(address _twap, address _weth) {
        twap = TWAP(_twap);
        weth = _weth;
    }

    function bid(
        uint64 id,
        address exchange,
        uint256 dstFee,
        uint32 bufferPercent,
        bytes calldata data
    ) external onlyOwner {
        twap.bid(id, exchange, dstFee, bufferPercent, data);
    }

    function fill(
        uint64 id,
        address feeExchange,
        uint256 feeMinAmountOut,
        bytes calldata feeData
    ) external onlyOwner {
        twap.fill(id);
        OrderLib.Order memory o = twap.order(id);

        if (o.ask.dstToken != weth && feeExchange != address(0)) {
            uint256 dstAmount = ERC20(o.ask.dstToken).balanceOf(address(this));
            ERC20(o.ask.dstToken).safeIncreaseAllowance(feeExchange, dstAmount);
            IExchange(feeExchange).swap(dstAmount, feeMinAmountOut, feeData);
        }

        rescue(o.ask.dstToken);
    }

    function rescue(address token) public {
        if (ERC20(weth).balanceOf(address(this)) > 0) {
            IWETH(weth).withdraw(ERC20(weth).balanceOf(address(this)));
        }

        if (address(this).balance > 0) {
            Address.sendValue(payable(owner()), address(this).balance);
        }

        if (token != address(0) && ERC20(token).balanceOf(address(this)) > 0) {
            ERC20(token).safeTransfer(owner(), ERC20(token).balanceOf(address(this)));
        }
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks
}