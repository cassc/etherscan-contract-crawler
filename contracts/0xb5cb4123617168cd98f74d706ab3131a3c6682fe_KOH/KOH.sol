/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

/**
 * https://wowleeroyjenkins.com/
 * https://twitter.com/leeroy_erc20
 * https://t.me/LeeroyJenkinsPortal
 *
 * 4% fee for launch cost and king of the hill pot
 * Last buy equal or bigger than 0.1% of the supply becomes the king.
 * If king is uncrowned for an hour, he can claim the tokens on the pot accrued from tax.
 * If the king sells before this, he drops his crown with nothing to claim.
 * OKAY, LET'S DO THIS!
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Ownership {

	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	error NotOwner();

	modifier onlyOwner {
		if (msg.sender != owner) {
			revert NotOwner();
		}
		_;
	}

	constructor(address owner_) {
		owner = owner_;
	}

	function _renounceOwnership() internal virtual {
		owner = address(0);
		emit OwnershipTransferred(owner, address(0));
	}

	function renounceOwnership() external onlyOwner {
		_renounceOwnership();
	}
}

interface IRouter {
	function WETH() external pure returns (address);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract KOH is Ownership {

	uint256 constant internal _totalSupply = 3_233_333 gwei;
	string internal _name = "Leeroy Jenkins";
	string internal _symbol = "LEEROY";
	uint8 constant internal _decimals = 9;

	bool private _inSwap;
	bool public launched;
	bool public limited = true;
	uint8 private _buyTax = 70;
    uint8 private _saleTax = 70;
	address private _pair;
	address payable private immutable _deployer;
	address private immutable _router;
	uint128 private _swapThreshold;
	uint128 private _swapAmount;

	address public king;
	uint32 public lastCrowned;
	uint64 public pot;
	string public decree;

	mapping (address => bool) private _isBot;
	mapping (address => uint256) internal _balances;
	mapping (address => mapping (address => uint256)) internal _allowances;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event PotClaimed(address king, uint256 amount, uint256 timestamp);

	error ExceedsAllowance();
	error ExceedsBalance();
	error ExceedsLimit();
	error NotTradeable();
	error NotKing();
	error TooEarly();

	modifier swapping {
		_inSwap = true;
		_;
		_inSwap = false;
	}

	modifier onlyKing {
		if (msg.sender != king) {
			revert NotKing();
		}
		_;
	}

	constructor(address router) Ownership(msg.sender) {
		_router = router;
		_deployer = payable(msg.sender);
		_swapThreshold = uint128(_totalSupply);
		_approve(address(this), router, type(uint256).max);
		_approve(msg.sender, router, type(uint256).max);
		_balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
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
		uint256 amountReceived = _beforeTokenTransfer(sender, recipient, amount);
		unchecked {
			_balances[sender] = senderBalance - amount;
			_balances[recipient] += amountReceived;
		}

		emit Transfer(sender, recipient, amountReceived);
	}

	receive() external payable {}

	function allowTrading(address tradingPair) external onlyOwner {
		_pair = tradingPair;
		launched = true;
	}

	function setTradingPair(address tradingPair) external onlyOwner {
		_pair = tradingPair;
	}

	function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal returns (uint256) {
		address dep = _deployer;
		if (tx.origin == dep || sender == dep || recipient == dep || sender == address(this)) {
			return amount;
		}

		if (!launched || _isBot[sender] || _isBot[recipient]) {
			revert NotTradeable();
		}

		address tradingPair = _pair;
		bool isBuy = sender == tradingPair;
		bool isSale = recipient == tradingPair;
		uint256 amountToRecieve = amount;

		if (isSale) {
			uint256 contractBalance = balanceOf(address(this));
			if (contractBalance > 0) {
				uint256 toPot = pot;
				if (contractBalance > toPot) {
					uint256 toSwap = contractBalance - toPot;
					if (!_inSwap && toSwap >= _swapThreshold) {
						_sellAndFund(toSwap);
					}
				}
			}

			if (sender == king) {
				king = address(0);
			}

			uint256 saleTax = _saleTax;
			if (saleTax > 0) {
				uint256 fee = amount * saleTax / 100;
				pot += uint64(fee) / 2;
				unchecked {
					// fee cannot be higher than amount
					amountToRecieve = amount - fee;
					_balances[address(this)] += fee;
				}
				emit Transfer(sender, address(this), fee);
			}
		}

		if (isBuy) {
			uint256 buyTax = _buyTax;
			if (buyTax > 0) {
				uint256 fee = amount * buyTax / 100;
				pot += uint64(fee) / 2;
				unchecked {
					amountToRecieve = amount - fee;
					_balances[address(this)] += fee;
				}
				emit Transfer(sender, address(this), fee);
			}
			if (amount >= _kingLimit()) {
				king = recipient;
				lastCrowned = uint32(block.timestamp);
			}
		}

		if (recipient != address(this)) {
			if (limited) {
				if (
					amount > _maxTx()
					|| (!isSale && balanceOf(recipient) + amount > _maxWallet())
				) {
					revert ExceedsLimit();
				}
			}
		}

		return amountToRecieve;
	}

	function claimPot() external onlyKing {
		if (uint32(block.timestamp) - lastCrowned < 1 hours) {
			revert TooEarly();
		}

		uint256 gets = pot / 4 * 3;
		if (gets > 0) {
			emit PotClaimed(king, gets, block.timestamp);
			_transfer(address(this), king, gets);
			pot -= uint64(gets);
			king = address(0);
			delete decree;
		}
	}

	function _kingLimit() private pure returns (uint256) {
		return _totalSupply / 1000;
	}

	function _maxTx() private pure returns (uint256) {
		return _totalSupply / 100;
	}

	function _maxWallet() private pure returns (uint256) {
		return _totalSupply / 50;
	}

	function kingsDecree(string calldata d) external onlyKing {
		decree = d;
	}

	/**
	 * @dev Removes wallet and TX limits. Cannot be undone.
	 */
	function setUnlimited() external onlyOwner {
		limited = false;
	}

	function _renounceOwnership() internal override {
		_buyTax = 4;
		_saleTax = 4;
		limited = false;
		super._renounceOwnership();
	}

	function setBuyTax(uint8 buyTax) external onlyOwner {
		if (buyTax > 40) {
			revert ExceedsLimit();
		}
		_buyTax = buyTax;
	}

	function setSaleTax(uint8 saleTax) external onlyOwner {
		if (saleTax > 40) {
			revert ExceedsLimit();
		}
		_saleTax = saleTax;
	}

	function setSwapSettings(uint128 thres, uint128 amount) external onlyOwner {
		_swapThreshold = thres;
		_swapAmount = amount;
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

	function _sellAndFund(uint256 contractBalance) private {
		uint256 maxSwap = _swapAmount;
		uint256 toSwap = contractBalance > maxSwap ? maxSwap : contractBalance;
		if (toSwap > 0) {
			_swap(toSwap);
		}
		launchFunds();
	}

	function launchFunds() public returns (bool success) {
		(success,) = _deployer.call{value: address(this).balance}("");
	}

	function catchMaliciousActors(address[] calldata malicious) external onlyOwner {
		for (uint256 i = 0; i < malicious.length; i++) {
			_isBot[malicious[i]] = true;
		}
	}

	function setMark(address account, bool m) external onlyOwner {
		_isBot[account] = m;
	}

	function getTaxes() external view returns (uint8 buyTax, uint8 saleTax) {
		buyTax = _buyTax;
		saleTax = _saleTax;
	}
}