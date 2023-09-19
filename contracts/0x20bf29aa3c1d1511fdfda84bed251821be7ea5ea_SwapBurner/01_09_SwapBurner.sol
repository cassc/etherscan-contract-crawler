// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBurner.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

interface ISwapRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SwapBurner is IBurner, Ownable2Step {
    event SetRouters(ISwapRouter[] _routers);

    ISwapRouter[] public routers;
    IERC20 public immutable HOPE;
    address public immutable feeVault;
    mapping(ISwapRouter => mapping(address => bool)) public approved; // router=>token=>bool

    constructor(IERC20 _HOPE, address _feeVault) {
        HOPE = _HOPE;
        feeVault = _feeVault;
    }

    /**
     * @notice Set routers
     * @param _routers routers implment ISwapRouter
     */
    function setRouters(ISwapRouter[] calldata _routers) external onlyOwner {
        require(_routers.length != 0, "Invalid addresses");
        for (uint i = 0; i < _routers.length; i++) {
            require(address(_routers[i]) != address(0), "Zero address not valid");
        }
        routers = _routers;
        emit SetRouters(_routers);
    }

    function burn(address to, address token, uint amount, uint amountOutMin, address[] calldata path) external {
        require(msg.sender == feeVault, "Invalid caller");

        uint256 spendAmount = TransferHelper.doTransferFrom(token, msg.sender, address(this), amount);

        ISwapRouter bestRouter = routers[0];
        uint bestExpected = 0;

        for (uint i = 0; i < routers.length; i++) {
            uint[] memory expected = routers[i].getAmountsOut(spendAmount, path);
            if (expected[path.length-1] > bestExpected) {
                bestExpected = expected[path.length-1];
                bestRouter = routers[i];
            }
        }

        require(bestExpected >= amountOutMin, "Wrong slippage");
        if (!approved[bestRouter][token]) {
            TransferHelper.doApprove(token, address(bestRouter), type(uint).max);
            approved[bestRouter][token] = true;
        }

        bestRouter.swapExactTokensForTokens(spendAmount, 0, path, to, block.timestamp);
    }
}