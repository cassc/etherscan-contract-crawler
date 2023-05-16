/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount)
	external
	returns (bool);

	function allowance(address owner, address spender)
	external
	view
	returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

interface IFactory {
	function createPair(address tokenA, address tokenB)
	external
	returns (address pair);

	function getPair(address tokenA, address tokenB)
	external
	view
	returns (address pair);
}

interface IRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
	external
	payable
	returns (
		uint256 amountToken,
		uint256 amountETH,
		uint256 liquidity
	);

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{value: amount}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
		functionCallWithValue(
			target,
			data,
			value,
			"Address: low-level call with value failed"
		);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(
		data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
	internal
	view
	returns (bytes memory)
	{
		return
		functionStaticCall(
			target,
			data,
			"Address: low-level static call failed"
		);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return
		functionDelegateCall(
			target,
			data,
			"Address: low-level delegate call failed"
		);
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
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

abstract contract Context {
		function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract PEDRO is IERC20, Ownable {
	using Address for address;
	using SafeMath for uint256;

	IRouter public uniswapV2Router;
	address public immutable uniswapV2Pair;

	string private constant _name =  "PEDRO";
	string private constant _symbol = "PEDRO";
	uint8 private constant _decimals = 18;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping(address => bool) private _isWalletLocked;

	uint256 private constant MAX = ~uint256(0);
	uint256 private constant _tTotal = 10_000_000_000 * 10**18;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;

	bool private _swapping;
	uint256 public minimumTokensBeforeSwap = 2_500_000 * (10**18);

    address public forLiquidityWallet;
	address public walletXWallet;
    address public walletYWallet;
    address public walletZWallet;
	address public buyBackBurnWallet;
    address public foundationWallet;
	address public marketingWallet;
	address public presaleWallet;
    address public deadWallet;

	struct CustomTaxPeriod {
		bytes23 periodName;
		uint8 blocksInPeriod;
		uint256 timeInPeriod;
		uint8 liquidityFeeOnBuy;
		uint8 liquidityFeeOnSell;
		uint8 walletXFeeOnBuy;
		uint8 walletXFeeOnSell;
        uint8 walletYFeeOnBuy;
		uint8 walletYFeeOnSell;
        uint8 walletZFeeOnBuy;
		uint8 walletZFeeOnSell;
		uint8 buyBackBurnFeeOnBuy;
		uint8 buyBackBurnFeeOnSell;
        uint8 foundationFeeOnBuy;
		uint8 foundationFeeOnSell;
		uint8 holdersFeeOnBuy;
		uint8 holdersFeeOnSell;
	}

	// Base taxes
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,10,10,5,5,5,5,1,1,10,10,9,9,10,10);

    uint256 private _launchStartTimestamp;
	uint256 private _launchBlockNumber;
    uint256 private constant _blockedTimeLimit = 172800;
    mapping (address => bool) private _isBlacklisted;
	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromDividends;
    mapping (address => bool) private _feeOnSelectedWalletTransfers;
	address[] private _excludedFromDividends;
	mapping (address => bool) public automatedMarketMakerPairs;

	uint8 private _liquidityFee;
	uint8 private _walletXFee;
    uint8 private _walletYFee;
    uint8 private _walletZFee;
	uint8 private _buyBackBurnFee;
    uint8 private _foundationFee;
	uint8 private _holdersFee;
	uint8 private _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event WalletChange(string indexed walletIdentifier, address indexed newWallet, address indexed oldWallet);
	event FeeChange(string indexed identifier, uint8 liquidityFee, uint8 walletXFee, uint8 walletYFee, uint8 walletZFee, uint8 buyBackBurnFee, uint8 foundationFee, uint8 holdersFee);
	event CustomTaxPeriodChange(uint8 indexed newValue, uint8 indexed oldValue, string indexed taxType, bytes23 period);
	event BlacklistedAccountChange(address indexed holder, bool indexed status);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
	event excludeFromRewardChange(address indexed account, bool isExcluded);
	event Swap(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
	event ClaimEthOverflow(uint256 amount);
	event TradingStatusChange(bool indexed newValue, bool indexed oldValue);

	constructor() {
        
		forLiquidityWallet = 0xb606f9AA3BeD2E90BEaEdd8B7F619C27c3E47448;
        walletXWallet = 0x7E9b9Ac761a7B31774FC47F88F2C3E903cC9F7fE;
        walletYWallet = 0x1dd4964E6139C0AC0E48C7833cAB8793aca0f16a;
        walletZWallet = 0x4Ed4e51f19745a3fee20ec19e15bD904f2867a23;
		buyBackBurnWallet = 0x6207A1CB8Fc82d7D31c9c83B116bC263c724fdd6;
        foundationWallet = 0x7E9b9Ac761a7B31774FC47F88F2C3E903cC9F7fE;
		marketingWallet = 0xE2901d1DfAa7295C2FE2Df491BE80cdACa66fe56;
        
		deadWallet = 0x000000000000000000000000000000000000dEaD;
        

		IRouter _uniswapV2Router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(
			address(this),
			_uniswapV2Router.WETH()
		);
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[marketingWallet] = true;
		_isExcludedFromFee[foundationWallet] = true;
		_isExcludedFromFee[deadWallet] = true;
		_isExcludedFromFee[buyBackBurnWallet] = true;
		_isExcludedFromFee[forLiquidityWallet] = true;

		excludeFromReward(address(0), true);
		excludeFromReward(address(_uniswapV2Router), true);
		excludeFromReward(address(_uniswapV2Pair), true);
		excludeFromReward(marketingWallet, true);
		excludeFromReward(deadWallet, true);
		excludeFromReward(buyBackBurnWallet, true);
		excludeFromReward(forLiquidityWallet, true);

		_rOwned[owner()] = _rTotal;
		emit Transfer(address(0), owner(), _tTotal);
	}

	receive() external payable {}

	// Setters
	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}
	function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
		return true;
	}
	function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
		_approve(_msgSender(),spender,_allowances[_msgSender()][spender].add(addedValue));
		return true;
	}
	function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
		_approve(_msgSender(),spender,_allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
		return true;
	}
	function _approve(address owner,address spender,uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

    function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
		require(_feeOnSelectedWalletTransfers[account] != value, "PEDRO: The selected wallet is already set to the value ");
		_feeOnSelectedWalletTransfers[account] = value;
		emit FeeOnSelectedWalletTransfersChange(account, value);
	}
	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "PEDRO: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit AutomatedMarketMakerPairChange(pair, value);
	}
    function blockAccount(address account) external onlyOwner {
		require(!_isBlacklisted[account], "PEDRO: Account is already blocked");
		if (_launchStartTimestamp > 0) {
			require((block.timestamp - _launchStartTimestamp) < _blockedTimeLimit, "PEDRO: Time to block accounts has expired");
		}
		_isBlacklisted[account] = true;
		emit BlacklistedAccountChange(account, true);
	}
	function unblockAccount(address account) external onlyOwner {
		require(_isBlacklisted[account], "PEDRO: Account is not blcoked");
		_isBlacklisted[account] = false;
		emit BlacklistedAccountChange(account, false);
	}
	function excludeFromFees(address account, bool excluded) external onlyOwner {
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}

	function excludeFromReward(address account, bool excluded) public onlyOwner {
		if(excluded) {
			if(_rOwned[account] > 0) {
				_tOwned[account] = tokenFromReflection(_rOwned[account]);
			}
			_isExcludedFromDividends[account] = excluded;
			_excludedFromDividends.push(account);
		} else {
			for (uint256 i = 0; i < _excludedFromDividends.length; i++) {
				if (_excludedFromDividends[i] == account) {
					_excludedFromDividends[i] = _excludedFromDividends[_excludedFromDividends.length - 1];
					_tOwned[account] = 0;
					_isExcludedFromDividends[account] = false;
					_excludedFromDividends.pop();
					break;
				}
			}
		}
		emit excludeFromRewardChange(account, excluded);
	}

	
	function setForLiquidityWallet(address newforLiquidityWallet) external onlyOwner {
		require(!_isWalletLocked[forLiquidityWallet], "PEDRO: Wallet is locked.");
		require(newforLiquidityWallet != address(0), "PEDRO: The forLiquidityWallet cannot be 0");
		emit WalletChange('forLiquidityWallet', newforLiquidityWallet, forLiquidityWallet);
		forLiquidityWallet = newforLiquidityWallet;
	}

	function setWalletX(address newWalletX) external onlyOwner {
		require(!_isWalletLocked[walletXWallet], "PEDRO: Wallet is locked.");
		require(newWalletX != address(0), "PEDRO: The walletX cannot be 0");
		emit WalletChange('walletX', newWalletX, walletXWallet);
		walletXWallet = newWalletX;
	}

	function setWalletY(address newWalletY) external onlyOwner {
		require(!_isWalletLocked[walletYWallet], "PEDRO: Wallet is locked.");
		require(newWalletY != address(0), "PEDRO: The walletY cannot be 0");
		emit WalletChange('walletY', newWalletY, walletYWallet);
		walletYWallet = newWalletY;
	}

	function setWalletZ(address newWalletZ) external onlyOwner {
		require(!_isWalletLocked[walletZWallet], "PEDRO: Wallet is locked.");
		require(newWalletZ != address(0), "PEDRO: The walletZ cannot be 0");
		emit WalletChange('walletZ', newWalletZ, walletZWallet);
		walletZWallet = newWalletZ;
	}

	function setBuyBackBurnWallet(address newBuyBackBurnWallet) external onlyOwner {
		require(!_isWalletLocked[buyBackBurnWallet], "PEDRO: Wallet is locked.");
		require(newBuyBackBurnWallet != address(0), "PEDRO: The buyBackBurnWallet cannot be 0");
		emit WalletChange('buyBackBurnWallet', newBuyBackBurnWallet, buyBackBurnWallet);
		buyBackBurnWallet = newBuyBackBurnWallet;
	}

	function setFoundationWallet(address newFoundationWallet) external onlyOwner {
		require(!_isWalletLocked[foundationWallet], "PEDRO: Wallet is locked.");
		require(newFoundationWallet != address(0), "PEDRO: The foundationWallet cannot be 0");
		emit WalletChange('foundationWallet', newFoundationWallet, foundationWallet);
		foundationWallet = newFoundationWallet;
	}

	function setMarketingWallet(address newMarketingWallet) external onlyOwner {
		require(!_isWalletLocked[marketingWallet], "PEDRO: Wallet is locked.");
		require(newMarketingWallet != address(0), "PEDRO: The marketingWallet cannot be 0");
		emit WalletChange('marketingWallet', newMarketingWallet, marketingWallet);
		marketingWallet = newMarketingWallet;
	}

	function setPresaleWallet(address newPresaleWallet) external onlyOwner {
		require(!_isWalletLocked[presaleWallet], "PEDRO: Wallet is locked.");
		require(newPresaleWallet != address(0), "PEDRO: The presaleWallet cannot be 0");
		emit WalletChange('presaleWallet', newPresaleWallet, presaleWallet);
		presaleWallet = newPresaleWallet;
	}

	function lockWallet(address walletToLock) external onlyOwner {
		_isWalletLocked[walletToLock] = true;
	}


	function setBaseFeesOnBuy(uint8 _liquidityFeeOnBuy, uint8 _walletXFeeOnBuy, uint8 _walletYFeeOnBuy, uint8 _walletZFeeOnBuy, uint8 _buyBackBurnFeeOnBuy, uint8 _foundationFeeOnBuy, uint8 _holdersFeeOnBuy) external onlyOwner {
		uint _totalFees = _liquidityFeeOnBuy + _walletXFeeOnBuy + _walletYFeeOnBuy + _walletZFeeOnBuy + _buyBackBurnFeeOnBuy + _foundationFeeOnBuy + _holdersFeeOnBuy;
    	require(_totalFees <= 5, "Total fees cannot be more than 5%");
		_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _walletXFeeOnBuy, _walletYFeeOnBuy, _walletZFeeOnBuy, _buyBackBurnFeeOnBuy, _foundationFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _walletXFeeOnBuy, _walletYFeeOnBuy, _walletZFeeOnBuy, _buyBackBurnFeeOnBuy, _foundationFeeOnBuy, _holdersFeeOnBuy);
	}
	function setBaseFeesOnSell(uint8 _liquidityFeeOnSell,uint8 _walletXFeeOnSell, uint8 _walletYFeeOnSell, uint8 _walletZFeeOnSell, uint8 _buyBackBurnFeeOnSell, uint8 _foundationFeeOnSell, uint8 _holdersFeeOnSell) external onlyOwner {
		uint _totalFees = _liquidityFeeOnSell + _walletXFeeOnSell + _walletYFeeOnSell + _walletZFeeOnSell + _buyBackBurnFeeOnSell + _foundationFeeOnSell + _holdersFeeOnSell;
    	require(_totalFees <= 5, "Total fees cannot be more than 5%");
		_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _walletXFeeOnSell, _walletYFeeOnSell, _walletZFeeOnSell, _buyBackBurnFeeOnSell, _foundationFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _walletXFeeOnSell, _walletYFeeOnSell, _walletZFeeOnSell, _buyBackBurnFeeOnSell, _foundationFeeOnSell, _holdersFeeOnSell);
	}
	function setUniswapRouter(address newAddress) external onlyOwner {
		require(newAddress != address(uniswapV2Router), "PEDRO: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IRouter(newAddress);
	}
	function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "PEDRO: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}
	function claimEthOverflow(uint256 amount) external onlyOwner {
		require(amount < address(this).balance, "PEDRO: Cannot send more than contract balance");
		(bool success,) = address(owner()).call{value : amount}("");
		if (success){
			emit ClaimEthOverflow(amount);
		}
	}

	// Getters
	function name() external pure returns (string memory) {
		return _name;
	}
	function symbol() external pure returns (string memory) {
		return _symbol;
	}
	function decimals() external view virtual returns (uint8) {
		return _decimals;
	}
	function totalSupply() external pure override returns (uint256) {
		return _tTotal;
	}
	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcludedFromDividends[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}
	function totalFees() external view returns (uint256) {
		return _tFeeTotal;
	}
	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}
	function getBaseBuyFees() external view returns (uint8, uint8, uint8, uint8, uint8, uint8, uint8){
		return (_base.liquidityFeeOnBuy, _base.walletXFeeOnBuy, _base.walletYFeeOnBuy, _base.walletZFeeOnBuy, _base.buyBackBurnFeeOnBuy, _base.foundationFeeOnBuy, _base.holdersFeeOnBuy);
	}
	function getBaseSellFees() external view returns (uint8, uint8, uint8, uint8, uint8, uint8, uint8){
		return (_base.liquidityFeeOnSell, _base.walletXFeeOnSell, _base.walletYFeeOnSell, _base.walletZFeeOnSell, _base.buyBackBurnFeeOnSell, _base.foundationFeeOnSell, _base.holdersFeeOnSell);
	}
	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "PEDRO: Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount / currentRate;
	}
	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
		require(tAmount <= _tTotal, "PEDRO: Amount must be less than supply");
		uint256 currentRate = _getRate();
		uint256 rAmount  = tAmount * currentRate;
		if (!deductTransferFee) {
			return rAmount;
		}
		else {
			uint256 rTotalFee  = tAmount * _totalFee / 1000 * currentRate;
			uint256 rTransferAmount = rAmount - rTotalFee;
			return rTransferAmount;
		}
	}

	// Main
	function _transfer(
	address from,
	address to,
	uint256 amount
	) internal {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "PEDRO: Transfer amount must be greater than zero");
		require(amount <= balanceOf(from), "PEDRO: Cannot transfer more than balance");
		require(!_isBlacklisted[to], "PEDRO: Account is blocked");
		require(!_isBlacklisted[from], "PEDRO: Account is blocked");

		_adjustTaxes(automatedMarketMakerPairs[from], automatedMarketMakerPairs[to], to, from);
		bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

		if (
			canSwap &&
			!_swapping &&
			_totalFee > 0 &&
			automatedMarketMakerPairs[to]
		) {
			_swapping = true;
			_swap();
			_swapping = false;
		}

		bool takeFee = !_swapping;

		if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}

		_tokenTransfer(from, to, amount, takeFee);

	}
	function _tokenTransfer(address sender,address recipient, uint256 tAmount, bool takeFee) private {
		(uint256 tTransferAmount,uint256 tFee, uint256 tOther) = _getTValues(tAmount, takeFee);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rOther) = _getRValues(tAmount, tFee, tOther, _getRate());

		if (_isExcludedFromDividends[sender]) {
			_tOwned[sender] = _tOwned[sender] - tAmount;
		}
		if (_isExcludedFromDividends[recipient]) {
			_tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
		}
		_rOwned[sender] = _rOwned[sender] - rAmount;
		_rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
		_reflectFee(rFee, tFee, rOther, tOther);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	function _reflectFee(uint256 rFee, uint256 tFee, uint256 rOther, uint256 tOther) private {
		_rTotal -= rFee;
		_tFeeTotal += tFee;

        if (_isExcludedFromDividends[address(this)]) {
			_tOwned[address(this)] += tOther;
		}
		_rOwned[address(this)] += rOther;
	}
	function _getTValues(uint256 tAmount, bool takeFee) private view returns (uint256,uint256,uint256){
		if (!takeFee) {
			return (tAmount, 0, 0);
		}
		else {
			uint256 tFee = tAmount * _holdersFee / 1000;
			uint256 tOther = tAmount * (_liquidityFee + _walletXFee + _walletYFee + _walletZFee + _foundationFee + _buyBackBurnFee) / 1000;
			uint256 tTransferAmount = tAmount - (tFee + tOther);
			return (tTransferAmount, tFee, tOther);
		}
	}
	function _getRValues(
		uint256 tAmount,
		uint256 tFee,
		uint256 tOther,
		uint256 currentRate
		) private pure returns ( uint256, uint256, uint256, uint256) {
		uint256 rAmount = tAmount * currentRate;
		uint256 rFee = tFee * currentRate;
		uint256 rOther = tOther * currentRate;
		uint256 rTransferAmount = rAmount - (rFee + rOther);
		return (rAmount, rTransferAmount, rFee, rOther);
	}
	function _getRate() private view returns (uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}
	function _getCurrentSupply() private view returns (uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		for (uint256 i = 0; i < _excludedFromDividends.length; i++) {
			if (
				_rOwned[_excludedFromDividends[i]] > rSupply ||
				_tOwned[_excludedFromDividends[i]] > tSupply
			) return (_rTotal, _tTotal);
			rSupply = rSupply - _rOwned[_excludedFromDividends[i]];
			tSupply = tSupply - _tOwned[_excludedFromDividends[i]];
		}
		if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}
	function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp, address to, address from) private {
		_liquidityFee = 0;
        _walletXFee = 0;
        _walletYFee = 0;
        _walletZFee = 0;
        _foundationFee = 0;
        _buyBackBurnFee = 0;
        _holdersFee = 0;

        if (isBuyFromLp) {
            _liquidityFee = _base.liquidityFeeOnBuy;
            _walletXFee = _base.walletXFeeOnBuy;
            _walletYFee = _base.walletYFeeOnBuy;
            _walletZFee = _base.walletZFeeOnBuy;
            _buyBackBurnFee = _base.buyBackBurnFeeOnBuy;
            _foundationFee = _base.foundationFeeOnBuy;
            _holdersFee = _base.holdersFeeOnBuy;
		}
		if (isSelltoLp) {
			_liquidityFee = _base.liquidityFeeOnSell;
			_walletXFee = _base.walletXFeeOnSell;
            _walletYFee = _base.walletYFeeOnSell;
            _walletZFee = _base.walletZFeeOnSell;
			_buyBackBurnFee = _base.buyBackBurnFeeOnSell;
            _foundationFee = _base.foundationFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;
		}
		if (!isSelltoLp && !isBuyFromLp && (_feeOnSelectedWalletTransfers[from] || _feeOnSelectedWalletTransfers[to])) {
			_liquidityFee = _base.liquidityFeeOnSell;
			_walletXFee = _base.walletXFeeOnSell;
            _walletYFee = _base.walletYFeeOnSell;
            _walletZFee = _base.walletZFeeOnSell;
			_buyBackBurnFee = _base.buyBackBurnFeeOnSell;
            _foundationFee = _base.foundationFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;
		}
		_totalFee = _liquidityFee + _walletXFee + _walletYFee + _walletZFee + _buyBackBurnFee + _foundationFee + _holdersFee;
	}
	function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
		uint8 _liquidityFeeOnSell,
		uint8 _walletXFeeOnSell,
        uint8 _walletYFeeOnSell,
        uint8 _walletZFeeOnSell,
		uint8 _buyBackBurnFeeOnSell,
        uint8 _foundationFeeOnSell,
		uint8 _holdersFeeOnSell
		) private {
		if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
			emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
			map.liquidityFeeOnSell = _liquidityFeeOnSell;
		}
		if (map.walletXFeeOnSell != _walletXFeeOnSell) {
			emit CustomTaxPeriodChange(_walletXFeeOnSell, map.walletXFeeOnSell, 'walletXFeeOnSell', map.periodName);
			map.walletXFeeOnSell = _walletXFeeOnSell;
		}
        if (map.walletYFeeOnSell != _walletYFeeOnSell) {
			emit CustomTaxPeriodChange(_walletYFeeOnSell, map.walletYFeeOnSell, 'walletYFeeOnSell', map.periodName);
			map.walletYFeeOnSell = _walletYFeeOnSell;
		}
        if (map.walletZFeeOnSell != _walletZFeeOnSell) {
			emit CustomTaxPeriodChange(_walletZFeeOnSell, map.walletZFeeOnSell, 'walletZFeeOnSell', map.periodName);
			map.walletZFeeOnSell = _walletZFeeOnSell;
		}
		if (map.buyBackBurnFeeOnSell != _buyBackBurnFeeOnSell) {
			emit CustomTaxPeriodChange(_buyBackBurnFeeOnSell, map.buyBackBurnFeeOnSell, 'buyBackBurnFeeOnSell', map.periodName);
			map.buyBackBurnFeeOnSell = _buyBackBurnFeeOnSell;
		}
        if (map.foundationFeeOnSell != _foundationFeeOnSell) {
			emit CustomTaxPeriodChange(_foundationFeeOnSell, map.foundationFeeOnSell, 'foundationFeeOnSell', map.periodName);
			map.foundationFeeOnSell = _foundationFeeOnSell;
		}
		if (map.holdersFeeOnSell != _holdersFeeOnSell) {
			emit CustomTaxPeriodChange(_holdersFeeOnSell, map.holdersFeeOnSell, 'holdersFeeOnSell', map.periodName);
			map.holdersFeeOnSell = _holdersFeeOnSell;
		}
	}
	function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
		uint8 _liquidityFeeOnBuy,
		uint8 _walletXFeeOnBuy,
        uint8 _walletYFeeOnBuy,
        uint8 _walletZFeeOnBuy,
		uint8 _buyBackBurnFeeOnBuy,
        uint8 _foundationFeeOnBuy,
		uint8 _holdersFeeOnBuy
		) private {
		if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
			emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
			map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
		}
		if (map.walletXFeeOnBuy != _walletXFeeOnBuy) {
			emit CustomTaxPeriodChange(_walletXFeeOnBuy, map.walletXFeeOnBuy, 'walletXFeeOnBuy', map.periodName);
			map.walletXFeeOnBuy = _walletXFeeOnBuy;
		}
        if (map.walletYFeeOnBuy != _walletYFeeOnBuy) {
			emit CustomTaxPeriodChange(_walletYFeeOnBuy, map.walletYFeeOnBuy, 'walletYFeeOnBuy', map.periodName);
			map.walletYFeeOnBuy = _walletYFeeOnBuy;
		}
        if (map.walletZFeeOnBuy != _walletZFeeOnBuy) {
			emit CustomTaxPeriodChange(_walletZFeeOnBuy, map.walletZFeeOnBuy, 'walletZFeeOnBuy', map.periodName);
			map.walletZFeeOnBuy = _walletZFeeOnBuy;
		}
		if (map.buyBackBurnFeeOnBuy != _buyBackBurnFeeOnBuy) {
			emit CustomTaxPeriodChange(_buyBackBurnFeeOnBuy, map.buyBackBurnFeeOnBuy, 'buyBackBurnFeeOnBuy', map.periodName);
			map.buyBackBurnFeeOnBuy = _buyBackBurnFeeOnBuy;
		}
        if (map.foundationFeeOnBuy != _foundationFeeOnBuy) {
			emit CustomTaxPeriodChange(_foundationFeeOnBuy, map.foundationFeeOnBuy, 'foundationFeeOnBuy', map.periodName);
			map.foundationFeeOnBuy = _foundationFeeOnBuy;
		}
		if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
			emit CustomTaxPeriodChange(_holdersFeeOnBuy, map.holdersFeeOnBuy, 'holdersFeeOnBuy', map.periodName);
			map.holdersFeeOnBuy = _holdersFeeOnBuy;
		}
	}
    function _calculateAndSendETH(uint256 balance, uint8 fee, address wallet) private {
        uint256 amount = balance * fee / _totalFee;
        Address.sendValue(payable(wallet), amount);
    }

    function _swap() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialEthBalance = address(this).balance;

        _swapTokensForEth(contractBalance);

        uint256 ethBalanceAfterSwap = address(this).balance - initialEthBalance;

        _calculateAndSendETH(ethBalanceAfterSwap, _liquidityFee, forLiquidityWallet);
        _calculateAndSendETH(ethBalanceAfterSwap, _walletXFee, walletXWallet);
        _calculateAndSendETH(ethBalanceAfterSwap, _walletYFee, walletYWallet);
        _calculateAndSendETH(ethBalanceAfterSwap, _walletZFee, walletZWallet);
        _calculateAndSendETH(ethBalanceAfterSwap, _buyBackBurnFee, buyBackBurnWallet);
		_calculateAndSendETH(ethBalanceAfterSwap, _foundationFee, foundationWallet);
    }

	function _swapTokensForEth(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			1, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}
}