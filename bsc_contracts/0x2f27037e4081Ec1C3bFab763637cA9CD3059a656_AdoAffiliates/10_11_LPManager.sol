// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./abstracts/Context.sol";
import "./libraries/SafeMath.sol";
import "./AdoToken.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IPancakeSwapV2Pair.sol";
import "./interfaces/IPancakeSwapV2Router02.sol";

contract LPManager is Context {
	using SafeMath for uint256;

	address private _owner;
	uint private _lockedUntil;
	address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
	AdoToken public tokenContract;
	address public mainLPToken;
	IBEP20 public busdContract;
	IPancakeSwapV2Router02 public pancakeSwapV2Router;
	IPancakeSwapV2Pair public pancakeSwapWETHV2Pair;
	IPancakeSwapV2Pair public pancakeSwapBUSDV2Pair;

	event LPLocked(uint indexed newDate);

	modifier onlyOwner() {
		require(_owner == _msgSender(), "LPManager: caller is not the owner");
		_;
	}

	modifier onlyTokenContract() {
		require(
			_msgSender() == address(tokenContract),
			"LPManager: Only the token contract can call this function"
		);
		_;
	}

	constructor(AdoToken _tokenContract) {
		_owner = _msgSender();
		tokenContract = _tokenContract;
		_lockedUntil = block.timestamp;
	}

	receive() external payable {}

	function owner() external view returns (address) {
		return _owner;
	}

	function lpWBNB() external view returns (uint256) {
		return pancakeSwapWETHV2Pair.balanceOf(address(this));
	}

	function lpBUSD() external view returns (uint256) {
		return pancakeSwapBUSDV2Pair.balanceOf(address(this));
	}

	function totalWBNBLPs() external view returns (uint256) {
		return pancakeSwapWETHV2Pair.totalSupply();
	}

	function totalBUSDLPs() external view returns (uint256) {
		return pancakeSwapBUSDV2Pair.totalSupply();
	}

	function lockedUntil() external view returns (uint) {
		return _lockedUntil;
	}

	function updateTokenDetails() external onlyOwner {
		require(address(tokenContract.pancakeSwapV2Router()) != address(0), "LPManager: PancakeSwapV2Router is invalid");
		require(address(tokenContract.busdContract()) != address(0), "LPManager: BusdContract is invalid");
		require(address(tokenContract.pancakeSwapWETHV2Pair()) != address(0), "LPManager: PancakeSwap WETHV2Pair: is invalid");
		require(address(tokenContract.pancakeSwapBUSDV2Pair()) != address(0), "LPManager: PancakeSwap BUSDV2Pair is invalid");
		pancakeSwapV2Router = tokenContract.pancakeSwapV2Router();
		busdContract = tokenContract.busdContract();
		pancakeSwapWETHV2Pair = tokenContract.pancakeSwapWETHV2Pair();
		pancakeSwapBUSDV2Pair = tokenContract.pancakeSwapBUSDV2Pair();
		mainLPToken = tokenContract.mainLPToken();
	}

	function checkAmountsOut() public view returns (bool, uint256, uint256) {
		address[] memory path = new address[](3);
		path[0] = address(tokenContract);
		path[1] = mainLPToken;
		path[2] = mainLPToken == pancakeSwapV2Router.WETH()
			? address(busdContract)
			: pancakeSwapV2Router.WETH();
		uint256 mp = pancakeSwapV2Router.getAmountsOut(10**18, path)[1];
		path[1] = path[2];
		path[2] = mainLPToken;
		uint256 sp = pancakeSwapV2Router.getAmountsOut(10**18, path)[2];
		uint256 op = mp.div(100);
		uint256 tp = op.mul(3);
		if (sp >= mp) {
			return (false, mp.sub(tp), mp.sub(op));
		} else {
			uint256 pd = mp.sub(sp);
			return (pd > op && pd < tp, mp.sub(tp), mp.sub(op));
		}
	}

	function switchPool(uint256 bp) external onlyTokenContract returns (address, bool) {
		require(pancakeSwapWETHV2Pair.balanceOf(address(this)) > 0, "LPManager: ADO WETH LPs Balance is 0");
		require(pancakeSwapBUSDV2Pair.balanceOf(address(this)) > 0, "LPManager: ADO BUSD LPs Balance is 0");
		(bool canBeSwitched,,) = checkAmountsOut();
		require(canBeSwitched == true, "LPManager: The parity between the liquidity pools is invalid");
		bool updateBB = false;
		if (mainLPToken == pancakeSwapV2Router.WETH()) {
			uint256 liquidity = pancakeSwapWETHV2Pair.balanceOf(address(this)).div(100).mul(99);
			pancakeSwapWETHV2Pair.approve(address(pancakeSwapV2Router), liquidity);
			uint256 amountETH = pancakeSwapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
				address(tokenContract),
				liquidity,
				0,
				0,
				address(this),
				block.timestamp
			);
			uint256 amountADO = tokenContract.balanceOf(address(this));
			if (bp > 0) {
				uint256 burn = amountADO.div(100).mul(bp);
				tokenContract.transfer(BURN_ADDRESS, burn);
				amountADO = amountADO.sub(burn);
			}
			address[] memory path = new address[](2);
			path[0] = pancakeSwapV2Router.WETH();
			path[1] = address(busdContract);
			pancakeSwapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(
				0,
				path,
				address(this),
				block.timestamp
			);
			uint256 amountBUSD = busdContract.balanceOf(address(this));
			busdContract.approve(address(pancakeSwapV2Router), amountBUSD);
			tokenContract.approve(address(pancakeSwapV2Router), amountADO);
			pancakeSwapV2Router.addLiquidity(
				address(tokenContract),
				address(busdContract),
				amountADO,
				amountBUSD,
				amountADO,
				0,
				address(this),
				block.timestamp
			);
			amountBUSD = busdContract.balanceOf(address(this));
			if (amountBUSD > 0) {
				busdContract.transfer(address(tokenContract), amountBUSD);
			}
			mainLPToken = address(busdContract);
		} else {
			uint256 liquidity = pancakeSwapBUSDV2Pair.balanceOf(address(this)).div(100).mul(99);
			pancakeSwapBUSDV2Pair.approve(address(pancakeSwapV2Router), liquidity);
			(uint256 amountADO, uint256 amountBUSD) = pancakeSwapV2Router.removeLiquidity(
				address(tokenContract),
				address(busdContract),
				liquidity,
				0,
				0,
				address(this),
				block.timestamp
			);
			if (bp > 0) {
				uint256 burn = amountADO.div(100).mul(bp);
				tokenContract.transfer(BURN_ADDRESS, burn);
				amountADO = amountADO.sub(burn);
			}
			address[] memory path = new address[](2);
			path[0] = address(busdContract);
			path[1] = pancakeSwapV2Router.WETH();
			busdContract.approve(address(pancakeSwapV2Router), amountBUSD);
			pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
				amountBUSD,
				0,
				path,
				address(this),
				block.timestamp
			);
			uint256 ethBalance = address(this).balance;
			tokenContract.approve(address(pancakeSwapV2Router), amountADO);
			pancakeSwapV2Router.addLiquidityETH{value: ethBalance}(
				address(tokenContract),
				amountADO,
				amountADO,
				0,
				address(this),
				block.timestamp
			);
			ethBalance = address(this).balance;
			if (ethBalance > 0) {
				(updateBB,) = payable(address(tokenContract)).call{value: ethBalance, gas: 3000}("");
			}
			mainLPToken = pancakeSwapV2Router.WETH();
		}
		return (mainLPToken, updateBB);
	}

	function extendLockedLPs(uint _days) external onlyOwner returns (bool) {
		uint timeunit = 1 days;
		if (_lockedUntil < block.timestamp) {
			_lockedUntil = block.timestamp + (_days * timeunit);
		} else {
			_lockedUntil = _lockedUntil + (_days * timeunit);
		}
		emit LPLocked(_lockedUntil);
		return true;
	}

	function withdrawalLPs() external onlyOwner returns (bool) {
		require(block.timestamp > _lockedUntil, "LPManager: LP tokens cannot be withdrawn");
		bool success = true;
		uint256 wethl = pancakeSwapWETHV2Pair.balanceOf(address(this));
		if (wethl > 0) {
			pancakeSwapWETHV2Pair.transfer(_owner, wethl);
		}
		uint256 busdl = pancakeSwapBUSDV2Pair.balanceOf(address(this));
		if (busdl > 0) {
			pancakeSwapBUSDV2Pair.transfer(_owner, busdl);
		}
		uint256 busd = busdContract.balanceOf(address(this));
		if (busd > 0) {
			busdContract.transfer(_owner, busd);
		}
		uint256 token = tokenContract.balanceOf(address(this));
		if (token > 0) {
			tokenContract.transfer(_owner, token);
		}
		uint256 eth = address(this).balance;
		if (eth > 0) {
			(success,) = payable(_owner).call{value: eth, gas: 3000}("");
		}
		return success;
	}
}