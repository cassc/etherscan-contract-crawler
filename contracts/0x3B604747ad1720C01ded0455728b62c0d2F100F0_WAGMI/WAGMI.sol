/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

/**
 * SPDX-License-Identifier: MIT
 */ 
 
// WAGMI GAMES - WE ARE ALL GOING TO MAKE IT - https://www.wagmigame.io/

pragma solidity ^0.8.6;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
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
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

abstract contract Ownable is Context {
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

interface IPancakeV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract WAGMI is IERC20Metadata, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    
    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    address public marketingWallet = 0x10b33D3CbcB6f674fc626bfd83a701D2422352E2;
    address public devWallet = 0x8Da67EF3CA0D9a2e28EB32DDd323295A64d20AD3;
    address public teamWallet = 0xf96cb8E903AE8AABf92c5668871e5ACE37316c64;
    
    string constant _name = "WAGMI GAMES";
    string constant _symbol = "WAGMIGAMES";
    uint8 constant _decimals = 18;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _totalSupply = 2_200_000_000_000 * (10**18);
    uint256 internal _reflectedSupply = (MAX - (MAX % _totalSupply));
    
    uint256 public collectedFeeTotal;
  
    uint256 public maxTxAmount = _totalSupply / 1000; // 0.1% of the total supply
    uint256 public maxWalletBalance = _totalSupply / 50; // 2% of the total supply
    
    bool public takeFeeEnabled = true;
    bool public tradingIsEnabled = true;
    bool public isInPresale = false;
    
    bool private swapping;
    bool public swapEnabled = true;
    uint256 public swapTokensAtAmount = 100_000_000 * (10**18);

    bool public antiBotEnabled = false;
    uint256 public antiBotFee = 990; // 99%
    uint256 public _startTimeForSwap;
    
    uint256 private constant FEES_DIVISOR = 10**3;
    
    uint256 public rfiFee = 10; // 1%
    uint256 public marketingFee = 30; // 3%
    uint256 public devFee = 20; // 2%
    uint256 public teamFee = 25; // 2.5%
    uint256 public lpFee = 15; // 1.5%
    uint256 private totalFee;
    
    // Total = 100% (1000)
    uint256 public marketingPortionOfSwap = 500; // 50%
    uint256 public devPortionOfSwap = 200; // 20%
    uint256 public teamPortionOfSwap = 150; // 15%
    uint256 public lpPortionOfSwap = 150; // 15%
    
    IPancakeV2Router public router;
    address public pair;
    
    
    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    mapping(address => bool) public _isBlacklisted;
    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;
    
    event UpdatePancakeswapRouter(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DevWalletUpdated(address indexed newDevWallet, address indexed oldDevWallet);
    event TeamWalletUpdated(address indexed newTeamWallet, address indexed oldTeamWallet);
    
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);
    
    event SwapTokensForETH(uint256 amountIn, address[] path);

    modifier zeroAddressCheck(address _theAddress) {
        require(_theAddress != address(0), "Address cannot be the zero address");
        _;
    }
    
    constructor () {
        _reflectedBalances[owner()] = _reflectedSupply;
        
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        router = _newPancakeRouter;

        // set fees
        totalFee = rfiFee.add(marketingFee).add(devFee).add(teamFee).add(lpFee);
        
        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));
        
        // exclude the pair address from rewards - we don't want to redistribute
        _exclude(pair);
        _exclude(deadAddress);
        
        _approve(owner(), address(router), ~uint256(0));
        
        emit Transfer(address(0), owner(), _totalSupply);
    }
    
    receive() external payable { }
    
    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256){
        if (_isExcludedFromRewards[account]) return _balances[account];
        return tokenFromReflection(_reflectedBalances[account]);
        }
        
    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
        }
        
    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
        }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
        }
        
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
        }
        
    function burn(uint256 amount) external nonReentrant {

        address sender = _msgSender();
        require(sender != address(0), "ERC20: burn from the zero address");
        require(sender != address(deadAddress), "ERC20: burn from the burn address");

        uint256 balance = balanceOf(sender);
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        uint256 reflectedAmount = amount.mul(_getCurrentRate());

        // remove the amount from the sender's balance first
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(reflectedAmount);
        if (_isExcludedFromRewards[sender])
            _balances[sender] = _balances[sender].sub(amount);

        _burnTokens( sender, amount, reflectedAmount );
    }
    
    /**
     * @dev "Soft" burns the specified amount of tokens by sending them 
     * to the burn address
     */
    function _burnTokens(address sender, uint256 tBurn, uint256 rBurn) internal {

        /**
         * @dev Do not reduce _totalSupply and/or _reflectedSupply. (soft) burning by sending
         * tokens to the burn address (which should be excluded from rewards) is sufficient
         * in RFI
         */ 
        _reflectedBalances[deadAddress] = _reflectedBalances[deadAddress].add(rBurn);
        if (_isExcludedFromRewards[deadAddress])
            _balances[deadAddress] = _balances[deadAddress].add(tBurn);

        /**
         * @dev Emit the event so that the burn address balance is updated (on bscscan)
         */
        emit Transfer(sender, deadAddress, tBurn);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BaseRfiToken: approve from the zero address");
        require(spender != address(0), "BaseRfiToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
     /**
     * @dev Calculates and returns the reflected amount for the given amount with or without 
     * the transfer fees (deductTransferFee true/false)
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        uint256 feesSum;
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount,0);
            return rAmount;
        } else {
            feesSum = totalFee;
            (,uint256 rTransferAmount,,,) = _getValues(tAmount, feesSum);
            return rTransferAmount;
        }
    }

    /**
     * @dev Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }
    
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromRewards[account], "Account is not included");
        _exclude(account);
    }
    
    function _exclude(address account) private {
        if(_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_reflectedBalances[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function setExcludedFromFee(address account, bool value) external onlyOwner { 
        _isExcludedFromFee[account] = value; 
    }

    function _getValues(uint256 tAmount, uint256 feesSum) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }
    
    function _getCurrentRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = _totalSupply;

        /**
         * The code below removes balances of addresses excluded from rewards from
         * rSupply and tSupply, which effectively increases the % of transaction fees
         * delivered to non-excluded holders
         */    
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectedBalances[_excluded[i]] > rSupply || _balances[_excluded[i]] > tSupply)
            return (_reflectedSupply, _totalSupply);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(_totalSupply)) return (_reflectedSupply, _totalSupply);
        return (rSupply, tSupply);
    }
    
    
    /**
     * @dev Redistributes the specified amount among the current holders via the reflect.finance
     * algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`. 
     * 
     */
    function _redistribute(uint256 amount, uint256 currentRate, uint256 fee) private {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        
        collectedFeeTotal = collectedFeeTotal.add(tFee);
    }
    
    function _burn(uint256 amount, uint256 currentRate, uint256 fee) private {
        uint256 tBurn = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rBurn = tBurn.mul(currentRate);

        _burnTokens(address(this), tBurn, rBurn);
        
        collectedFeeTotal = collectedFeeTotal.add(tBurn);
    }
    
     function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }
    
    function isExcludedFromFee(address account) public view returns(bool) { 
        return _isExcludedFromFee[account]; 
    }
    

    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled  = _enabled;
    }
    
    function updateSwapTokensAt(uint256 _swaptokens) external onlyOwner {
        swapTokensAtAmount = _swaptokens * (10**18);
    }
    
    function updateWalletMax(uint256 _walletMax) external onlyOwner {
        maxWalletBalance = _walletMax * (10**18);
    }
    
    function updateTransactionMax(uint256 _txMax) external onlyOwner {
        maxTxAmount = _txMax * (10**18);
    }

    function updateFees(uint256 _rfi, uint256 _marketing, uint256 _dev, uint256 _team, uint256 _lp) external onlyOwner {
       totalFee = _rfi.add(_marketing).add(_dev).add(_team).add(_lp); 
       require(totalFee <= 100, "Total Fees cannot be greater than 10% (100)");

       rfiFee = _rfi;
       marketingFee = _marketing;
       devFee = _dev;
       teamFee = _team;
       lpFee = _lp;
    }

   
    function updateMarketingWallet(address newWallet) external onlyOwner zeroAddressCheck(newWallet) {
        require(newWallet != marketingWallet, "The Marketing wallet is already this address");
        emit MarketingWalletUpdated(newWallet, marketingWallet);
        
        marketingWallet = newWallet;
    }
    
    function updateDevWallet(address newWallet) external onlyOwner zeroAddressCheck(newWallet) {
        require(newWallet != devWallet, "The Dev wallet is already this address");
        emit DevWalletUpdated(newWallet, devWallet);
        
        devWallet = newWallet;
    }
    
    function updateTeamWallet(address newWallet) external onlyOwner zeroAddressCheck(newWallet) {
        require(newWallet != teamWallet, "The Team wallet is already this address");
        emit TeamWalletUpdated(newWallet, teamWallet);
        
        teamWallet = newWallet;
    }
    
    function updatePortionsOfSwap(uint256 marketingPortion, uint256  devPortion, uint256 lpPortion, uint256 teamPortion) 
    external onlyOwner {
        
        uint256 totalPortion = marketingPortion.add(devPortion).add(lpPortion).add(teamPortion);
        require(totalPortion == 1000, "Total must be equal to 1000 (100%)");
        
        marketingPortionOfSwap = marketingPortion;
        devPortionOfSwap = devPortion;
        lpPortionOfSwap = lpPortion;
        teamPortionOfSwap = teamPortion;
    }
    
    function updateTradingIsEnabled(bool tradingStatus) external onlyOwner() {
        tradingIsEnabled = tradingStatus;
    }
    
    function updateRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(router), "The router already has that address");
        emit UpdatePancakeswapRouter(newAddress, address(router));
        
        router = IPancakeV2Router(newAddress);   
    }

    function toggleAntiBot(bool toggleStatus) external onlyOwner() {
        antiBotEnabled = toggleStatus;
        if(antiBotEnabled){
            _startTimeForSwap = block.timestamp + 60;    
        }    
    }
    
    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        collectedFeeTotal = collectedFeeTotal.add(tAmount);
    }
    
    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee) private {
        
        uint256 sumOfFees = totalFee;

        // antibot enabled
        sumOfFees = antiBotEnabled && block.timestamp <= _startTimeForSwap ? antiBotFee : sumOfFees;

        // transfer between wallets
        if(sender != pair && recipient != pair) {
            sumOfFees = 0;
        }
        
        if ( !takeFee ){ sumOfFees = 0; }
        
        processReflectedBal(sender, recipient, amount, sumOfFees);
       
    }
    
    function processReflectedBal (address sender, address recipient, uint256 amount, uint256 sumOfFees) private {
        
        (uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, 
        uint256 tTransferAmount, uint256 currentRate ) = _getValues(amount, sumOfFees);
         
        theReflection(sender, recipient, rAmount, rTransferAmount, tAmount, tTransferAmount); 
        
        _takeFees(amount, currentRate, sumOfFees);
        
        emit Transfer(sender, recipient, tTransferAmount);    
    }
    
    function theReflection(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, 
        uint256 tTransferAmount) private {
            
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rTransferAmount);
        
        /**
         * Update the true/nominal balances for excluded accounts
         */        
        if (_isExcludedFromRewards[sender]) { _balances[sender] = _balances[sender].sub(tAmount); }
        if (_isExcludedFromRewards[recipient] ) { _balances[recipient] = _balances[recipient].add(tTransferAmount); }
    }
    
    
    function _takeFees(uint256 amount, uint256 currentRate, uint256 sumOfFees) private {
        if ( sumOfFees > 0 && !isInPresale ){
            _redistribute( amount, currentRate, rfiFee );  // redistribute to holders
            
            uint256 otherFees = sumOfFees.sub(rfiFee);
            _takeFee( amount, currentRate, otherFees, address(this));

        }
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Token: transfer from the zero address");
        require(recipient != address(0), "Token: transfer to the zero address");
        require(sender != address(deadAddress), "Token: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        require(tradingIsEnabled, "This account cannot send tokens until trading is enabled");

        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "Blacklisted address");
        
        if (
            sender != address(router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFee[recipient] && //no max for those excluded from fees
            !_isExcludedFromFee[sender] 
        ) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the Max Transaction Amount.");
            
        }
        
        if ( maxWalletBalance > 0 && !_isExcludedFromFee[recipient] && !_isExcludedFromFee[sender] && recipient != address(pair) ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(recipientBalance + amount <= maxWalletBalance, "New balance would exceed the maxWalletBalance");
            }
            
         // indicates whether or not fee should be deducted from the transfer
        bool _isTakeFee = takeFeeEnabled;
        if ( isInPresale ){ _isTakeFee = false; }
        
         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) { 
            _isTakeFee = false; 
        }
        
        _beforeTokenTransfer(recipient);
        _transferTokens(sender, recipient, amount, _isTakeFee);
        
    }
    
    function _beforeTokenTransfer(address recipient) private {
            
        if ( !isInPresale ){
            uint256 contractTokenBalance = balanceOf(address(this));
            // swap
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap && swapEnabled && recipient == pair) {
                swapping = true;
                
                swapBack();
                
                swapping = false;
            }
            
        }
    }
    
    function swapBack() private nonReentrant {
        uint256 splitLiquidityPortion = lpPortionOfSwap.div(2);
        uint256 amountToLiquify = balanceOf(address(this)).mul(splitLiquidityPortion).div(FEES_DIVISOR);
        uint256 amountToSwap = balanceOf(address(this)).sub(amountToLiquify);

        uint256 balanceBefore = address(this).balance;
        
        swapTokensForETH(amountToSwap);

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        
        uint256 amountBNBMarketing = amountBNB.mul(marketingPortionOfSwap).div(FEES_DIVISOR);
        uint256 amountBNBDev = amountBNB.mul(devPortionOfSwap).div(FEES_DIVISOR);
        uint256 amountBNBTeam = amountBNB.mul(teamPortionOfSwap).div(FEES_DIVISOR);
        uint256 amountBNBLiquidity = amountBNB.mul(splitLiquidityPortion).div(FEES_DIVISOR);
        
          //Send to addresses
        transferToAddress(payable(marketingWallet), amountBNBMarketing);
        transferToAddress(payable(devWallet), amountBNBDev);
        transferToAddress(payable(teamWallet), amountBNBTeam);
        
        // add liquidity
        _addLiquidity(amountToLiquify, amountBNBLiquidity);
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );

        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function transferToAddress(address payable recipient, uint256 amount) private {
        require(recipient != address(0), "Cannot transfer the ETH to a zero address");
        recipient.transfer(amount);
    }
    
    function TransferETH(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the ETH balance to a zero address");
        recipient.transfer(amount);
    }
    
}