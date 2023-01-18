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

    // Para prestamos FL
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    address[] TokensWithBalance;

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
        address recipient,
        address FACTORY,
        address ROUTER
    ) private returns (uint256) {
        address pair = IUniswapV2Factory(FACTORY).getPair(_fromToken, _toToken);
        require(pair != address(0), "Pool does not exist");

        // Calculate Amount Out from One token to Another
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(ROUTER).getAmountsOut(
            _amountIn,
            path
        )[1];

        // console.log("amountRequired", amountRequired);
        uint256 deadline = block.timestamp;

        // Perform Arbitrage - Swap for another token
        uint256 amountReceived = IUniswapV2Router01(ROUTER)
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
        uint256 amountInBNB,
        address A,
        address B,
        address M_FACTORY,
        address M_ROUTER,
        address N_FACTORY,
        address N_ROUTER
    ) external {
        // RESET safeApprove to 0: SafeERC20: approve from non-zero to non-zero allowance
        IERC20(A).safeApprove(address(M_ROUTER), 0);
        IERC20(B).safeApprove(address(M_ROUTER), 0);
        IERC20(WBNB).safeApprove(address(M_ROUTER), 0);
        IERC20(CAKE).safeApprove(address(M_ROUTER), 0);
        IERC20(USDT).safeApprove(address(M_ROUTER), 0);
        IERC20(BUSD).safeApprove(address(M_ROUTER), 0);

        IERC20(A).safeApprove(address(N_ROUTER), 0);
        IERC20(B).safeApprove(address(N_ROUTER), 0);
        IERC20(WBNB).safeApprove(address(N_ROUTER), 0);
        IERC20(CAKE).safeApprove(address(N_ROUTER), 0);
        IERC20(USDT).safeApprove(address(N_ROUTER), 0);
        IERC20(BUSD).safeApprove(address(N_ROUTER), 0);
        // Approve Router to trade on oour behalf
        IERC20(A).safeApprove(address(M_ROUTER), MAX_INT);
        IERC20(B).safeApprove(address(M_ROUTER), MAX_INT);

        IERC20(A).safeApprove(address(N_ROUTER), MAX_INT);
        IERC20(B).safeApprove(address(N_ROUTER), MAX_INT);

        // TO AVOID ERROR:  SafeERC20: approve from non-zero to non-zero allowance
        if (A != WBNB && B != WBNB) {
            IERC20(WBNB).safeApprove(address(M_ROUTER), MAX_INT);
        }

        // TO AVOID ERROR:  SafeERC20: approve from non-zero to non-zero allowance
        if (A != CAKE && B != CAKE) {
            IERC20(CAKE).safeApprove(address(M_ROUTER), MAX_INT);
        }
        if (A != USDT && B != USDT) {
            IERC20(USDT).safeApprove(address(M_ROUTER), MAX_INT);
        }
        if (A != BUSD && B != BUSD) {
            IERC20(BUSD).safeApprove(address(M_ROUTER), MAX_INT);
        }
        // Get the Factory Pair adess for combined Tokens - PAIR Between A and WBNB
        address pair;
        pair = IUniswapV2Factory(M_FACTORY).getPair(A, CAKE);
        console.log(pair);
        // If base token is WBNB then Borrow from CAKE-WBNB Pair
        if (A != WBNB && B != WBNB) {
            pair = IUniswapV2Factory(M_FACTORY).getPair(A, WBNB);
        } else if (A != USDT && B != USDT) {
            pair = IUniswapV2Factory(M_FACTORY).getPair(A, USDT);
        } else if (A != BUSD && B != BUSD) {
            pair = IUniswapV2Factory(M_FACTORY).getPair(A, BUSD);
        } else if (A != CAKE && B != CAKE) {
            pair = IUniswapV2Factory(M_FACTORY).getPair(A, CAKE);
        }

        uint256 loanAmount = getAmountsInBNB(A, amountInBNB, N_ROUTER);

        // Figure out wich token (0 or 1) has the amount and assing
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = A == token0 ? loanAmount : 0;
        uint256 amount1Out = A == token1 ? loanAmount : 0;

        address[7] memory AdressesArray;

        AdressesArray[0] = A;
        AdressesArray[1] = B;
        AdressesArray[2] = M_FACTORY;
        AdressesArray[3] = M_ROUTER;
        AdressesArray[4] = N_FACTORY;
        AdressesArray[5] = N_ROUTER;
        AdressesArray[6] = msg.sender;

        // Pasing data as bytes so that the 'swap' function knows it is a flashloan
        bytes memory data = abi.encode(loanAmount, AdressesArray);
        // bytes memory data = abi.encode(loanAmount, msg.sender);
        console.log("BREAKPOINT startArbitrage");
        // Execute the initial swap to get the loan - FLASH LOAN INIT
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data); // FLASH LOAN - (FL-A)
    }

    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        DEX_CALL(_sender, _amount0, _amount1, _data, msg.sender);
    }

    function swapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        DEX_CALL(_sender, _amount0, _amount1, _data, msg.sender);
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        DEX_CALL(_sender, _amount0, _amount1, _data, msg.sender);
    }

    function BiswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        DEX_CALL(_sender, _amount0, _amount1, _data, msg.sender);
    }

    function DEX_CALL(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes memory _data,
        address _pair_sender
    ) internal {
        // Ensure this request came from the contract
        // _sender = PancakeFlashSwap.sol address
        //msg.sender = Pair.address
        // Decode data for calculating the repayment

        (uint256 _LoanAmount, address[7] memory adressesArray) = abi.decode(
            _data,
            (uint256, address[7])
        );

        // AdressesArray[0] = A;
        // AdressesArray[1] = B;
        // AdressesArray[2] = M_FACTORY;
        // AdressesArray[3] = M_ROUTER;
        // AdressesArray[4] = N_FACTORY;
        // AdressesArray[5] = N_ROUTER;
        // AdressesArray[6] = msg.sender;

        address token0 = IUniswapV2Pair(_pair_sender).token0();
        address token1 = IUniswapV2Pair(_pair_sender).token1();

        address pair = IUniswapV2Factory(adressesArray[2]).getPair(
            token0,
            token1
        );
        require(_pair_sender == pair, "The sender needs to match the pair");
        require(_sender == address(this), "Sender should match this contract");

        console.log("PancakeFlashSwap.sol ", _pair_sender, "==", pair);

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
        console.log("PancakeFlashSwap.sol DO ARBITRAGE ");

        uint256 B_amount = placeTrade(
            adressesArray[0],
            adressesArray[1],
            loanAmount,
            address(this),
            adressesArray[2],
            adressesArray[3]
        ); // (A-B)
        console.log("PancakeFlashSwap.sol A to B  = ", B_amount);

        uint256 A_amount = placeTrade(
            adressesArray[1],
            adressesArray[0],
            B_amount,
            address(this),
            adressesArray[4],
            adressesArray[5]
        ); // (B-C)
        console.log("PancakeFlashSwap.sol B to A  = ", A_amount);

        // Check Profitability
        bool profCheck = checkProfitability(amountToRepay, A_amount); // 100.03 < 102, Cnatidad final > prestamo + interes
        console.log("PancakeFlashSwap.sol  profCheck= ", profCheck);

        require(profCheck, "Arbitrage not profitable"); //////////////////////////////////////////////////////////////////////////
        // // Pay Myself
        A_amount = getBalanceOfToken(adressesArray[0]);
        console.log("PancakeFlashSwap.sol A balance  = ", A_amount);

        IERC20 otherToken = IERC20(adressesArray[0]);
        otherToken.transfer(adressesArray[6], A_amount - amountToRepay); //adressesArray[6] = My Wallet

        bool flag = true;
        for (uint i = 0; i < TokensWithBalance.length; i++) {
            if (TokensWithBalance[i] == adressesArray[0]) {
                flag = false;
            }
        }
        if (flag) {
            TokensWithBalance.push(adressesArray[0]);
        }

        console.log("BREAKPOINT DEX_CALL 1");
        console.log("PancakeFlashSwap.sol PAY FLASH LOAN BACK");
        // PAY FLASH LOAN
        IERC20(adressesArray[0]).transfer(pair, amountToRepay);

        //PAY IN WBNB

        console.log("PancakeFlashSwap.sol pancakeCall END");
    }

    // ////////////////////
    function getAmountsInBNB(
        address X,
        uint256 amountOut,
        address M_ROUTER
    ) private view returns (uint256) {
        uint256 AmountsIn;
        if (X != WBNB) {
            address[] memory path = new address[](2);
            path[0] = X;
            path[1] = WBNB;

            AmountsIn = IUniswapV2Router02(M_ROUTER).getAmountsIn(
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
        uint256 amountIn,
        address ROUTER
    ) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = X;
        path[1] = Y;

        uint256 AmountsOut = IUniswapV2Router02(ROUTER).getAmountsOut(
            amountIn,
            path
        )[1];

        return AmountsOut;
    }

    function try_arbitrage(
        address J,
        address K,
        uint256 amountInBNB,
        address M_ROUTER,
        address N_ROUTER
    ) private view returns (uint256) {
        uint256 loanAmount = getAmountsInBNB(J, amountInBNB, M_ROUTER);

        uint256 amountOut1 = simulate_swap_tokens(J, K, loanAmount, M_ROUTER);
        uint256 amountOut2 = simulate_swap_tokens(K, J, amountOut1, N_ROUTER);

        return (amountOut2 * 100000) / loanAmount; // J - A
    }

    function Calculate_Arbitrage(
        address J,
        address K,
        uint256 amountInBNB,
        address M_FACTORY,
        address M_ROUTER,
        address N_FACTORY,
        address N_ROUTER
    ) external view returns (uint256, address[6] memory) {
        // amountInBNB = 1000000000000000000
        uint256 ratio;
        uint256 best_ratio;
        address[6] memory best_order;
        // J K - M N
        ratio = try_arbitrage(J, K, amountInBNB, M_ROUTER, N_ROUTER);
        best_ratio = ratio;
        best_order = [J, K, M_FACTORY, M_ROUTER, N_FACTORY, N_ROUTER];

        // K J - M N
        ratio = try_arbitrage(K, J, amountInBNB, M_ROUTER, N_ROUTER);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [K, J, M_FACTORY, M_ROUTER, N_FACTORY, N_ROUTER];
        }

        //  J K - N M
        ratio = try_arbitrage(K, J, amountInBNB, N_ROUTER, M_ROUTER);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [K, J, N_FACTORY, N_ROUTER, M_FACTORY, M_ROUTER];
        }

        // K J - N M
        ratio = try_arbitrage(K, J, amountInBNB, N_ROUTER, M_ROUTER);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [K, J, N_FACTORY, N_ROUTER, M_FACTORY, M_ROUTER];
        }

        // uint256 loanAmount = getAmountsInBNB(
        //     best_order[0], // A
        //     amountInBNB,
        //     best_order[3] // M_ROUTER
        // );
        // START ARBITRAGE

        // if(best_ratio > loanAmount){

        //         // startArbitrage(loanAmount,best_order[0], best_order[1],best_order[2],best_order[3],best_order[4],best_order[5],);
        // }

        return (best_ratio, best_order);
    }

    function GetTokensWithBalance() public view returns (address[] memory) {
        return TokensWithBalance;
    }
}