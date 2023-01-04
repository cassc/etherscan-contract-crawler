// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "contracts/interfaces/IUniswapV2Factory.sol";
import "contracts/interfaces/IUniswapV2Pair.sol";
import "contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract communityHandler is Ownable {

 using SafeMath for uint256;

    // base assets
    address public BUSD;
    address public WBNB;
    address public DROP;
    address public DSHARE;
    address public DRIP;
    address public _router;

    constructor(address _BUSD, address _WBNB,address _DROP, address _DSHARE, address _DRIP, address _router_){
    BUSD = _BUSD;
    WBNB = _WBNB;
    DROP = _DROP;
    DSHARE = _DSHARE;
    DRIP = _DRIP;
    _router = _router_;

    }
    

	function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
		IERC20(_tokenIn).approve(router, _amount);
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint deadline = block.timestamp + 300;
		IUniswapV2Router02(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
	}

	function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router02(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
	}

    function sellDividendsDrop(uint256 _amount) external onlyOwner {
       //  require(nativePrice > nativePriceCeiling, "cant sell below price ceil");
        swap(_router,DROP,BUSD,_amount);
  }

    function buyBackDrop(uint256 _amount) external onlyOwner {
    //  require(nativePrice < nativePriceCeiling, "cant sell below price ceil");
        swap(_router,BUSD,DROP,_amount);
  }

    function buyBackDrip(uint256 _amount) external onlyOwner {
        swap(_router,BUSD,DRIP,_amount);
  }
  
    function sellDividendsDshare(uint256 _amount) external onlyOwner {
        swap(_router,DSHARE,BUSD,_amount);
   
  }

    function buyBackDshare(uint256 _amount) external onlyOwner {
        swap(_router,BUSD,DSHARE,_amount);
  }

  // example BUSD as token 1 - DROP as token 2 - WBNB as token 3 - BUSD back to token 1
  function estimateTriangularTrade(address _token1, address _token2,address _token3, uint256 _amount) external view returns (uint256) {
		uint256 amtBack1 = getAmountOutMin(_router, _token1, _token2, _amount);
		uint256 amtBack2 = getAmountOutMin(_router, _token2, _token3, amtBack1);
        uint256 amtBack3 = getAmountOutMin(_router, _token3, _token1, amtBack2);
		return amtBack3;
  }

  function triangularTrade(address _token1, address _token2, address _token3, uint256 _amount) external onlyOwner {
    
    // log start balance
    uint token1InitialBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    uint token3InitialBalance = IERC20(_token3).balanceOf(address(this));

    // swap from base to mid
    swap(_router,_token1, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount2 = token2Balance - token2InitialBalance;

    // get the value
    swap(_router,_token2, _token3,tradeableAmount2);
    uint token3Balance = IERC20(_token3).balanceOf(address(this));
    uint tradeableAmount3 = token3Balance - token3InitialBalance;

    // swap back to base
    swap(_router,_token3, _token1,tradeableAmount3);

    // log the end balance
    uint endBalance = IERC20(_token1).balanceOf(address(this));

    // ensure trade is profitable
    require(endBalance > token1InitialBalance, "Trade Reverted, No Profit Made");
  }

   // example BUSD as token 1 - DROP as token 2 - DShare as token 3,  WBNB as token 4 - BUSD back to token 1
  function estimateQtrade(address _token1, address _token2,address _token3,address _token4, uint256 _amount) external view returns (uint256) {
		uint256 amtBack1 = getAmountOutMin(_router, _token1, _token2, _amount);
		uint256 amtBack2 = getAmountOutMin(_router, _token2, _token3, amtBack1);
        uint256 amtBack3 = getAmountOutMin(_router, _token3, _token4, amtBack2);
        uint256 amtBack4 = getAmountOutMin(_router, _token4, _token1, amtBack3);
		return amtBack4;
	}


  function qTradeBaseBUSD(address _token2, address _token3, address _token4, uint256 _amount) external onlyOwner {
    
    // log start balance
    uint token1InitialBalance = IERC20(BUSD).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    uint token3InitialBalance = IERC20(_token3).balanceOf(address(this));
    uint token4InitialBalance = IERC20(_token4).balanceOf(address(this));

    // swap from base to mid
    swap(_router,BUSD, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount2 = token2Balance - token2InitialBalance;

    // get the value
    swap(_router,_token2, _token3,tradeableAmount2);
    uint token3Balance = IERC20(_token3).balanceOf(address(this));
    uint tradeableAmount3 = token3Balance - token3InitialBalance;

   
    swap(_router,_token3, _token4,tradeableAmount3);
    uint token4Balance = IERC20(_token4).balanceOf(address(this));
    uint tradeableAmount4 = token4Balance - token4InitialBalance;

    // swap back to base
    swap(_router,_token4, BUSD,tradeableAmount4);

    // log the end balance
    uint endBalance = IERC20(BUSD).balanceOf(address(this));

    // ensure trade is profitable
    require(endBalance > token1InitialBalance, "Trade Reverted, No Profit Made");
  }

  function qTradeBaseWBNB(address _token2, address _token3, address _token4, uint256 _amount) external onlyOwner {
    
    // log start balances
    uint token1InitialBalance = IERC20(WBNB).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    uint token3InitialBalance = IERC20(_token3).balanceOf(address(this));
    uint token4InitialBalance = IERC20(_token4).balanceOf(address(this));

    // swap from base to mid
    swap(_router,WBNB, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount2 = token2Balance - token2InitialBalance;

    // get the value
    swap(_router,_token2, _token3,tradeableAmount2);
    uint token3Balance = IERC20(_token3).balanceOf(address(this));
    uint tradeableAmount3 = token3Balance - token3InitialBalance;

    swap(_router,_token3, _token4,tradeableAmount3);
    uint token4Balance = IERC20(_token4).balanceOf(address(this));
    uint tradeableAmount4 = token4Balance - token4InitialBalance;

    // swap back to base
    swap(_router,_token4, WBNB,tradeableAmount4);

    // log the end balance
    uint endBalance = IERC20(WBNB).balanceOf(address(this));

    // ensure trade is profitable
    require(endBalance > token1InitialBalance, "Trade Reverted, No Profit Made");
  }

	function getBalance (address _tokenContractAddress) external view  returns (uint256) {
		uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}
	
	function recoverBnb() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function recoverTokens(address tokenAddress) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}
	
	receive() external payable {}

}