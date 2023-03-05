// SPDX-License-Identifier: MIT
// Built by Libera.Financial - the Multichian Store of Value token
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./AuthUpgradeable.sol";
import "./IUniswap.sol";

pragma solidity ^0.8.13;

interface IAutoLiquidity {
    function calcCircuitFlag(address sender, address recipient, uint256 amount, bool isSelling) external returns(uint256);
    function liquidify() external;
}

contract KeyOfLife is Initializable, UUPSUpgradeable, AuthUpgradeable, IERC20Upgradeable  {

    string public constant name= "KeyOfLife - Multichain Store Of Value";
    string public constant symbol= "KOL";
    uint8  public constant decimals = 18;

    function _authorizeUpgrade(address) internal override onlyOwner {}

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _tokenTotal;
    uint256 internal _reflectionTotal;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _allChainTotal = 50_000_000 * 10**18;
    uint256 internal constant _startingRate = (MAX - (MAX % _allChainTotal)) / _allChainTotal;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public isExcludedFromReward;
    address[] internal _excludedFromReward;

    uint256 public constant feeDecimal = 2;

    // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
    uint256[] public distributionFee;
    uint256[] public burnFee;
    uint256[] public liquidityFee;

    uint256 public distributionCollected;
    uint256 public liquidityFeeCollected;
    uint256 public burnFeeCollected;

    bool public isFeeActive;

    address public liquidityEngine;
    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant swapContract = 0x2Fd7D812d0D9a53FdaaA24F6E5A06ADa4aB28565;

    mapping (address => bool) public automatedMarketMakerPairs;
    address[] internal _markerPairs;

    uint256 public circuitBreakerFlag;
    uint256 public minAmountToLiquidify;
    uint256 public maxSellTransactionAmount;
    uint256 public feeBreakerSell; // 150%
    uint256 public feeBreakerBuy; // 50%

    receive() external payable {}

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();

        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[deadAddress] = true;
        _isExcludedFromFee[swapContract] = true;
        _isExcludedFromFee[liquidityEngine] = true;
        _isExcludedFromFee[address(this)] = true;

        excludeFromReward(deadAddress);
        excludeFromReward(swapContract);

        // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
        distributionFee.push(0);
        distributionFee.push(250);
        distributionFee.push(250);

        burnFee.push(100);
        burnFee.push(250);
        burnFee.push(250);

        liquidityFee.push(0);
        liquidityFee.push(500);
        liquidityFee.push(500);

        _tokenTotal = _allChainTotal;
        _reflectionTotal = _tokenTotal * _startingRate;

        liquidityEngine = 0x3A28a3feCDc4036FDbc1945E66cB504CF72f2220;
        minAmountToLiquidify = 500 * 1e18; // 500 KOL = $500 at start
        maxSellTransactionAmount = 20_000 * 1e18; // $20,000K
        isFeeActive = true;
        circuitBreakerFlag = 1; //normal mode
        feeBreakerSell = 150;
        feeBreakerBuy = 50;

        _tokenBalance[owner] = _tokenTotal;
        _reflectionBalance[owner] = _reflectionTotal;
    }

    function totalSupply() external view override returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (isExcludedFromReward[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256){
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool){
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }
        return true;
    }

    function reflectionFromToken(uint256 tokenAmount) public view returns (uint256){
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        return tokenAmount * _getReflectionRate();
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256){
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        return reflectionAmount/_getReflectionRate();
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(sender)>=amount,"ERC20: transfer amount exceeds balance");

        bool isSelling = automatedMarketMakerPairs[recipient];
        bool isBuying = automatedMarketMakerPairs[sender];
        bool excludedAccount = _isExcludedFromFee[sender] || _isExcludedFromFee[recipient];

        if (isSelling && !excludedAccount) {
            require(amount<=maxSellTransactionAmount,"Sell amount is too much");
        }

        if (isSelling || isBuying) {
            circuitBreakerFlag = IAutoLiquidity(liquidityEngine).calcCircuitFlag(sender, recipient, amount, isSelling);
            //function is reserved for future use, currently this function will auto return 1
        }

        if (!isBuying && liquidityFeeCollected>=minAmountToLiquidify) {
            liquidityFeeCollected = 0;
            IAutoLiquidity(liquidityEngine).liquidify();
        }

        if (sender==recipient || amount==0) {
            emit Transfer(sender, recipient, amount);
            return;
        }

        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if (isFeeActive && !excludedAccount) {
            transferAmount = _collectFee(
                sender,
                amount,
                rate,
                isSelling,
                !isSelling && !isBuying);
        }

        //transfer reflection
        _reflectionBalance[sender] -= amount * rate;
        _reflectionBalance[recipient] += transferAmount *rate;

        //if any account belongs to the excludedAccount transfer token
        if (isExcludedFromReward[sender]) _tokenBalance[sender] -= amount;
        if (isExcludedFromReward[recipient]) _tokenBalance[recipient] += transferAmount;

        emit Transfer(sender, recipient, transferAmount);
    }

    // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
    function _calculateFee(uint256 feeIndex, uint256 amount) internal view
    returns (uint256 _distributionFee, uint256 _liquidityFee, uint256 _burnFee)  {

        _distributionFee = amount*distributionFee[feeIndex]/(10**(feeDecimal + 2));
        _liquidityFee = amount*liquidityFee[feeIndex]/(10**(feeDecimal + 2));
        _burnFee = amount*burnFee[feeIndex]/(10**(feeDecimal + 2));
        if (circuitBreakerFlag==2) {
            if (feeIndex==0) {
                _distributionFee = _distributionFee * feeBreakerSell/100;
                _liquidityFee = _liquidityFee * feeBreakerSell/100;
                _burnFee = _burnFee * feeBreakerSell/100;

            } else if (feeIndex==1) {
                _distributionFee = _distributionFee * feeBreakerBuy/100;
                _liquidityFee = _liquidityFee  * feeBreakerBuy/100;
                _burnFee = _burnFee * feeBreakerBuy/100;
            }
        }

        return (_distributionFee, _liquidityFee, _burnFee);
    }


    function _collectFee(address account, uint256 amount, uint256 rate,  bool sell, bool p2p) private returns (uint256) {
        uint256 transferAmount = amount;

        (uint256 _distributionFee, uint256 _liquidityFee, uint256 _burnFee) = _calculateFee( p2p ? 2 : sell ? 1 : 0, amount);

        if (_burnFee > 0) {
            transferAmount -= _burnFee;
            _reflectionBalance[deadAddress] += _burnFee*rate;
            if (isExcludedFromReward[deadAddress]) _tokenBalance[deadAddress] += _burnFee;
            emit Transfer(account, deadAddress, _burnFee);
            burnFeeCollected += _burnFee;
        }

        if (_liquidityFee > 0) {
            transferAmount -= _liquidityFee;
            _reflectionBalance[liquidityEngine] += _liquidityFee*rate;
            if (isExcludedFromReward[liquidityEngine]) _tokenBalance[liquidityEngine] += _liquidityFee;
            emit Transfer(account, liquidityEngine, _liquidityFee);
            liquidityFeeCollected += _liquidityFee;
        }

        if (_distributionFee > 0) {
            transferAmount -= _distributionFee;
            _reflectionTotal -= _distributionFee*rate;
            distributionCollected += _distributionFee;
        }
        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        if (_tokenTotal==0) return _startingRate;
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;

        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if(
                _reflectionBalance[_excludedFromReward[i]] > reflectionSupply ||
                _tokenBalance[_excludedFromReward[i]] > tokenSupply
            ){
                return _reflectionTotal/_tokenTotal;
            }

            reflectionSupply -= _reflectionBalance[_excludedFromReward[i]];

            tokenSupply -= _tokenBalance[_excludedFromReward[i]];
        }

        if (reflectionSupply < _reflectionTotal/_tokenTotal || tokenSupply==0){
            return _reflectionTotal/_tokenTotal;
        }

        return reflectionSupply/tokenSupply;
    }

    function excludeFromReward(address account) public authorized {
        require(!isExcludedFromReward[account], "Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(_reflectionBalance[account]);
        }
        isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
        emit ExcludeFromRewards(account);
    }

    function includeInReward(address account) external authorized {
        require(isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _reflectionBalance[account] = reflectionFromToken(_tokenBalance[account]);
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
        emit IncludeInRewards(account);
    }

    function setExcludeFromFee(address account, bool value) external authorized {
        require(_isExcludedFromFee[account] != value, "Already set");
        _isExcludedFromFee[account] = value;
        emit ExcludeFromFees(account, value);
    }

    function setFeeActive(bool value) external onlyOwner{
        require(isFeeActive != value, "Already set");
        isFeeActive = value;
        emit SetFeeActive(value);
    }

    function setliquidityEngine(address _address) external onlyOwner {
        require(_address!=address(0),"cannot be zero address");
        liquidityEngine = _address;
        _isExcludedFromFee[liquidityEngine] = true;
        emit SetliquidityEngine(_address);
    }

    function setAutomatedMarketMakerPair(address _dexPair, bool _status) external onlyOwner {
        require(automatedMarketMakerPairs[_dexPair] != _status,"already set");

        automatedMarketMakerPairs[_dexPair] = _status;

        if(_status){
            _markerPairs.push(_dexPair);
            if (!isExcludedFromReward[_dexPair]) excludeFromReward(_dexPair);
        }else{
            for (uint256 i = 0; i < _markerPairs.length; i++) {
                if (_markerPairs[i] == _dexPair) {
                    _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                    _markerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_dexPair, _status);
    }

    function setDistributionFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        require(buy <= 1000 && sell <= 1000 && p2p <= 1000, "No fee should be >10%");
        distributionFee[0] = buy;
        distributionFee[1] = sell;
        distributionFee[2] = p2p;
        emit SetDistributionFee( buy,  sell,  p2p);
    }

    function setBurnFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        require(buy <= 1000 && sell <= 1000 && p2p <= 1000, "No fee should be >10%");
        burnFee[0] = buy;
        burnFee[1] = sell;
        burnFee[2] = p2p;
        emit SetBurnFee( buy,  sell,  p2p);
    }

    function setLiquidityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        require(buy <= 1000 && sell <= 1000 && p2p <= 1000, "No fee should be >10%");
        liquidityFee[0] = buy;
        liquidityFee[1] = sell;
        liquidityFee[2] = p2p;
        emit SetLiquidityFee( buy,  sell,  p2p);
    }

    function setMinAmountToLiquidify(uint256 _minAmount) external onlyOwner {
        minAmountToLiquidify = _minAmount;
        emit SetMinAmountToLiquidify(_minAmount);
    }

    function setMaxSellPerTx(uint256 _amount) external onlyOwner {
        require(_amount >= 1 * 1e18,"Need to be >=1");
        maxSellTransactionAmount = _amount;
        emit SetMaxSellPerTx(_amount);
    }

    function activateCircuitBreaker() external authorized {
        circuitBreakerFlag = 2;
        emit SetCircuitBreakerFlag(2);
    }

    function deActivateCircuitBreaker() external authorized {
        circuitBreakerFlag = 1;
        emit SetCircuitBreakerFlag(1);
    }

    function setBreakerFeeMultiplier(uint256 _feeBreakerSell, uint256 _feeBreakerBuy) external authorized {
        require(_feeBreakerSell<=200 && _feeBreakerBuy<=200,"Maximum 200% of buy & sell fee");
        feeBreakerSell = _feeBreakerSell;
        feeBreakerBuy = _feeBreakerBuy;
        emit SetBreakerFeeMultiplier(_feeBreakerSell, _feeBreakerBuy );
    }


    function manualSync() public {
        for(uint i = 0; i < _markerPairs.length; i++){

            try IUniswapV2Pair(_markerPairs[i]).sync() {
            }
            catch Error (string memory reason) {
                emit SyncLpErrorEvent(_markerPairs[i], reason);
            }
        }
    }

    function getStuckBNB() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getStuckToken(address token) external onlyOwner {
        uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
        require(IERC20Upgradeable(token).transfer(msg.sender, balance), "Transfer failed");
    }

    /////////////////////////////////////////////////////
    ///////////    V1 compability FUNCTIONS    //////////
    /////////////////////////////////////////////////////

    function checkIsExcludedFromFees(address _account) external view returns (bool) {
        return(_isExcludedFromFee[_account]);
    }
    function totalSellFees() public view returns (uint256) {
        return (distributionFee[1] + burnFee[1] + liquidityFee[1]);
    }
    function totalBuyFees() public view returns (uint256) {
        return (distributionFee[0] + burnFee[0] + liquidityFee[0]);
    }
    function normalTransferFee() public view returns (uint256) {
        return (distributionFee[2] + burnFee[2] + liquidityFee[2]);
    }
    function breakerSellFee() external view returns (uint256) {
        return totalSellFees() * feeBreakerSell/100;
    }
    function breakerBuyFee() external view returns (uint256) {
        return totalBuyFees() * feeBreakerBuy/100;
    }
    function marketingWallet() external pure returns (address) {
        return 0x770BdD792f6471EB28cBccD4F193BB26e8B5B07E;
    }
    function circulatingSupply() public view returns (uint256) {
        return _tokenTotal - balanceOf(deadAddress) - balanceOf(swapContract);
    }
    function getPeriod() public pure returns (uint256) {
        return 1;
    }
    /////////////////////////////////////////////////////
    ///////////    Compability FUNCTIONS ENDs  //////////
    /////////////////////////////////////////////////////

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromRewards(address indexed account);
    event IncludeInRewards(address indexed account);
    event SetliquidityEngine(address indexed account);
    event SetFeeActive(bool value);
    event SetDistributionFee(uint256 buy, uint256 sell, uint256 p2p);
    event SetBurnFee(uint256 buy, uint256 sell, uint256 p2p);
    event SetLiquidityFee(uint256 buy, uint256 sell, uint256 p2p);
    event SetCircuitBreakerFlag(uint256 flag);
    event SetMinAmountToLiquidify(uint256 minAmount);
    event SyncLpErrorEvent(address lpPair, string reason);
    event SetBreakerFeeMultiplier(uint256 _feeBreakerSell, uint256 _feeBreakerBuy);
    event SetMaxSellPerTx(uint256 amount);
}