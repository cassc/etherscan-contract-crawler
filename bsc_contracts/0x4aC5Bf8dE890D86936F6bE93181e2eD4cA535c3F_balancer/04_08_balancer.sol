// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "contracts/interfaces/IUniswapV2Factory.sol";
import "contracts/interfaces/IUniswapV2Pair.sol";
import "contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract balancer is Ownable {

  address public BUSD;
  address public LIT;
  address public _router;
  address public pairBusdLit;

  uint256 public goodPeg = 1.2 ether;
  uint256 public healthyPeg = 1.1 ether;

  mapping(address => bool) public auth;

  modifier onlyAuth() {
         require(auth[_msgSender()] == true, "You are not authorised");  
        _;
    }

  constructor(address _pairBusdLit, address _BUSD, address _LIT, address _router_){
      pairBusdLit = _pairBusdLit;
      BUSD = _BUSD;
      LIT = _LIT;
      _router = _router_;
      auth[msg.sender] = true;
  }

  function setAuth(address _auth) public onlyOwner {
    auth[_auth] = true;
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

   function getAmountInMin(address router, address _tokenOut, address _tokenIn, uint256 _amount) public view returns (uint256) {
      address[] memory path;
      path = new address[](2);
      path[0] = _tokenOut;
      path[1] = _tokenIn;
      uint256[] memory amountOutMins = IUniswapV2Router02(router).getAmountsIn(_amount, path);
      return amountOutMins[path.length -1];
   }


  
   function getProposalAbove() public view returns (uint256) {

      uint256 balanceTokenLit = IERC20(LIT).balanceOf(pairBusdLit);
      uint256 balanceTokenBusd = IERC20(BUSD).balanceOf(pairBusdLit);

      uint256 FictiveBalanceTokenBusd = (balanceTokenBusd / goodPeg) * 1 ether;


      uint256 desiredAmount = FictiveBalanceTokenBusd - balanceTokenLit; 
      uint256 dividedAmount = desiredAmount / 2;

      
      return getAmountInMin(_router,LIT,BUSD, dividedAmount);
    

	}

  function sellProposal() external onlyAuth {
      uint256 sellAmount = getProposalAbove();
      require(IERC20(LIT).balanceOf(address(this)) >= sellAmount, "not enough tokens to do the trade");
      swap(_router,LIT,BUSD,sellAmount);
  }

  function setGoodPeg(uint256 newPeg) public onlyOwner {
      goodPeg = newPeg;
  }

  function setHealthyPeg(uint256 newPeg) public onlyOwner {
      healthyPeg = newPeg;
  }

  function sellLIT(uint256 _amount) external onlyOwner {
      swap(_router,LIT,BUSD,_amount);
  }

  function buyLIT(uint256 _amount) external onlyOwner {
      swap(_router,BUSD,LIT,_amount);
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