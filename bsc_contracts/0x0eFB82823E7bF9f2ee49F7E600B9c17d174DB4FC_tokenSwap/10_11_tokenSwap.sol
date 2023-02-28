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
    uint256 private deadline = block.timestamp + 30 minutes;
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
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
    address private constant GNY = 0xe4A4Ad6E0B773f47D28f548742a23eFD73798332; // GNY

    address private constant myaddress = 0x6984a72B81d269f2de608526e0a44f9D2bC892Bb;

    //address private constant BNB = 0xbe0eb53f46cd790cd13851d5eff43d12404d33e8;
    //address private constant SFUND = 0x477bc8d23c634c154061869478bce96be6045d12;
    //address private constant MOOV = 0x0ebd9537a25f56713e34c45b38f421a1e7191469;
    //address private constant CELL = 0xf3e1449ddb6b218da2c9463d4594ceccc8934346;
    //address private constant CATE = 0xe4fae3faa8300810c835970b9187c268f55d998f;
    //address private constant METIS = 0xe552fb52a4f19e44ef5a967632dbc320b0820639;
    //address private constant RBC = 0x8e3bcc334657560253b83f08331d85267316e08a;
    //address private constant ATOM = 0x0eb3a705fc54725037cc9e008bdede697f62f335;
    //address private constant MATIC = 0xcc42724c6683b7e57334c4e856f4c9965ed682bd;
    //address private constant VOLT = 0x7db5af2b9624e1b3b4bb69d6debd9ad1016a58ac;
    //address private constant STG = 0xb0d502e938ed5f4df2e681fe6e419ff29631d62b;
    //address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    //address private constant OM = 0xf78d2e7936f5fe18308a3b2951a93b6c4a41f5e2;
    //address private constant FRONT = 0x928e55dab735aa8260af3cedada18b5f70c72f1b;


    // FUND SWAP CONTRACT
    // Provides a function to allow contract to be funded
    function fundFlashSwapContract(
        address _owner,
        address _token,
        uint256 _amount
    ) external {
        IERC20(_token).approve(address(this), MAX_INT);
        IERC20(_token).transferFrom(_owner, address(this), _amount);
    }

    // GET CONTRACT BALANCE
    // Allows public view of balance for contract
    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }
    

    function placeTrade(
        address _factory,
        address _router,
        address _fromToken,
        address _toToken,
        uint256 _amountIn
    ) external returns (uint256) {
        address pair = IUniswapV2Factory(_factory).getPair(
            _fromToken,
            _toToken
        );
        require(pair != address(0), "Pool does not exist");

        // Perform Arbitrage - Swap for another token on Uniswap
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(_router).getAmountsOut(
            _amountIn,
            path
        )[1];

        //uint256 deadline = block.timestamp + 30 minutes;
        IERC20(path[0]).approve(address(_router), MAX_INT);


        uint256 amountReceived = IUniswapV2Router01(_router)
            .swapExactTokensForTokens(
                _amountIn, // amountIn
                amountRequired, // amountOutMin
                path, // contract addresses
                address(this), // address to
                deadline // block deadline
            )[1];

        // Return output
        require(amountReceived > 0, "Aborted Tx: Trade returned zero");
        return amountReceived;
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
    uint256 _amountIn, 
    uint256 _amountOutMin
    ) external {

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
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router01(PANCAKE_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), deadline);
    }
    

       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
     function getAmountOutMin(
      address _tokenIn, 
      address _tokenOut, 
      uint256 _amountIn
      ) external view returns (uint256) {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
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
        return amountOutMins[path.length -1];  
    }  
}