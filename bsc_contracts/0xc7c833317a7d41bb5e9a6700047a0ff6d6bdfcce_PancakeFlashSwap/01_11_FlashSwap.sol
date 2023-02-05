//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;

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

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    // Trade Variables
    uint256 private deadline = block.timestamp + 1 days;
    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // FUND SMART CONTRACT
    // Provides a function to allow contract to be funded
    function fundFlashSwapContract(
        address _owner,
        address _token,
        uint256 _amount
    ) public {
        IERC20(_token).transferFrom(_owner, address(this), _amount);
    }

    // GET CONTRACT BALANCE
    // Allows public view of balance for contract
    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    // PLACE A TRADE
    // Executed placing a trade
    function placeTrade(
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        address factory,
        address router
    ) private returns (uint256) {
        address pair = IUniswapV2Factory(factory).getPair(_fromToken, _toToken);

        require(pair != address(0), "Pool does not exist");

        // Calculate Amount Out
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(router).getAmountsOut(
            _amountIn,
            path
        )[1];

        // console.log("amountRequired", amountRequired);

        // Perform Arbitrage - Swap for another token
        uint256 amountReceived = IUniswapV2Router01(router)
            .swapExactTokensForTokens(
                _amountIn, // amountIn
                amountRequired, // amountOutMin
                path, // path
                address(this), // address to
                deadline // deadline
            )[1];

        // console.log("amountRecieved", amountReceived);

        require(amountReceived > 0, "Aborted Tx: Trade returned zero");

        return amountReceived;
    }

    // CHECK PROFITABILITY
    // Checks whether > output > input
    function checkProfitability(uint256 _input, uint256 _output)
        private
        returns (bool)
    {
        return _output > _input;
    }

    function execute(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes memory _data
    ) internal {
        // Ensure this request came from the contract
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        // Decode data for calculating the repayment
        (
            address tokenBorrow,
            address tokenSwap,
            address sourceFactory,
            address sourceRouter,
            address targetFactory,
            address targetRouter
        ) = abi.decode(
                _data,
                (address, address, address, address, address, address)
            );

        address pair = IUniswapV2Factory(sourceFactory).getPair(token0, token1);
        require(msg.sender == pair, "The sender needs to match the pair");
        require(_sender == address(this), "Sender should match this contract");

        // Calculate the amount to repay at the end
        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;
        uint256 fee = ((loanAmount * 3) / 997) + 1;
        uint256 amountToRepay = loanAmount + fee;

        // Place Trades
        uint256 trade1AcquiredCoin = placeTrade(
            tokenBorrow,
            tokenSwap,
            loanAmount,
            sourceFactory,
            sourceRouter
        );

        uint256 trade2AcquiredCoin = placeTrade(
            tokenSwap,
            tokenBorrow,
            trade1AcquiredCoin,
            targetFactory,
            targetRouter
        );

        // Check Profitability
        bool profCheck = checkProfitability(amountToRepay, trade2AcquiredCoin);
        require(profCheck, "Arbitrage not profitable");

        // Pay Myself
        IERC20 otherToken = IERC20(tokenBorrow);
        otherToken.transfer(tx.origin, trade2AcquiredCoin - amountToRepay);

        // Pay Loan Back
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    // INITIATE ARBITRAGE
    // Begins receiving loan to engage performing arbitrage trades
    function startArbitrage(
        address _tokenBorrow,
        address _tokenSwap,
        uint256 _amount,
        address sourceFactory,
        address sourceRouter,
        address targetFactory,
        address targetRouter
    ) external {
        IERC20(_tokenBorrow).safeApprove(address(sourceRouter), MAX_INT);
        IERC20(_tokenSwap).safeApprove(address(sourceRouter), MAX_INT);
        IERC20(CAKE).safeApprove(address(sourceRouter), MAX_INT);

        IERC20(_tokenBorrow).safeApprove(address(targetRouter), MAX_INT);
        IERC20(_tokenSwap).safeApprove(address(targetRouter), MAX_INT);
        IERC20(CAKE).safeApprove(address(targetRouter), MAX_INT);

        // Get the Factory Pair address for combined tokens
        address pair = IUniswapV2Factory(sourceFactory).getPair(
            _tokenBorrow,
            CAKE
        );

        // Return error if combination does not exist
        require(pair != address(0), "Pool does not exist");

        // Figure out which token (0 or 1) has the amount and assign
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // Passing data as bytes so that the 'swap' function knows it is a flashloan
        bytes memory data = abi.encode(
            _tokenBorrow,
            _tokenSwap,
            sourceFactory,
            sourceRouter,
            targetFactory,
            targetRouter
        );

        // Execute the initial swap to get the loan
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        execute(_sender, _amount0, _amount1, _data);
    }
}