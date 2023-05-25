/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

/**
 * https://t.me/Spidey_ERC
 * https://twitter.com/Spidey_Eth
 *
                   ,,,, 
             ,;) .';;;;',
 ;;,,_,-.-.,;;'_,|I\;;;/),,_
  `';;/:|:);{ ;;;|| \;/ /;;;\__
      L;/-';/ \;;\',/;\/;;;.') \
      .:`''` - \;;'.__/;;;/  . _'-._ 
    .'/   \     \;;;;;;/.'_7:.  '). \_
  .''/     | '._ );}{;//.'    '-:  '.,L
.'. /       \  ( |;;;/_/         \._./;\   _,
 . /        |\ ( /;;/_/             ';;;\,;;_,
. /         )__(/;;/_/                (;;'''''
 /        _;:':;;;;:';-._             );
/        /   \  `'`   --.'-._         \/
       .'     '.  ,'         '-,
      /    /   r--,..__       '.\
    .'    '  .'        '--._     ]
    (     :.(;>        _ .' '- ;/
    |      /:;(    ,_.';(   __.'
     '- -'"|;:/    (;;;;-'--'
           |;/      ;;(
           ''      /;;|
                   \;;|
                    \/
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

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

abstract contract ERC20 {

	uint256 immutable internal _totalSupply;
	string internal _name;
	string internal _symbol;
	uint8 immutable internal _decimals;

	mapping (address => uint256) internal _balances;
	mapping (address => mapping (address => uint256)) internal _allowances;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	error ExceedsAllowance();
	error ExceedsBalance();

	constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint8 decimals_) {
		_name = name_;
		_symbol = symbol_;
		_totalSupply = totalSupply_;
		_balances[msg.sender] = totalSupply_;
		_decimals = decimals_;
		emit Transfer(address(0), msg.sender, totalSupply_);
	}

	function name() external view returns (string memory) {
		return _name;
	}

	function symbol() external view returns (string memory) {
		return _symbol;
	}

	function decimals() external view returns (uint8) {
		return _decimals;
	}

	function totalSupply() external view returns (uint256) {
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

	function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual returns (uint256) {}

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

		emit Transfer(sender, recipient, amount);
	}
}

interface IUniRouter {
	function WETH() external pure returns (address);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract Spidey is ERC20, Ownership {

	bool private _inSwap;
	bool public launched;
	bool public limited = true;
	uint8 private _buyTax = 69;
    uint8 private _saleTax = 69;
	address private _pair;
	address payable private immutable _devWallet;
	address private _router;
	uint64 private immutable _maxTx;
	uint64 private immutable _maxWallet;
	uint64 private _swapThreshold;
	uint64 private _swapAmount;
	mapping (address => bool) private _isBot;
	error ExceedsLimit();
	error NotTradeable();

	modifier swapping {
		_inSwap = true;
		_;
		_inSwap = false;
	}

	constructor(address router) ERC20("Spidey", "SPIDEY", 1_000_000_000 gwei, 9) Ownership(msg.sender) {
		_devWallet = payable(msg.sender);
		uint64 opct = uint64(_totalSupply / 100);
		_maxTx = opct;
		_maxWallet = opct * 2;
		_swapThreshold = opct;
		_swapAmount = opct / 100;
		_router = router;
		_approve(address(this), router, type(uint256).max);
	}

	receive() external payable {}

	/**
	 * @dev Allow everyone to trade the token. To be called after liquidity is added.
	 */
	function allowTrading(address tradingPair) external onlyOwner {
		_pair = tradingPair;
		launched = true;
	}

	/**
	 * @dev Update main trading pair in case allowTrading was called wrongly.
	 */
	function setTradingPair(address tradingPair) external onlyOwner {
		_pair = tradingPair;
	}

	function setRouter(address r) external onlyOwner {
		_router = r;
	}

	function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override returns (uint256) {
		address owner_ = owner;
		if (tx.origin == owner_ || sender == owner_ || recipient == owner_ || sender == address(this)) {
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
				if (!_inSwap && contractBalance >= _swapThreshold) {
					uint256 maxSwap = _swapAmount;
					uint256 toSwap = contractBalance > maxSwap ? maxSwap : contractBalance;
					_swap(toSwap);
					if (address(this).balance > 0) {
						marketingFunds();
					}
				}
			}

			uint8 saleTax = _saleTax;
			if (saleTax > 0) {
				uint256 fee = amount * _saleTax / 100;
				unchecked {
					// fee cannot be higher than amount
					amountToRecieve = amount - fee;
					// Impossible to overflow, max token supply fits in uint64
					_balances[address(this)] += fee;
				}
				emit Transfer(sender, address(this), fee);
			}
		}

		if (isBuy) {
			// Gas savings to assign and check here :)
			uint8 buyTax = _buyTax;
			if (buyTax > 0) {
				uint256 fee = amount * _buyTax / 100;
				// Same comments as above.
				unchecked {
					amountToRecieve = amount - fee;
					_balances[address(this)] += fee;
				}
				emit Transfer(sender, address(this), fee);
			}
		}

		if (recipient != address(this)) {
			if (limited) {
				if (
					amountToRecieve > _maxTx
					|| (!isSale && balanceOf(recipient) + amountToRecieve > _maxWallet)
				) {
					revert ExceedsLimit();
				}
			}
		}

		return amountToRecieve;
	}

	/**
	 * @dev Removes wallet and TX limits. Cannot be undone.
	 */
	function setUnlimited() external onlyOwner {
		limited = false;
	}

	/**
	 * @dev Automatically removes tax and limits when renouncing contract. This makes it impossible to raise taxes from 0 just before renounce and bamboozle gamblers.
	 */
	function _renounceOwnership() internal override {
		_buyTax = 0;
		_saleTax = 0;
		limited = false;
		// No need to update max tx / wallet because they are only check when `limited` is true.
		super._renounceOwnership();
	}

	/**
	 * @dev Sets temporary buy tax. Taxes are entirely removed when ownership is renounced.
	 */
	function setBuyTax(uint8 buyTax) external onlyOwner {
		if (buyTax > 99) {
			revert ExceedsLimit();
		}
		_buyTax = buyTax;
	}

	/**
	 * @dev Sets temporary sale tax. Taxes are entirely removed when ownership is renounced.
	 */
	function setSaleTax(uint8 saleTax) external onlyOwner {
		if (saleTax > 99) {
			revert ExceedsLimit();
		}
		_saleTax = saleTax;
	}

	/**
	 * @dev Amount at which the swap triggers if set.
	 */
	function setSwapThreshold(uint64 t) external onlyOwner {
		_swapThreshold = t;
	}

	/**
	 * @dev Contract swap limit.
	 */
	function setSwapAmount(uint64 amount) external onlyOwner {
		_swapAmount = amount;
	}

	function _swap(uint256 amount) private swapping {
		address[] memory path = new address[](2);
		path[0] = address(this);
		IUniRouter router = IUniRouter(_router);
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
		require(msg.sender == _devWallet);
		_swap(amount);
		marketingFunds();
	}

	function marketingFunds() public returns (bool success) {
		// warning,,,
		(success,) = _devWallet.call{value: address(this).balance}("");
	}

	function marketingFundsWithGas(uint256 gasgasgas) external returns (bool success) {
		(success,) = _devWallet.call{value: address(this).balance, gas: gasgasgas}("");
	}

	function areTheyNonHuman(address account, bool notOnlyAHuman) external onlyOwner {
		_isBot[account] = notOnlyAHuman;
	}

	function getTaxes() external view returns (uint8 buyTax, uint8 saleTax) {
		buyTax = _buyTax;
		saleTax = _saleTax;
	}
}