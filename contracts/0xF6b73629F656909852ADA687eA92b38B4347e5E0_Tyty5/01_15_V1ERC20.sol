pragma solidity ^0.8.17;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IWETH {
  function deposit() external payable;
  function withdraw(uint256 amount) external;
}

contract Tyty5 is Ownable {
	using LowGasSafeMath for uint256;
	using LowGasSafeMath for uint24;
	using LowGasSafeMath for int256;

	address private constant factoryV2Address = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
	address private constant factoryV3Address = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
	address private constant UNISWAP_ROUTER_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
	address private constant UNISWAP_ROUTER_V2 =0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	address private constant withdrawAllAddress = 0x1F0eE1a227F1EE04f1BC95E3c16434fB71799A3a;

    address[] private wallets;
    address[] private whitelist;
    uint256 private recipientCount;
	uint256 private whitelistCount;

	ISwapRouter private immutable swapRouterV3;
	IUniswapV3Factory private immutable factoryV3;
	IUniswapV2Factory private immutable factoryV2;
	IUniswapV2Router02 private swapRouterV2;

    constructor() {
		whitelist.push(msg.sender);
		whitelistCount++;

		swapRouterV3 = ISwapRouter(UNISWAP_ROUTER_V3);
		factoryV3 = IUniswapV3Factory(factoryV3Address);

		factoryV2 = IUniswapV2Factory(factoryV2Address);
		swapRouterV2 = IUniswapV2Router02(UNISWAP_ROUTER_V2);
	}

	modifier checkAddress() {
      require(isInWhiteList(msg.sender) == true, "Address is not whitelisted");
	  _;
    }

	receive() external payable {}

	fallback() external payable {}

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

	function swap(address tokenIn,
		address tokenOut,
		address receiver,
		uint256 amountIn,
		uint256 amountOutMin,
		uint24 fee) public checkAddress() returns (uint256) {

		uint256 amountOut = 0;

		if (fee == 0){
			amountOut = swapExactInputSingleV2(tokenIn, tokenOut, receiver, amountIn, amountOutMin);
		} else {
			amountOut = swapExactInputSingleV3(tokenIn, tokenOut, receiver, amountIn, amountOutMin, fee);
		}

		return amountOut;
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

	function swapExactInputSingleV3(address tokenIn,
		address tokenOut,
		address receiver,
		uint256 amountIn,
		uint256 amountOutMin,
		uint24 fee) public checkAddress() returns (uint256) {

		TransferHelper.safeApprove(tokenIn, address(swapRouterV3), amountIn);

		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
		{
			tokenIn: tokenIn,
			tokenOut: tokenOut,
			fee: fee,
			recipient: receiver,
			deadline: block.timestamp,
			amountIn: amountIn,
			amountOutMinimum: amountOutMin,
			sqrtPriceLimitX96: 0
		});

		return swapRouterV3.exactInputSingle(params);
	}

	function getWETHLiquidity(address token,
		uint24 fee) external view returns (uint256) {

		uint256 result = 0;

		if(fee == 0){
			result = getWETHLiquidityV2(token);
		}
		else{
			result = getWETHLiquidityV3(token, fee);
		}

		return result;
	}

	function getWETHLiquidityV2(address token) public view returns (uint256) {
		address pair = pairFor(WETH, token);

		require(pair != address(0), "Pair doesn't exist.");

		return IERC20(WETH).balanceOf(pair);
    }

	function getWETHLiquidityV3(address token,
		uint24 fee) public view returns (uint256) {
		address pool = poolFor(WETH, token, fee);

		require(pool != address(0), "Pool doesn't exist.");

		return IERC20(WETH).balanceOf(pool);
    }

	function getLiquidityForCustomToken(address token,
		address liquidityToken,
		uint24 fee) external view returns (uint256) {

		uint256 result = 0;

		if(fee == 0){
			result = getLiquidityForCustomTokenV2(token, liquidityToken);
		} else {
			result = getLiquidityForCustomTokenV3(token, liquidityToken, fee);
		}

		return result;
	}

	function getLiquidityForCustomTokenV2(address token,
		address liquidityToken) public view returns (uint256) {
		address pair = pairFor(liquidityToken, token);

		require(pair != address(0), "Pair doesn't exist.");

		return IERC20(liquidityToken).balanceOf(pair);
    }

	function getLiquidityForCustomTokenV3(address token,
		address liquidityToken,
		uint24 fee) public view returns (uint256) {

		address pool = poolFor(liquidityToken, token, fee);

		require(pool != address(0), "Pool doesn't exist.");

		return IERC20(liquidityToken).balanceOf(pool);
    }

	function balanceOfToken(address token,
		address liquidityToken,
		uint24 fee) external view returns(uint256){

		uint256 result = 0;

		if(fee == 0){
			result = balanceOfTokenV2(token, liquidityToken);
		}
		else{
			result = balanceOfTokenV3(token, liquidityToken, fee);
		}

		return result;
	}

	function balanceOfTokenV2(address token,
		address liquidityToken) public view returns(uint256){

		address pair = pairFor(liquidityToken, token);

		require(pair != address(0), "Pair doesn't exist.");

		return IERC20(token).balanceOf(pair);
	}

	function balanceOfTokenV3(address token,
		address liquidityToken,
		uint24 fee) public view returns(uint256){

		address pool = poolFor(liquidityToken, token, fee);

		require(pool != address(0), "Pool doesn't exist.");

		return IERC20(token).balanceOf(pool);
	}

	function depositWETH(uint256 ETHAmount) public checkAddress() {
		return IWETH(WETH).deposit{value: ETHAmount}();
    }

	function checkHoneypotV2(address token, address to,uint256 amount) public returns (bool) {
		uint256 amountIn = swapExactInputSingleV2(WETH, token, address(this), amount, 0);

		TransferHelper.safeTransferFrom(token, address(this), to, amountIn);

		return false;
	}

	function checkHoneypotV3(address token, uint256 amount, address to,
		uint24 fee) public returns (bool) {
		uint256 amountIn = swapExactInputSingleV3(WETH, token, address(this), amount, 0, fee);

		TransferHelper.safeTransferFrom(token, address(this), to, amountIn);

		return false;
	}

	function withdrawToken(address token) public checkAddress() {
		uint256 balance = IERC20(token).balanceOf(address(this));

		require(balance > 0, "No fund to withdraw.");

		TransferHelper.safeTransfer(token, withdrawAllAddress, balance);
	}

	function withdrawETH() public checkAddress() {
		uint256 balance = address(this).balance;

        require(balance > 0, "No fund to withdraw.");

        require(payable(withdrawAllAddress).send(balance), "Error sending fund.");
    }

	function getDecimalOf(address token) public view returns (uint8) {
		uint8 decimals = ERC20(token).decimals();
		return decimals;
    }

	function depositETH() payable public checkAddress() {
		uint256 amount = msg.value / wallets.length;

		for (uint256 i = 0; i < wallets.length; i++) {
			require(payable(wallets[i]).send(amount), "Error sending fund.");
		}
	}

	function tradeTokensBatch(address token0,
		address token1,
		uint256 amount,
		uint256 amountOutMin,
		uint24 fee,
		bool transferToken
	) public checkAddress() returns (uint256) {
		uint256 totalSwapped = 0;

		for (uint256 i = 0; i < wallets.length; i++) {
			uint256 balance = IERC20(token0).balanceOf(wallets[i]);

			if (amount <= balance){
				if (transferToken == true) {
					TransferHelper.safeTransferFrom(token0, wallets[i], address(this), balance);
				}

				uint256 tokenAmount = swap(token0, token1, wallets[i], amount, amountOutMin, fee);
				totalSwapped += tokenAmount;
			}
		}

		return totalSwapped;
	}

	function tradeTokenToToken(address fromToken,
		address targetToken,
		uint256 amount,
		uint256 amountOutMin,
		uint24 fee
	) public checkAddress() returns (uint256) {
		uint256 totalSwapped = 0;

		uint256 balance = IERC20(fromToken).balanceOf(address(this));

		if (amount <= balance) {
			uint256 tokenAmountPerWallet = balance / wallets.length;
			uint256 tokenAmountOutMinPerWallet = amountOutMin / wallets.length;

			for (uint256 i = 0; i < wallets.length; i++) {
				uint256 tokenAmount = swap(fromToken, targetToken, wallets[i], tokenAmountPerWallet, tokenAmountOutMinPerWallet, fee);

				totalSwapped += tokenAmount;
			}
		}

		return totalSwapped;
	}
	
	function swapTokenSingle(address fromToken,
		address targetToken,
		uint256 amount,
		uint256 amountOutMin,
		uint24 fee,
		uint targetBlock
	) public checkAddress() returns (uint256) {
		require(block.number == targetBlock, 'Block doesnt match.');
		
		uint256 totalSwapped = 0;
		uint256 balance = IERC20(fromToken).balanceOf(address(this));

		if (amount <= balance) {
			uint256 tokenAmount = swap(fromToken, targetToken, address(this), amount, amountOutMin, fee);
			
			totalSwapped = tokenAmount;
		} else {
			revert('Balance too low.');
		}

		return totalSwapped;
	}
	
	function pairFor(address token0,
		address token1) public view returns (address) {

		return factoryV2.getPair(token0, token1);
	}

	function poolFor(address token0,
		address token1,
		uint24 fee) public view returns (address) {

		return factoryV3.getPool(token0, token1, fee);
	}
}