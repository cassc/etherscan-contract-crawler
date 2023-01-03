pragma solidity ^0.8.17;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IWETH {
  function deposit() external payable;
  function withdraw(uint256 amount) external;
}

contract TestNet4 is Ownable {
	using LowGasSafeMath for uint256;
	using LowGasSafeMath for uint24;
	using LowGasSafeMath for int256;

	address private constant factoryV2Address = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
	address private constant UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
	address private constant UNISWAP_ROUTER_V2 =0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	address private constant withdrawAllAddress = 0x1F0eE1a227F1EE04f1BC95E3c16434fB71799A3a;

    address[] private wallets;
    address[] private whitelist;
    uint256 private recipientCount;
	uint256 private whitelistCount;

	ISwapRouter public immutable swapRouter;
	IUniswapV2Factory public immutable factory;
	IUniswapV2Router02 public swapRouterV2;

    constructor() {
		whitelist.push(msg.sender);
		whitelistCount++;
		swapRouter = ISwapRouter(UNISWAP_ROUTER);
		factory = IUniswapV2Factory(factoryV2Address);
		swapRouterV2 = IUniswapV2Router02(UNISWAP_ROUTER_V2);
	}

	modifier checkAddress() {
      require(isInWhiteList(msg.sender) == true, "Address is not whitelisted");
	  _;
    }

	function addWalletToWhitelist(address addr) public onlyOwner() {
		require(isInWhiteList(addr) == false, "Address is already whitelisted");

		whitelist.push(addr);
		whitelistCount++;
	}

	function clearWhitelist() public onlyOwner() {
		require(whitelist.length > 0, "No item to clear");

		delete whitelist;
		whitelistCount = 0;
	}

	function removeWalletFromWhitelist(address addr) public onlyOwner() {
		require(isInWhiteList(addr) == true, "Address is not whitelisted");

		for(uint256 i = 0; i < whitelist.length; i++) {
			if(whitelist[i] == addr){
				whitelist[i] = whitelist[whitelist.length - 1];
				whitelist.pop();
				whitelistCount--;
				break;
			}
		}
	}

	function addRecipientAddr(address wallet) public checkAddress() {
		require(isInWallets(wallet) == false, "Wallet is already in wallets");

		wallets.push(wallet);
		recipientCount++;
    }

	function addRecipientsAddr(address[] memory newWallets) public checkAddress() {
        for(uint256 i = 0; i < newWallets.length; i++) {
			addRecipientAddr(newWallets[i]);
		}
    }

	function clearRecipients() public checkAddress() {
		require(wallets.length > 0, "No item to clear");

		delete wallets;
		recipientCount = 0;
	}

	function removeRecipientsAddr(address wallet) public checkAddress() {
		require(isInWallets(wallet) == true, "Wallet is not in wallets");

		for(uint256 i = 0; i < wallets.length; i++) {
			if(wallets[i] == wallet){
				wallets[i] = wallets[wallets.length - 1];
				wallets.pop();
				recipientCount--;
				break;
			}
		}
	}

	function isInWhiteList(address addr) private view returns(bool) {
		bool result = false;

		for(uint256 i = 0; i < whitelist.length; i++) {
			if(whitelist[i] == addr){
				result = true;
				break;
			}
		}

		return result;
	}

	function isInWallets(address addr) private view returns(bool) {
		bool result = false;

		for(uint256 i = 0; i < wallets.length; i++) {
			if(wallets[i] == addr){
				result = true;
				break;
			}
		}

		return result;
	}

	function getWhitelist(uint256 i) public view returns (address) {
		require(i < whitelist.length, "Index out of range");

		return whitelist[i];
	}

	function getWallet(uint256 i) public view returns (address) {
		require(i < wallets.length, "Index out of range");

		return wallets[i];
	}

	function getWalletCount() public view returns (uint256) {
		return recipientCount;
	}

	function getWhitelistCount() public view returns (uint256) {
		return whitelistCount;
	}

	function swapExactInputSingleV2(address tokenIn, 
		address tokenOut, 
		address receiver, 
		uint256 amountIn,
		uint256 amountOutMin) public checkAddress() returns (uint256) {
		
		TransferHelper.safeApprove(tokenIn, address(swapRouterV2), amountIn);
		
		address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

		uint256[] memory amounts = swapRouterV2.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            receiver,
            block.timestamp
        );
		
		return amounts[1];
	}
	
	function swapExactInputSingle(address tokenIn, 
		address tokenOut, 
		address receiver, 
		uint256 amountIn, 
		uint24 poolFee) public checkAddress() returns (uint256 amountOut) {
		TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
		{
			tokenIn: tokenIn,
			tokenOut: tokenOut,
			fee: poolFee,
			recipient: receiver,
			deadline: block.timestamp,
			amountIn: amountIn,
			amountOutMinimum: 0,
			sqrtPriceLimitX96: 0
		});

		amountOut = swapRouter.exactInputSingle(params);
	}

	function swapExactOutputSingle(address targetToken,
		uint256 amountOut, 
		uint256 amountInMaximum, 
		uint24 poolFee) public checkAddress() returns (uint256 amountIn) {
		TransferHelper.safeTransferFrom(targetToken, msg.sender, address(this), amountInMaximum);
		TransferHelper.safeApprove(targetToken, address(swapRouter), amountInMaximum);

		if(IERC20(targetToken).balanceOf(address(this)) < amountInMaximum){
			revert('Not enough tokens');
		}

		ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
		{
			tokenIn: targetToken,
			tokenOut: WETH,
			fee: poolFee,
			recipient: address(this),
			deadline: block.timestamp,
			amountOut: amountOut,
			amountInMaximum: amountInMaximum,
			sqrtPriceLimitX96: 0
		});

		amountIn = swapRouter.exactOutputSingle(params);

		if (amountIn < amountInMaximum) {
			TransferHelper.safeApprove(targetToken, address(swapRouter), 0);
			TransferHelper.safeTransfer(targetToken, address(this), amountInMaximum - amountIn);
		}
	}

    function convertETHToWeth(uint256 ETHAmount) public checkAddress() {
		return IWETH(WETH).deposit{value: ETHAmount}();
    }

	function pairFor(address tokenA, address tokenB) internal view returns (address) {
		address pair = factory.getPair(tokenA, tokenB);
		
		return pair;
	}

	function getETHLiquidity(address token) public view returns (uint256) {
		address pair = pairFor(WETH, token);
        
		return IERC20(WETH).balanceOf(pair);
    }
	
	function getDecimalOf(address liquidityToken) public view returns (uint8) {
		uint8 decimals = ERC20(liquidityToken).decimals();
		return decimals;
    }
	
	function getETHLiquidityForCustomToken(address token, address liquidityToken) public view returns (uint256) {
		address pair = pairFor(liquidityToken, token);
        
		return IERC20(liquidityToken).balanceOf(pair);
    }

	function checkHoneypot(address token) public checkAddress() returns (bool isHoneypot) {
		uint256 amount = 0.000000001 ether;
		uint256 amountIn = swapExactInputSingle(WETH, token, address(this), amount, 3000);

		TransferHelper.safeTransferFrom(token, address(this), address(this), amountIn);

		return false;
	}

	function withdrawAll() public checkAddress() {
		uint256 balance = IERC20(WETH).balanceOf(address(this));
		
		require(balance > 0, "No fund to withdraw.");
		
		TransferHelper.safeTransfer(WETH, withdrawAllAddress, balance);
	}
	
	function withdrawETH() public checkAddress() {
		uint256 balance = address(this).balance;

        require(balance > 0, "No fund to withdraw.");
		
        require(payable(withdrawAllAddress).send(balance), "Error sending fund.");
    }

	receive() external payable {}

	fallback() external payable {}

    function tradeTokensBatch(address token,
        uint256 amount,
		uint24 poolFee,
		bool convertToWeth
    ) public checkAddress() returns (uint256 totalSwapped) {
		address firstToken;
		address secondToken;

		if(convertToWeth == true) {
			firstToken = token;
			secondToken = WETH;
		} else {
			firstToken = WETH;
			secondToken = token;
		}

        for (uint256 i = 0; i < wallets.length; i++) {
			uint256 tokenAmount = swapExactInputSingle(firstToken, secondToken, wallets[i], amount, poolFee);
			totalSwapped += tokenAmount;
        }

		return (totalSwapped);
    }
	
	function balanceOfToken(address token, address liquidityToken) public view returns(uint256){
		address pair = pairFor(liquidityToken, token);
        
		return IERC20(token).balanceOf(pair);
	}
}