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

    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    // Factory and Routing Addresses BSC MAINNET
    address private constant PANCAKE_FACTORY =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Para prestamos FL
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; // Para prestamos en WBNB
    address[] TokensWithBalance;
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
        uint256 deadline = block.timestamp;

        // Perform Arbitrage - Swap for another token
        uint256 amountReceived = IUniswapV2Router01(PANCAKE_ROUTER)
            .swapExactTokensForTokens(
                _amountIn, // amountIn
                amountRequired, // amountOutMin
                path, // path
                recipient, // address to
                deadline // deadline
            )[1];

        // console.log("PancakeFlashSwap.sol BREAKPOINT 3");
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
        uint256 amountInBNB
    ) external {
        A = _A;
        B = _B;
        C = _C;
        // RESET safeApprove to 0: SafeERC20: approve from non-zero to non-zero allowance
        IERC20(A).safeApprove(address(PANCAKE_ROUTER), 0);
        IERC20(B).safeApprove(address(PANCAKE_ROUTER), 0);
        IERC20(C).safeApprove(address(PANCAKE_ROUTER), 0);
        IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER), 0);
        IERC20(WBNB).safeApprove(address(PANCAKE_ROUTER), 0);
        // Approve Router to trade on oour behalf
        IERC20(A).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(B).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(C).safeApprove(address(PANCAKE_ROUTER), MAX_INT);

        // TO AVOID ERROR:  SafeERC20: approve from non-zero to non-zero allowance
        if (A != WBNB && B != WBNB && C != WBNB) {
            IERC20(WBNB).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        }

        // TO AVOID ERROR:  SafeERC20: approve from non-zero to non-zero allowance
        if (A != CAKE && B != CAKE && C != CAKE) {
            IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        }

        // Get the Factory Pair adess for combined Tokens - PAIR Between A and WBNB
        address pair;
        // If base token is WBNB then Borrow from CAKE-WBNB Pair
        if (A != WBNB) {
            pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(A, WBNB);
        } else {
            pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(A, CAKE);
        }

        uint256 loanAmount = getAmountsInBNB(A, amountInBNB);

        // Figure out wich token (0 or 1) has the amount and assing
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = A == token0 ? loanAmount : 0;
        uint256 amount1Out = A == token1 ? loanAmount : 0;

        // Pasing data as bytes so that the 'swap' function knows it is a flashloan
        bytes memory data = abi.encode(loanAmount, msg.sender);
        console.log("loanAmount", loanAmount);
        // Execute the initial swap to get the loan - FLASH LOAN INIT
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data); // FLASH LOAN - (FL-A)

        // uint256 A_balance = getBalanceOfToken(A);
        // require(A_balance > 0, "A_balance = 0");
        // console.log("PancakeFlashSwap.sol A_balance= ", A_balance);
        // // //PAY IN WBNB
        // // if (A != WBNB) {
        // //     placeTrade(A, WBNB, A_balance, owner); // Trade A for WBNB and send it to wallet on the same transaction
        // // } else {
        // //     IERC20(WBNB).transfer(owner, A_balance);
        // // }
        // IERC20(A).transfer(owner, A_balance);

        // PAY IN BNB
        // swapTokensForETH(A, A_balance, PANCAKE_ROUTER, msg.sender);

        // SET TO ZERO safeApprove
        // IERC20(A).safeApprove(address(PANCAKE_ROUTER), 0);
        // IERC20(B).safeApprove(address(PANCAKE_ROUTER), 0);
        // IERC20(C).safeApprove(address(PANCAKE_ROUTER), 0);
        // IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER), 0);
        // IERC20(WBNB).safeApprove(address(PANCAKE_ROUTER), 0);
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
        (uint256 _LoanAmount, address myWallet) = abi.decode(
            _data,
            (uint256, address)
        );

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
        console.log("PancakeFlashSwap.sol A to B  = ", B_amount);

        uint256 C_amount = placeTrade(B, C, B_amount, address(this)); // (B-C)
        console.log("PancakeFlashSwap.sol B to C  = ", C_amount);

        uint256 A_amount = placeTrade(C, A, C_amount, address(this)); // (C-A) 102.0
        console.log("PancakeFlashSwap.sol C to A = ", A_amount);
        console.log("PancakeFlashSwap.sol amountToRepay= ", amountToRepay);

        // Check Profitability
        bool profCheck = checkProfitability(amountToRepay, A_amount); // 100.03 < 102, Cnatidad final > prestamo + interes
        console.log("PancakeFlashSwap.sol  profCheck= ", profCheck);

        require(profCheck, "Arbitrage not profitable"); //////////////////////////////////////////////////////////////////////////
        // // Pay Myself
        IERC20 otherToken = IERC20(A);
        otherToken.transfer(myWallet, A_amount - amountToRepay);

        TokensWithBalance.push(A);
        // console.log(
        //     "PancakeFlashSwap.sol checkProfitability(amountToRepay, A_balance);",
        //     checkProfitability(amountToRepay, A_balance)
        // );
        console.log("PancakeFlashSwap.sol PAY FLASH LOAN BACK");
        // PAY FLASH LOAN
        IERC20(A).transfer(pair, amountToRepay);

        //PAY IN WBNB

        console.log("PancakeFlashSwap.sol pancakeCall END");
    }

    // function swapTokensForETH(
    //     address tokenIn,
    //     uint256 amountTokenIn,
    //     address router,
    //     address MyWallet
    // ) public returns (uint256) {
    //     IERC20(tokenIn).approve(router, amountTokenIn);
    //     uint256 allowedAmount = IERC20(tokenIn).allowance(
    //         address(this),
    //         router
    //     );

    //     address[] memory path = new address[](2);
    //     path[0] = tokenIn;
    //     path[1] = IUniswapV2Router02(router).WETH();

    //     console.log("swapExactTokensForETH allowedAmount", allowedAmount);
    //     console.log("swapExactTokensForETH path[0]", path[0]);
    //     console.log("swapExactTokensForETH path[1]", path[1]);
    //     try
    //         IUniswapV2Router02(router).swapExactTokensForETH(
    //             allowedAmount,
    //             0,
    //             path,
    //             MyWallet,
    //             block.timestamp
    //         )
    //     {
    //         //get the ETHBalance of the contract
    //         uint256 ETHBalance = msg.sender.balance;
    //         return ETHBalance;
    //     } catch {
    //         revert();
    //     }
    // }

    // ////////////////////
    function getAmountsInBNB(
        address X,
        uint256 amountOut
    ) private view returns (uint256) {
        uint256 AmountsIn;
        if (X != WBNB) {
            address[] memory path = new address[](2);
            path[0] = X;
            path[1] = WBNB;

            AmountsIn = IUniswapV2Router02(PANCAKE_ROUTER).getAmountsIn(
                amountOut,
                path
            )[0];
        } else {
            AmountsIn = amountOut;
        }

        return AmountsIn;
    }

    function simulate_swap_tokens(
        address X,
        address Y,
        uint256 amountIn
    ) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = X;
        path[1] = Y;

        uint256 AmountsOut = IUniswapV2Router02(PANCAKE_ROUTER).getAmountsOut(
            amountIn,
            path
        )[1];

        return AmountsOut;
    }

    function try_arbitrage(
        address J,
        address K,
        address L,
        uint256 amountInBNB
    ) private view returns (uint256) {
        uint256 loanAmount = getAmountsInBNB(J, amountInBNB);

        uint256 amountOut1 = simulate_swap_tokens(J, K, loanAmount);
        uint256 amountOut2 = simulate_swap_tokens(K, L, amountOut1);
        uint256 amountOut3 = simulate_swap_tokens(L, J, amountOut2);

        return amountOut3; // J - A
    }

    function Calculate_Arbitrage(
        address J,
        address K,
        address L,
        uint256 amountInBNB
    ) external view returns (address, address, address, uint256, uint256) {
        // amountInBNB = 1000000000000000000
        uint256 ratio;
        uint256 best_ratio;
        address[3] memory best_order;
        // J K L
        ratio = try_arbitrage(J, K, L, amountInBNB);
        best_ratio = ratio;
        best_order = [J, K, L];
        // J L K
        ratio = try_arbitrage(J, L, K, amountInBNB);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [J, L, K];
        }
        //  L K J
        ratio = try_arbitrage(L, K, J, amountInBNB);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [L, K, J];
        }
        //  K J L
        ratio = try_arbitrage(K, J, L, amountInBNB);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [K, J, L];
        }
        // L J K
        ratio = try_arbitrage(L, J, K, amountInBNB);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [L, J, K];
        }
        // K L J
        ratio = try_arbitrage(K, L, J, amountInBNB);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [K, L, J];
        }

        // START ARBITRAGE
        uint256 loanAmount = getAmountsInBNB(best_order[0], amountInBNB);

        // if(best_ratio > loanAmount){

        //         // startArbitrage(best_order[0], best_order[1],best_order[2],loanAmount);
        // }

        return (
            best_order[0],
            best_order[1],
            best_order[2],
            loanAmount,
            best_ratio
        );
    }

    function GetTokensWithBalance() public view returns (address[] memory) {
        return TokensWithBalance;
    }
}