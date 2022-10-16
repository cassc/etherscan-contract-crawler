// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./import/GPO.sol";
import "./utils/SwapData.sol";
import "./GPOReserve.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

contract SwapRouterV1 is Ownable {
    GPO public gpo;
    GPOReserve public gpoReserve;

    event SwapStateChanged(
        bool swapEnabled,
        address gpoReserve
    );

    bool public swapEnabled = true;
    uint256 public maxBuyTradeSize;
    uint256 public maxSellTradeSize;
    uint256 public maxSellPerTx;

    constructor(address _gpo) {
        gpo = GPO(_gpo);
    }

    function toggleSwap() public onlyOwner {
        swapEnabled = !swapEnabled;
        emit SwapStateChanged(swapEnabled, address(gpoReserve));
    }

    function setGPOReserve(address _gpoRes) public onlyOwner {
        gpoReserve = GPOReserve(_gpoRes);
        emit SwapStateChanged(swapEnabled, address(gpoReserve));
    }

    function swapToExactOutput(uint256 amountInMaximum, uint256 amountOut, uint256 deadline) external returns (uint256 amountIn) {
        require(amountInMaximum > 0 && amountOut > 0);
        require(swapEnabled);

        address _usdc = gpo.addrUSDC();
        address _gpo = address(gpo);
        address _from = msg.sender;

        TransferHelper.safeTransferFrom(_gpo, _from, address(this), amountInMaximum);

        if (maxSellTradeSize >= amountInMaximum && amountInMaximum <= maxSellPerTx) {
            TransferHelper.safeApprove(_gpo, _gpo, amountInMaximum);
            amountIn = gpo.swapToExactOutput(amountInMaximum, amountOut, deadline);
            maxSellTradeSize -= amountIn;
            TransferHelper.safeTransfer(_gpo, _from, amountInMaximum - amountIn);
            TransferHelper.safeTransfer(_usdc, _from, amountOut);
        } else
            revert("GP-SR: Order above sell trade size");
    }

    function swapToExactInput(uint256 amountIn, uint256 amountOutMinimum, uint256 deadline) external returns (uint256 amountOut) {
        require(amountIn > 0 && amountOutMinimum > 0);
        require(swapEnabled);

        address _usdc = gpo.addrUSDC();
        address _gpo = address(gpo);
        address _from = msg.sender;

        TransferHelper.safeTransferFrom(_gpo, _from, address(this), amountIn);

        if (maxSellTradeSize >= amountIn && amountIn <= maxSellPerTx) {
            TransferHelper.safeApprove(_gpo, _gpo, amountIn);
            amountOut = gpo.swapToExactInput(amountIn, amountOutMinimum, deadline);
            maxSellTradeSize -= amountIn;
            TransferHelper.safeTransfer(_usdc, _from, amountOut);
        } else
            revert("GP-SR: Order above sell trade size");
    }

    function swapFromExactOutput(uint256 amountInMaximum, uint256 amountOut, uint256 deadline) external returns (uint256 amountIn) {
        require(amountInMaximum > 0 && amountOut > 0);
        require(swapEnabled);

        address _usdc = gpo.addrUSDC();
        address _gpo = address(gpo);
        address _from = msg.sender;


        if (maxBuyTradeSize >= amountInMaximum) {
            TransferHelper.safeTransferFrom(_usdc, _from, address(this), amountInMaximum);

            TransferHelper.safeApprove(_usdc, _gpo, amountInMaximum);
            amountIn = gpo.swapFromExactOutput(amountInMaximum, amountOut, deadline);
            maxBuyTradeSize -= amountIn;
            TransferHelper.safeTransfer(_usdc, _from, amountInMaximum - amountIn);
            TransferHelper.safeTransfer(_gpo, _from, amountOut);
        }
    }

    function swapFromExactInput(uint256 amountIn, uint256 amountOutMinimum, uint256 deadline) external returns (uint256 amountOut) {
        require(amountIn > 0 && amountOutMinimum > 0);
        require(swapEnabled);

        address _usdc = gpo.addrUSDC();
        address _gpo = address(gpo);
        address _from = msg.sender;

        TransferHelper.safeTransferFrom(_usdc, _from, address(this), amountIn);

        if (maxBuyTradeSize >= amountIn) {
            TransferHelper.safeApprove(_usdc, _gpo, amountIn);
            amountOut = gpo.swapFromExactInput(amountIn, amountOutMinimum, deadline);
            maxBuyTradeSize -= amountIn;
            TransferHelper.safeTransfer(_gpo, _from, amountOut);
        } else {
            uint256 amountMinusFee = amountIn - (amountIn * gpo.feeOnSwap() / 100);
            uint256 fee = amountIn - amountMinusFee;

            amountOut = calculateGPOOut(amountMinusFee);
            
            TransferHelper.safeApprove(_usdc, address(gpoReserve), amountMinusFee);
            gpoReserve.buyGPOx(address(this), amountOut, amountMinusFee);

            TransferHelper.safeTransfer(_gpo, _from, amountOut);

            sendFeeSplit(fee);
        }
    }

    function sendFeeSplit(uint256 amount) internal {
        uint256 grandTotal = 0;
        uint256 len = gpo.feeSplitsLength();
        address addrUSDC = gpo.addrUSDC();

        for (uint256 i = 0; i < len; i++) {
            (address recipient, uint16 fee) = gpo.feeSplits(i);
            uint256 distributeAmount = amount * fee / 100;
            TransferHelper.safeTransfer(addrUSDC, recipient, distributeAmount);
            grandTotal += distributeAmount;
        }

        if (grandTotal != amount && len > 0) {
            (address recipient,) =  gpo.feeSplits(0);
            TransferHelper.safeTransfer(addrUSDC, recipient, amount - grandTotal);
        }
    }


    function canPerformSwap(bool sell, uint256 amount) public view returns(bool) {
        if (sell && amount > maxSellTradeSize && amount <= maxSellPerTx) 
            return false;
        return true;
    }

    function setTradeSizeLimitations(uint256 maxBuy, uint256 maxSell, uint256 maxSellTx) public onlyOwner {
        maxBuyTradeSize = maxBuy;
        maxSellTradeSize = maxSell;
        maxSellPerTx = maxSellTx;
    }

    function calculateGPOOut(uint256 usdc) public view returns (uint256 amountOut) {
        (int24 tick, ) = OracleLibrary.consult(gpo.authorizedPool(), 60);
        amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(usdc),
            gpo.addrUSDC(),
            address(gpo)
        );
    }

}