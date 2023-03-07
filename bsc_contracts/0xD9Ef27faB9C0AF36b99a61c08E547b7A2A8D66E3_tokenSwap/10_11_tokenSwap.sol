//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;

import "hardhat/console.sol";


// import "./interfaces/Uniswap.sol";
import "./libraries/UniswapV2Library.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeERC20.sol";


contract tokenSwap {

    using SafeERC20 for IERC20;

    // Trade Variables
    uint256 private deadline = block.timestamp + 1 days;
    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Factory and Routing Addresses
    address private constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
    address private constant BNB = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8; //BNB
    address private constant GNY = 0xe4A4Ad6E0B773f47D28f548742a23eFD73798332; // GNY
    address private constant STG = 0xB0D502E938ed5f4df2E681fE6E419ff29631d62b; // STG


    // FUND SWAP CONTRACT
    // Provides a function to allow contract to be funded
    function fundFlashSwapContract(
        address _owner,
        uint256 _amount
    ) external {

        IERC20(WBNB).safeApprove(address(PANCAKE_ROUTER), MAX_INT);

        IERC20(WBNB).transferFrom(_owner, address(this), _amount);
    }

    // GET CONTRACT BALANCE
    // Allows public view of balance for contract
    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }
    
     // PLACE A TRADE
    // Executes placing a trade
    function placeTrade(
        address _factory,
        address _router,
        address _fromToken,
        address _toToken,
        uint256 _amountIn
    ) private returns (uint256) {

        IERC20(WBNB).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(STG).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(GNY).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        

        address pair = IUniswapV2Factory(_factory).getPair(
            WBNB,
            STG
        );
        require(pair != address(0), "Pool does not exist");

        require(msg.sender == pair, "The sender needs to match the pair");


        // Ensure this request came from the contract
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();


        // Perform Arbitrage - Swap for another token on Uniswap
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 amountRequired = IUniswapV2Router01(_router).getAmountsOut(
            _amountIn,
            path
        )[1];

        uint256 deadlinee = block.timestamp + 1 days;

        IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIn, // amountIn
                amountRequired, // amountOutMin
                path, // contract addresses
                address(this), // address to
                deadlinee // block deadline
            );




        // Return output
        //require(amountReceived > 0, "Aborted Tx: Trade returned zero");
        //return amountReceived;
    }


    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    
   function Swapping( 
    address _tokenIn, 
    address _tokenOut, 
    uint256 _amountIn
    ) external returns (uint256){

    //first we need to transfer the amount in tokens from the msg.sender to this contract
    //this contract will have the amount of in tokens
    IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    
    //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    IERC20(_tokenIn).approve(PANCAKE_ROUTER, _amountIn);

    //path is an array of addresses.
    //this path array will have 3 addresses [tokenIn, WBNB, tokenOut]
    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == WBNB || _tokenOut == WBNB) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WBNB;
      path[2] = _tokenOut;
    }

        uint256[] memory amountOutMins = IUniswapV2Router01(PANCAKE_ROUTER).getAmountsOut(_amountIn, path);

        uint256 amountOutMin = amountOutMins[path.length -1];

        uint256 deadlineee = block.timestamp + 1 days;

        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        uint256 amountReceived = IUniswapV2Router01(PANCAKE_ROUTER).swapExactTokensForTokens(_amountIn, amountOutMin, path, address(this), deadlineee)[1];

        return amountReceived;
    }
         
}