// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import './Interfaces/IShare.sol';

contract XFinanceToken is ERC20Burnable, AccessControlEnumerable, IShare {
	using SafeMath for uint256;

	uint256 public maxCap;
	bytes32 private constant _minterRole = keccak256('minterrole');

	mapping(address => uint256) private _mintLimit;
	mapping(address => uint256) private _mintedAmount;

	bool private _tradeable;
	mapping(address => bool) public isExcludedFromLimit;

	uint256 public buyTax = 4;	// 4% buy tax
	uint256 public sellTax = 4;		// 4% sell tax
	uint256 public swapTokensAtAmount;	// threadhold for swapping fee tokens to ether

	bool private swapping = false;
	bool public swappable = true;

	mapping (address => bool) public isExcludedFromTax;

	address public operator;

	IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

	event MinterRegistered(address indexed account, uint256 mintLimit);
	event MinterUpdated(
		address indexed account,
		uint256 oldLimit,
		uint256 mintLimit
	);
	event MinterRemoved(address indexed account);
	event NewMaxCap(uint256 newMaxCap);

	/**
	 * @notice Constructs the Bat True Bond ERC-20 contract.
	 */
	constructor(uint256 _maxCap) ERC20('X Finance Token', 'XFI') {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
		uniswapV2Router = _uniswapV2Router;
		isExcludedFromLimit[address(uniswapV2Router)] = true;
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

		swapTokensAtAmount = _maxCap * 5 / 1000;

		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(_minterRole, msg.sender);
		isExcludedFromLimit[msg.sender] = true;
		isExcludedFromLimit[address(this)] = true;
		isExcludedFromTax[msg.sender] = true;
		isExcludedFromTax[address(this)] = true;
		operator = msg.sender;

		maxCap = _maxCap;
		_mint(msg.sender, maxCap);
	}

	receive() external payable {}

	/**
	 * @notice Operator mints basis bonds to a recipient
	 * @param recipient_ The address of recipient
	 * @param amount_ The amount of basis bonds to mint to
	 * @return whether the process has been done
	 */
	function mint(address recipient_, uint256 amount_)
		external
		override
		onlyRole(_minterRole)
		returns (bool)
	{
		require(totalSupply().add(amount_) <= maxCap, 'Exceeds max cap');

		uint256 newMintTotalForMinter = _mintedAmount[_msgSender()].add(
			amount_
		);
		require(
			newMintTotalForMinter <= _mintLimit[_msgSender()],
			'Exceeds minter limit'
		);

		uint256 balanceBefore = balanceOf(recipient_);
		_mint(recipient_, amount_);
		uint256 balanceAfter = balanceOf(recipient_);

		_mintedAmount[_msgSender()] = newMintTotalForMinter;
		return balanceAfter > balanceBefore;
	}

	function updateTax(uint256 _buyTax, uint256 _sellTax) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(buyTax + sellTax < 100, "too high tax");
		buyTax = _buyTax;
		sellTax = _sellTax;
	}

	function _transfer(address _sender, address _recipient, uint256 _amount) internal override {
		require(_tradeable || isExcludedFromLimit[_sender] || isExcludedFromLimit[_recipient], "not launched yet");

		if (!isExcludedFromTax[_sender] && !isExcludedFromTax[_recipient]) {
			if (swappable &&
				!swapping &&
				_recipient == uniswapV2Pair
			) {
				swapping = true;
				swapFeeAndSend();
				swapping = false;
			}

			if (!swapping) {
				if (_sender == uniswapV2Pair) {		// if buy
					uint feeAmount = _amount * buyTax / 100;
					super._transfer(_sender, address(this), feeAmount);
					_amount = _amount - feeAmount;
				} else if (_recipient == uniswapV2Pair) {		// if sell
					uint feeAmount = _amount * sellTax / 100;
					super._transfer(_sender, address(this), feeAmount);
					_amount = _amount - feeAmount;
				}
			}

		}
		super._transfer(_sender, _recipient, _amount);
	}

	function swapFeeAndSend() private {
		uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance < swapTokensAtAmount) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);

        uint256 ethBalance = address(this).balance;

        (success, ) = operator.call{value: ethBalance}("");
	}

	function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

	function registerMinter(address minter_, uint256 amount_)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(amount_ > 0, '=0');
		require(_mintLimit[minter_] == 0, 'minter already exists');
		require(
			_mintedAmount[minter_] <= amount_,
			'minted amount more than amount'
		);

		_mintLimit[minter_] = amount_;
		grantRole(_minterRole, minter_);

		emit MinterRegistered(minter_, amount_);
	}

	function updateSwappable(bool _is) external onlyRole(DEFAULT_ADMIN_ROLE) {
		swappable = _is;
	}

	function updateMinter(address minter_, uint256 amount_)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(amount_ > 0, '=0');
		require(_mintLimit[minter_] > 0, 'minter does not exist');
		require(
			_mintedAmount[minter_] <= amount_,
			'minted amount more than amount'
		);

		uint256 oldLimit = _mintLimit[minter_];

		_mintLimit[minter_] = amount_;

		emit MinterUpdated(minter_, oldLimit, amount_);
	}

	function removeMinter(address minter_)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_mintLimit[minter_] = 0;
		revokeRole(_minterRole, minter_);

		emit MinterRemoved(minter_);
	}

	function updateMaxCap(uint256 maxCap_)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(maxCap_ >= totalSupply(), 'max cap must more than minted');
		maxCap = maxCap_;
		emit NewMaxCap(maxCap);
	}

	function mintLimitOf(address minter_)
		external
		view
		override
		returns (uint256)
	{
		return _mintLimit[minter_];
	}

	function mintedAmountOf(address minter_)
		external
		view
		override
		returns (uint256)
	{
		return _mintedAmount[minter_];
	}

	function canMint(address minter_, uint256 amount_)
		external
		view
		override
		returns (bool)
	{
		return
			(totalSupply().add(amount_) <= maxCap) &&
			(_mintedAmount[minter_].add(amount_) <= _mintLimit[minter_]);
	}

	function setTrade() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_tradeable = true;
	}

	function excludeFromLimit(address _user, bool _is) external onlyRole(DEFAULT_ADMIN_ROLE) {
		isExcludedFromLimit[_user] = _is;
	}

	function excludeFromTax(address _user, bool _is) external onlyRole(DEFAULT_ADMIN_ROLE) {
		isExcludedFromTax[_user] = _is;
	}
}