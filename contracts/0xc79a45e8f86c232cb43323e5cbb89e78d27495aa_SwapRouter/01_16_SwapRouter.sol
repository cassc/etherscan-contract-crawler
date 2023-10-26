// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISwapRouter.sol";
import "../interfaces/ISwitchEvent.sol";
import "../interfaces/IUniswapFactory.sol";
import "./IWETH.sol";
import "../lib/UniswapExchangeLib.sol";
import "../lib/DataTypes.sol";

contract SwapRouter is Ownable, ISwapRouter {
    using UniswapExchangeLib for IUniswapExchange;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    ISwitchEvent public switchEvent;
    uint256 public dexCount;
    uint256 public pathCount;
    uint256 public pathSplit;
    IWETH public weth; // chain's native token
    IWETH public otherToken; //could be weth on a non-eth chain or other mid token(like busd)
    address public paraswapProxy;
    address public augustusSwapper;
    address[] public factories;

    event SwitchEventSet(address switchEvent);
    event ParaswapProxySet(address paraswapProxy);
    event AugustusSwapperSet(address augustusSwapper);
    event WETHSet(address _weth);
    event OtherTokenSet(address _otherToken);
    event PathCountSet(uint256 _pathCount);
    event PathSplitSet(uint256 _pathSplit);
    event FactoriesSet(address[] _factories);

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper
    ) {
        switchEvent = ISwitchEvent(_switchEventAddress);
        paraswapProxy = _paraswapProxy;
        augustusSwapper = _augustusSwapper;

        weth = IWETH(_weth);
        otherToken = IWETH(_otherToken);
        pathCount = _pathCount;
        pathSplit = _pathSplit;
        dexCount = _factories.length;

        for (uint256 i; i < dexCount; ) {
            factories.push(_factories[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @inheritdoc ISwapRouter
    function swap(SwapRequest calldata swapRequest)
        external
        payable
        override
        returns (uint256 unspent, uint256 returnAmount)
    {
        uint256 prevDstBal = swapRequest.dstToken.universalBalanceOf(
            address(this)
        );

        require(swapRequest.amountIn != 0, "zero");
        swapRequest.srcToken.universalTransferFrom(
            msg.sender,
            address(this),
            swapRequest.amountIn
        );

        uint256 prevSrcBal = swapRequest.srcToken.universalBalanceOf(
            address(this)
        ) - swapRequest.amountIn;

        uint256 spentAmount;
        // If amountIn is less than minimum, we couldn't use any aggregator
        if (swapRequest.amountIn >= swapRequest.amountMinSpend) {
            require(
                !swapRequest.useParaswap ||
                    _swapOnParaswap(
                        swapRequest.srcToken,
                        swapRequest.amountIn,
                        swapRequest.paraswapData
                    ) ||
                    !swapRequest.raiseError,
                "Paraswap swap failed"
            );

            _swapExternal(
                swapRequest.srcToken,
                swapRequest.splitSwapData,
                swapRequest.raiseError
            );

            uint256 currSrcBal = swapRequest.srcToken.universalBalanceOf(
                address(this)
            );
            require(currSrcBal >= prevSrcBal, "Too much swapped");
            spentAmount = prevSrcBal + swapRequest.amountIn - currSrcBal;
        }

        if (
            swapRequest.distribution.length != 0 &&
            swapRequest.distribution.length < dexCount * pathCount &&
            swapRequest.amountIn != spentAmount
        ) {
            _swapForSingleSwap(
                swapRequest.srcToken,
                swapRequest.dstToken,
                swapRequest.amountIn - spentAmount,
                swapRequest.distribution,
                swapRequest.raiseError
            );
        }

        uint256 finalSrcBal = swapRequest.srcToken.universalBalanceOf(
            address(this)
        );
        uint256 finalDstBal = swapRequest.dstToken.universalBalanceOf(
            address(this)
        );

        unspent = finalSrcBal - prevSrcBal;
        returnAmount = finalDstBal - prevDstBal;

        if (unspent != 0) {
            swapRequest.srcToken.universalTransfer(msg.sender, unspent);
        }

        if (returnAmount != 0) {
            swapRequest.dstToken.universalTransfer(msg.sender, returnAmount);
        }

        require(returnAmount >= swapRequest.amountOutMin);
    }

    function _swapOnParaswap(
        IERC20 token,
        uint256 amount,
        bytes memory callData
    ) internal returns (bool success) {
        if (callData.length == 0) {
            return true;
        }
        uint256 value;
        if (token.isETH()) {
            value = amount;
        } else {
            token.universalApprove(paraswapProxy, amount);
        }

        (success, ) = augustusSwapper.call{value: value}(callData);
    }

    function _swapExternal(
        IERC20 srcToken,
        DataTypes.SplitSwapInfo[] memory splitSwapData,
        bool raiseError
    ) internal {
        if (splitSwapData.length != 0) {
            uint256 len = splitSwapData.length;
            for (uint256 i; i < len; ) {
                try this.swapExternal(srcToken, splitSwapData[i]) {} catch {
                    require(!raiseError, "External swap failed");
                }

                unchecked {
                    i++;
                }
            }
        }
    }

    function swapExternal(
        IERC20 srcToken,
        DataTypes.SplitSwapInfo memory splitSwapData
    ) external {
        require(
            msg.sender == address(this),
            "Msg.sender can be contract it self"
        );

        if (splitSwapData.spender == address(0) && !srcToken.isETH()) {
            // Manually transfer instead of approve
            srcToken.universalTransfer(
                splitSwapData.swapContract,
                splitSwapData.amount
            );
        } else {
            srcToken.universalApprove(
                splitSwapData.spender,
                splitSwapData.amount
            );
        }
        (bool success, ) = splitSwapData.swapContract.call{
            value: srcToken.isETH() ? splitSwapData.amount : 0
        }(splitSwapData.swapData);

        require(success, "External swap failed");
    }

    function _swapForSingleSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256[] memory distribution,
        bool raiseError
    ) private returns (uint256 returnAmount, uint256 parts) {
        uint256 lastNonZeroIndex = 0;
        uint256 len = distribution.length;
        for (uint256 i; i < len; ) {
            if (distribution[i] > 0) {
                parts += distribution[i];
                lastNonZeroIndex = i;
            }

            unchecked {
                i++;
            }
        }

        require(parts > 0 || !raiseError, "invalid distribution param");

        // break function to avoid stack too deep error
        returnAmount = _swapInternalForSingleSwap(
            distribution,
            amount,
            parts,
            lastNonZeroIndex,
            srcToken,
            dstToken
        );
        require(returnAmount > 0 || !raiseError, "Swap failed from dex");

        switchEvent.emitSwapped(
            msg.sender,
            address(this),
            IERC20(srcToken),
            IERC20(dstToken),
            amount,
            returnAmount,
            0
        );
    }

    function _swapInternalForSingleSwap(
        uint256[] memory distribution,
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        IERC20 fromToken,
        IERC20 dstToken
    ) internal returns (uint256 totalAmount) {
        uint256 remainingAmount = amount;
        uint256 swappedAmount = 0;
        uint256 len = distribution.length;
        for (uint256 i; i < len; i++) {
            if (distribution[i] == 0) {
                continue;
            }
            uint256 swapAmount = (amount * distribution[i]) / parts;
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            if (i % pathCount == 0) {
                swappedAmount = _swap(
                    fromToken,
                    dstToken,
                    swapAmount,
                    IUniswapFactory(factories[i / pathCount])
                );
            } else if (i % pathCount == 1) {
                swappedAmount = _swapETH(
                    fromToken,
                    dstToken,
                    swapAmount,
                    IUniswapFactory(factories[i / pathCount])
                );
            } else {
                swappedAmount = _swapOtherToken(
                    fromToken,
                    dstToken,
                    swapAmount,
                    IUniswapFactory(factories[i / pathCount])
                );
            }
            totalAmount += swappedAmount;
        }
    }

    // Swap helpers
    function _swapInternal(
        IERC20 fromToken,
        IERC20 dstToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal returns (uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit{value: amount}();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = dstToken.isETH() ? weth : dstToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(
            fromTokenReal,
            toTokenReal,
            amount
        );
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(0x46Fd07da395799F113a7584563b8cB886F33c2bc);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint160(address(fromTokenReal)) < uint160(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (dstToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 dstToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal returns (uint256 returnAmount) {
        returnAmount = _swapInternal(
            midToken,
            dstToken,
            _swapInternal(fromToken, midToken, amount, factory),
            factory
        );
    }

    function _swap(
        IERC20 fromToken,
        IERC20 dstToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal returns (uint256 returnAmount) {
        returnAmount = _swapInternal(fromToken, dstToken, amount, factory);
    }

    function _swapETH(
        IERC20 fromToken,
        IERC20 dstToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal returns (uint256 returnAmount) {
        returnAmount = _swapOverMid(fromToken, weth, dstToken, amount, factory);
    }

    function _swapOtherToken(
        IERC20 fromToken,
        IERC20 dstToken,
        uint256 amount,
        IUniswapFactory factory
    ) internal returns (uint256 returnAmount) {
        returnAmount = _swapOverMid(
            fromToken,
            otherToken,
            dstToken,
            amount,
            factory
        );
    }

    function setWETH(address _weth) external onlyOwner {
        weth = IWETH(_weth);
        emit WETHSet(_weth);
    }

    function setOtherToken(address _otherToken) external onlyOwner {
        otherToken = IWETH(_otherToken);
        emit OtherTokenSet(_otherToken);
    }

    function setPathCount(uint256 _pathCount) external onlyOwner {
        pathCount = _pathCount;
        emit PathCountSet(_pathCount);
    }

    function setPathSplit(uint256 _pathSplit) external onlyOwner {
        pathSplit = _pathSplit;
        emit PathSplitSet(_pathSplit);
    }

    function setFactories(address[] memory _factories) external onlyOwner {
        dexCount = _factories.length;
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
        }
        emit FactoriesSet(_factories);
    }

    receive() external payable {}
}