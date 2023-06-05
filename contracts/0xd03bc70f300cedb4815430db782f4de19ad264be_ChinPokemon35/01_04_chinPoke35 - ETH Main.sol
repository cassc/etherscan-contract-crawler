// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;

/**

CHINPOKEMON TEST v35

*/

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ChinPokemon35 is Context, IERC20, Ownable {

    struct RValuesStruct {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflectionFee;
        uint256 rMarketingFee;
    }

    struct TValuesStruct {
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tMarketingFee;
    }

    struct ValuesStruct {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflectionFee;
        uint256 rMarketingFee;
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tMarketingFee;
    }

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    
    mapping (address => bool)    private _isExcludedFromFee;
    mapping (address => bool)    private _isExcluded; // should be as low as possible to keep transactions fees low
    mapping (address => bool)    private _isContractAdmin;
	mapping (address => bool)    private _isContractManager;

    mapping (address => bool)    public isAntiBotDistribution;
    mapping (address => bool)    public isWhitelisted;
    mapping (address => bool)    public automatedMarketMakerPairs;
    mapping (address => uint256) public userTransferTax;

    mapping (address => mapping (address => uint256)) private _allowances;
			 
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e10 * 10 ** _decimals; // 10 Billion Tokens

    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tReflectionFeeTotal;
    uint256 private _numTokensSwapForMarketing = 3e3 * 10 ** _decimals;

    uint256 public maxTxAmount = _tTotal / 100;
    uint256 public marketingFeeTokensCounter = 0;

    uint8 private constant _decimals = 18;

    uint8 public reflectionFeeSell = 1;
    uint8 public reflectionFeeBuy = 1;
    uint8 public marketingFeeSell = 4;
    uint8 public marketingFeeTransfer = 1;
    uint8 public transferFeeRatio = 100;

    string private constant _name = "CHINPOKEMON35TEST";
    string private constant _symbol = "CHINKO35TEST";

    address public constant WBTC = 0xC04B0d3107736C32e19F1c62b2aF67BE61d63a05;

    address public immutable uniswapV2Pair;

    address public marketingFeeWallet = 0x21F0C38DC1dC10da34eADb93Ddc72A8CBf01adc8;
    address public swapTokenAddress = WBTC; //Default to WBTC

    address[] private _excluded;

    IUniswapV2Router public immutable uniswapV2Router;

    bool private _inMarketingSellSwap = false;
    
    bool public marketingConvertToToken = true;
    bool public fairLaunchStarted = false;
    bool public fairLaunchCompleted = false;

    event ExcludeFromReward(address account);
    event AccountAntiBotDistribution(address account, bool status);
    event MarketingTokensSwapped(uint256 amount);
    event ContractManagerChange(address account, bool status);
    event ContractAdminChange(address account, bool status);
    event WhitelistedStatus(address account, bool status);
    event FeesUpdated(uint8 reflectionFeeBuy, uint8 reflectionFeeSell, uint8 marketingFeeSell, uint8 marketingFeeTransfer);
    event ChangeSwapToken(address newSwapToken);
    event ChangeMarketingWallet(address newAddress);
    event SetMaxTx(uint256 amount);
    event FairlaunchStarted(bool);
    event FairlaunchCompleted(bool);
    event SetMarketingConvertToToken(bool status);
    event SetSwapForMarketing(uint256 amount);
    event ChangeUserTransferTax(address user, uint256 amount);
    event ChangeTransferFeeRatio(uint8 amount);
    event SetAMM(address pair, bool status);
    event ETHRecovered(uint256 amount);
    event ERC20Rescued(address tokenAddress, uint256 amount);
 
    modifier lockTheSwap {
        _inMarketingSellSwap = true;
        _;
        _inMarketingSellSwap = false;
    }

    modifier contractAdmin() {
        require(isContractAdmin(_msgSender())  || _isOwner(), "Admin: caller is not a contract Administrator");
        _;
    }

    modifier contractManager() {
        require(isContractManager(_msgSender())  || _isOwner(), "Manager: caller is not a contract Manager");
        _;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
 
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // Uniswap V2
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //.createPair(address(this), _uniswapV2Router.WETH9());
        .createPair(WBTC, address(this));

        _allowances[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isContractAdmin[owner()] = true;
        _isContractManager[owner()] = true;                                
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(_allowances[_msgSender()][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalReflectionFees() external view returns (uint256) {
        return _tReflectionFeeTotal;
    }

    /**
     * @dev Returns the Number of tokens in contract that are needed to be reached before swapping to Set Token and sending to Marketing Wallet.
     */
    function numTokensSwapForMarketing() external view returns (uint256) {
        return _numTokensSwapForMarketing;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) external contractManager() {
        require(account != address(uniswapV2Router), 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account already excluded");
        require(_excluded.length < 100, "Excluded list is too long");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);

        emit ExcludeFromReward(account);
    }

    //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _getValues(uint256 tAmount, uint256 tReflectionFee, uint256 tMarketingFee) private view returns (ValuesStruct memory) {
        TValuesStruct memory tvs = _getTValues(tAmount, tReflectionFee, tMarketingFee);
        RValuesStruct memory rvs = _getRValues(tAmount, tvs.tReflectionFee, tvs.tMarketingFee, _getRate()) ;

        return ValuesStruct(
            rvs.rAmount,
            rvs.rTransferAmount,
            rvs.rReflectionFee,
            rvs.rMarketingFee,
            tvs.tTransferAmount,
            tvs.tReflectionFee,
            tvs.tMarketingFee
        );
    }

    function _getTValues(uint256 tAmount, uint256 _tReflectionFee, uint256 _tMarketingFee) private pure returns (TValuesStruct memory) {
        uint256 tReflectionFee = _tReflectionFee;
        uint256 tMarketingFee = _tMarketingFee;
        
        uint256 tTransferAmount = tAmount - tReflectionFee - tMarketingFee;
        return TValuesStruct(tTransferAmount, tReflectionFee, tMarketingFee);
    }

    function _getRValues(uint256 tAmount, uint256 tReflectionFee, uint256 tMarketingFee, uint256 currentRate) private pure returns (RValuesStruct memory) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rReflectionFee = tReflectionFee * currentRate;
        uint256 rMarketingFee = tMarketingFee * currentRate;
       
        uint256 rTransferAmount = rAmount - rReflectionFee - rMarketingFee;
        return RValuesStruct(rAmount, rTransferAmount, rReflectionFee, rMarketingFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRandomNumber(uint256 inputValue) private view returns (uint256) {
        // Generate a random number using keccak256, block.timestamp and msg.sender
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;

        // Calculate the percentage of the input value
        uint256 result = inputValue * randomNumber / 100;

        return result;
    }

    function _takeMarketingFee(uint256 rMarketingFee, uint256 tMarketingFee) private {
        if (tMarketingFee > 0) {
            if(!marketingConvertToToken) {
                _rOwned[marketingFeeWallet] = _rOwned[marketingFeeWallet] + rMarketingFee;
                if(_isExcluded[marketingFeeWallet]) _tOwned[marketingFeeWallet] = _tOwned[marketingFeeWallet] + tMarketingFee;
            } else {
                _rOwned[address(this)] = _rOwned[address(this)] + rMarketingFee;
                if(_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)] + tMarketingFee;
            }
        }
    }

    function _distributeFee(uint256 rReflectionFee, uint256 tReflectionFee) private {
        if (tReflectionFee > 0) {
            _rTotal = _rTotal - rReflectionFee;
            _tReflectionFeeTotal = _tReflectionFeeTotal + tReflectionFee;
        }
    }

    function _calculateFeeAmount(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount * fee / 100;
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /* In case of emergency dev can apply a 25% reflection tax on compromised wallets or bots causing detriment to project, this doesn't apply to smartcontracts (like LPs and farms).
    Additionally only not excluded from fees addresses can't have this applied. Once the contract is renounced this function doesn't apply anymore. */
    function antiBotDistribution(address target, bool status) external onlyOwner {
        require (!_isContract(target), "Can't apply to a contract");
        require(!_isExcludedFromFee[target], "Can't use with an excluded from fee account");

        isAntiBotDistribution[target] = status;
        emit AccountAntiBotDistribution(target, status);
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isContractAdmin(address account) public view returns(bool) {
        return _isContractAdmin[account];
    }

	function isContractManager(address account) public view returns(bool) {
        return _isContractManager[account];
    }																	   

    function _isOwner() private view returns(bool) {
        return owner() == msg.sender;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount, "Insufficient Balance");
        
        // whitelisted both excluded from fees and allowed to buy
        // block trading until owner has added liquidity & launched
        if (!fairLaunchStarted && from != owner() && to != owner() && from != address(this) && !_isExcludedFromFee[from]) {
            revert("Trading not yet enabled!");
        }

        // revert trading from non authorized users till fairlaunch is completed
        if(fairLaunchStarted && !fairLaunchCompleted && from != owner() && to != owner() && !isWhitelisted[to] && from != address(this)) {
            revert("Trading not yet enabled!");
        }

        if (automatedMarketMakerPairs[to]) {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinTokenBalance = contractTokenBalance >= _numTokensSwapForMarketing;
            uint256 amountToSwap = _getRandomNumber(_numTokensSwapForMarketing);

            if (
                overMinTokenBalance &&
                !_inMarketingSellSwap &&
                marketingConvertToToken
            ) {
                swapMarketingAndSendToken(amountToSwap); //Perform a Swap of Token for ETH Portion of Marketing Fees
            }
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount);
    }

    function swapMarketingAndSendToken(uint256 tokenAmount) internal lockTheSwap {
        address[] memory path;
        if (swapTokenAddress == WBTC) {
            // generate the uniswap pair path of token -> weth
            path = new address[](2);
            path[0] = address(this);
            path[1] = WBTC;
        } else {
            path = new address[](4);
            path[0] = address(this);
            path[1] = WBTC;
            path[2] = uniswapV2Router.WETH();
            path[3] = swapTokenAddress;

            address pairAddress = pairFor(uniswapV2Router.factory(), path[2], path[3]);
            (uint112 reserve0, , ) = IUniswapV2Pair(pairAddress).getReserves();
            uint liquidity = uint(reserve0);

            if (liquidity == 0) {
                // Swap pair does not exist or has no liquidity, skip this iteration
                return;
            }
        }

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap in a try-catch block
        try uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of token to receive
            path,
            marketingFeeWallet,
            block.timestamp
        ) {
            if (marketingFeeTokensCounter < tokenAmount) marketingFeeTokensCounter = 0;
            else marketingFeeTokensCounter -= tokenAmount;
        } catch {
            return;
        }

        emit MarketingTokensSwapped(tokenAmount);
    }

    // Helper function to get the pair address
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(tokenA, tokenB)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        )))));
    }

    function calculateReflectionFee(uint256 amount, address recipient, address sender) private view returns (uint256) {
        if (!_excludedFromFee(recipient, sender)) {
            if (_antiBotDistribution(recipient, sender) && !isRenounced()) {
                return _calculateFeeAmount(amount, 25);
            } else if (automatedMarketMakerPairs[recipient]) {
                return _calculateFeeAmount(amount, reflectionFeeSell);
            } else if (automatedMarketMakerPairs[sender]) {
                return _calculateFeeAmount(amount, reflectionFeeBuy);
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    function calculateMarketingFee(uint256 amount, address recipient, address sender) private view returns (uint256) {
        uint256 marketingFee = 0;
        if (!_excludedFromFee(recipient, sender)) {
            if (_antiBotDistribution(recipient, sender) && !isRenounced()) {
                return 0;
            } else if (automatedMarketMakerPairs[recipient]) {
                return _calculateFeeAmount(amount, marketingFeeSell);
            } else if (!automatedMarketMakerPairs[sender]) {
                marketingFee = _calculateFeeAmount(amount, marketingFeeTransfer);
            }
        }

        if (marketingFee > 0) {
            uint256 tax = getTaxAmount(recipient, sender);
            if (tax == 1) marketingFee = 0;
            else marketingFee = _calculateFeeAmount(marketingFee, tax);
        }

        return marketingFee;
    }

    function getTaxAmount(address recipient, address sender) private view returns (uint256) {
        if (userTransferTax[recipient] > 0 && userTransferTax[sender] > 0) {
            return min(userTransferTax[recipient], userTransferTax[sender]);
        } else if (userTransferTax[recipient] > 0) {
            return userTransferTax[recipient];
        } else if (userTransferTax[sender] > 0) {
            return userTransferTax[sender];
        } else {
            return transferFeeRatio;
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _excludedFromFee(address recipient, address sender) private view returns (bool) {
        return _inMarketingSellSwap || _isExcludedFromFee[recipient] || _isExcludedFromFee[sender];
    }

    function _antiBotDistribution(address recipient, address sender) private view returns (bool) {
        return (isAntiBotDistribution[recipient] || isAntiBotDistribution[sender]) && !isRenounced();
    }

    function takeFee(address sender, uint256 amount, address recipient) internal view returns (uint256[2] memory) {
        uint256 reflectionFee = calculateReflectionFee(amount, recipient, sender);
        uint256 marketingFee = calculateMarketingFee(amount, recipient, sender);

        return [reflectionFee, marketingFee];
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient])  {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256[2] memory calculateFees = takeFee(sender, amount, recipient);
        uint256 reflectionFee = calculateFees[0];
        uint256 marketingFee = calculateFees[1];

        marketingFeeTokensCounter += marketingFee;
        ValuesStruct memory vs = _getValues(amount, reflectionFee, marketingFee);
        _takeMarketingFee(vs.rMarketingFee, vs.tMarketingFee);
        _distributeFee(vs.rReflectionFee, vs.tReflectionFee);
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, vs);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, vs);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, vs);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, vs);
        }
    }

    function _transferStandard(address sender, address recipient, ValuesStruct memory vs) private {
        _rOwned[sender] = _rOwned[sender] - vs.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + vs.rTransferAmount;
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, ValuesStruct memory vs) private {
        _rOwned[sender] = _rOwned[sender] - vs.rAmount;
        _tOwned[recipient] = _tOwned[recipient] + vs.tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + vs.rTransferAmount;
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - vs.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + vs.rTransferAmount;
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - vs.rAmount;
        _tOwned[recipient] = _tOwned[recipient] + vs.tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + vs.rTransferAmount;
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function excludeFromFee(address[] calldata accounts) external contractAdmin {
        unchecked {
            require(accounts.length < 501,"GAS Error: max limit is 500 addresses");
            for (uint32 i = 0; i < accounts.length; i++) {
                _isExcludedFromFee[accounts[i]] = true;
            }
        }
    }

    function setContractManager(address account, bool status) external contractManager {
        require(account != address(0), "Contract Manager Can't be the zero address");
        _isContractManager[account] = status;

        emit ContractManagerChange(account, status);
    }

    function setContractAdmin(address account, bool status) external contractManager {
        require(account != address(0), "Contract Admin Can't be the zero address");
        _isContractAdmin[account] = status;

        emit ContractAdminChange(account, status);
    }

    function setIsWhitelisted(address account, bool status) external onlyOwner {
        require(isWhitelisted[account] != status || _isExcludedFromFee[account] != status, "Nothing to change");
        if (isWhitelisted[account] != status) isWhitelisted[account] = status;
        if (_isExcludedFromFee[account] != status) _isExcludedFromFee[account] = status;

        emit WhitelistedStatus(account, status);
    }

    function includeInFee(address[] calldata accounts) external contractAdmin {
        unchecked {
            require(accounts.length < 501, "GAS Error: max limit is 500 addresses");
            for (uint32 i = 0; i < accounts.length; i++) {
                _isExcludedFromFee[accounts[i]] = false;
            }
        }
    }

    function isRenounced() public view returns(bool) {
        return owner() == address(0);
    }

    function setFeesWithLimits(uint8 _reflectionFeeBuy, uint8 _reflectionFeeSell, uint8 _marketingFeeSell, uint8 _marketingFeeTransfer) external onlyOwner() {
        require(_reflectionFeeBuy <= 1 && _reflectionFeeSell + _marketingFeeSell <= 5 && _marketingFeeTransfer <= 1, "Fees too high");
        reflectionFeeBuy = _reflectionFeeBuy;
        reflectionFeeSell = _reflectionFeeSell;
        marketingFeeSell = _marketingFeeSell;
        marketingFeeTransfer = _marketingFeeTransfer;

        emit FeesUpdated(reflectionFeeBuy, reflectionFeeSell, marketingFeeSell, marketingFeeTransfer);
    }

    function setSwapTokenAddress(address newToken) external contractAdmin() {
        require(newToken != address(0), "Swap Token address can't be the zero address");
        swapTokenAddress = newToken;

        emit ChangeSwapToken(newToken);
    }

    function setMarketingWallet(address newWallet) external contractAdmin() {
        require(newWallet != address(0), "Marketing Wallet Can't be the zero address");
        marketingFeeWallet = newWallet;

        emit ChangeMarketingWallet(newWallet);
    }

    function setMaxTxAmount(uint256 maxAmountInTokensWithDecimals) external contractAdmin {
        require(maxAmountInTokensWithDecimals > _tTotal / 1000, "Cannot set transaction amount less than 0.1 percent of initial Total Supply!");
        maxTxAmount = maxAmountInTokensWithDecimals;

        emit SetMaxTx(maxAmountInTokensWithDecimals);
    }

    function startFairlaunch() external onlyOwner {
        require(!fairLaunchStarted, "Fairlaunch Already enabled!");
        fairLaunchStarted = true;

        emit FairlaunchStarted(true);
    }

    function completeFairlaunch() external onlyOwner {
        require(!fairLaunchCompleted, "Fairlaunch Already Completed!");
        fairLaunchCompleted = true;
        if (!fairLaunchStarted) {
            fairLaunchStarted = true;
            emit FairlaunchStarted(true);
        }

        emit FairlaunchCompleted(true);
    }

    function setMarketingConvertToToken(bool status) external contractAdmin {
        require(marketingConvertToToken != status);
        marketingConvertToToken = status;

        emit SetMarketingConvertToToken(status);
    }

    // Number of Tokens to Accrue before Selling To Add to Marketing
	function setTokensSwapForMarketingAmounts(uint256 numTokensSwap) external contractAdmin {
        require(numTokensSwap <= _tTotal/100, "Can't swap more than 1% at once");
        _numTokensSwapForMarketing = numTokensSwap;

        emit SetSwapForMarketing(numTokensSwap);
    }
    
    /* This function sets a percentage of the Marketing Transfer Tax that is used for specific wallets. This is to be have a way
    to be able to offer exchanges a reduced Transfer Tax Amount below the standard 1%. Ie. If set to 100 Fee is 1%, if set to 50 Fee is 0.5%  
    */
    function setUserTransferTax(address user, uint256 amount) external contractAdmin {
        require(amount <= 100, "Amount out of percentage range!");
        userTransferTax[user] = amount;

        emit ChangeUserTransferTax(user, amount);
    }

    /* This function sets a percentage of the Marketing Transfer Tax that is used globaly. It is used to reduce the Marketing Transfer Fee to below 1
    Ie. If set to 100 Fee is 1%, if set to 50 Fee is 0.5%  
    */
    function setTransferFeeRatio(uint8 amount) external contractAdmin {
        require(amount <= 100, "Amount out of percentage range!");
        transferFeeRatio = amount;

        emit ChangeTransferFeeRatio(amount);
    }

    function setAutomatedMarketMakerPair(address pair, bool status) public onlyOwner {
        require(pair != uniswapV2Pair, "The original pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = status;

        emit SetAMM(pair, status);
    }

    /**
     * @dev Function to recover any ETH sent to Contract by Mistake.
    */	
    function recoverETHFromContract(uint256 weiAmount) external contractManager{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(owner()).transfer(weiAmount);

        emit ETHRecovered(weiAmount);
    }

    function rescueToken(address tokenAddr, address to) external contractManager {
        uint256 amount = IERC20(tokenAddr).balanceOf(address(this));
        if (tokenAddr == address(this)) {
            if (marketingFeeTokensCounter > amount) {
                revert("No tokens to withdraw!");
            }
            amount -= marketingFeeTokensCounter;
        }
        bool success = IERC20(tokenAddr).transfer(to, amount);
        require(success, "ERC20 transfer failed!");

        emit ERC20Rescued(tokenAddr, amount);
    }
}

