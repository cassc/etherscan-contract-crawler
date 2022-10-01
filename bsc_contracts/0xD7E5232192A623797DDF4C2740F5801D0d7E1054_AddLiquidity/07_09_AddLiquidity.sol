// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IPancakeRouter.sol";
import "hardhat/console.sol";

contract AddLiquidity is Ownable {
    using SafeERC20 for IERC20;

    IPancakeRouter02 public router =
        IPancakeRouter02(address(0x10ED43C718714eb63d5aA57B78B54704E256024E));

    IERC20 public palm =
        IERC20(address(0x29745314B4D294B7C77cDB411B8AAa95923aae38));

    address public lp = address(0x044066f6Ce410407CC738d0feb5E40b5ab69e83a);

    function getAmount(uint256 initialAmount, uint256 palmAmount)
        external
        view
        returns (uint256)
    {
        uint256 bnbBal = IERC20(router.WETH()).balanceOf(lp);
        uint256 palmBal = palm.balanceOf(lp);

        console.log(palmBal);
        console.log(initialAmount);
        if (palmBal < initialAmount) {
            uint256 addPalm = initialAmount - palmBal;
            console.log(bnbBal);
            uint256 receiveBnb = router.getAmountOut(addPalm, palmBal, bnbBal);

            console.log(addPalm);
            // return 0;
            return (palmAmount * (bnbBal - receiveBnb)) / initialAmount;
        } else {
            uint256 removePalm = palmBal - initialAmount;
            uint256 receiveBnb = router.getAmountIn(
                removePalm,
                bnbBal,
                palmBal
            );

            return (palmAmount * (bnbBal + receiveBnb)) / initialAmount;
        }
    }

    function add(uint256 initialAmount, uint256 palmAmount) external payable {
        uint256 bnbBal = IERC20(router.WETH()).balanceOf(lp);
        uint256 palmBal = palm.balanceOf(lp);

        palm.safeTransferFrom(msg.sender, address(this), palmAmount);

        if (palmBal < initialAmount) {
            uint256 addPalm = initialAmount - palmBal;

            address[] memory path = new address[](2);
            path[0] = address(palm);
            path[1] = router.WETH();

            router.swapExactTokensForETH(
                addPalm,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 bnbBal = IERC20(router.WETH()).balanceOf(lp);
            uint256 palmBal = palm.balanceOf(lp);

            uint256 remainingPalmAmount = palm.balanceOf(address(this));
            uint256 requiredBnb = (remainingPalmAmount * bnbBal) / palmBal;

            router.addLiquidityETH{value: requiredBnb}(
                address(palm),
                remainingPalmAmount,
                0,
                requiredBnb,
                address(this),
                block.timestamp
            );
        }
    }

    function recover(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(recipient, amount);
    }

    function recoverBnb(address recipient, uint256 amount) external onlyOwner {
        recipient.call{value: amount}("");
    }
}