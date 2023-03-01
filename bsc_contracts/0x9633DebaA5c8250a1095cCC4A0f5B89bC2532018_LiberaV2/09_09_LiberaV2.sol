// SPDX-License-Identifier: MIT
// Built by Libera.Financial - the Multichian Store of Value token
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

pragma solidity ^0.8.4;

abstract contract AuthUpgradeable is Initializable, UUPSUpgradeable, ContextUpgradeable {
    address owner;
    mapping (address => bool) private authorizations;

    function __AuthUpgradeable_init() internal onlyInitializing {
        __AuthUpgradeable_init_unchained();
    }

    function __AuthUpgradeable_init_unchained() internal onlyInitializing {
        owner = _msgSender();
        authorizations[_msgSender()] = true;
        __UUPSUpgradeable_init();
    }

    modifier onlyOwner() {
        require(isOwner(_msgSender()),"not owner"); _;
    }

    modifier authorized() {
        require(isAuthorized(_msgSender()),"unthorized access"); _;
    }

    function authorize(address _address) public onlyOwner {
        authorizations[_address] = true;
        emit Authorized(_address);
    }

    function unauthorize(address _address) public onlyOwner {
        authorizations[_address] = false;
        emit Unauthorized(_address);
    }

    function isOwner(address _address) public view returns (bool) {
        return _address == owner;
    }

    function isAuthorized(address _address) public view returns (bool) {
        return authorizations[_address];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        authorizations[oldOwner] = false;
        authorizations[newOwner] = true;
        emit Unauthorized(oldOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    event OwnershipTransferred(address oldOwner, address newOwner);
    event Authorized(address _address);
    event Unauthorized(address _address);

    uint256[49] private __gap;
}
interface IAutoLiquidity {
    function notifyLiquidity(address recipient, uint256 amount, bool isSelling, bool isBuying) external;
}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}
library SafeERC20 {

    using Address for address;
    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LiberaV2 is IERC20, Initializable, UUPSUpgradeable, AuthUpgradeable  {

    using SafeERC20 for IERC20;

    string public constant name= "Libera Multichain Store Of Value";
    string public constant symbol= "LIBERA";
    uint8  public constant decimals = 18;

    function _authorizeUpgrade(address) internal override onlyOwner {}
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();

        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[deadAddress] = true;
        _isExcludedFromFee[liquidityEngine] = true;

        excludeFromReward(deadAddress);
        excludeFromReward(liberoTreasury); // Reserve treasury to wrap Libero to Libera, never come to circulation
        excludeFromReward(burnTreasury); // Burn treasury for weekly burn, never come to circulation

        // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
        distributionFee.push(250);
        distributionFee.push(500);
        distributionFee.push(250);

        burnFee.push(250);
        burnFee.push(500);
        burnFee.push(250);

        liquidityFee.push(500);
        liquidityFee.push(1000);
        liquidityFee.push(500);

        _tokenTotal = _allChainTotal;
        _reflectionTotal = _tokenTotal * _startingRate;

        liquidityEngine = 0xbf90836cEfe8f93e88379BFDC84F12B855f649a2;
        minAmountToLiquidify = 500 * 1e18;
        isFeeActive = true;
        circuitBreakerFlag = 1; //normal mode

        //Migration from v1 to v2 code
        isMigrating = true;
        firstTimeMigration = true;
    }

    function _migrate() external onlyOwner { //can call this only once
        require(firstTimeMigration, "first time migration only");
        _isExcludedFromFee[address(this)] = true;
        excludeFromReward(address(this));
        _tokenBalance[address(this)] = _tokenTotal;
        _reflectionBalance[address(this)] = _reflectionTotal;
        address liberaV1=0x3A806A3315E35b3F5F46111ADb6E2BAF4B14A70D;
        uint256 deadBalance=IERC20(liberaV1).balanceOf(deadAddress);
        transfer(deadAddress,deadBalance);
        uint256 burnBalance=IERC20(liberaV1).balanceOf(burnTreasury);
        transfer(burnTreasury,burnBalance);
        uint256 liberoBalance=IERC20(liberaV1).balanceOf(liberoTreasury);
        transfer(liberoTreasury,liberoBalance);
        transfer(owner,balanceOf(address(this))); // owner will transfer to current holders
        firstTimeMigration = false;
    }

    bool private firstTimeMigration;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _tokenTotal;
    uint256 internal _reflectionTotal;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _allChainTotal = 50_000_000 * 10**18;
    uint256 internal constant _startingRate = (MAX - (MAX % _allChainTotal)) / _allChainTotal;

    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromReward;
    address[] internal _excludedFromReward;

    uint256 public constant _feeDecimal = 2;

    // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
    uint256[] public distributionFee;
    uint256[] public burnFee;
    uint256[] public liquidityFee;

    uint256 public distributionCollected;
    uint256 public liquidityFeeCollected;
    uint256 public burnFeeCollected;

    bool public isFeeActive;
    bool public isMigrating;

    address public liquidityEngine;
    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address internal constant liberoTreasury = 0xd01c6969C7Dc0B086f118bA3B4D926Da73acA2c7;
    address internal constant burnTreasury = 0x8908ea968D2f79D078D893c0bcecD63eACDD9322;

    mapping (address => bool) public automatedMarketMakerPairs;
    address[] internal _markerPairs;

    uint256 public circuitBreakerFlag;
    uint256 public minAmountToLiquidify;
    bool private inSwapping;

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tokenBalance[account];
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
        require(!isMigrating || tx.origin==owner, "Migration is in progress");
        require(!inSwapping,"Liquidity Engine is working");

        bool isSelling = automatedMarketMakerPairs[recipient];
        bool isBuying = automatedMarketMakerPairs[sender];

        if (liquidityFeeCollected>=minAmountToLiquidify) {
            liquidityFeeCollected = 0;
            inSwapping = true;
            IAutoLiquidity(liquidityEngine).notifyLiquidity(recipient, amount, isSelling, isBuying);
            inSwapping = false;
        }

        if (sender==recipient || amount==0) {
            emit Transfer(sender, recipient, amount);
            return;
        }

        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if (
            isFeeActive &&
            !_isExcludedFromFee[sender] &&
            !_isExcludedFromFee[recipient]
        ) {
            transferAmount = collectFee(
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
        if (_isExcludedFromReward[sender]) _tokenBalance[sender] -= amount;
        if (_isExcludedFromReward[recipient]) _tokenBalance[recipient] += transferAmount;

        emit Transfer(sender, recipient, transferAmount);
    }

    // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
    function calculateFee(uint256 feeIndex, uint256 amount) internal view
    returns (uint256 _distributionFee, uint256 _liquidityFee, uint256 _burnFee)  {

        _distributionFee = amount*distributionFee[feeIndex]/(10**(_feeDecimal + 2));
        _liquidityFee = amount*liquidityFee[feeIndex]/(10**(_feeDecimal + 2));
        _burnFee = amount*burnFee[feeIndex]/(10**(_feeDecimal + 2));
        if (circuitBreakerFlag==2) {
            if (feeIndex==0) {
                _distributionFee = _distributionFee/2;
                _liquidityFee = _liquidityFee/2;
                _burnFee = _burnFee/2;

            } else if (feeIndex==1) {
                _distributionFee = _distributionFee * 2;
                _liquidityFee = _liquidityFee  * 2;
                _burnFee = _burnFee * 2;
            }
        }

        return (_distributionFee, _liquidityFee, _burnFee);
    }


    function collectFee(address account, uint256 amount, uint256 rate,  bool sell, bool p2p) private returns (uint256) {
        uint256 transferAmount = amount;

        (uint256 _distributionFee, uint256 _liquidityFee, uint256 _burnFee) = calculateFee( p2p ? 2 : sell ? 1 : 0, amount);

        if (_burnFee > 0) {
            transferAmount -= _burnFee;
            _reflectionBalance[deadAddress] += _burnFee*rate;
            if (_isExcludedFromReward[deadAddress]) _tokenBalance[deadAddress] += _burnFee;
            emit Transfer(account, deadAddress, _burnFee);
            burnFeeCollected += _burnFee;
        }

        if (_liquidityFee > 0) {
            transferAmount -= _liquidityFee;
            _reflectionBalance[liquidityEngine] += _liquidityFee*rate;
            if (_isExcludedFromReward[liquidityEngine]) _tokenBalance[liquidityEngine] += _liquidityFee;
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
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(_reflectionBalance[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
        emit ExcludeFromRewards(account);
    }

    function includeInReward(address account) external authorized {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tokenBalance[account] = 0;
                _isExcludedFromReward[account] = false;
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

    function setIsMigrating(bool _status) external onlyOwner {
        require(isMigrating != _status, "Already set");
        require(isMigrating == false, "Can only set to false");
        isMigrating = _status;
        emit SetIsMigrating(_status);
    }

    function setAutomatedMarketMakerPair(address _dexPair, bool _status) external onlyOwner {
        require(automatedMarketMakerPairs[_dexPair] != _status,"already set");

        automatedMarketMakerPairs[_dexPair] = _status;

        if(_status){
            _markerPairs.push(_dexPair);
            if (!_isExcludedFromReward[_dexPair]) excludeFromReward(_dexPair);
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

    function activateCircuitBreakerFlag() external authorized {
        circuitBreakerFlag = 2;
        emit SetCircuitBreakerFlag(2);
    }

    function deActivateCircuitBreakerFlag() external authorized {
        circuitBreakerFlag = 1;
        emit SetCircuitBreakerFlag(1);
    }

    function getStuckBNB() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getStuckToken(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(msg.sender, balance), "Transfer failed");
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
        return totalSellFees() * 2;
    }
    function breakerBuyFee() external view returns (uint256) {
        return totalBuyFees() / 2;
    }
    function marketingWallet() external pure returns (address) {
        return 0x770BdD792f6471EB28cBccD4F193BB26e8B5B07E;
    }
    function circulatingSupply() public view returns (uint256) {
        return _tokenTotal - balanceOf(deadAddress) - balanceOf(burnTreasury) - balanceOf(liberoTreasury);
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
    event SetIsMigrating(bool value);
    event SetDistributionFee(uint256 buy, uint256 sell, uint256 p2p);
    event SetBurnFee(uint256 buy, uint256 sell, uint256 p2p);
    event SetLiquidityFee(uint256 buy, uint256 sell, uint256 p2p);
    event SetCircuitBreakerFlag(uint256 flag);
    event SetMinAmountToLiquidify(uint256 minAmount);
}