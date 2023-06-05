// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";


import "./ISwapRouter.sol";
import "./IQuoterV2.sol";


import "./IUniswapV3Pool.sol";
import "./IPancakeV3LmPool.sol";
import "./IUniswapV3Factory.sol";

import "./IMasterChefV3.sol";

import "./ICompute.sol";
import "./INonfungiblePositionManager.sol";
import "./IWETH9.sol";
import "./IAssets.sol";


contract StakedV3 is Ownable,ReentrancyGuard {
	using SafeMath for uint256;
	using SafeCast for uint256;
	
	
	address public route;
	address public quotev2;
	address public compute;
	address public assets;

	address public factory;
	address public weth;
	address public manage;

	uint public fee;
	

	struct pool {
		address token0; 		//质押币种合约地址
		address token1;		//另一种币种合约地址
		address pool;		//pool 合约地址
		address farm;		//farm 地址
		uint24 fee;			//pool手续费
		uint point;			//滑点
		bool inStatus;		//是否开启质押
		bool outStatus;		//是否可以提取
		uint tokenId;		//质押的nft tokenId
		uint wight0;
		uint wight1;
		uint lp0;
		uint lp1;
	}

	// 是否自动进行Farm
	mapping(uint => bool) public isFarm;
	// 滑点最大比率 * 2
	uint private pointMax = 10 ** 8;
	// 项目库
	mapping(uint => pool) public pools;

	event VerifyUpdate(address signer);
	event Setting(address route,address quotev2,address compute,address factory,address weth,address manage);
	event InvestToken(uint pid,address user,uint amount,uint investType,uint cycle,uint time);
	event ExtractToken(uint pid,address user,address token,uint amount,uint fee,uint tradeType,uint time);

	constructor (
		address _route,
		address _quotev2,
		address _compute,
		address _assets,
		uint _fee
	) {
		_setting(_route,_quotev2,_compute,_assets,_fee);
	}

	// 接收ETH NFT
    receive() external payable {}
    fallback() external payable {}
	function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

	function _tokenSend(
        address _token,
        uint _amount
    ) private returns (bool result) {
        if(_token == address(0)){
            Address.sendValue(payable(msg.sender),_amount);
            result = true;
        }else{
            IERC20 token = IERC20(_token);
            result = token.transfer(msg.sender,_amount);
        }
    }

	function balanceOf(
		address _token
	) public view returns (uint balance) {
		if(_token == weth) {
			balance = address(this).balance;
		}else {
			IERC20 token = IERC20(_token);
            balance = token.balanceOf(address(this));
		}
	}

	function unWrapped() private {
		IERC20 token = IERC20(weth);
        uint balance = token.balanceOf(address(this));
		if(balance > 0) {
			IWETH9(weth).withdraw(balance);
		}
	}

	function pointHandle(
		uint point,
		uint amount,
		bool isplus
	) private view returns (uint result) {
		uint rate = 1;
		if(isplus) {
			rate = pointMax.add(point);
		}else {
			rate = pointMax.sub(point);
		}
		result = amount.mul(rate).div(pointMax);
	}

	function abs(
		int x
	) private pure returns (int) {
		return x >= 0 ? x : -x;
	}

	// Balance check attempted to distribute and returned whether the distribution was successful
	function extractAmount(
		address token,
		uint amount
	) private returns (bool) {
		uint balance = balanceOf(token);
		// Is the platform's storage sufficient for direct distribution
		if(balance >= amount) {
			if(token != weth) {
				require(_tokenSend(token,amount),"Staked::extract fail");
			}else {
				require(_tokenSend(address(0),amount),"Staked::extract fail");
			}
			return true;
		}else {
			return false;
		}
	}

	// Activate failed projects
	function Reboot(
		uint id,
		uint deadline
	) public onlyOwner {
		
		(bool pass,PoolToken memory tokens) = Challenge(id);
		if(!pass) {
			// Harvest income
			_harvest(id);
			// Remove all liquidity from the current project Farm
			_remove(id,tokens,deadline);

			// Exchange into pledged currency
			_reSwap(id,tokens);
			// Withdrawal of NFT
			_withdraw(id);

			// Update the latest currency price ratio
			wightReset(id);

			// Convert a single currency to two currencies for Farm
			uint amount0 = lpRate(id);
			(uint amountOut,) = _amountOut(id,pools[id].token0,pools[id].token1,amount0,false);

			Swap(id,pools[id].token0,pools[id].token1,amount0,amountOut,0);
			Mint(id,deadline);
		}
	}
	
	// Handling When Extracting Token Liquidity Fails
	function invalid(
		uint id,
		address token,
		uint amount,
		uint deadline,
		PoolToken memory tokens
	) private {
		// Harvest income
		_harvest(id);
		// Remove all liquidity from the current project Farm
		_remove(id,tokens,deadline);
		// bytes memory path;
		uint amountOut;
		uint balance;

		// Convert all to extraction currency
		if(tokens.token0 == token) {
			if(tokens.amount0 == 0) {
				(amountOut,balance) = _amountOut(id,tokens.token1,tokens.token0,0,true);
				Swap(id,tokens.token1,tokens.token0,balance,amountOut,0);
			}
		}else {
			if(tokens.amount1 == 0) {
				(amountOut,balance) = _amountOut(id,tokens.token0,tokens.token1,0,true);
				Swap(id,tokens.token0,tokens.token1,balance,amountOut,0);
			}
		}
		// Second attempt to distribute
		bool result = extractAmount(token,amount);
		require(result,"Staked::extraction failed (invalid:Insufficient reserves1)");
		// Withdrawal of NFT and Reset of Farm Pledge
		_withdraw(id);
		// Convert all to pledge currency
		if(pools[id].token0 != token) {
			(amountOut,balance) = _amountOut(id,pools[id].token1,pools[id].token0,0,true);
			Swap(id,pools[id].token1,pools[id].token0,balance,amountOut,0);
		}
		
		// Update the latest currency price ratio
		wightReset(id);

		// Convert a single currency to two currencies for Farm
		uint amount0 = lpRate(id);
		(amountOut,) = _amountOut(id,pools[id].token0,pools[id].token1,amount0,false);
		Swap(id,pools[id].token0,pools[id].token1,amount0,amountOut,0);
		Mint(id,deadline);
	}
	
	function wightReset(
		uint id
	) private {
		(uint amountOut,) = _amountOut(id,pools[id].token0,pools[id].token1,10 ** 18,false);
		pools[id].wight0 = 10 ** 18;
		pools[id].wight1 = amountOut;
	}

	function tryRun(
		uint id,
		address token,
		uint amount,
		uint deadline,
		PoolToken memory tokens,
		uint liquidity
	) private returns (bool) {
		
		if(tokens.liquidity > liquidity) {
			tokens.liquidity = uint128(liquidity);
		}else {
			tokens.liquidity = uint128(tokens.liquidity * 9999 / 10000);
		}
		require(tokens.liquidity > 0,"Staked::insufficient liquidity (valid)");
		(tokens.amount0,tokens.amount1) = ICompute(compute).getAmountsForLiquidity(tokens.sqrtPriceX96,tokens.sqrtRatioAX96,tokens.sqrtRatioBX96,tokens.liquidity);
		_remove(id,tokens,deadline);
		// Attempt to distribute
		bool result = extractAmount(token,amount);
		uint balance;
		if(!result) {
			if(token == tokens.token0) {
				balance = balanceOf(tokens.token1);
				tokens.amount1 = tokens.amount1 > balance ? balance : tokens.amount1;
				Swap(id,tokens.token1,tokens.token0,tokens.amount1,6,0);
			}else {
				balance = balanceOf(tokens.token0);
				tokens.amount0 = tokens.amount0 > balance ? balance : tokens.amount0;
				Swap(id,tokens.token0,tokens.token1,tokens.amount0,6,0);
			}
			// Attempt to distribute
			result = extractAmount(token,amount);
		}
		return result;
	}

	function valid(
		uint id,
		address token,
		uint amount,
		uint deadline,
		PoolToken memory tokens
	) private {
		uint liquidity;
		uint balance = balanceOf(token);
		uint temp = amount.sub(balance).div(2);
		temp = temp >= 1 ? temp : 1;

		if(token == tokens.token0 && tokens.amount0 > 0) {
			liquidity = tokens.liquidity * temp / tokens.amount0;
		}else if(tokens.amount1 > 0) {
			liquidity = tokens.liquidity * temp / tokens.amount1;
		}
		// Remove floating 2%
		uint upAmount = liquidity * 102 / 100;
		if(upAmount > tokens.liquidity) {
			liquidity = liquidity * 101 / 100;
		}else {
			liquidity = upAmount;
		}
		// The second and third times
		bool result = tryRun(id,token,amount,deadline,tokens,liquidity);

		if(!result) {
			balance = balanceOf(token);
			uint outAmount = amount.sub(balance).mul(102).div(100);
			(,tokens) = Challenge(id);
			liquidity = uint128(liquidity * outAmount / temp);
			// The fourth and fifth time
			result = tryRun(id,token,amount,deadline,tokens,liquidity);
		}
		
		require(result,"Staked::final extraction failed");
	}

	function lpExtract(
		uint id,
		address token,
		uint amount,
		uint deadline
	) private {
		require(pools[id].token0 == token || pools[id].token1 == token,"Staked::does not support decompression");
		// First attempt to distribute
		bool result = extractAmount(token,amount);
		
		if(!result) {
			require(pools[id].tokenId != 0,"Staked::insufficient liquidity (lpExtract)");
			(bool pass,PoolToken memory tokens) = Challenge(id);
			// Is liquidity ineffective
			if(pass) {
				valid(id,token,amount,deadline,tokens);
			}else {
				invalid(id,token,amount,deadline,tokens);
			}
			
		}
	}

	function unlpExtract(
		uint amount,
		address token
	) private {
		uint balance = balanceOf(token);
		if(token != weth) {
			require(balance >= amount,"Staked::insufficient funds reserves");
			require(_tokenSend(token,amount),"Staked::profit extract fail");
		}else {
			require(balance >= amount,"Staked::insufficient funds reserves");
			require(_tokenSend(address(0),amount),"Staked::profit extract fail");
		}
	}

	function Extract(
		uint id,
		uint tradeType,
		address token,
		uint amount,
		uint deadline
	) public nonReentrant {
		require(pools[id].outStatus,"Staked::extract closed");
		require(deadline > block.timestamp,"Staked::transaction lapsed");
		
		
		uint reduceAmount = amount;
		// Asset inspection
		amount = pointMax.sub(fee).mul(amount).div(pointMax);
		uint total = IAssets(assets).asset(msg.sender,id,token);
		require(total >= amount,"Staked::Overdrawing");

		// Is the income in the currency that constitutes lp
		if(pools[id].token0 == token) {
			lpExtract(id,token,amount,deadline);
		} else if(pools[id].token1 == token) {
			lpExtract(id,token,amount,deadline);
		} else {
			unlpExtract(amount,token);
		}
		// Accounting
		IAssets(assets).reduceAlone(msg.sender,id,token,reduceAmount);
		emit ExtractToken(id,msg.sender,token,amount,reduceAmount.sub(amount),tradeType,block.timestamp);
	}

	function Convert(
		address tokenIn,
		uint inAmount,
		uint outAmount,
		bytes memory path,
		uint side
	) public onlyOwner {
		_swap(tokenIn,inAmount,outAmount,path,side);
	}


	function pendingReward(
		uint id
	) public view returns (uint256 reward) {
		reward = IMasterChefV3(pools[id].farm).pendingCake(pools[id].tokenId);
	}

	function harvestFarm(
		uint id
	) public onlyOwner {
		_harvest(id);
	}
	function _harvest(
		uint id
	) private {
		IMasterChefV3(pools[id].farm).harvest(pools[id].tokenId,address(this));
	}

	function withdrawNFT(
		uint tokenId
	) public onlyOwner {
		INonfungiblePositionManager(manage).safeTransferFrom(address(this),msg.sender,tokenId);
	}

	function withdrawFarm(
		uint id,
		uint deadline
	) public onlyOwner {
		_harvest(id);
		(,PoolToken memory tokens) = Challenge(id);
		_remove(id,tokens,deadline);
		_withdraw(id);
	}

	function _withdraw(
		uint id
	) private {
		IMasterChefV3(pools[id].farm).withdraw(pools[id].tokenId,address(this));
		// Reset tokenId to 0
		pools[id].tokenId = 0;
	}

	function Invest(
		uint id,
		uint amount,
		uint quoteAmount,
		uint investType,
		uint cycle,
		uint deadline
	) public payable nonReentrant {
		require(pools[id].inStatus,"Staked::invest project closed");
		require(deadline > block.timestamp,"Staked::transaction lapsed");
		// Pledged Tokens
		if(pools[id].token0 == weth) {
			require(msg.value == amount,"Staked::input eth is not accurate");
		}else {
			TransferHelper.safeTransferFrom(pools[id].token0,msg.sender,address(this),amount);
		}
		uint balance = balanceOf(pools[id].token0);
		uint amount0 = lpRate(id);

		if(isFarm[id]) {
			// Liquidity check
			(bool pass,PoolToken memory tokens) = Challenge(id);
			if(!pass) {
				// Harvest income
				_harvest(id);
				// Remove liquidity
				_remove(id,tokens,deadline);
				// Exchange into pledged currency
				_reSwap(id,tokens);
				// Withdrawal of NFT
				_withdraw(id);
				// Update the latest currency price ratio
				wightReset(id);
			}
			// Token exchange
			// Number of tokens participating in redemption
			balance = balanceOf(pools[id].token0);
			amount0 = lpRate(id);
			// QuoteAmount Recalculate Valuation
			if(!pass) {
				(quoteAmount,) = _amountOut(id,pools[id].token0,pools[id].token1,amount0,false);
			}
			// Exchange token 1 token 0: Spend a fixed number of tokens
			Swap(id,pools[id].token0,pools[id].token1,amount0,quoteAmount,0);

			// Add liquidity
			if(pools[id].tokenId == 0) {
				// Mint
				Mint(id,deadline);
			}else {
				// Append
				Append(id,tokens,deadline);
			}
		}
		if(amount > 0) {
			// Accounting
			if(investType == 1) {
				IAssets(assets).plusAlone(msg.sender,id,pools[id].token0,amount);
			}
			emit InvestToken(id,msg.sender,amount,investType,cycle,block.timestamp);
		}
	}

	struct PoolToken {
		address token0;
		address token1;
		uint amount0;
		uint amount1;
		int24 tickLower;
		int24 tickUpper;
		uint160 sqrtPriceX96;
		uint160 sqrtRatioAX96;
		uint160 sqrtRatioBX96;
		uint128 liquidity;
	}

	// Converting tokens from ineffective liquidity into pledged tokens
	function _reSwap(
		uint id,
		PoolToken memory tokens
	) private {
		uint balance;
		uint amountOut;
		if(tokens.amount0 != 0) {
			if(tokens.token0 != pools[id].token0) {
				(amountOut,balance) = _amountOut(id,tokens.token0,tokens.token1,0,true);
				Swap(id,tokens.token0,tokens.token1,balance,amountOut,0);
			}
		}else if(tokens.amount1 != 0) {
			if(tokens.token1 == pools[id].token1) {
				(amountOut,balance) = _amountOut(id,tokens.token1,tokens.token0,0,true);
				Swap(id,tokens.token1,tokens.token0,balance,amountOut,0);
			}
		}
	}

	function _amountOut(
		uint id,
		address tokenIn,
		address tokenOut,
		uint amountIn,
		bool all
	) private returns (uint outAmount,uint inAmount) {
		if(all) {
			amountIn = balanceOf(tokenIn);
		}
		bytes memory path = abi.encodePacked(tokenIn,pools[id].fee,tokenOut);
		(outAmount,,,) = IQuoterV2(quotev2).quoteExactInput(path,amountIn);
		inAmount = amountIn;
	}

	function _remove(
		uint id,
		PoolToken memory tokens,
		uint deadline
	) private {
		uint min0 = pointHandle(pools[id].point,tokens.amount0,false);
		uint min1 = pointHandle(pools[id].point,tokens.amount1,false);
		if(tokens.liquidity > 0) {
			IMasterChefV3(pools[id].farm).decreaseLiquidity(
				IMasterChefV3.DecreaseLiquidityParams({
					tokenId:pools[id].tokenId,
					liquidity:tokens.liquidity,
					amount0Min:min0,
					amount1Min:min1,
					deadline:deadline
				})
			);
		}
		IMasterChefV3(pools[id].farm).collect(
			IMasterChefV3.CollectParams({
				tokenId:pools[id].tokenId,
				recipient:address(this),
				amount0Max:uint128(0xffffffffffffffffffffffffffffffff),
				amount1Max:uint128(0xffffffffffffffffffffffffffffffff)
			})
		);
		unWrapped();
	}

	function MintTick(
		uint id
	) private view returns (uint160,uint160,uint160,int24,int24) {
		(uint160 sqrtPriceX96,int24 tick,,,,,) = IUniswapV3Pool(pools[id].pool).slot0();
		int24 tickSpacing = IUniswapV3Pool(pools[id].pool).tickSpacing();
		int256 grap = abs(tick * pools[id].point.toInt256() / pointMax.toInt256());
		int24 tickLower;
		int24 tickUpper;
		if(grap > tickSpacing) {
			tickLower = int24((tick - grap) / tickSpacing * tickSpacing);
			tickUpper = int24((tick + grap) / tickSpacing * tickSpacing);
		}else {
			int256 multiple = abs(tick / tickSpacing);
			if(multiple >= 1) {
				tickLower = int24(-tickSpacing * (multiple + 3));
				tickUpper = int24(tickSpacing * (multiple + 3));
			}else {
				tickLower = int24(-tickSpacing * 3);
				tickUpper = int24(tickSpacing * 3);
			}
			if(tickUpper > 887272) {
				tickLower = int24(-887272 / tickSpacing * tickSpacing);
				tickUpper = int24(887272 / tickSpacing * tickSpacing);
			}
		}
	
		uint160 sqrtRatioAX96 = ICompute(compute).sqrtRatioAtTick(tickLower);
		uint160 sqrtRatioBX96 = ICompute(compute).sqrtRatioAtTick(tickUpper);
		return (sqrtPriceX96,sqrtRatioAX96,sqrtRatioBX96,tickLower,tickUpper);
	}

	function Mint(
		uint id,
		uint deadline
	) private {
		(uint160 sqrtPriceX96,uint160 sqrtRatioAX96,uint160 sqrtRatioBX96,int24 tickLower,int24 tickUpper) = MintTick(id);
		// Corresponding correct currency and quantity
		bool correct = pools[id].token0 < pools[id].token1;
		PoolToken memory tokens;
		if(correct) {
			tokens = PoolToken({
				token0:pools[id].token0,
				token1:pools[id].token1,
				amount0:balanceOf(pools[id].token0),
				amount1:balanceOf(pools[id].token1),
				tickLower:tickLower,
				tickUpper:tickUpper,
				sqrtPriceX96:sqrtPriceX96,
				sqrtRatioAX96:sqrtRatioAX96,
				sqrtRatioBX96:sqrtRatioBX96,
				liquidity:0
			});
		}else {
			tokens = PoolToken({
				token0:pools[id].token1,
				token1:pools[id].token0,
				amount0:balanceOf(pools[id].token1),
				amount1:balanceOf(pools[id].token0),
				tickLower:tickLower,
				tickUpper:tickUpper,
				sqrtPriceX96:sqrtPriceX96,
				sqrtRatioAX96:sqrtRatioAX96,
				sqrtRatioBX96:sqrtRatioBX96,
				liquidity:0
			});
		}
		uint128 liquidity = ICompute(compute).getLiquidityForAmounts(sqrtPriceX96,sqrtRatioAX96,sqrtRatioBX96,tokens.amount0,tokens.amount1);
		(tokens.amount0,tokens.amount1) = ICompute(compute).getAmountsForLiquidity(sqrtPriceX96,sqrtRatioAX96,sqrtRatioBX96,liquidity);
		_mint(id,tokens,deadline);
	}

	function _mint(
		uint id,
		PoolToken memory tokens,
		uint deadline
	) private {
		require(tokens.amount0 > 0,"Staked::Abnormal liquidity");
		require(tokens.amount1 > 0,"Staked::Abnormal liquidity");
		uint ethAmount = 0;
		
		if(tokens.token0 != weth) {
			TransferHelper.safeApprove(tokens.token0,manage,tokens.amount0);
		} else {
			ethAmount = tokens.amount0;
		}
		if(tokens.token1 != weth) {
			TransferHelper.safeApprove(tokens.token1,manage,tokens.amount1);
		} else {
			ethAmount = tokens.amount1;
		}
		uint amount0;
		uint amount1;
		// Add liquidity location
		(pools[id].tokenId,,amount0,amount1) = INonfungiblePositionManager(manage).mint{ value:ethAmount }(
			INonfungiblePositionManager.MintParams({
				token0:tokens.token0,
				token1:tokens.token1,
				fee:pools[id].fee,
				tickLower:tokens.tickLower,
				tickUpper:tokens.tickUpper,
				amount0Desired:tokens.amount0,
				amount1Desired:tokens.amount1,
				amount0Min:1,
				amount1Min:1,
				recipient:address(this),
				deadline:deadline
			})
		);
		if(tokens.token0 == pools[id].token0) {
			pools[id].lp0 = amount0;
			pools[id].lp1 = amount1;
		}else {
			pools[id].lp0 = amount1;
			pools[id].lp1 = amount0;
		}
		// Farm Pledge
		INonfungiblePositionManager(manage).safeTransferFrom(address(this),pools[id].farm,pools[id].tokenId);
	}

	function Challenge(
		uint id
	) public view returns (bool result,PoolToken memory tokens) {
		uint amount0;
		uint amount1;
		int24 tickLower;
		int24 tickUpper;
		uint160 sqrtPriceX96;
		uint160 sqrtRatioAX96;
		uint160 sqrtRatioBX96;
		if(pools[id].tokenId == 0) {
			result = true;
		} else {
			IMasterChefV3.UserPositionInfo memory tokenPosition = IMasterChefV3(pools[id].farm).userPositionInfos(pools[id].tokenId);
			tickLower = tokenPosition.tickLower;
			tickUpper = tokenPosition.tickUpper;

			(sqrtPriceX96,,,,,,) = IUniswapV3Pool(pools[id].pool).slot0();
			sqrtRatioAX96 = ICompute(compute).sqrtRatioAtTick(tickLower);
			sqrtRatioBX96 = ICompute(compute).sqrtRatioAtTick(tickUpper);
			
			(amount0,amount1) = ICompute(compute).getAmountsForLiquidity(sqrtPriceX96,sqrtRatioAX96,sqrtRatioBX96,tokenPosition.liquidity);
			if(amount0 == 0 || amount1 == 0) {
				result = false;
			}else {
				result = true;
			}
			bool correct = pools[id].token0 < pools[id].token1;
			tokens = PoolToken({
				token0:correct ? pools[id].token0 : pools[id].token1,
				token1:correct ? pools[id].token1 : pools[id].token0,
				amount0:amount0,
				amount1:amount1,
				tickLower:tickLower,
				tickUpper:tickUpper,
				sqrtPriceX96:sqrtPriceX96,
				sqrtRatioAX96:sqrtRatioAX96,
				sqrtRatioBX96:sqrtRatioBX96,
				liquidity:tokenPosition.liquidity
			});
		}
	}

	function Append(
		uint id,
		PoolToken memory tokens,
		uint deadline
	) private {
		require(pools[id].tokenId != 0,"Staked::no liquidity position");

		uint amount0 = balanceOf(tokens.token0);
		uint amount1 = balanceOf(tokens.token1);

		uint128 liquidity = ICompute(compute).getLiquidityForAmounts(tokens.sqrtPriceX96,tokens.sqrtRatioAX96,tokens.sqrtRatioBX96,amount0,amount1);
		(tokens.amount0,tokens.amount1) = ICompute(compute).getAmountsForLiquidity(tokens.sqrtPriceX96,tokens.sqrtRatioAX96,tokens.sqrtRatioBX96,liquidity);
		_append(id,tokens,deadline);
	} 

	function _append(
		uint id,
		PoolToken memory tokens,
		uint deadline
	) private {
		require(tokens.amount0 > 0,"Staked::Abnormal liquidity");
		require(tokens.amount1 > 0,"Staked::Abnormal liquidity");
		uint ethAmount = 0;
		if(tokens.token0 != weth) {
			TransferHelper.safeApprove(tokens.token0,pools[id].farm,tokens.amount0);
		} else {
			ethAmount = tokens.amount0;
		}
		if(tokens.token1 != weth) {
			TransferHelper.safeApprove(tokens.token1,pools[id].farm,tokens.amount1);
		} else {
			ethAmount = tokens.amount1;
		}
		(,uint amount0,uint amount1) = IMasterChefV3(pools[id].farm).increaseLiquidity{ value:ethAmount }(
			IMasterChefV3.IncreaseLiquidityParams({
				tokenId:pools[id].tokenId,
				amount0Desired:tokens.amount0,
				amount1Desired:tokens.amount1,
				amount0Min:1,
				amount1Min:1,
				deadline:deadline
			})
		);
		if(tokens.token0 == pools[id].token0) {
			pools[id].lp0 = amount0;
			pools[id].lp1 = amount1;
		}else {
			pools[id].lp0 = amount1;
			pools[id].lp1 = amount0;
		}
	}
	

	// Side 0: Spending fixed quantity tokens 1: Booking fixed quantity tokens
	function Swap(
		uint id,
		address tokenIn,
		address tokenOut,
		uint inAmount,
		uint outAmount,
		uint side
	) private returns (uint,uint) {
		bytes memory path;
		if(side == 0) {
			path = abi.encodePacked(tokenIn,pools[id].fee,tokenOut);
			outAmount = pointHandle(pools[id].point,outAmount,false);
		}else if(side == 1) {
			path = abi.encodePacked(tokenOut,pools[id].fee,tokenIn);
			inAmount = pointHandle(pools[id].point,inAmount,true);
		}
		if(inAmount > 0 && outAmount > 0) {
			_swap(tokenIn,inAmount,outAmount,path,side);
		}
		return (inAmount,outAmount);
	}
	
	function _swap(
		address tokenIn,
		uint inAmount,
		uint outAmount,
		bytes memory path,
		uint side
	) private {
		uint ethAmount = 0;
		if(tokenIn != weth) {
			TransferHelper.safeApprove(tokenIn,route,inAmount);
		}else {
			ethAmount = inAmount;
		}
		
		if(side == 0) {
			// Perform a fixed input exchange, if the execution fails, retrieve the exchange rate and try to execute it again
			try ISwapRouter(route).exactInput{ value:ethAmount }(
				ISwapRouter.ExactInputParams({
					path:path,
					recipient:address(this),
					amountIn:inAmount,
					amountOutMinimum:outAmount
				})
			) {} catch {
				(outAmount,,,) = IQuoterV2(quotev2).quoteExactInput(path,inAmount);
				ISwapRouter(route).exactInput{ value:ethAmount }(
					ISwapRouter.ExactInputParams({
						path:path,
						recipient:address(this),
						amountIn:inAmount,
						amountOutMinimum:outAmount
					})
				);
			}
		}else if(side == 1) {
			// Perform a fixed output exchange, if the execution fails, retrieve the exchange rate and try to execute it again
			try ISwapRouter(route).exactOutput{ value:ethAmount }(
				ISwapRouter.ExactOutputParams({
					path:path,
					recipient:address(this),
					amountOut:outAmount,
					amountInMaximum:inAmount
				})
			) {} catch {
				(inAmount,,,) = IQuoterV2(quotev2).quoteExactOutput(path,outAmount);
				ISwapRouter(route).exactOutput{ value:ethAmount }(
					ISwapRouter.ExactOutputParams({
						path:path,
						recipient:address(this),
						amountOut:outAmount,
						amountInMaximum:inAmount
					})
				);
			}
		}
		unWrapped();
	}

	function poolCreat(
		uint _id,
		address _token0,
		address _token1,
		uint24 _fee,
		uint _point,
		uint[] memory _level0,
		uint[] memory _level1
	) public onlyOwner nonReentrant {
		require(pools[_id].pool == address(0),"Staked::project existent");
		require(_point < pointMax,"Staked::invalid slippage");
		require(_token0 != _token1,"Staked::invalid pair");

		address tokenIn = _token0 == address(0) ? weth : _token0;
		address tokenOut = _token1 == address(0) ? weth : _token1;

		address _pool = IUniswapV3Factory(factory).getPool(tokenIn,tokenOut,_fee);
		require(_pool != address(0),"Staked::liquidit pool non-existent");
		address _lmPool = IUniswapV3Pool(_pool).lmPool();
		require(_lmPool != address(0),"Staked::does not support farms");
		address _farm = IPancakeV3LmPool(_lmPool).masterChef();
		require(_farm != address(0),"Staked::not bound to farm");
		pools[_id] = pool({
			token0:tokenIn,
			token1:tokenOut,
			fee:_fee,
			pool:_pool,
			farm:_farm,
			point:_point,
			inStatus:true,
			outStatus:true,
			tokenId:uint(0),
			wight0:_level0[0],
			wight1:_level1[0],
			lp0:_level0[1],
			lp1:_level1[1]
		});
		_autoFarm(_id,true);
	}

	// Calculate the amount of participation in exchange through value and liquidity ratio before calculating the pledge
	function lpRate(
		uint id
	) public view returns (uint inAmount) {
		uint balance = balanceOf(pools[id].token0);
		uint rate0 = pools[id].lp0.mul(pools[id].wight1);
		rate0 = rate0.div(pools[id].wight0);
		uint rate1 = pools[id].lp1;
		uint total = rate0.add(rate1);
		if(total > 0) {
			inAmount = rate1.mul(balance).div(total);
			if(inAmount == 0) {
				inAmount = balance.div(2);
			}
		}else {
			inAmount = balance.div(2);
		}
	}

	function poolControl(
		uint _id,
		bool _in,
		bool _out,
		uint _point,
		uint[] memory _level0,
		uint[] memory _level1
	) public onlyOwner {
		require(_point < pointMax,"Staked::invalid slippage");
		pools[_id].inStatus = _in;
		pools[_id].outStatus = _out;
		pools[_id].point = _point;

		require(_level0[0] > 0,"Staked::level0[0] > 0");
		require(_level1[0] > 0,"Staked::level1[0] > 0");
		require(_level0[1] > 0,"Staked::level0[1] > 0");
		require(_level1[1] > 0,"Staked::level1[1] > 0");
		pools[_id].wight0 = _level0[0];
		pools[_id].wight1 = _level1[0];
		pools[_id].lp0 = _level0[1];
		pools[_id].lp1 = _level1[1];
	}


	function setting(
		address _route,
		address _quotev2,
		address _compute,
		address _assets,
		uint _fee
	) public onlyOwner {
		_setting(_route,_quotev2,_compute,_assets,_fee);
	}

	function _setting(
		address _route,
		address _quotev2,
		address _compute,
		address _assets,
		uint _fee
	) private {
		require(_route != address(0),"Staked::invalid route address");
		require(_quotev2 != address(0),"Staked::invalid quotev2 address");
		require(_compute != address(0),"Staked::invalid compute address");
		route = _route;
		quotev2 = _quotev2;
		compute = _compute;
		assets = _assets;
		fee = _fee;
		factory = ISwapRouter(_route).factory();
		weth = ISwapRouter(_route).WETH9();
		manage = ISwapRouter(_route).positionManager();
		emit Setting(route,quotev2,compute,factory,weth,manage);
	}

	function autoFarm(
		uint _id,
		bool _auto
	) public onlyOwner {
		_autoFarm(_id,_auto);
	}

	function _autoFarm(
		uint _id,
		bool _auto
	) private {
		isFarm[_id] = _auto;
	}

}
