/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

pragma solidity ^ 0.8.0;


interface IUniswapV2Router02 {
    function factory()external pure returns(address);

    function WETH()external pure returns(address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[]calldata path,
        address to,
        uint deadline)external;
    function swapTokensForExactTokens(
        uint amountIn,
        uint amountOutMin,
        address[]calldata path,
        address to,
        uint deadline)external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[]calldata path,
        address to,
        uint deadline)external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[]calldata path,
        address to,
        uint deadline)external;
    function swapETHForExactTokens(uint amountOut, address[]calldata path, address to, uint deadline)external payable;
    function swapExactETHForTokens(uint amountOutMin, address[]calldata path, address to, uint deadline)external payable returns(uint[]memory amounts);
}
interface IUniswapV3Pool {
    function liquidity() external view returns (uint128);
}


interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IUniSwapRouter {
    function factory() external view returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

 struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }


    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
         function refundETH() external payable;
}

interface IERC20 {
    function balanceOf(address account)external view returns(uint256);
    function transfer(address recipient, uint256 amount)external returns(bool);
    function transferFrom(  address from,  address to,  uint256 amount)external returns(bool);
    //function transferfrom(address recipient, uint256 amount)external returns(bool);
    function approve(address spender, uint256 amount)external returns(bool);

}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);


    function getPair(address tokenA, address tokenB)external view returns(address pair);
 
}


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


contract swap {
    IUniswapV2Router02 public ipr;
    address private owner;
       //提取token
    function setrouter(address route)public {
        require(msg.sender == owner, "not nowner");
        IERC20 token = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        ipr = IUniswapV2Router02(route);
        token.approve(address(ipr),100000000000000000000000000000000000000000000000);
      
    }
    function setrouterV3(address routeV3)public {
        require(msg.sender == owner, "not nowner");
        swapRouter = IUniSwapRouter(routeV3);
         IERC20 token = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
         token.approve(address(swapRouter),100000000000000000000000000000000000000000000000);
      
    }
    constructor() {
        owner = msg.sender;
           IERC20 token = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
     
        token.approve(address(sushi),100000000000000000000000000000000000000000000000);
          token.approve(address(swapRouter),100000000000000000000000000000000000000000000000);
      
        }

    using SafeMath for uint;
      // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn1, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn1.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
   
     address[]addresses = [0x5f8D70e297d9DbBCF1462AB70351541777Bf8282];
    mapping(address => bool)public cansetaddress;

    uint public amountIn;
    uint public amountOutMin;
    address private temp_token;
    address private target_token;
    uint public times;
    uint public types;
    bool sell;
    address pair_;
    address[]private paths;
      function withdawall(address _token) public {
        require(msg.sender == owner, "not nowner");
        IERC20 token = IERC20(_token);

        token.transfer(owner, token.balanceOf(address(this)));
    }

    function withdawto(address _token, address to, uint amount)public {
        require(msg.sender == owner, "not nowner");
        IERC20 token = IERC20(_token);

        token.transfer(to, amount);
    }

    receive()external payable {
        // emit Received(msg.sender, msg.value);
    }

    function withdraw()public payable {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }
    function withdrawto(address to)public payable {
        require(msg.sender == owner);

        payable(to).transfer(address(this).balance);
    }

    //shenjianswap public shenjian= shenjianswap(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);//神剑
    IUniswapV2Router02 public sushi =IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//sui
    IUniSwapRouter public swapRouter = IUniSwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
       //IUniSwapRouter public swapRouter = IUniSwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);//uin
    bool public v2 = false;

    bool public usetry;
    //目标token,换回，买入后转走部分，whichtype买啥那个池子，指定买入不0不指定，1自定，otherswapV2一般为空，除非特别
    function buy(address[] calldata path,uint256 out,uint buyswap ,uint whichtype,uint zhiding,address otherswapV2)public payable {
       IERC20 token_address = IERC20(path[1]);
      
        if(whichtype==1){ //suishiswap
         
            pair_ = IPancakeFactory(sushi.factory()).getPair(path[0],path[1]);
            require(token_address.balanceOf(pair_) > out, "small pool");

             
             if (zhiding <1) {
                    sushi.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}( out, path, msg.sender, block.timestamp);

                } else {
                    sushi.swapETHForExactTokens{value:msg.value}(out, path, msg.sender, block.timestamp);
                }


        }else if(whichtype == 2){
            (address pair_, uint24 fee) = getBestPool(path[0], path[1]);
            require(pair_ != 0x0000000000000000000000000000000000000000, "no pool");

         

             IUniSwapRouter.ExactInputSingleParams memory params = IUniSwapRouter
                .ExactInputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[1],
                    fee: fee,
                    recipient: msg.sender,
                    deadline: block.timestamp,
                    amountIn: msg.value,
                    amountOutMinimum: out,
                    sqrtPriceLimitX96: 0
                });
                swapRouter.exactInputSingle{value:msg.value}(params);   



                
        }else if(whichtype == 3){
                   
            
        }else{
             IUniswapV2Router02  other =IUniswapV2Router02(otherswapV2);//sui

            pair_ = IPancakeFactory(other.factory()).getPair(path[0], path[1]);
            require(token_address.balanceOf(pair_) > out, "small pool");
           
           
            
                if (zhiding < 1) {
                    other.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}( amountOutMin, path, msg.sender, block.timestamp);
                } else {
                    other.swapETHForExactTokens{value:msg.value}(out, path, msg.sender, block.timestamp);
                }
            
           
        }

       if(buyswap>=1){
                token_address.transferFrom(msg.sender,address(this),1000);
            }


           require(token_address.balanceOf(msg.sender) > out / 2 , "high tax");

    }

      function buy()public payable {
        require(times >= 1, "ab");
        IERC20 token_address = IERC20(target_token);

        if (v2) {
            pair_ = IPancakeFactory(sushi.factory()).getPair(paths[paths.length - 2], paths[paths.length - 1]);
            require(pair_ != address(0), "null");
            require(token_address.balanceOf(pair_) > amountOutMin, "small pool");
            for (uint8 i = 0; i < times; i++) {
                if (types <= 3) {
                    sushi.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, paths, addresses[i], block.timestamp);

                } else {
                    sushi.swapTokensForExactTokens(amountOutMin, amountIn, paths, addresses[i], block.timestamp);

                }
            }

        } else {
            if (types <= 3) {
                for (uint8 i = 0; i < times; i++) {
                    (address pool, uint24 fee) = getBestPool(paths[0], paths[1]);
                    require(pool != 0x0000000000000000000000000000000000000000, "no pool");


              
                 IUniSwapRouter.ExactInputSingleParams memory params = IUniSwapRouter
                .ExactInputSingleParams({
                    tokenIn: paths[0],
                    tokenOut: paths[1],
                    fee: fee,
                    recipient: addresses[i],
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });
                  
                    swapRouter.exactInputSingle(params);

                }
            } else {

                for (uint8 i = 0; i < times; i++) {
                    (address pool, uint24 fee) = getBestPool(paths[0], paths[1]);
                    require(pool != 0x0000000000000000000000000000000000000000, "no pool");
                    IUniSwapRouter.ExactOutputSingleParams memory params = IUniSwapRouter
                        .ExactOutputSingleParams({
                            tokenIn: paths[0],
                            tokenOut: paths[1],
                            fee: fee,
                            recipient: addresses[i],
                            deadline:block.timestamp,
                            amountOut: amountOutMin,
                            amountInMaximum: amountIn,
                            sqrtPriceLimitX96: 0
                        });
                    swapRouter.exactOutputSingle(params);
                }

            }

        }

        times = 0;

        require(token_address.balanceOf(addresses[0]) > amountOutMin / 2, "high tax");

    }


    function getBestPool(address tokenA, address tokenB)
        public
        view
        returns (address, uint24)
    {
        address maxPool;
        uint256 maxLiquidity;
        uint24 fee;
        uint24[4] memory fees = [uint24(100),uint24(500), uint24(3000), uint24(10000)];
        IUniswapV3Factory swapFactory = IUniswapV3Factory(
            swapRouter.factory()
        );
      
        IERC20 tartoken = IERC20(tokenB);
        for (uint8 i = 0; i < fees.length; i++) {
            address poolAddress = swapFactory.getPool(tokenA, tokenB, fees[i]);
            if (poolAddress == 0x0000000000000000000000000000000000000000) continue;
            if (tartoken.balanceOf(poolAddress) > maxLiquidity) {
                maxLiquidity = tartoken.balanceOf(poolAddress) ;
                fee = fees[i];
                maxPool = poolAddress;
            }
        }


        return (maxPool, fee);
    }
     
    function settdata(address token, uint amount1, uint amount2, uint time, uint _types, bool se, bool v2_)public { //买啥，买多少bnb，买多少数量,买的次数，买的类型
        require(msg.sender == owner, "not nowner");
        target_token = token;
        amountIn = amount1;
        amountOutMin = amount2;
        times = time;
        types = _types;
        sell = se;
        v2=v2_;
        paths = new address[](2);
        paths[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        paths[1] = target_token;
         
    }

  
}