// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ICurve.sol";
import "../interfaces/IStETH.sol";
import "../interfaces/IWstETH.sol";
import "../interfaces/IExchange.sol";
import "../../utils/TransferHelper.sol";

contract ETHLeverExchange is Ownable, IExchange {
    address public leverSS;

    address public weth;

    address public curvePool;

    address public stETH;

    constructor(
        address _weth,
        address _leverSS,
        address _curvePool,
        address _stETH
    ) {
        weth = _weth;
        stETH = _stETH;
        leverSS = _leverSS;
        curvePool = _curvePool;
    }

    receive() external payable {}

    modifier onlyLeverSS() {
        require(_msgSender() == leverSS, "ONLY_LEVER_VAULT_CALL");
        _;
    }
    
    function swapStETH(address token,uint256 amount,uint256 minAmount) external override onlyLeverSS {
        require(address(this).balance >= amount, "INSUFFICIENT_ETH");

        if (token != stETH){
            minAmount = IWstETH(token).getStETHByWstETH(minAmount);
        } 
        uint256 curveOut = ICurve(curvePool).get_dy(0, 1, amount);
        if (curveOut < amount) {
            IStETH(stETH).submit{value: address(this).balance}(address(this));
        } else {
            require(curveOut>=minAmount,"ETH_STETH_SLIPPAGE");
            ICurve(curvePool).exchange{value: address(this).balance}(
                0,
                1,
                amount,
                minAmount
            );
        }
        uint256 stETHBal = IERC20(stETH).balanceOf(address(this));
        if (token != stETH){
            IERC20(stETH).approve(token, 0);
            IERC20(stETH).approve(token, stETHBal);
            IWstETH(token).wrap(stETHBal);
            stETHBal = IERC20(token).balanceOf(address(this));
        }
        // Transfer STETH to LeveraSS
        TransferHelper.safeTransfer(token, leverSS, stETHBal);
    }

    function swapETH(address token,uint256 amount,uint256 minAmount) external override onlyLeverSS {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "INSUFFICIENT_STETH"
        );
        if (token != stETH){
            IWstETH(token).unwrap(amount);
            amount = IERC20(stETH).balanceOf(address(this));
        }
        // Approve STETH to curve
        IERC20(stETH).approve(curvePool, 0);
        IERC20(stETH).approve(curvePool, amount);
        ICurve(curvePool).exchange(1, 0, amount, minAmount);

        uint256 ethBal = address(this).balance;

        // Transfer STETH to LeveraSS
        TransferHelper.safeTransferETH(leverSS, ethBal);
    }
    /*
    function swapExactETH(
        uint256 input,
        uint256 output
    ) external override onlyLeverSS {
        require(
            IERC20(stETH).balanceOf(_msgSender()) >= input,
            "INSUFFICIENT_STETH"
        );
        require(
            IERC20(stETH).allowance(_msgSender(), address(this)) >= input,
            "INSUFFICIENT_ALLOWANCE"
        );

        // ETH output
        uint256 ethOut = ICurve(curvePool).get_dy(1, 0, input);
        require(ethOut >= output, "EXTREME_MARKET");

        // StETH percentage
        uint256 toSwap = (input * output) / ethOut;

        // Transfer STETH from SS to exchange
        TransferHelper.safeTransferFrom(
            stETH,
            _msgSender(),
            address(this),
            toSwap
        );

        // Approve STETH to curve
        IERC20(stETH).approve(curvePool, 0);
        IERC20(stETH).approve(curvePool, toSwap);
        ICurve(curvePool).exchange(1, 0, toSwap, output);

        uint256 ethBal = address(this).balance;

        require(ethBal >= output, "STETH_ETH_SLIPPAGE");

        // Transfer STETH to LeveraSS
        TransferHelper.safeTransferETH(leverSS, ethBal);
    }
    */
}