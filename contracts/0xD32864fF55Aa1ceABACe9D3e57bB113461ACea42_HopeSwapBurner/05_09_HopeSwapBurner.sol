// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IBurner.sol";
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

contract HopeSwapBurner is IBurner, Ownable2Step {
    event SetRouters(ISwapRouter[] _routers);

    ISwapRouter[] public routers;
    IERC20 public immutable HOPE;
    address public immutable feeVault;
    mapping(ISwapRouter => mapping(IERC20 => bool)) public approved;

    constructor(IERC20 _HOPE, address _feeVault) {
        HOPE = _HOPE;
        feeVault = _feeVault;
    }

    /**
     * @notice Set routers
     * @param _routers routers implment ISwapRouter
     */
    function setRouters(ISwapRouter[] calldata _routers) external onlyOwner {
        require(_routers.length != 0, "invalid param");
        for (uint i = 0; i < _routers.length; i++) {
            require(address(_routers[i]) != address(0), "invalid address");
        }
        routers = _routers;
        emit SetRouters(_routers);
    }

    function burn(address to, IERC20 token, uint amount, uint amountOutMin) external {
        require(msg.sender == feeVault, "LSB04");

        if (token == HOPE) {
            require(token.transferFrom(msg.sender, to, amount), "LSB00");
            return;
        }

        uint256 spendAmount = TransferHelper.doTransferFrom(address(token), msg.sender, address(this), amount);

        ISwapRouter bestRouter = routers[0];
        uint bestExpected = 0;
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(HOPE);

        for (uint i = 0; i < routers.length; i++) {
            uint[] memory expected = routers[i].getAmountsOut(spendAmount, path);
            if (expected[1] > bestExpected) {
                bestExpected = expected[1];
                bestRouter = routers[i];
            }
        }

        require(bestExpected >= amountOutMin, "LSB02");
        if (!approved[bestRouter][token]) {
            TransferHelper.doApprove(address(token), address(bestRouter), type(uint).max);
            approved[bestRouter][token] = true;
        }

        bestRouter.swapExactTokensForTokens(spendAmount, 0, path, to, block.timestamp);
    }
}