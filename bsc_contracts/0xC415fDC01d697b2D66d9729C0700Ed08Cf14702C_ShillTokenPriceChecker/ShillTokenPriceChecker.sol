/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

pragma solidity ^0.6.12;

/*
/  _____ __    _ ____   ______      __                
  / ___// /_  (_) / /  /_  __/___  / /_____  ____     
  \__ \/ __ \/ / / /    / / / __ \/ //_/ _ \/ __ \    
 ___/ / / / / / / /    / / / /_/ / ,< /  __/ / / /    
/____/_/ /_/_/_/_/    /_/  \____/_/|_|\___/_/ /_/ ____
   / __ \_____(_)_______     / ____/__  ___  ____/ / /
  / /_/ / ___/ / ___/ _ \   / /_  / _ \/ _ \/ __  / / 
 / ____/ /  / / /__/  __/  / __/ /  __/  __/ /_/ /_/  
/_/   /_/  /_/\___/\___/  /_/    \___/\___/\__,_(_)   
                                                      
*/
interface Token {
    function decimals() external view returns (uint);
}
interface IUniswapV2Router {
    function WETH() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract ShillTokenPriceChecker{
  address public constant uniswapV2router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //Default address in all Networks
  IUniswapV2Router router = IUniswapV2Router(uniswapV2router);

    function getTokenPrice(address tokenAddress) public view returns (uint) {
      uint amountIn = getAmountIn(tokenAddress);
        address[] memory _path = new address[](2);
        _path[0] = tokenAddress;
        _path[1] = router.WETH();
        uint[] memory _amts = router.getAmountsOut(amountIn, _path);
        return _amts[1];
    }

    function getEthPerToken(address tokenAddress) public view returns (uint[] memory) {
      uint amountIn = getAmountIn(tokenAddress);
        address[] memory _path = new address[](2);
        _path[0] = tokenAddress;
        _path[1] = router.WETH();
        uint[] memory _amts = router.getAmountsOut(amountIn, _path);
        return _amts;
    }

    function getAmountIn(address tokenAddress) public view returns (uint) {
      Token token = Token(tokenAddress);
      uint decimals = token.decimals();
      uint amountIn = (10 ** decimals);
      return amountIn;
    }

    function getDecimals(address tokenAddress) public view returns (uint) {
      uint decimals = Token(tokenAddress).decimals();
      return decimals;
    }
}