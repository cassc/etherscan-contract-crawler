// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;
pragma abicoder v2;

import "./Utils.sol";
import "./Libs.sol";

contract AffinitySwapperV3 is ReentrancyGuard, Ownable, PeripheryValidation {
    using Path for bytes;
    using BytesLib for bytes;

    uint public fee; //100 =1%
    uint public standardization = 10000;
    address payable public feeWallet;
    // ETH
    address public WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // // Georli
    // address public WETH9 = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    ISwapRouter public _swapRouter;

    IV3SwapRouter public _v3SwapRouter;

    event exactInputSwapped(
        address _tokenIn,
        address _tokenOut,
        address _to,
        uint256 _amountIn,
        uint256 _amountOut
    );

    constructor() {
        // replace fee and wallet
        fee = 75;
        feeWallet = payable(0xcc4A1aD4a623d5D4a6fCB1b1A581FFFeb8727Dc5);

        // uniswap v3 router address
        _swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        _v3SwapRouter = IV3SwapRouter(
            0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
        );
    }

    receive() external payable {}

    function swapExactInputSingle(
        ISwapRouter.ExactInputSingleParams memory params
    )
        external
        payable
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 amountOut)
    {
        uint16 tokenInType = getTokenType(params.tokenIn, params.amountIn);
        require(tokenInType != 0, "invalid token in");
        uint256 feeAmt = (params.amountIn * fee) / standardization;
        uint256 amountIn = params.amountIn;
        address recipient = params.recipient;
        params.amountIn = params.amountIn - feeAmt;

        if (tokenInType == 1) {
            // from ETH
            TransferHelper.safeTransferETH(address(this), params.amountIn);
            amountOut = _swapRouter.exactInputSingle{value: params.amountIn}(
                params
            );
            TransferHelper.safeTransferETH(feeWallet, feeAmt);
        } else {
            // from ERC20
            TransferHelper.safeTransferFrom(
                params.tokenIn,
                msg.sender,
                address(this),
                params.amountIn
            );
            TransferHelper.safeApprove(
                params.tokenIn,
                address(_swapRouter),
                params.amountIn
            );
            if (params.tokenOut == WETH9) {
                params.recipient = address(this);
                amountOut = _swapRouter.exactInputSingle(params);
                IWETH(WETH9).withdraw(amountOut);
                TransferHelper.safeTransferETH(recipient, amountOut);
                // _swapRouter.unwrapWETH9(amountOut, recipient);
            } else {
                amountOut = _swapRouter.exactInputSingle(params);
            }
            TransferHelper.safeTransferFrom(
                params.tokenIn,
                msg.sender,
                feeWallet,
                feeAmt
            );
        }

        emit exactInputSwapped(
            params.tokenIn,
            params.tokenOut,
            recipient,
            amountIn,
            amountOut
        );
    }

    function swapExactInputSingleV3(
        IV3SwapRouter.ExactInputSingleParams memory params
    ) external payable nonReentrant returns (uint256 amountOut) {
        uint16 tokenInType = getTokenType(params.tokenIn, params.amountIn);
        require(tokenInType != 0, "invalid token in");
        uint256 feeAmt = (params.amountIn * fee) / standardization;
        uint256 amountIn = params.amountIn;
        address recipient = params.recipient;
        params.amountIn = params.amountIn - feeAmt;

        if (tokenInType == 1) {
            //from ETH
            TransferHelper.safeTransferETH(address(this), params.amountIn);
            amountOut = _v3SwapRouter.exactInputSingle{value: params.amountIn}(
                params
            );
            TransferHelper.safeTransferETH(feeWallet, feeAmt);
        } else {
            //from ERC20
            TransferHelper.safeTransferFrom(
                params.tokenIn,
                msg.sender,
                address(this),
                params.amountIn
            );
            TransferHelper.safeApprove(
                params.tokenIn,
                address(_v3SwapRouter),
                params.amountIn
            );
            if (params.tokenOut == WETH9) {
                params.recipient = address(this);
                amountOut = _v3SwapRouter.exactInputSingle(params);
                IWETH(WETH9).withdraw(amountOut);
                TransferHelper.safeTransferETH(recipient, amountOut);
            } else {
                amountOut = _v3SwapRouter.exactInputSingle(params);
            }
            TransferHelper.safeTransferFrom(
                params.tokenIn,
                msg.sender,
                feeWallet,
                feeAmt
            );
        }

        emit exactInputSwapped(
            params.tokenIn,
            params.tokenOut,
            recipient,
            amountIn,
            amountOut
        );
    }

    function swapExactInput(
        ISwapRouter.ExactInputParams memory params
    )
        external
        payable
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 amountOut)
    {
        bool hasMultiplePools = params.path.hasMultiplePools();
        require(hasMultiplePools, "invalid params");
        (address tokenIn, , ) = params.path.decodeFirstPool();
        uint16 tokenInType = getTokenType(tokenIn, params.amountIn);
        require(tokenInType != 0, "invalid token in");

        address finalTokenOut = getTokenOut(params.path);
        uint256 feeAmt = (params.amountIn * fee) / standardization;
        uint256 amountIn = params.amountIn;
        address recipient = params.recipient;
        params.amountIn = params.amountIn - feeAmt;

        if (tokenInType == 1) {
            //from ETH
            TransferHelper.safeTransferETH(address(this), params.amountIn);
            amountOut = _swapRouter.exactInput{value: params.amountIn}(params);
            TransferHelper.safeTransferETH(feeWallet, feeAmt);
        } else {
            //from ERC20
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                params.amountIn
            );
            TransferHelper.safeApprove(
                tokenIn,
                address(_swapRouter),
                params.amountIn
            );
            if (finalTokenOut == WETH9) {
                params.recipient = address(this);
                amountOut = _swapRouter.exactInput(params);
                IWETH(WETH9).withdraw(amountOut);
                TransferHelper.safeTransferETH(recipient, amountOut);
            } else {
                amountOut = _swapRouter.exactInput(params);
            }
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                feeWallet,
                feeAmt
            );
        }

        emit exactInputSwapped(
            tokenIn,
            finalTokenOut,
            recipient,
            amountIn,
            amountOut
        );
    }

    function swapExactInputV3(
        IV3SwapRouter.ExactInputParams memory params
    ) external payable nonReentrant returns (uint256 amountOut) {
        bool hasMultiplePools = params.path.hasMultiplePools();
        require(hasMultiplePools, "invalid params");
        (address tokenIn, , ) = params.path.decodeFirstPool();

        uint16 tokenInType = getTokenType(tokenIn, params.amountIn);
        require(tokenInType != 0, "invalid token in");

        address finalTokenOut = getTokenOut(params.path);
        uint256 feeAmt = (params.amountIn * fee) / standardization;
        uint256 amountIn = params.amountIn;
        address recipient = params.recipient;
        params.amountIn = params.amountIn - feeAmt;

        if (tokenInType == 1) {
            //from ETH
            TransferHelper.safeTransferETH(address(this), params.amountIn);
            amountOut = _v3SwapRouter.exactInput{value: params.amountIn}(
                params
            );
            TransferHelper.safeTransferETH(feeWallet, feeAmt);
        } else {
            //from ERC20
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                params.amountIn
            );
            TransferHelper.safeApprove(
                tokenIn,
                address(_v3SwapRouter),
                params.amountIn
            );
            if (finalTokenOut == WETH9) {
                params.recipient = address(this);
                amountOut = _v3SwapRouter.exactInput(params);
                IWETH(WETH9).withdraw(amountOut);
                TransferHelper.safeTransferETH(recipient, amountOut);
            } else {
                amountOut = _v3SwapRouter.exactInput(params);
            }
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                feeWallet,
                feeAmt
            );
        }

        emit exactInputSwapped(
            tokenIn,
            finalTokenOut,
            recipient,
            amountIn,
            amountOut
        );
    }

    /** 
    View Functions
    **/

    function getTokenOut(
        bytes memory path
    ) public pure returns (address tokenOut) {
        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();
            if (!hasMultiplePools) {
                (, address tokenB, ) = path.decodeFirstPool();
                return tokenB;
            }
            path = path.skipToken();
        }
    }

    // return 1: from eth 2: from erc20 0: error
    function getTokenType(
        address tokenAddr,
        uint256 amountIn
    ) internal view returns (uint16 result) {
        if (tokenAddr == WETH9 && msg.value > 0 && msg.value >= amountIn)
            return 1;
        if (tokenAddr != WETH9 && amountIn > 0 && msg.value == 0) return 2;
        return 0;
    }

    /*
     **Admin Functions
     */
    function setFee(uint _val) external onlyOwner {
        require(_val < 1000, "Max Fee is 10%");
        fee = _val;
    }

    function setFeeWallet(address _newFeeWallet) external onlyOwner {
        feeWallet = payable(_newFeeWallet);
    }

    function setWETH(address _newETH) external onlyOwner {
        WETH9 = _newETH;
    }

    function setRouterAddress(address _newSwapRouterAddr) external onlyOwner {
        _swapRouter = ISwapRouter(_newSwapRouterAddr);
    }

    function setV3RouterAddress(
        address _newV3SwapRouterAddr
    ) external onlyOwner {
        _v3SwapRouter = IV3SwapRouter(_newV3SwapRouterAddr);
    }

    function withdrawERC20(
        address _tokenAddr,
        uint amounts
    ) external onlyOwner {
        TransferHelper.safeTransferFrom(
            _tokenAddr,
            address(this),
            feeWallet,
            amounts
        );
    }

    function withdrawETH(uint amounts) external onlyOwner {
        TransferHelper.safeTransferETH(feeWallet, amounts);
    }
}
