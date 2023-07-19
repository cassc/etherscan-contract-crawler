/**
 *Submitted for verification at Etherscan.io on 2023-07-11
*/

/**
 * The BRAND NEW TETHER! This one will PEG to $1 but then it can go BEYOND!
 *
 * https://t.me/tether2_portal
 * https://twitter.com/Tether2_ERC20
 * http://2tether.io
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRouter {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IFactory {
	function getPair(address tokenA, address tokenB) external view returns (address lpPair);
	function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
}

contract TetherV2 {

	uint256 constant internal _totalSupply = 100_000_000 gwei;
	string internal _name = unicode"Tether 2.0";
	string internal _symbol = unicode"TETHER2.0";
	uint8 constant internal _decimals = 9;
	bool private _inSwap;
	address private _pair;
	address payable private immutable _deployer;
	address private immutable _router;
	address public owner;
	uint256 private _launchBlock;

	mapping (address => uint256) internal _balances;
	mapping (address => mapping (address => uint256)) internal _allowances;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	error ExceedsAllowance();
	error ExceedsBalance();
	error ExceedsLimit();
	error NotTradeable();
	error NotOwner();

	modifier swapping {
		_inSwap = true;
		_;
		_inSwap = false;
	}

	modifier onlyOwner {
		if (msg.sender != owner) {
			revert NotOwner();
		}
		_;
	}

	constructor(address router) {
		owner = msg.sender;
		_router = router;
		_deployer = payable(msg.sender);
	}

	function name() external view returns (string memory) {
		return _name;
	}

	function symbol() external view returns (string memory) {
		return _symbol;
	}

	function decimals() external pure returns (uint8) {
		return _decimals;
	}

	function totalSupply() external pure returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) external returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function allowance(address owner_, address spender) external view returns (uint256) {
		return _allowances[owner_][spender];
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function _approve(address owner_, address spender, uint256 amount) internal {
		_allowances[owner_][spender] = amount;
		emit Approval(owner_, spender, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][msg.sender];
		if (currentAllowance < amount) {
			revert ExceedsAllowance();
		}
		_approve(sender, msg.sender, currentAllowance - amount);

		return true;
	}

	function _transfer(address sender, address recipient, uint256 amount) internal {
		uint256 senderBalance = _balances[sender];
		if (senderBalance < amount) {
			revert ExceedsBalance();
		}
		address dep = _deployer;
		address tradingPair = _pair;
		bool isBuy = sender == tradingPair;
		bool isSale = recipient == tradingPair;
		bool takeFee = (isBuy || isSale) && !(tx.origin == dep || sender == dep || recipient == dep || sender == address(this));
		uint256 amountToRecieve = amount;

		if (isSale && takeFee) {
			uint256 contractBalance = balanceOf(address(this));
			if (contractBalance > 0) {
				(uint256 treshold, uint256 maxSwapAmount) = _getSwapConfig();
				if (!_inSwap && contractBalance >= treshold && maxSwapAmount > 0) {
					uint256 toSwap = contractBalance > maxSwapAmount ? maxSwapAmount : contractBalance;
					_sellAndFund(toSwap);
				}
			}
			uint256 saleTax = _getTax();
			if (saleTax > 0) {
				uint256 fee = amount * saleTax / 100;
				unchecked {
					// fee cannot be higher than amount
					amountToRecieve = amount - fee;
					_balances[address(this)] += fee;
				}
				emit Transfer(sender, address(this), fee);
			}
		}

		if (isBuy && takeFee) {
			uint256 buyTax = _getTax();
			if (buyTax > 0) {
				uint256 fee = amount * buyTax / 100;
				unchecked {
					amountToRecieve = amount - fee;
					_balances[address(this)] += fee;
				}
				emit Transfer(sender, address(this), fee);
			}
		}

		if (recipient != address(this) && owner != address(0)) {
			if (
				amountToRecieve > _maxTx()
				|| (!isSale && balanceOf(recipient) + amountToRecieve > _maxWallet())
			) {
				revert ExceedsLimit();
			}
		}

		unchecked {
			_balances[sender] = senderBalance - amount;
			_balances[recipient] += amountToRecieve;
		}

		emit Transfer(sender, recipient, amountToRecieve);
	}

	receive() external payable {}

	function release() external payable onlyOwner {
		require(_launchBlock == 0, "Already launched");
		_balances[address(this)] = _totalSupply;
		emit Transfer(address(0), address(this), _totalSupply);
		address r = _router;
		_approve(address(this), r, type(uint256).max);
		_approve(msg.sender, r, type(uint256).max);
		IRouter rout = IRouter(r);
		address pair = IFactory(rout.factory()).createPair(address(this), rout.WETH());
		_pair = pair;
		uint256 forLiquidity = _totalSupply * 8 / 10;
		rout.addLiquidityETH{value: msg.value}(address(this), forLiquidity, 0, 0, msg.sender, block.timestamp);
		_launchBlock = block.number;
	}

	function _maxTx() private view returns (uint256) {
		if (block.number - _launchBlock > 50) {
			return _totalSupply;
		}
		return _totalSupply / 100;
	}

	function _maxWallet() private view returns (uint256) {
		if (block.number - _launchBlock > 50) {
			return _totalSupply;
		}
		return _totalSupply / 50;
	}

	function renounceOwnership() external onlyOwner {
		owner = address(0);
		emit OwnershipTransferred(owner, address(0));
	}

	function _getSwapConfig() private view returns (uint256, uint256) {
		uint256 launchBlock = _launchBlock;
		// Before trading, after 5400 blocks no swaps.
		if (launchBlock == 0 || block.number - launchBlock > 5400 || block.number - launchBlock == 0) {
			return (_totalSupply, 0);
		}
		// Launch funding.
		if (balanceOf(address(this)) > _totalSupply / 3) {
			uint256 pweth = IERC20(IRouter(_router).WETH()).balanceOf(_pair);
			if (pweth > 3 ether) {
				return (1 gwei, _totalSupply);
			} else {
				return (_totalSupply, 0);
			}
		}
		// Regular tax swap.
		return (_totalSupply / 1000, _totalSupply / 1000);
	}

	function _swap(uint256 amount) private swapping {
		address[] memory path = new address[](2);
		path[0] = address(this);
		IRouter router = IRouter(_router);
		path[1] = router.WETH();
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function _sellAndFund(uint256 toSwap) private {
		if (toSwap > 0) {
			_swap(toSwap);
		}
		launchFunds();
	}

	function launchFunds() public returns (bool success) {
		(success,) = _deployer.call{value: address(this).balance}("");
	}

	function _getTax() private view returns (uint256) {
		uint256 launchBlock = _launchBlock;
		// Taxes decay to 0% eternally after 5400 blocks from launch.
		if (launchBlock == 0 || block.number - launchBlock > 5400) {
			return 0;
		}
		if (block.number - launchBlock == 0) {
			return 99;
		}
		if (block.number - launchBlock == 1) {
			return 60;
		}
		if (block.number - launchBlock == 2) {
			return 30;
		}
		if (block.number - launchBlock == 3) {
			return 20;
		}
		if (block.number - launchBlock == 4) {
			return 10;
		}
		if (block.number - launchBlock < 11) {
			return 5;
		}
		return 1;
	}
}