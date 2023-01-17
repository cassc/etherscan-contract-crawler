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
    // address private constant DEX_FACTORY =
    //     0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    // address private constant DEX_ROUTER =
    //     0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Para prestamos FL
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; // Para prestamos en WBNB
    address[] TokensWithBalance;
    // Token Addresses
    // address private A;
    // address private B;
    // address private C;

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
        address DEX_FACTORY,
        address DEX_ROUTER
    ) private returns (uint256) {
        address pair = IUniswapV2Factory(DEX_FACTORY).getPair(
            _fromToken,
            _toToken
        );
        require(pair != address(0), "Pool does not exist");

        // Calculate Amount Out from One token to Another
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(DEX_ROUTER).getAmountsOut(
            _amountIn,
            path
        )[1];

        // console.log("amountRequired", amountRequired);
        uint256 deadline = block.timestamp;

        // Perform Arbitrage - Swap for another token
        uint256 amountReceived = IUniswapV2Router01(DEX_ROUTER)
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
        address A,
        address B,
        address C,
        uint256 amountInBNB,
        address DEX_FACTORY,
        address DEX_ROUTER
    ) external {
        // RESET safeApprove to 0: SafeERC20: approve from non-zero to non-zero allowance
        IERC20(A).safeApprove(address(DEX_ROUTER), 0);
        IERC20(B).safeApprove(address(DEX_ROUTER), 0);
        IERC20(C).safeApprove(address(DEX_ROUTER), 0);
        IERC20(CAKE).safeApprove(address(DEX_ROUTER), 0);
        IERC20(WBNB).safeApprove(address(DEX_ROUTER), 0);
        // Approve Router to trade on oour behalf
        IERC20(A).safeApprove(address(DEX_ROUTER), MAX_INT);
        IERC20(B).safeApprove(address(DEX_ROUTER), MAX_INT);
        IERC20(C).safeApprove(address(DEX_ROUTER), MAX_INT);

        // TO AVOID ERROR:  SafeERC20: approve from non-zero to non-zero allowance
        if (A != WBNB && B != WBNB && C != WBNB) {
            IERC20(WBNB).safeApprove(address(DEX_ROUTER), MAX_INT);
        }

        // TO AVOID ERROR:  SafeERC20: approve from non-zero to non-zero allowance
        if (A != CAKE && B != CAKE && C != CAKE) {
            IERC20(CAKE).safeApprove(address(DEX_ROUTER), MAX_INT);
        }

        // Get the Factory Pair adess for combined Tokens - PAIR Between A and WBNB
        address pair;
        // If base token is WBNB then Borrow from CAKE-WBNB Pair
        if (A != WBNB && B != WBNB && C != WBNB) {
            pair = IUniswapV2Factory(DEX_FACTORY).getPair(A, WBNB);
        } else {
            pair = IUniswapV2Factory(DEX_FACTORY).getPair(A, CAKE);
        }

        uint256 loanAmount = getAmountsInBNB(A, amountInBNB, DEX_ROUTER);

        // Figure out wich token (0 or 1) has the amount and assing
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = A == token0 ? loanAmount : 0;
        uint256 amount1Out = A == token1 ? loanAmount : 0;

        address[6] memory AdressesArray;

        AdressesArray[0] = A;
        AdressesArray[1] = B;
        AdressesArray[2] = C;
        AdressesArray[3] = DEX_FACTORY;
        AdressesArray[4] = DEX_ROUTER;
        AdressesArray[5] = msg.sender;

        // Pasing data as bytes so that the 'swap' function knows it is a flashloan
        bytes memory data = abi.encode(loanAmount, AdressesArray);
        // bytes memory data = abi.encode(loanAmount, msg.sender);
        console.log("loanAmount", loanAmount);
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
        (uint256 _LoanAmount, address[6] memory adressesArray) = abi.decode(
            _data,
            (uint256, address[6])
        );

        // address A = adressesArray[0];
        // address B = adressesArray[1];
        // address C = adressesArray[2];
        // address DEX_FACTORY = adressesArray[3];
        // address DEX_ROUTER = adressesArray[4];
        // address myWallet = adressesArray[5];

        address token0 = IUniswapV2Pair(_pair_sender).token0();
        address token1 = IUniswapV2Pair(_pair_sender).token1();
        address pair = IUniswapV2Factory(adressesArray[3]).getPair(
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
        console.log(
            "PancakeFlashSwap.sol DO ARBITRAGE ",
            adressesArray[0],
            adressesArray[1],
            adressesArray[2]
        );

        uint256 B_amount = placeTrade(
            adressesArray[0],
            adressesArray[1],
            loanAmount,
            address(this),
            adressesArray[3],
            adressesArray[4]
        ); // (A-B)
        console.log("PancakeFlashSwap.sol A to B  = ", B_amount);

        uint256 C_amount = placeTrade(
            adressesArray[1],
            adressesArray[2],
            B_amount,
            address(this),
            adressesArray[3],
            adressesArray[4]
        ); // (B-C)
        console.log("PancakeFlashSwap.sol B to C  = ", C_amount);
        IERC20(WBNB).safeApprove(address(this), MAX_INT);

        uint256 A_amount = placeTrade(
            adressesArray[2],
            adressesArray[0],
            C_amount,
            address(this),
            adressesArray[3],
            adressesArray[4]
        ); // (C-A) 102.0
        console.log("PancakeFlashSwap.sol C to A = ", A_amount);

        // Check Profitability
        bool profCheck = checkProfitability(amountToRepay, A_amount); // 100.03 < 102, Cnatidad final > prestamo + interes
        console.log("PancakeFlashSwap.sol  profCheck= ", profCheck);

        // require(profCheck, "Arbitrage not profitable"); //////////////////////////////////////////////////////////////////////////
        // // Pay Myself
        A_amount = getBalanceOfToken(adressesArray[0]);
        IERC20 otherToken = IERC20(adressesArray[0]);
        otherToken.transfer(adressesArray[5], A_amount - amountToRepay);

        bool flag = true;
        for (uint i = 0; i < TokensWithBalance.length; i++) {
            if (TokensWithBalance[i] == adressesArray[0]) {
                flag = false;
            }
        }

        if (flag) {
            TokensWithBalance.push(adressesArray[0]);
        }
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
        address DEX_ROUTER
    ) private view returns (uint256) {
        uint256 AmountsIn;
        if (X != WBNB) {
            address[] memory path = new address[](2);
            path[0] = X;
            path[1] = WBNB;

            AmountsIn = IUniswapV2Router02(DEX_ROUTER).getAmountsIn(
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
        address DEX_ROUTER
    ) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = X;
        path[1] = Y;

        uint256 AmountsOut = IUniswapV2Router02(DEX_ROUTER).getAmountsOut(
            amountIn,
            path
        )[1];

        return AmountsOut;
    }

    function try_arbitrage(
        address J,
        address K,
        address L,
        uint256 amountInBNB,
        address DEX_ROUTER
    ) private view returns (uint256) {
        uint256 loanAmount = getAmountsInBNB(J, amountInBNB, DEX_ROUTER);

        uint256 amountOut1 = simulate_swap_tokens(J, K, loanAmount, DEX_ROUTER);
        uint256 amountOut2 = simulate_swap_tokens(K, L, amountOut1, DEX_ROUTER);
        uint256 amountOut3 = simulate_swap_tokens(L, J, amountOut2, DEX_ROUTER);

        return (amountOut3 * 100000) / loanAmount; // J - A
    }

    function Calculate_Arbitrage(
        address J,
        address K,
        address L,
        uint256 amountInBNB,
        address DEX_ROUTER
    ) external view returns (address, address, address, uint256) {
        // amountInBNB = 1000000000000000000
        uint256 ratio;
        uint256 best_ratio;
        address[3] memory best_order;
        // J K L
        ratio = try_arbitrage(J, K, L, amountInBNB, DEX_ROUTER);
        best_ratio = ratio;
        best_order = [J, K, L];
        // J L K
        ratio = try_arbitrage(J, L, K, amountInBNB, DEX_ROUTER);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [J, L, K];
        }
        //  L K J
        ratio = try_arbitrage(L, K, J, amountInBNB, DEX_ROUTER);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [L, K, J];
        }
        //  K J L
        ratio = try_arbitrage(K, J, L, amountInBNB, DEX_ROUTER);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [K, J, L];
        }
        // L J K
        ratio = try_arbitrage(L, J, K, amountInBNB, DEX_ROUTER);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [L, J, K];
        }
        // K L J
        ratio = try_arbitrage(K, L, J, amountInBNB, DEX_ROUTER);
        if (ratio > best_ratio) {
            best_ratio = ratio;
            best_order = [K, L, J];
        }

        // START ARBITRAGE
        // if(best_ratio > 1.003){

        //         // startArbitrage(best_order[0], best_order[1],best_order[2],loanAmount);
        // }

        return (best_order[0], best_order[1], best_order[2], best_ratio);
    }

    function GetTokensWithBalance() public view returns (address[] memory) {
        return TokensWithBalance;
    }
}