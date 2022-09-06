// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './interfaces/IPYESwapRouter.sol';
import './libraries/TransferHelper.sol';
import './libraries/PYESwapLibrary.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/IToken.sol';
import './FeeStore.sol';

abstract contract SupportingSwap is FeeStore, IPYESwapRouter {


    address public override factory;
    address public override WETH;
    address public override USDC;
    uint8 private maxHops = 4;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PYESwapRouter: EXPIRED');
        _;
    }

    function _swap(address _feeCheck, uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PYESwapLibrary.sortTokens(input, output);

            IPYESwapPair pair = IPYESwapPair(PYESwapLibrary.pairFor(input, output));

            uint amountOut = amounts[i + 1];
            {
                uint amountsI = amounts[i];
                address[] memory _path = path;
                address finalPath = i < _path.length - 2 ? _path[i + 2] : address(0);
                (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
                (uint amount0Fee, uint amount1Fee, uint _amount0Out, uint _amount1Out) = PYESwapLibrary._calculateFees(_feeCheck, input, output, amountsI, amount0Out, amount1Out);
                address to = i < _path.length - 2 ? PYESwapLibrary.pairFor(output, finalPath) : _to;

                pair.swap(
                    _amount0Out, _amount1Out, amount0Fee, amount1Fee, to, new bytes(0)
                );

            }
        }
    }


    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        if(amountIn == 0) { return amounts; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        address feeTaker = IPYESwapPair(pair).feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amounts[0]
        );
        amounts = PYESwapLibrary.amountsOut(amountIn, path, totalFee);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        _swap(to, amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        uint adminFeeDeduct;
        address feeTaker = IPYESwapPair(pair).feeTaker();
        uint totalFee;
        if(path[0] == pairFeeAddress[pair]) {
            
            totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;
            amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
            require(amounts[0] <= amountInMax, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');
            (, adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amounts[0], adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );

            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, amounts[0]
            );

        } else {
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, 1
            );
            totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;
            amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
            require(amounts[0] <= amountInMax, "PYESwapRouter: EXCESSIVE_INPUT_AMOUNT");
            if(feeTaker != address(0)) { IToken(feeTaker).handleFee(0, path[1]); }
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, amounts[0] - 1
            );
        }

        _swap(to, amounts, path, to);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[0] == WETH, "PYESwapRouter: INVALID_PATH");

        uint amountIn = msg.value;
        if(amountIn == 0) { return amounts; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        address feeTaker = IPYESwapPair(pair).feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn, adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn, adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }
        }

        amounts = PYESwapLibrary.amountsOut(amountIn, path, totalFee);

        require(amounts[amounts.length - 1] >= amountOutMin, "PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pair, amounts[0]));
        _swap(to, amounts, path, to);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');

        uint adminFeeDeduct;
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);
        address feeTaker = IPYESwapPair(pair).feeTaker();
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, 1
        );
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;
        amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
        require(amounts[0] <= amountInMax, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');

        if(feeTaker != address(0)) { IToken(feeTaker).handleFee(0, WETH); }
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amounts[0] - 1
        );
        
        _swap(to, amounts, path, address(this));

        uint amountETHOut = amounts[amounts.length - 1];
        if(path[1] == pairFeeAddress[pair]){
            (amountETHOut,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountETHOut,adminFee);
        }
        if(totalFee > 0) {
            amountETHOut = (amountETHOut * (10000 - totalFee)) / 10000;
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');
        if(amountIn == 0) { return amounts; }
        uint adminFeeDeduct;
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        address feeTaker = IPYESwapPair(pair).feeTaker();

        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amounts[0]
        );
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;
        amounts = PYESwapLibrary.amountsOut(amountIn, path, totalFee);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        _swap(to, amounts, path, address(this));

        uint amountETHOut = amounts[amounts.length - 1];
        if(path[1] == pairFeeAddress[pair]){
            (amountETHOut,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountETHOut,adminFee);
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[0] == WETH, 'PYESwapRouter: INVALID_PATH');

        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        address feeTaker = IPYESwapPair(pair).feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
            require(amounts[0] <= msg.value, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');

            ( ,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amounts[0], adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }

            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(pair, amounts[0]));

        } else {
            amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
            require(amounts[0] <= msg.value, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(PYESwapLibrary.pairFor(path[0], path[1]), amounts[0]));
        }

        _swap(to, amounts, path, to);
        // refund dust eth, if any
        uint bal = amounts[0] + adminFeeDeduct;
        if (msg.value > bal) TransferHelper.safeTransferETH(msg.sender, msg.value - bal);
    }


    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address _feeCheck, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PYESwapLibrary.sortTokens(input, output);

            IPYESwapPair pair = IPYESwapPair(PYESwapLibrary.pairFor(input, output));

            (uint amountInput, uint amountOutput) = PYESwapLibrary._calculateAmounts(_feeCheck, input, output, token0);
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));

            (uint amount0Fee, uint amount1Fee, uint _amount0Out, uint _amount1Out) = PYESwapLibrary._calculateFees(_feeCheck, input, output, amountInput, amount0Out, amount1Out);

            {
                address[] memory _path = path;
                address finalPath = i < _path.length - 2 ? _path[i + 2] : address(0);
                address to = i < _path.length - 2 ? PYESwapLibrary.pairFor(output, finalPath) : _to;
                pair.swap(_amount0Out, _amount1Out, amount0Fee, amount1Fee, to, new bytes(0));
            }
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        if(amountIn == 0) { return; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);
        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn,adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(to, path, to);
        if(path[1] == pairFeeAddress[pair]){
            (amountOutMin,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountOutMin,adminFee);
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    payable
    ensure(deadline)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[0] == WETH, 'PYESwapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        if(amountIn == 0) { return; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);
        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn,adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }
        }

        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pair, amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(to, path, to);
        if(path[1] == pairFeeAddress[pair]){
            (amountOutMin,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountOutMin,adminFee);
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    ensure(deadline)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');
        if(amountIn == 0) { return; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amountIn
        );
        _swapSupportingFeeOnTransferTokens(to, path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        amountOutMin;
        
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
    function setMaxHops(uint8 _maxHops) external {
        require(msg.sender == adminFeeSetter);
        require(_maxHops >= 2);
        maxHops = _maxHops;
    }
}