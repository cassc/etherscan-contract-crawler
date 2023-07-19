/**
 *Submitted for verification at Etherscan.io on 2023-07-11
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

interface IERC20 {
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	event TransferDetails(address indexed from, address indexed to, uint256 total_Amount, uint256 reflected_amount, uint256 total_TransferAmount, uint256 reflected_TransferAmount);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}
}

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () {
		_owner = _msgSender();
		emit OwnershipTransferred(address(0), _owner);
	}
	
	function owner() public view virtual returns (address) {
		return _owner;
	}
	
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}

	function renounceOwnership() public virtual onlyOwner {
		address newOwner = address(0);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

interface IUniswapV2Factory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}


contract ERC20FLOKINOMICS2 is Context, IERC20, Ownable {
	mapping (address => uint256) public _balance_reflected;
	mapping (address => uint256) public _balance_total;
	mapping (address => mapping (address => uint256)) private _allowances;
	
	mapping (address => bool) public _isExcluded;
	
	bool public tradingOpen = false;
	
	uint256 private constant MAX = ~uint256(0);
	address constant deadAddress = 0x000000000000000000000000000000000000dEaD;
	uint256 public constant decimals = 18;
	uint256 public constant totalSupply = 10**9 * 10**decimals;
	uint256 private _supply_reflected = (MAX - (MAX % totalSupply));

	string public constant name = "Flokinomics 2.0";
	string public constant symbol = "Flokin2";
	
	uint256 public _fee_reflection = 5;
	uint256 private _fee_reflection_old = _fee_reflection;
	uint256 public _contractReflectionStored = 0;
	
	uint256 public _fee_marketing = 5;
	uint256 private _fee_marketing_old = _fee_marketing;
	address payable public _wallet_marketing;

	uint256 public constant _fee_denominator = 100;

	IUniswapV2Router public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;

	bool inSwapAndLiquify;
	bool public swapAndLiquifyEnabled = false;
	uint256 public swapThreshold = totalSupply / 500;

	mapping (address => bool) public isFeeExempt;
	address[] public _excluded;

	uint256 public buyMultiplier = 0;
	uint256 public sellMultiplier = 0;
	uint256 public transferMultiplier = 0;

	event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiqudity
	);
	
	modifier lockTheSwap {
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}
	
	constructor () {
		_balance_reflected[owner()] = _supply_reflected;

		_wallet_marketing = payable(0xEAb7B2faD637021A29E43B1E38B25c8Aded0c269);
		
		IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;

		isFeeExempt[msg.sender] = true;
		isFeeExempt[_wallet_marketing] = true;
		isFeeExempt[address(this)] = true;
		isFeeExempt[deadAddress] = true;
		
		emit Transfer(address(0), owner(), totalSupply);
	}

	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcluded[account]) return _balance_total[account];
		return tokenFromReflection(_balance_reflected[account]);
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		require (_allowances[sender][_msgSender()] >= amount,"ERC20: transfer amount exceeds allowance");
		_approve(sender, _msgSender(), (_allowances[sender][_msgSender()]-amount));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, (_allowances[_msgSender()][spender] + addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		require (_allowances[_msgSender()][spender] >= subtractedValue,"ERC20: decreased allowance below zero");
		_approve(_msgSender(), spender, (_allowances[_msgSender()][spender] - subtractedValue));
		return true;
	}

	function changeWallets(address _newMarketing) external onlyOwner {
		_wallet_marketing = payable(_newMarketing);
	}

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _supply_reflected, "Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return (rAmount / currentRate);
	}

	function excludeFromReward(address account) external onlyOwner {
		require(!_isExcluded[account], "Account is already excluded");
		if(_balance_reflected[account] > 0) {
			_balance_total[account] = tokenFromReflection(_balance_reflected[account]);
		}
		_isExcluded[account] = true;
		_excluded.push(account);
	}

	function includeInReward(address account) external onlyOwner {
		require(_isExcluded[account], "Account is already included");
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_excluded[i] == account) {
				_excluded[i] = _excluded[_excluded.length - 1];
				_balance_total[account] = 0;
				_isExcluded[account] = false;
				_excluded.pop();
				break;
			}
		}
	}

	function goLive() external onlyOwner {
		require(!tradingOpen,"Cannot be executed after going live");
		tradingOpen = true;
		swapAndLiquifyEnabled = true;
		buyMultiplier = 50;
		sellMultiplier = 200;
		transferMultiplier = 0;
	}

	function setSwapSettings(bool _status, uint256 _threshold) external onlyOwner {
		require(_threshold > 0,"swap threshold cannot be 0");
		swapAndLiquifyEnabled = _status;
		swapThreshold = _threshold;
	}

	function manage_excludeFromFee(address[] calldata addresses, bool status) external onlyOwner {
		for (uint256 i; i < addresses.length; ++i) {
			isFeeExempt[addresses[i]] = status;
		}
	}

	function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
		uint256 amountToClear = amountPercentage * address(this).balance / 100;
		payable(msg.sender).transfer(amountToClear);
	}

	function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
		if(tokens == 0){
			tokens = IERC20(tokenAddress).balanceOf(address(this));
		}
		return IERC20(tokenAddress).transfer(msg.sender, tokens);
	}

	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply / tSupply;
	}

	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _supply_reflected;
		uint256 tSupply = totalSupply;
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_balance_reflected[_excluded[i]] > rSupply || _balance_total[_excluded[i]] > tSupply) return (_supply_reflected, totalSupply);
			rSupply = rSupply - _balance_reflected[_excluded[i]];
			tSupply = tSupply - _balance_total[_excluded[i]];
		}
		if (rSupply < (_supply_reflected/totalSupply)) return (_supply_reflected, totalSupply);
		return (rSupply, tSupply);
	}


	function _getValues(uint256 tAmount, address recipient, address sender) private view returns (
		uint256 rAmount, uint256 rTransferAmount, uint256 rReflection,
		uint256 tTransferAmount, uint256 tMarketing, uint256 tReflection) {

		uint256 multiplier = transferMultiplier;

		if(recipient == uniswapV2Pair) {
			multiplier = sellMultiplier;
		} else if(sender == uniswapV2Pair) {
			multiplier = buyMultiplier;
		}

		tMarketing = ( tAmount * _fee_marketing ) * multiplier / (_fee_denominator * 100);
		tReflection = ( tAmount * _fee_reflection ) * multiplier  / (_fee_denominator * 100);

		tTransferAmount = tAmount - ( tMarketing + tReflection);
		rReflection = tReflection * _getRate();
		rAmount = tAmount * _getRate();
		rTransferAmount = tTransferAmount * _getRate();
	}

	function _takeMarketingFee(uint256 feeAmount, address receiverWallet) private {
		uint256 reflectedReeAmount = feeAmount * _getRate();
		_balance_reflected[receiverWallet] = _balance_reflected[receiverWallet] + reflectedReeAmount;

		if(_isExcluded[receiverWallet]){
			_balance_total[receiverWallet] = _balance_total[receiverWallet] + feeAmount;
		}
		if(feeAmount > 0){
			emit Transfer(msg.sender, receiverWallet, feeAmount);
		}
	}

	function _setAllFees(uint256 marketingFee, uint256 reflectionFees) private {
		_fee_marketing = marketingFee;
		_fee_reflection = reflectionFees;
	}

	function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {

		require(_buy <= 100, "Max buy multiplier allowed is 1x");
		require(_sell <= 100, "Max sell multiplier allowed is 1x");
		require(_trans <= 100, "Max transfer multiplier allowed is 1x");

		sellMultiplier = _sell;
		buyMultiplier = _buy;
		transferMultiplier = _trans;
	}

	function set_All_Fees(uint256 Reflection_Fees, uint256 Marketing_Fee) external onlyOwner {
		uint256 total_fees =  Marketing_Fee + Reflection_Fees;
		require(total_fees <= 20, "Max fee allowed is 20%");
		_setAllFees( Marketing_Fee, Reflection_Fees);
	}

	function removeAllFee() private {
		_fee_marketing_old = _fee_marketing;
		_fee_reflection_old = _fee_reflection;

		_setAllFees(0,0);
	}
	
	function restoreAllFee() private {
		_setAllFees(_fee_marketing_old, _fee_reflection_old);
	}

	function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			_wallet_marketing,
			block.timestamp
		);
	}


	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(address from, address to, uint256 amount) private {

		if(!isFeeExempt[from] && !isFeeExempt[to]){
			require(tradingOpen,"Trading not open yet");
		}

		if(!inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled && balanceOf(address(this)) > swapThreshold){
			swapTokensForEth(swapThreshold);
		}
		
		bool takeFee = true;
		if(isFeeExempt[from] || isFeeExempt[to]){
		    takeFee = false;
		    removeAllFee();
		}
		
		(uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tMarketing, uint256 tReflection) = _getValues(amount, to, from);

		_transferStandard(from, to, amount, rAmount, tTransferAmount, rTransferAmount);

		_supply_reflected = _supply_reflected - rReflection;
		_contractReflectionStored = _contractReflectionStored + tReflection;

		if(!takeFee){
		    restoreAllFee();
		} else{
		    _takeMarketingFee(tMarketing,address(this));
		}	
	}

	function _transferStandard(address from, address to, uint256 tAmount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
		_balance_reflected[from]    = _balance_reflected[from]  - rAmount;

		if (_isExcluded[from]){
		    _balance_total[from]    = _balance_total[from]      - tAmount;
		}

		if (_isExcluded[to]){
		    _balance_total[to]      = _balance_total[to]        + tTransferAmount;
		}
		_balance_reflected[to]      = _balance_reflected[to]    + rTransferAmount;

		if(tTransferAmount > 0){
			emit Transfer(from, to, tTransferAmount);	
		}
	}

	receive() external payable {}
}