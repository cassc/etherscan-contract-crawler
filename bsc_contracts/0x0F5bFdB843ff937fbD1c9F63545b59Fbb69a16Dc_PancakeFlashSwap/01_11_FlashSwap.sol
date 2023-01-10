// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

import "hardhat/console.sol";

// Uniswap interface and library imports
import "./libraries/UniswapV2Library.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC20.sol";

contract PancakeFlashSwap {
    using SafeERC20 for IERC20;

    // Factory and Routing Addresses BSC MAINNET
    address private constant PANCAKE_FACTORY =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Para prestamos FL
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; // Para prestamos en WBNB

    // Token Addresses
    address private A;
    address private B;
    address private C;

    // Trade Variables
    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // uint256 private constant MAX_INT = 1e30;

    function testFunction() public returns (address) {
        emit EventMessage("testFunction", 1234, CAKE);
        console.log("PancakeFlashSwap.sol testFunction");
        return CAKE;
    }

    //  EVENT
    event EventMessage(string msg, uint256 value, address Address);

    // GET CONTRACT BALANCE
    // Allows public view of balance for contract
    function getBalanceOfToken(
        address _addressToken
    ) public view returns (uint256) {
        return IERC20(_addressToken).balanceOf(address(this));
    }

    // PLACE A TRADE
    // Executed placing a trade
    function placeTrade(
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        address recipient
    ) private returns (uint256) {
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(
            _fromToken,
            _toToken
        );
        require(pair != address(0), "Pool does not exist");

        // Calculate Amount Out from One token to Another
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(PANCAKE_ROUTER)
            .getAmountsOut(_amountIn, path)[1];

        // console.log("amountRequired", amountRequired);
        uint256 deadline = block.timestamp + 300;

        // Perform Arbitrage - Swap for another token
        uint256 amountReceived = IUniswapV2Router01(PANCAKE_ROUTER)
            .swapExactTokensForTokens(
                _amountIn, // amountIn
                amountRequired, // amountOutMin
                path, // path
                recipient, // address to
                deadline // deadline
            )[1];

        console.log("PancakeFlashSwap.sol BREAKPOINT 3");
        // console.log("amountRecieved", amountReceived);

        require(amountReceived > 0, "Aborted Tx: Trade returned zero");

        return amountReceived;
    }

    // CHECK PROFITABILITY
    // Checks whether > output > input
    function checkProfitability(
        uint256 _input,
        uint256 _output
    ) private pure returns (bool) {
        return _output > _input;
    }

    function startArbitrage(
        address _A,
        address _B,
        address _C,
        uint256 _LoanAmount
    ) external payable {
        A = _A;
        B = _B;
        C = _C;
        // _tokenBorrow : First Token (A) to be Loaned to us
        // _amount0 : A amount borrowed by us
        // Apprve Router to trade on oour behalf
        IERC20(A).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(B).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(C).safeApprove(address(PANCAKE_ROUTER), MAX_INT);

        // Get the Factory Pair adess for combined Tokens - PAIR Between A and WBNB
        address pair;
        if (A != WBNB) {
            pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(A, WBNB);
        } else {
            IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER), MAX_INT);

            pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(A, CAKE);
        }

        // Figure out wich token (0 or 1) has the amount and assing
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = A == token0 ? _LoanAmount : 0;
        uint256 amount1Out = A == token1 ? _LoanAmount : 0;

        // Pasing data as bytes so that the 'swap' function knows it is a flashloan
        bytes memory data = abi.encode(_LoanAmount);

        // Execute the initial swap to get the loan - FLASH LOAN INIT
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data); // FLASH LOAN - (FL-A)

        uint256 A_balance = getBalanceOfToken(A);
        console.log("PancakeFlashSwap.sol A_balance= ", A_balance);
        //PAY IN WBNB
        placeTrade(A, WBNB, A_balance, msg.sender); // Trade A for WBNB and send it to wallet on the same transaction

        // PAY IN BNB
        // swapTokensForETH(A, A_balance, PANCAKE_ROUTER, msg.sender);
        // SET TO ZERO safeApprove
        IERC20(A).safeApprove(address(PANCAKE_ROUTER), 0);
        IERC20(B).safeApprove(address(PANCAKE_ROUTER), 0);
        IERC20(C).safeApprove(address(PANCAKE_ROUTER), 0);
        IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER), 0);
    }

    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        // Ensure this request came from the contract
        // _sender = PancakeFlashSwap.sol address
        //msg.sender = Pair.address
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(
            token0,
            token1
        );
        require(msg.sender == pair, "The sender needs to match the pair");
        require(_sender == address(this), "Sender should match this contract");

        console.log("PancakeFlashSwap.sol ", msg.sender, "==", pair);
        // Decode data for calculating the repayment
        uint256 _LoanAmount = abi.decode(_data, (uint256));

        // Calculate the amount to repay at the end
        uint256 fee = ((_LoanAmount * 3) / 997) + 1; // Comision 0.03%
        uint256 amountToRepay = _LoanAmount + fee; // 100 + 0.03 = 100.03
        console.log("PancakeFlashSwap.sol _LoanAmount= ", _LoanAmount);
        console.log("PancakeFlashSwap.sol fee= ", fee);
        console.log(
            "PancakeFlashSwap.sol amountToRepay= _LoanAmount + fee = ",
            amountToRepay
        );

        // DO ARBITRAGE

        // Assign loan amount
        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;

        // Place Trades
        console.log("PancakeFlashSwap.sol A = ", A);
        console.log("PancakeFlashSwap.sol B = ", B);
        console.log("PancakeFlashSwap.sol C = ", C);

        uint256 B_amount = placeTrade(A, B, loanAmount, address(this)); // (A-B)
        console.log("PancakeFlashSwap.sol B_amount = ", B_amount);

        uint256 C_amount = placeTrade(B, C, B_amount, address(this)); // (B-C)
        console.log("PancakeFlashSwap.sol C_amount = ", C_amount);

        uint256 A_amount = placeTrade(C, A, C_amount, address(this)); // (C-A) 102.0
        console.log("PancakeFlashSwap.sol A_amount= ", A_amount);
        console.log("PancakeFlashSwap.sol amountToRepay= ", amountToRepay);

        // Check Profitability
        bool profCheck = checkProfitability(amountToRepay, A_amount); // 100.03 < 102, Cnatidad final > prestamo + interes
        console.log("PancakeFlashSwap.sol  profCheck= ", profCheck);

        // require(profCheck, "Arbitrage not profitable");//////////////////////////////////////////////////////////////////////////

        console.log("PancakeFlashSwap.sol PAY FLASH LOAN BACK");

        // PAY FLASH LOAN BACK - FLASH LOAN END
        IERC20(A).transfer(pair, amountToRepay);

        console.log("PancakeFlashSwap.sol pancakeCall END");
    }

    function swapTokensForETH(
        address tokenIn,
        uint256 amountTokenIn,
        address router,
        address MyWallet
    ) public returns (uint256) {
        IERC20(tokenIn).approve(router, amountTokenIn);
        uint256 allowedAmount = IERC20(tokenIn).allowance(
            address(this),
            router
        );

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = IUniswapV2Router02(router).WETH();

        console.log("swapExactTokensForETH allowedAmount", allowedAmount);
        console.log("swapExactTokensForETH path[0]", path[0]);
        console.log("swapExactTokensForETH path[1]", path[1]);
        try
            IUniswapV2Router02(router).swapExactTokensForETH(
                allowedAmount,
                0,
                path,
                MyWallet,
                block.timestamp
            )
        {
            //get the ETHBalance of the contract
            uint256 ETHBalance = msg.sender.balance;
            return ETHBalance;
        } catch {
            revert();
        }
    }
}