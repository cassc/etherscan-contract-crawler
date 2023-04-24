//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;

//import "hardhat/console.sol";

// Uniswap interface and library imports
import "./UniswapV2Library.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";

contract PancakeFlashSwap {
    using SafeERC20 for IERC20;

    // Factory and Routing address
    address private constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // OwnerAddress
    address private constant ownerAddress = 0x81445CB6a531B03068839d652E57a68f71250cdB;

    // Trade Variables
    uint256 private deadline = block.timestamp + 1 days;
    uint256 private constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // FUND SMART CONTRACT
    // Provides a function to allow contract to be funded
    function fundFlashSwapContract(address _owner, address _token, uint256 _amount) public {
        IERC20(_token).transferFrom(_owner, address(this), _amount);
    }

    // GET CONTRACT BALANCE
    // Allows public view of balance for contract
    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    // PLACE A TRADE (TRADING FUNCTION)
    // Execute placing a trade
    function placeTrade(
        address _fromToken,
        address _toToken,
        uint256 _amountIn
    ) private returns (uint256) {
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(_fromToken, _toToken);
        require(pair != address(0), "Pool does not exist");

        // Calculate Amount Out
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(PANCAKE_ROUTER).getAmountsOut(_amountIn, path)[1];

        //console.log("amaountRequired", amountRequired);

        // Perform Arbitrage - Swap for another token
        uint amountReceived = IUniswapV2Router01(PANCAKE_ROUTER).swapExactTokensForTokens(
            _amountIn, // amountIn
            amountRequired, // amountOutMin
            path, // path
            address(this), // addressTo
            deadline // deadline
        )[1];

        //console.log("amountReceived", amountReceived);

        require(amountReceived > 0, "Aborted Tx: Trade returned zero");

        return amountReceived;
    }

    // CHECK PROFITABILITY
    // Checks whether OutputAmount > InputAmount
    function checkProfitability(uint256 _input, uint256 _output) private returns (bool) {
        return _output > _input;
    }

    // INITIATE ARBITRAGE
    // Begins receiving loan to engage performing arbitrage trades
    function startArbitrage(address _tokenBorrow, address _tokenBorrowPair, uint256 _amount, address _tokenArbitrage2, address _tokenArbitrage3) external {
        IERC20(_tokenBorrow).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(_tokenArbitrage2).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(_tokenArbitrage3).safeApprove(address(PANCAKE_ROUTER), MAX_INT);

        // Get the Factory Pair address for combined tokens
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(_tokenBorrow, _tokenBorrowPair);

        // Return error if combination does not exist
        require(pair != address(0), "Pool does not exist");

        // Figure out which token (0 or 1) has the amount and assign
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // Passing data as bytes so that the 'Swap' function knows it is a flashloan
        bytes memory data = abi.encode(_tokenBorrow, _amount, msg.sender, _tokenArbitrage2, _tokenArbitrage3);

        // Execute the initial swap to get the flashloan
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function pancakeCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        // Ensure this request came from the contract
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(token0, token1);
        require(msg.sender == pair, "The sender needs to match the pair contract");
        require(_sender == address(this), "Sender needs to match this contract");

        // Decode data for calculating the repayment
        (address tokenBorrow, uint256 amount, address myAddress, address tokenArbitrage2, address tokenArbitrage3) = abi.decode(_data, (address, uint256, address, address, address));

        // Calculate the amount to repay at the end
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        // DO ARBITRAGE
        // Assign loan amount
        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;

        // Place Trades
        uint256 trade1AcquiredCoin = placeTrade(tokenBorrow, tokenArbitrage2, loanAmount);
        uint256 trade2AcquiredCoin = placeTrade(tokenArbitrage2, tokenArbitrage3, trade1AcquiredCoin);
        uint256 trade3AcquiredCoin = placeTrade(tokenArbitrage3, tokenBorrow, trade2AcquiredCoin);
        
        // CHECK PROFITABILITY
        bool profCheck = checkProfitability(amountToRepay, trade3AcquiredCoin);
        require(profCheck, "Arbitrage not profitable");

        // Pay Myself
        IERC20 otherToken = IERC20(tokenBorrow);
        if (myAddress == ownerAddress){
            otherToken.transfer(myAddress, trade3AcquiredCoin - amountToRepay);
        } else {
            uint256 processingFee = ((( trade3AcquiredCoin - amountToRepay ) * 3) / 997) + 1;
            otherToken.transfer(ownerAddress, processingFee);
            otherToken.transfer(myAddress, (trade3AcquiredCoin - ( amountToRepay + processingFee )));
        }
        
        // Pay Loan Back
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    } 
}