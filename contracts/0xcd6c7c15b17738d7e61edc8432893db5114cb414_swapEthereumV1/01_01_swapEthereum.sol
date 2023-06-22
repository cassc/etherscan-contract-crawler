// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IUniswapFactoryV3{
  function getPool(address tokenA, address tokenB,uint24 fee) external view returns (address pair);
  function owner() external view returns (address);
}

interface IUniswapFactoryV2{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapRouterV2 {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline) external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}

interface IUniswapRouterV3{
        struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;}

    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);
}

interface IPancakeRouterV3{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;}

    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);
}

interface IUniswapPoolV2{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0()external view returns(address);
}

interface IUniswapPoolsV3 {
    function slot0()external view returns (uint160 sqrtPriceX96 , 
                                      int24 tick, uint16 observationIndex,
                                      uint16 observationCardinality,
                                      uint16 observationCardinalityNext,
                                      uint8 feeProtocol,
                                      bool unlocked);// use for uniswap contracts
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0()external view returns(address);
}

interface IBancorNetworkInfo{
    function tradeInputByTargetAmount(address sourceToken, address targetToken, uint256 targetAmount)external view returns(uint);
    function tradingFeePPM(address pool) external view returns (uint32);
    function tradeOutputBySourceAmount(address sourceToken, address targetToken, uint256 sourceAmount)external view returns(uint);
    function tradingEnabled(address pool) external view returns (bool);
}

interface IBancorNetwork{
        function tradeBySourceAmount(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable;
        function version()external view returns(uint);
        function pendingNetworkFeeAmount()external view returns(uint);
}

interface IERC20{
    function decimals() external view returns(uint8);
    function balanceOf(address owner)external view returns(uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address to , uint value)external;

}

 interface IWERC20{
    function deposit()external payable;
    function withdraw(uint256 amount) external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner)external view returns(uint);
    function transfer(address to , uint value)external view;
 }

interface ItypeData{

    struct EndResult{
        address pool;
        uint price;
        int decimalDifference;
        uint amonutIn;
        uint24 fee;
        bool invert; 
        string dexVersion;
    }
}

contract swapEthereumV1{

    mapping(string =>mapping(string => address)) dexsToSymbols;
    mapping(string => uint24)feeOfTheDex;

    address immutable admin;
    address Weth;
    string [] totalDexs;
    uint24 [] DexFees;

    modifier onlyAdmin(){
        require(msg.sender == admin , "not the admin");
        _;
    }

    modifier isAmount(){
        require(msg.value > 0 , "amount does not exist");
        _;
    }

    modifier isToken(address token){
        require(token !=address(0) , "address token does not exits");
        _;
    }

    constructor(address _weth){
        admin = msg.sender;
        Weth = _weth;
    }

    receive()external payable{}

    function setDexSymbolContracts(string calldata dexName,string calldata symbol,address contractAddress) external onlyAdmin{
        require(dexsToSymbols[dexName][symbol] == address(0) , "dex address is set");
        dexsToSymbols[dexName][symbol] = contractAddress;
        // emit SetNewAddress(dexName , symbol);
    }

    function setDexList(string [] memory _dexsName)external onlyAdmin returns(bool){
        totalDexs = _dexsName;
        return true;
    }

    function setDexFeeList(uint24 [] memory fees)external onlyAdmin returns(bool){
        DexFees = fees;
        return true;
    }

    function setFeeOfDex(string memory contractType , uint24 feeAmount)external onlyAdmin{
        require(feeOfTheDex[contractType] == 0 ,"fee is set");
        feeOfTheDex[contractType] = feeAmount;
        // emit SetFeeDex(contractType , feeAmount);
    }

    function removeFeeOfDex(string memory contractType)external onlyAdmin{
        delete feeOfTheDex[contractType];
    }

    function deletedexContractAddress(string  memory dex , string memory contractType)external onlyAdmin returns(bool){
        
        bool status = dexsToSymbols[dex][contractType] == address(0) ? false : true;
        
        delete dexsToSymbols[dex][contractType];

        return status;
    }

    function getAllPrices(address token0,address token1 , uint amountIn)public isToken(token0) view returns(ItypeData.EndResult [] memory PriceRatios){

        require(token0 != address(0) , "not correct address");

        uint8 count;
        ItypeData.EndResult[] memory totalPairs = new ItypeData.EndResult[](9);
        

        for (uint i = 0 ; i < totalDexs.length ; i++){
            
            ItypeData.EndResult memory res = getPrice(token0 , token1 , amountIn , totalDexs[i] , DexFees[i]);

            if(res.pool != address(0)){
                totalPairs[count] = res;
                count++;
            }
        }

        ItypeData.EndResult[] memory availablePools = new ItypeData.EndResult[](count);

        for(uint8 i = 0 ; i < count ; i++){
            availablePools[i] = totalPairs[i];
        }

        return availablePools;

    }

    function getPrice(address token0 , address token1 , uint amountIn , string memory dexName ,uint24 fee) public view returns(ItypeData.EndResult memory){
        if(checkDexName(dexName , "UNISWAPV3") || checkDexName(dexName , "PANCAKESWAPV3")){
            require(fee != 0 , "fee is not set");
            return uniswapV3GetPrice(token0 , token1 , amountIn , dexName , fee);
        }else{
            return uniswapV2GetPrice(token0 , token1 , amountIn , dexName);
        }
    }

    function uniswapV3GetPrice(address token0,address token1 , uint amountIn , string memory contractType , uint24 fee)public view returns( ItypeData.EndResult memory ){
        
        address pairAddress = uniswapV3GetSinglePool(token0 , token1 , contractType , fee);
        
        if(pairAddress == address(0)){
            return ItypeData.EndResult(pairAddress , 0 ,0 , amountIn , fee , false , contractType);
        }

        uint8 decimal0 = IERC20(token0).decimals();
        uint8 decimal1 = IERC20(token1).decimals();

        bool invert  = token0 == IUniswapPoolsV3(pairAddress).token0() ? true : false;
        int decimalDifference = getDecimalDiffenrence(decimal0 , decimal1 , invert);
        // (uint160 sqrtPriceX96,,,,,,) = IUniswapPoolsV3(pairAddress).slot0();
        (bool status , bytes memory data)= pairAddress.staticcall(abi.encodeWithSelector(IUniswapPoolsV3(pairAddress).slot0.selector));
        require(status , "not called");
        (uint160 sqrtPriceX96,,,,,,) = abi.decode(data , (uint160 , int24 , uint16, uint16,uint16,uint32 , bool));
        
        uint160 amountOut = sqrtPriceX96;

        return ItypeData.EndResult(pairAddress , amountOut ,decimalDifference , amountIn , fee , invert , contractType);
    }

    function uniswapV3GetSinglePool(address token0 , address token1 , string memory contractType , uint24 fee)public view returns(address){
        address  factoryAddress = dexsToSymbols[contractType]["FACTORYV3"];
        require(factoryAddress != address(0) , "facotry address not set");

        return IUniswapFactoryV3(factoryAddress).getPool(token0,token1,fee);
    }

    function uniswapV2GetPrice(address token0,address token1 , uint amountIn , string memory contractType)public
    isToken(token0) view returns(ItypeData.EndResult memory){
        address factory = dexToContractAddress(contractType , "FACTORYV2");
        address router  = dexToContractAddress(contractType ,"ROUTERV2");
        uint24 feeDexV2 = feeOfTheDex[contractType];
        address[] memory path = new address[](2);

        path[0] = token0;
        path[1] = token1;
        
        require(factory != address(0) , "dex factory address is not set");
        require(router != address(0) , "dex Router address is not set");
        
        
        address PairPool = UniswapV2GetPoolPair(token0 , token1 , factory);

        if(PairPool == address(0)){
            ItypeData.EndResult memory notFound = ItypeData.EndResult(PairPool , 0 , 0 , amountIn , feeDexV2 , false , contractType);
            return notFound;
        }
        bool invert  = token0 == IUniswapPoolsV3(PairPool).token0() ? false : true;

        uint256[] memory amounts = IUniswapRouterV2(router).getAmountsOut(amountIn , path);

        ItypeData.EndResult memory endResult = ItypeData.EndResult(PairPool , amounts[1] , 0 , amounts[0], feeDexV2 , invert , contractType );

        return endResult;
    }

    function UniswapV2GetPoolPair(address token0,address token1,address factoryAddress)
    public view returns(address){
        address poolAddress = IUniswapFactoryV2(factoryAddress).getPair(token0 , token1);
        
        return poolAddress;
    }

    function executeSwap(address tokenIn ,address tokenOut , uint amountIn,uint24 fee ,bool isCoin ,uint amountOutMinimum , string memory contractType)
    public payable 
    isToken(tokenIn){

        if(checkDexName(contractType , "UNISWAPV3")){
            
            UniswapV3Execute(tokenIn , tokenOut , amountIn , fee , isCoin , amountOutMinimum , contractType);

        }else if(checkDexName(contractType , "PANCAKESWAPV3")){

            PancakeSwapExecute(tokenIn , tokenOut , amountIn , fee , isCoin , amountOutMinimum , contractType);

        }else{

            UniswapV2Execute(tokenIn , tokenOut , amountIn, isCoin , amountOutMinimum , contractType);
        }
    } 

    function UniswapV2Execute(address tokenIn ,address tokenOut , uint amountIn,bool isCoin , uint amountOutMinimum, string memory contractType)
    public payable 
    isToken(tokenIn){
        
        address payable RouterV2 = payable (dexToContractAddress(contractType ,"ROUTERV2"));
        uint deadline =block.timestamp + 30 minutes;
        // uint amountOutMin = 0; //for testing
        address [] memory path = new address[](2);
        path[0] = tokenIn; 
        path[1] = tokenOut; 

        if(tokenIn == Weth && isCoin && !(checkDexName(contractType,"PANCAKESWAPV2"))){
            
            require(msg.value > 0 ,"not enough ETH");
              
            IUniswapRouterV2(RouterV2).swapExactETHForTokens{value: msg.value}(amountOutMinimum , path, msg.sender , deadline);
            
        }
        else if(tokenOut == Weth && isCoin){
            require(IERC20(tokenIn).balanceOf(msg.sender)  >= amountIn , "not enough tokens");

            IERC20(tokenIn).transferFrom(msg.sender ,address(this) ,amountIn);
            IERC20(tokenIn).approve(RouterV2 ,amountIn);

            IUniswapRouterV2(RouterV2).swapExactTokensForETH(amountIn , amountOutMinimum ,path ,msg.sender ,deadline);
        }
        else{

            if(!isCoin || !checkDexName(contractType,"PANCAKESWAPV2")){

            require(msg.value == 0 , "eth must not be send");
            require(IERC20(tokenIn).balanceOf(msg.sender)  >= amountIn , "not enough tokens");
            }

            if(tokenIn == Weth && isCoin && checkDexName(contractType,"PANCAKESWAPV2")){
                bool status = ethToWeth(amountIn , true);
                require(status , "not deposited");
            }
            
            if(!isCoin || !checkDexName(contractType,"PANCAKESWAPV2")){
            IERC20(tokenIn).transferFrom(msg.sender ,address(this) ,amountIn);
            }
            
            
            IERC20(tokenIn).approve(RouterV2 ,amountIn);
            IUniswapRouterV2(RouterV2).swapExactTokensForTokens(amountIn , amountOutMinimum , path , msg.sender ,deadline);
        }      
    }

    function ethToWeth( uint amount , bool zeroToOne)public payable returns(bool){
        //zero for withdraw , one for deposit
        if(zeroToOne){
            require(amount == msg.value ,"not the same amount for deposit");
            IWERC20(Weth).deposit{value:msg.value}();
            return true;
        }else{
            IWERC20(Weth).withdraw(amount);
            return true;
        }
    }

    function UniswapV3Execute(address tokenIn ,address tokenOut , uint amountIn , uint24 fee , bool isCoin ,uint amountOutMinimum, string memory contractType)
    public payable 
    isToken(tokenIn) {

        require(tokenIn != address(0) , "not correct address");

        if(tokenIn == Weth && isCoin) require(msg.value == amountIn , "not correct amount");
        
        address  RouterV3 = dexToContractAddress(contractType , "ROUTERV3");
        address sender = msg.sender;
        uint deadline = block.timestamp + 60 minutes;
        // uint256 amountOutMinimum = 0;// for testing
        uint160 sqrtPriceLimitX96 = 0;//for testing
        IUniswapRouterV3.ExactInputSingleParams memory params;

        if(tokenOut == Weth && isCoin)sender = address(this);

        params = IUniswapRouterV3.ExactInputSingleParams(tokenIn , tokenOut , fee 
                                                        ,sender , deadline , amountIn 
                                                        ,amountOutMinimum ,sqrtPriceLimitX96);

        

        if(tokenIn == Weth && isCoin){
            
            uint amountOut = IUniswapRouterV3(RouterV3).exactInputSingle{value : msg.value}(params);
        
        }else {

            IERC20(tokenIn).transferFrom(msg.sender , address(this) , amountIn);
            IERC20(tokenIn).approve(RouterV3 ,amountIn);

            (bool status , bytes memory data) = RouterV3.call{value:0}(abi.encodeWithSelector(IUniswapRouterV3(RouterV3).exactInputSingle.selector,params));
            require(status , "swap failed");
            uint amountOut = abi.decode(data , (uint));

            

            // uint amountOut = IUniswapRouterV3(RouterV3).exactInputSingle(params);

            if(tokenOut == Weth && isCoin){
                ethToWeth(amountOut , false);
                (payable(msg.sender)).transfer(amountOut);
            }
        }
    }

    function PancakeSwapExecute(address tokenIn ,address tokenOut , uint amountIn , uint24 fee , bool isCoin ,uint amountOutMinimum , string memory contractType)
    public payable 
    isToken(tokenIn) { 
    
    require(tokenIn != address(0) , "not correct address");

    if(msg.value > 0) require(msg.value == amountIn , "not correct amount");
    
    address  RouterV3 = dexToContractAddress(contractType , "ROUTERV3");
    address sender = msg.sender;
    // uint256 amountOutMinimum = 0;// for testing
    uint160 sqrtPriceLimitX96 = 0;//for testing
    IPancakeRouterV3.ExactInputSingleParams memory params;

    params = IPancakeRouterV3.ExactInputSingleParams(tokenIn , tokenOut , fee 
                                                    ,sender , amountIn , amountOutMinimum 
                                                    ,sqrtPriceLimitX96);

    if(tokenIn == Weth && isCoin){
            IPancakeRouterV3(RouterV3).exactInputSingle{value : msg.value}(params);
        
        }else {

            IERC20(tokenIn).transferFrom(msg.sender , address(this) , amountIn);
            IERC20(tokenIn).approve(RouterV3 ,amountIn);

            (bool status , bytes memory data) = RouterV3.call{value:0}(abi.encodeWithSelector(IPancakeRouterV3(RouterV3).exactInputSingle.selector,params));
            require(status , "swap failed");
            uint amountOut = abi.decode(data , (uint));

            // uint amountOut = IUniswapRouterV3(RouterV3).exactInputSingle(params);

            if(tokenOut == Weth && isCoin){
                ethToWeth(amountOut , false);
                (payable(msg.sender)).transfer(amountOut);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////

    function getDecimalDiffenrence(uint decimal0,uint decimal1 , bool invertInputs)public pure returns(int){
        
        return decimal1>decimal0 ? int(decimal1 - decimal0) : int(decimal0 - decimal1);
    }

    function dexToContractAddress(string  memory dex , string memory contractType)public view returns(address){
        return dexsToSymbols[dex][contractType];
    }

    function checkDexName(string memory name , string memory dex)public pure returns(bool){
        return keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(dex));
    }

    function destroyContract()external onlyAdmin{
        selfdestruct(payable(admin));
    }
}