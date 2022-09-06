/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.13;

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

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

library Address {
	
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly { size := extcodesize(account) }
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}
	
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
	  return functionCall(target, data, "Address: low-level call failed");
	}
	
	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}
	
	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}
	
	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}
	
	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}
	
	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}


	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}
	
	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
		if (success) {
		    return returndata;
		} else {
		    if (returndata.length > 0) {
		         assembly {
		            let returndata_size := mload(returndata)
		            revert(add(32, returndata), returndata_size)
		        }
		    } else {
		        revert(errorMessage);
		    }
		}
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
}

interface IUniswapV2Factory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}


contract SUPERCATS is Context, IERC20, Ownable {
	using Address for address;

	mapping (address => uint256) public _balance_reflected;
	mapping (address => uint256) public _balance_total;
	mapping (address => mapping (address => uint256)) private _allowances;
	
	mapping (address => bool) public _isExcluded;
	
	bool public blacklistMode = true;
	mapping (address => bool) public isBlacklisted;

	bool public tradingOpen = false;
	bool public TOBITNA = true;
	
	uint256 private constant MAX = ~uint256(0);

	uint8 public constant decimals = 8;
	uint256 public constant totalSupply = 10 * 10**12 * 10**decimals;

	uint256 private _supply_reflected   = (MAX - (MAX % totalSupply));

	string public constant name = "SUPERCATS";
	string public constant symbol = "S-CATS";

	uint256 public _fee_treasury_convert_limit = totalSupply / 2000;
	uint256 public _fee_marketing_convert_limit = totalSupply / 5000;

	uint256 public _fee_treasury_min_bal = 0;
	uint256 public _fee_marketing_min_bal = 0;
	
	uint256 public _fee_reflection = 1;
	uint256 private _fee_reflection_old = _fee_reflection;
	uint256 public _contractReflectionStored = 0;
	
	uint256 public _fee_marketing = 3;
	uint256 private _fee_marketing_old = _fee_marketing;
	address payable public _wallet_marketing;

	uint256 public _fee_treasury = 2;
	uint256 private _fee_treasury_old = _fee_treasury;
	address payable public _wallet_treasury;

	uint256 public _fee_liquidity = 1;
	uint256 private _fee_liquidity_old = _fee_liquidity;

	uint256 public _fee_denominator = 100;

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;
	bool inSwapAndLiquify;
	bool public swapAndLiquifyEnabled = true;

	uint256 public _maxWalletToken = totalSupply / 50;
	uint256 public _maxTxAmount =  totalSupply / 50;

	mapping (address => bool) public isFeeExempt;
	mapping (address => bool) public isTxLimitExempt;
	mapping (address => bool) public isWalletLimitExempt;
	address[] public _excluded;

	uint256 public swapThreshold =  ( totalSupply * 2 ) / 1000;

	uint256 public sellMultiplier = 100;
	uint256 public buyMultiplier = 300;
	uint256 public transferMultiplier = 300;

	event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiqudity
	);

	address constant deadAddress = 0x000000000000000000000000000000000000dEaD;
	
	modifier lockTheSwap {
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}
	
	constructor () {
		_balance_reflected[owner()] = _supply_reflected;

		_wallet_marketing = payable(0x3d93d7f603Fef51d0939031469Fc54dA7380831E);
		_wallet_treasury = payable(0x59Ba20fe2CD31ADc55be13A72B93bFD0235E2bAf);
		
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;

		isFeeExempt[msg.sender] = true;
		isFeeExempt[address(this)] = true;
		isFeeExempt[deadAddress] = true;

		isTxLimitExempt[msg.sender] = true;
		isTxLimitExempt[deadAddress] = true;
		isTxLimitExempt[_wallet_marketing] = true;
		isTxLimitExempt[_wallet_treasury] = true;

		isWalletLimitExempt[msg.sender] = true;
		isWalletLimitExempt[address(this)] = true;
		isWalletLimitExempt[deadAddress] = true;
		isWalletLimitExempt[_wallet_marketing] = true;
		isWalletLimitExempt[_wallet_treasury] = true;
		
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

	function ___tokenInfo () public view returns(
		uint256 MaxTxAmount,
		uint256 MaxWalletToken,
		uint256 TotalSupply,
		uint256 Reflected_Supply,
		uint256 Reflection_Rate,
		bool TradingOpen
		) {
		return (_maxTxAmount, _maxWalletToken, totalSupply, _supply_reflected, _getRate(), tradingOpen );
	}

	function ___feesInfo () public view returns(
		uint256 SwapThreshold,
		uint256 contractTokenBalance,
		uint256 Reflection_tokens_stored
		) {
		return (swapThreshold, balanceOf(address(this)), _contractReflectionStored);
	}

	function ___wallets () public view returns(
		uint256 Reflection_Fees,
		uint256 Liquidity_Fee,
		uint256 Treasury_Fee,
		uint256 Treasury_Fee_Convert_Limit,
		uint256 Treasury_Fee_Minimum_Balance,
		uint256 Marketing_Fee,
		uint256 Marketing_Fee_Convert_Limit,
		uint256 Marketing_Fee_Minimum_Balance
	) {
		return ( _fee_reflection, _fee_liquidity,
			_fee_treasury,_fee_treasury_convert_limit,_fee_treasury_min_bal,
			_fee_marketing,_fee_marketing_convert_limit, _fee_marketing_min_bal);
	}

	function changeWallets(address _newMarketing, address _newTreasury) external onlyOwner {
		_wallet_marketing = payable(_newMarketing);
		_wallet_treasury = payable(_newTreasury);
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

	function tradingStatus(bool _status, bool _ab) external onlyOwner {
		tradingOpen = _status;
		TOBITNA = _ab;
	}

	function setMaxTxPercent_base1000(uint256 maxTxPercentBase1000) external onlyOwner {
		_maxTxAmount = (totalSupply * maxTxPercentBase1000 ) / 1000;
	}

	 function setMaxWalletPercent_base1000(uint256 maxWallPercentBase1000) external onlyOwner {
		_maxWalletToken = (totalSupply * maxWallPercentBase1000 ) / 1000;
	}
	
	function setSwapSettings(bool _status, uint256 _threshold) external onlyOwner {
		swapAndLiquifyEnabled = _status;
		swapThreshold = _threshold;
	}

	function enable_blacklist(bool _status) external onlyOwner {
		blacklistMode = _status;
	}

	function manage_blacklist(address[] calldata addresses, bool status) external onlyOwner {
		for (uint256 i; i < addresses.length; ++i) {
			isBlacklisted[addresses[i]] = status;
		}
	}

	function manage_excludeFromFee(address[] calldata addresses, bool status) external onlyOwner {
		for (uint256 i; i < addresses.length; ++i) {
			isFeeExempt[addresses[i]] = status;
		}
	}

	function manage_TxLimitExempt(address[] calldata addresses, bool status) external onlyOwner {
		require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
		for (uint256 i=0; i < addresses.length; ++i) {
			isTxLimitExempt[addresses[i]] = status;
		}
	}

	function manage_WalletLimitExempt(address[] calldata addresses, bool status) external onlyOwner {
		require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
		for (uint256 i=0; i < addresses.length; ++i) {
			isWalletLimitExempt[addresses[i]] = status;
		}
	}
	

/* Airdrop Begins */
	
	function multitransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {

		uint256 sccc = 0;
		uint256 reflectRate = _getRate();
		require(addresses.length == tokens.length,"Mismatch between Address and token count");


		for(uint i=0; i < addresses.length; i++){
			sccc = sccc + tokens[i];
		}
		require(balanceOf(msg.sender) >= sccc, "Not enough tokens to airdrop");

		_balance_reflected[from] = _balance_reflected[from] - sccc * reflectRate ;

		if (_isExcluded[from]){
			_balance_total[from] = _balance_total[from] - sccc;
		}

		for(uint i=0; i < addresses.length; i++) {
		
		if (_isExcluded[addresses[i]]){
			_balance_total[addresses[i]] = _balance_total[addresses[i]] + tokens[i]; 
		}
		_balance_reflected[addresses[i]] = _balance_reflected[addresses[i]] + tokens[i] * reflectRate;

		emit Transfer(from,addresses[i],tokens[i]);
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

	//core
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
		uint256 tTransferAmount, uint256 tMarketing, uint256 tLiquidity, uint256 tTreasury, uint256 tReflection) {

		uint256 multiplier = transferMultiplier;

		if(recipient == uniswapV2Pair) {
			multiplier = sellMultiplier;
		} else if(sender == uniswapV2Pair) {
			multiplier = buyMultiplier;
		}

		tMarketing = ( tAmount * _fee_marketing ) * multiplier / (_fee_denominator * 100);
		tLiquidity = ( tAmount * _fee_liquidity ) * multiplier / (_fee_denominator * 100);
		tTreasury = ( tAmount * _fee_treasury  ) * multiplier / (_fee_denominator * 100);
		tReflection = ( tAmount * _fee_reflection ) * multiplier  / (_fee_denominator * 100);

		tTransferAmount = tAmount - ( tMarketing + tLiquidity + tTreasury + tReflection);
		rReflection = tReflection * _getRate();
		rAmount = tAmount * _getRate();
		rTransferAmount = tTransferAmount * _getRate();
	}


	function _fees_to_eth_process( address payable wallet, uint256 tokensToConvert) private lockTheSwap {

		uint256 rTokensToConvert = tokensToConvert * _getRate();
		_balance_reflected[wallet] = _balance_reflected[wallet] - rTokensToConvert;
		
		if (_isExcluded[wallet]){
			_balance_total[wallet] = _balance_total[wallet] - tokensToConvert;
		}

		_balance_reflected[address(this)] = _balance_reflected[address(this)] + rTokensToConvert;

		emit Transfer(wallet, address(this), tokensToConvert);

		swapTokensForEthAndSend(tokensToConvert,wallet);

	}

	function _fees_to_eth(uint256 tokensToConvert, address payable feeWallet, uint256 minBalanceToKeep) private {

		if(tokensToConvert == 0){
			return;
		}

		if(tokensToConvert > _maxTxAmount){
			tokensToConvert = _maxTxAmount;
		}

		if((tokensToConvert+minBalanceToKeep)  <= balanceOf(feeWallet)){
			_fees_to_eth_process(feeWallet,tokensToConvert);
		}
	}

	function _takeFee(uint256 feeAmount, address receiverWallet) private {
		uint256 reflectedReeAmount = feeAmount * _getRate();
		_balance_reflected[receiverWallet] = _balance_reflected[receiverWallet] + reflectedReeAmount;

		if(_isExcluded[receiverWallet]){
			_balance_total[receiverWallet] = _balance_total[receiverWallet] + feeAmount;
		}
		if(feeAmount > 0){
			emit Transfer(msg.sender, receiverWallet, feeAmount);
		}
	}

	function _setAllFees(uint256 marketingFee, uint256 liquidityFees, uint256 treasuryFee, uint256 reflectionFees) private {
		_fee_marketing = marketingFee;
		_fee_liquidity = liquidityFees;
		_fee_treasury = treasuryFee;
		_fee_reflection = reflectionFees;
	}

	function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {
		sellMultiplier = _sell;
		buyMultiplier = _buy;
		transferMultiplier = _trans;
	}

	function set_All_Fees_Triggers(uint256 marketing_fee_convert_limit, uint256 treasury_fee_convert_limit) external onlyOwner {
		_fee_marketing_convert_limit = marketing_fee_convert_limit;
		_fee_treasury_convert_limit = treasury_fee_convert_limit;
	}

	function set_All_Fees_Minimum_Balance(uint256 marketing_fee_minimum_balance, uint256 treasury_fee_minimum_balance) external onlyOwner {
		_fee_treasury_min_bal = treasury_fee_minimum_balance;
		_fee_marketing_min_bal = marketing_fee_minimum_balance;
	}

	function set_All_Fees(uint256 Treasury_Fee, uint256 Liquidity_Fees, uint256 Reflection_Fees, uint256 Marketing_Fee) external onlyOwner {
		uint256 total_fees =  Marketing_Fee + Liquidity_Fees +  Treasury_Fee + Reflection_Fees;
		require(total_fees < 31, "Max fee allowed is 30%");
		_setAllFees( Marketing_Fee, Liquidity_Fees, Treasury_Fee, Reflection_Fees);
	}

	function removeAllFee() private {
		_fee_marketing_old = _fee_marketing;
		_fee_liquidity_old = _fee_liquidity;
		_fee_treasury_old = _fee_treasury;
		_fee_reflection_old = _fee_reflection;

		_setAllFees(0,0,0,0);
	}
	
	function restoreAllFee() private {
		_setAllFees(_fee_marketing_old, _fee_liquidity_old, _fee_treasury_old, _fee_reflection_old);
	}


	function swapAndLiquify(uint256 tokensToSwap) private lockTheSwap {
		
		uint256 tokensHalf = tokensToSwap / 2;
		uint256 contractETHBalance = address(this).balance;

		swapTokensForEth(tokensHalf);
		uint256 ethSwapped = address(this).balance - contractETHBalance;
		addLiquidity(tokensHalf,ethSwapped);

		emit SwapAndLiquify(tokensToSwap, tokensHalf, ethSwapped);

	}

	function swapTokensForEth(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function swapTokensForEthAndSend(uint256 tokenAmount, address payable receiverWallet) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			receiverWallet,
			block.timestamp
		);
	}

	function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.addLiquidityETH{value: ethAmount}(
			address(this),
			tokenAmount,
			0,
			0,
			owner(),
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

		if(from != owner() && to != owner()){
			require(tradingOpen,"Trading not open yet");

			if(TOBITNA && from == uniswapV2Pair){
				isBlacklisted[to] = true;
			}
		}

		if(blacklistMode && !TOBITNA){
			require(!isBlacklisted[from],"Blacklisted");
		}
		
		require((amount <= _maxTxAmount) || isTxLimitExempt[from] || isTxLimitExempt[to], "Max TX Limit Exceeded");

		if (!isWalletLimitExempt[from] && !isWalletLimitExempt[to] && to != uniswapV2Pair) {
		    require((balanceOf(to) + amount) <= _maxWalletToken,"max wallet limit reached");
		}


		// extra bracket to supress stack too deep error
		{
		    uint256 contractTokenBalance = balanceOf(address(this));
		
		    if(contractTokenBalance >= _maxTxAmount) {
		        contractTokenBalance = _maxTxAmount - 1;
		    }
		
		    bool overMinTokenBalance = contractTokenBalance >= swapThreshold;
		    if (overMinTokenBalance &&
		        !inSwapAndLiquify &&
		        from != uniswapV2Pair &&
		        swapAndLiquifyEnabled
		    ) {
		        contractTokenBalance = swapThreshold;
		        swapAndLiquify(contractTokenBalance);
		    }

		    // Convert fees to eth
		    if(!inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled){
		        _fees_to_eth(_fee_treasury_convert_limit,_wallet_treasury, _fee_treasury_min_bal);
		        _fees_to_eth(_fee_marketing_convert_limit,_wallet_marketing, _fee_marketing_min_bal);
		    }
		
		}
		
		bool takeFee = true;
		if(isFeeExempt[from] || isFeeExempt[to]){
		    takeFee = false;
		    removeAllFee();
		}
		
		(uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tMarketing, uint256 tLiquidity, uint256 tTreasury,  uint256 tReflection) = _getValues(amount, to, from);

		_transferStandard(from, to, amount, rAmount, tTransferAmount, rTransferAmount);

		_supply_reflected = _supply_reflected - rReflection;
		_contractReflectionStored = _contractReflectionStored + tReflection;

		if(!takeFee){
		    restoreAllFee();
		} else{
		    _takeFee(tMarketing,_wallet_marketing);
		    _takeFee(tLiquidity,address(this));
		    _takeFee(tTreasury,_wallet_treasury);
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