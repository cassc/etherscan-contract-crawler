// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../../swap/interfaces/IPool.sol";
import "../../assets/interfaces/IWETH.sol";
import "../../crossChain/interfaces/IWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;
    function coins(uint256 index) external returns (address);
}

contract O3EthereumCurveAggregator is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LOG_AGG_SWAP (
        uint256 amountOut,
        uint256 fee
    );

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public O3Wrapper = 0xeCF2B548e5c21028B0b60363207700fA421B6EcB;
    address public feeCollector;

    uint256 public aggregatorFee = 1 * 10**6;
    uint256 public constant FEE_DENOMINATOR = 10 ** 10;
    uint256 private constant MAX_AGGREGATOR_FEE = 5 * 10**8;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'O3Aggregator: EXPIRED');
        _;
    }

    constructor (address _feeCollector) {
        feeCollector = _feeCollector;
    }

    receive() external payable { }

    function setWETH(address _weth) external onlyOwner {
        WETH = _weth;
    }

    function setO3Wrapper(address _wrapper) external onlyOwner {
        O3Wrapper = _wrapper;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function setAggregatorFee(uint256 _fee) external onlyOwner {
        require(_fee < MAX_AGGREGATOR_FEE, "aggregator fee exceeds maximum");
        aggregatorFee = _fee;
    }

    function rescueFund(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        if (tokenAddress == WETH && address(this).balance > 0) {
            (bool success,) = _msgSender().call{value: address(this).balance}(new bytes(0));
            require(success, 'ETH_TRANSFER_FAILED');
        }
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function exchangePTokensForTokens(
        uint256 amountIn, address ptokenAddr, address ptokenPoolAddr, uint256 ptokenPoolMinDy,
        address curvePoolAddr, address[] calldata path, uint256 curvePoolMinDy,
        address toAddress, uint256 deadline, bool unwrapETH
    ) external virtual ensure(deadline) {
        uint256 amountOut = _exchangePTokensForTokens(
            amountIn, deadline, ptokenAddr, ptokenPoolAddr, ptokenPoolMinDy,
            curvePoolAddr, path, curvePoolMinDy
        );

        uint256 feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        if (unwrapETH) {
            require(path[1] == WETH, "O3Aggregator: INVALID_TO_TOKEN");
            IWETH(WETH).withdraw(amountOut);
            _sendETH(feeCollector, feeAmount);
            _sendETH(toAddress, amountOut.sub(feeAmount));
        } else {
            IERC20(path[1]).safeTransfer(feeCollector, feeAmount);
            IERC20(path[1]).safeTransfer(toAddress, amountOut.sub(feeAmount));
        }
    }

    function _exchangePTokensForTokens(
        uint256 amountIn, uint256 deadline,
        address ptokenAddr, address ptokenPoolAddr, uint256 ptokenPoolMinDy,
        address curvePoolAddr, address[] calldata path, uint256 curvePoolMinDy
    ) internal returns (uint256) {
        if (amountIn == 0) {
            amountIn = IERC20(ptokenAddr).allowance(_msgSender(), address(this));
        }

        IERC20(ptokenAddr).safeTransferFrom(_msgSender(), address(this), amountIn);

        (address underlyingToken, uint256 curveAmountIn) = _ptokenSwap(
            amountIn, ptokenAddr, ptokenPoolAddr, ptokenPoolMinDy, deadline
        );

        require(underlyingToken == path[0], "O3Aggregator: INVALID_PATH");
        return _curveSwap(curvePoolAddr, curveAmountIn, path, curvePoolMinDy);
    }

    function _ptokenSwap(
        uint256 amountIn,
        address ptokenAddr,
        address ptokenPoolAddr,
        uint256 minDy,
        uint256 deadline
    ) internal returns (address, uint256) {
        require(amountIn != 0, "O3Aggregator: amountIn cannot be zero");

        address underlyingToken = address(IPool(ptokenPoolAddr).coins(0));
        uint256 balanceBefore = IERC20(underlyingToken).balanceOf(address(this));
        IERC20(ptokenAddr).safeApprove(ptokenPoolAddr, amountIn);
        IPool(ptokenPoolAddr).swap(1, 0, amountIn, minDy, deadline);

        return (underlyingToken, IERC20(underlyingToken).balanceOf(address(this)) - balanceBefore);
    }

    function _curveSwap(
        address curvePoolAddr,
        uint256 amountIn,
        address[] calldata path,
        uint256 minDy
    ) internal returns (uint256) {
        require(amountIn != 0, "O3Aggregator: amountIn cannot be zero");
        require(path.length == 2, "O3Aggregator: INVALID_PATH");

        IERC20(path[0]).safeApprove(curvePoolAddr, amountIn);
        (int128 i, int128 j) = _getPoolTokenIndex(curvePoolAddr, path[0], path[1]);

        address toToken = ICurve(curvePoolAddr).coins(uint256(int256(j)));
        uint256 balanceBefore = IERC20(toToken).balanceOf(address(this));
        ICurve(curvePoolAddr).exchange(i, j, amountIn, minDy);

        return IERC20(toToken).balanceOf(address(this)) - balanceBefore;
    }

    function exchangeTokensForTokens(
        uint256 amountIn,
        address curvePoolAddr,
        uint256 curvePoolMinDy,
        address[] calldata path,
        address toAddress,
        uint256 deadline
    ) external virtual ensure(deadline) {
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amountIn);

        (uint256 amountOut, uint256 feeAmount) = _exchangeTokensForTokens(
            amountIn, curvePoolAddr, curvePoolMinDy, path
        );

        IERC20(path[1]).safeTransfer(feeCollector, feeAmount);
        IERC20(path[1]).safeTransfer(toAddress, amountOut.sub(feeAmount));
    }

    function _exchangeTokensForTokens(
        uint256 amountIn,
        address curvePoolAddr,
        uint256 curvePoolMinDy,
        address[] calldata path
    ) internal returns (uint256, uint256) {
        uint256 amountOut = _curveSwap(curvePoolAddr, amountIn, path, curvePoolMinDy);
        uint256 feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        return (amountOut, feeAmount);
    }

    function exchangeTokensForTokensCrossChain(
        uint256 amountIn, address curvePoolAddr, uint256 curvePoolMinDy, address[] calldata path,
        address ptokenPoolAddr, address ptokenAddr, uint256 ptokenPoolMinDy,
        uint64 toChainId, bytes memory toAddress, bytes memory callData, uint256 deadline
    ) external virtual payable ensure(deadline) {
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amountIn);

        uint256 crossChainAmount = _exchangeTokensForTokensCrossChain(
            amountIn, curvePoolAddr, curvePoolMinDy, path
        );

        IERC20(path[1]).safeApprove(O3Wrapper, crossChainAmount);

        IWrapper(O3Wrapper).swapAndBridgeOut{value: msg.value}(
            ptokenPoolAddr, path[1], ptokenAddr, crossChainAmount, ptokenPoolMinDy, deadline,
            toChainId, toAddress, callData
        );
    }

    function _exchangeTokensForTokensCrossChain(
        uint256 amountIn,
        address curvePoolAddr,
        uint256 curvePoolMinDy,
        address[] calldata path
    ) internal returns (uint256) {
        (uint256 amountOut, uint256 feeAmount) = _exchangeTokensForTokens(
            amountIn, curvePoolAddr, curvePoolMinDy, path
        );

        IERC20(path[1]).safeTransfer(feeCollector, feeAmount);

        return amountOut.sub(feeAmount);
    }

    function exchangeETHForTokens(
        address curvePoolAddr,
        address[] calldata path,
        uint256 minDy,
        address toAddress,
        uint256 deadline
    ) external payable ensure(deadline) {
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();

        require(path[0] == WETH, 'O3Aggregator: INVALID_PATH');
        uint256 amountOut = _curveSwap(curvePoolAddr, amountIn, path, minDy);
        uint256 feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        IERC20(path[1]).safeTransfer(feeCollector, feeAmount);
        IERC20(path[1]).safeTransfer(toAddress, amountOut.sub(feeAmount));
    }

    function exchangeETHForTokensCrossChain(
        address curvePoolAddr, uint256 curvePoolMinDy, address[] calldata path,
        address ptokenPoolAddr, address ptokenAddr, uint256 ptokenPoolMinDy,
        uint256 fee, uint64 toChainId, bytes memory toAddress, bytes memory callData, uint256 deadline
    ) external payable ensure(deadline) {
        IWETH(WETH).deposit{value: msg.value.sub(fee)}();

        require(path[0] == WETH, 'O3Aggregator: INVALID_PATH');
        uint256 crossChainAmount = _exchangeTokensForTokensCrossChain(
            msg.value.sub(fee), curvePoolAddr, curvePoolMinDy, path
        );

        IERC20(path[1]).safeApprove(O3Wrapper, crossChainAmount);

        IWrapper(O3Wrapper).swapAndBridgeOut{value: fee}(
            ptokenPoolAddr, path[1], ptokenAddr, crossChainAmount, ptokenPoolMinDy, deadline,
            toChainId, toAddress, callData
        );
    }

    function exchangeTokensForETH(
        uint256 amountIn,
        uint256 curvePoolMinDy,
        address curvePoolAddr,
        address[] calldata path,
        address toAddress,
        uint256 deadline
    ) external ensure(deadline) {
        require(path[1] == WETH, 'O3Aggregator: INVALID_PATH');

        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amountIn);

        uint256 amountOut = _curveSwap(curvePoolAddr, amountIn, path, curvePoolMinDy);
        uint256 feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        IWETH(WETH).withdraw(amountOut);

        _sendETH(feeCollector, feeAmount);
        _sendETH(toAddress, amountOut.sub(feeAmount));
    }

    function _sendETH(address to, uint256 amount) internal {
        (bool success,) = to.call{value:amount}(new bytes(0));
        require(success, 'O3Aggregator: ETH_TRANSFER_FAILED');
    }

    function _getPoolTokenIndex(
        address curvePoolAddr,
        address fromToken,
        address toToken
    ) internal returns (int128, int128) {
        int128 i;
        int128 j;
        bytes1 found = 0x00;

        for (uint256 idx = 0; idx < 8; idx++) {
            address coin = ICurve(curvePoolAddr).coins(idx);
            if (coin == fromToken) {
                i = int128(int256(idx));
                found |= bytes1(uint8(0x1));
            } else if (coin == toToken) {
                j = int128(int256(idx));
                found |= bytes1(uint8(0x2));
            }

            if (found == 0x03) {
                return (i, j);
            }
        }

        revert("token not pooled");
    }
}