// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakeSwap.sol";
import "./interfaces/IAsdicFee.sol";

contract Nori is ERC20, Ownable {
    using SafeERC20 for IERC20;

    IPancakeSwapV2Router02 public pancakeRouter;
    IPancakeSwapV2Pair public pancakeSwapV2Pair;
    INoriFee public asdicFee;

    bool public entered;

    uint public sellFee;//5%
    uint constant internal PRECISION = 1000;

    constructor(address _pancakeRouter, address _mos, address to) ERC20("Nori Token", "Nori") {
        _mint(to, 1e8 * 10 ** 18);
        pancakeRouter = IPancakeSwapV2Router02(_pancakeRouter);
        address pair = IPancakeSwapV2Factory(pancakeRouter.factory())
        .createPair(address(this), _mos);
        pancakeSwapV2Pair = IPancakeSwapV2Pair(pair);
        sellFee = 50;
    }

    function setAsdicFee(address _asdicFee) public onlyOwner {
        asdicFee = INoriFee(_asdicFee);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(super.allowance(from, msg.sender) >= amount, "insufficient allowance");
        //sell
        if (to == address(pancakeSwapV2Pair) && msg.sender == address(pancakeRouter) && !entered &&
        super.balanceOf(address(pancakeSwapV2Pair)) > 0) {
            entered = true;
            uint contractGet = sellFee * amount / PRECISION;
            if (contractGet > 0) {
                super.transferFrom(from, address(asdicFee), contractGet);
                asdicFee.distributeFee(contractGet);
                amount -= contractGet;
            }
            entered = false;
        }
        super.transferFrom(from, to, amount);
        return true;
    }
}