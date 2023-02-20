// SPDX-License-Identifier: NOLICENSE

pragma solidity ^0.8.10;
import "./mock_router/UniswapV2Router02.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

interface IBurner {
       function burnSaita() external; 
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external ;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline) external;    
}
contract VZZN is IERC20, OwnableUpgradeable {
    

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isBot;
    mapping(address => bool) private _isPair;

    address[] private _excluded;
    
    IRouter public router;
    address public pair;
    UniswapV2Router02 router02;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal;
    uint256 private _rTotal;
    
    uint256 public swapTokensAtAmount;
    uint256 public maxTxAmount;
    
    // Anti Dump //
    mapping (address => uint256) public _lastTrade;
    bool public coolDownEnabled = false;
    uint256 public coolDownTime = 0 seconds;
    uint256 public totalMarketingAndBurn;
    uint256 public totaloperationTax;

    address public buyBackAddress;
    address public marketingAddress;
    address public burnAddress;
    address public operations;

    address public USDT ;

    string private constant _name = "VZZN";
    string private constant _symbol = "VZZN";


    struct Taxes {
      uint256 rfi;
      uint256 buyback;
      uint256 marketing;
      uint256 burn;
      uint256 operationTax;
    }

    Taxes public taxes = Taxes(10,10,20,10,10);

    struct TotFeesPaidStruct {
        uint256 rfi;
        uint256 buyback;
        uint256 marketing;
        uint256 burn;
        uint256 operationTax;
    }

    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rbuyback;
      uint256 rMarketing;
      uint256 rBurn;
      uint256 roperationTax;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tbuyback;
      uint256 tMarketing;
      uint256 tBurn;
      uint256 toperationTax;
    }

    event FeesChanged();

    modifier addressValidation(address _addr) {
        require(_addr != address(0), 'VZZN Token: Zero address');
        _;
    }

    function init(address routerAddress, address owner_) public initializer {

    _tTotal = 10e7* 10**_decimals;
    _rTotal = (MAX - (MAX % _tTotal));
    
    swapTokensAtAmount = 300 * 10 ** 6;
    maxTxAmount = 100_000_000 * 10**_decimals;
    
    // Anti Dump //
    coolDownEnabled = false;
    coolDownTime = 0 seconds;
    totalMarketingAndBurn;
    totaloperationTax;

    buyBackAddress = 0x424eEFfB671e75961770CFf68cd35Fd667F6B76e;
    marketingAddress = 0x4DA2226Ac25155150932547abd3B5C788121c2fC;
    burnAddress = 0x000000000000000000000000000000000000dEaD;
    operations=0x6Fd941912781b705046ACECB7d5e88D1b6BeE0D2;

    USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    

    taxes = Taxes(10,10,20,10,10);

        __Ownable_init();
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory()).createPair(address(this) , address(_router.WETH()));
        
        router = _router;
        pair = _pair;
        addPair(pair);

        excludeFromReward(pair);

        _rOwned[owner_] = _rTotal;
        _isExcludedFromFee[owner_] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[buyBackAddress] = true;
        _isExcludedFromFee[burnAddress] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[operations] =true;
                
        emit Transfer(address(0), owner_, _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        //_transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }
    
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length <= 200, "Invalid length");
        require(account != owner(), "Owner cannot be excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }


    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function addPair(address _pair) public onlyOwner {
        _isPair[_pair] = true;
    }

    function removePair(address _pair) public onlyOwner {
        _isPair[_pair] = false;
    }

    function isPair(address account) public view returns(bool){
        return _isPair[account];
    }

    function setTaxes(uint256 _rfi, uint256 _buyback, uint256 _marketing, uint256 _burn, uint256 _operationTax) public onlyOwner {
        taxes.rfi = _rfi;
        taxes.buyback = _buyback;
        taxes.marketing = _marketing;
        taxes.burn = _burn;
        taxes.operationTax = _operationTax;
        emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi += tRfi;
    }

    function _takebuyback(uint256 rbuyback, uint256 tbuyback) private {
        totFeesPaid.buyback += tbuyback;
        if(_isExcluded[address(this)])_tOwned[address(this)] += tbuyback;
        _rOwned[address(this)] +=rbuyback;
    }
    
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private{
        totFeesPaid.marketing += tMarketing;
        if(_isExcluded[address(this)]) _tOwned[address(this)] += tMarketing;
        _rOwned[address(this)] += rMarketing;
    }

    function _takeBurn(uint256 rBurn, uint256 tBurn) private {
        totFeesPaid.burn += tBurn;
        if(_isExcluded[burnAddress]) _tOwned[burnAddress] += tBurn;
        _rOwned[burnAddress] += rBurn;
    }

    function _takeoperation(uint256 roperationTax, uint256 toperationTax) private { 
        totFeesPaid.operationTax += toperationTax;
        if(_isExcluded[address(this)]) _tOwned[address(this)] += toperationTax;
        _rOwned[address(this)]+= roperationTax;
    }

    function liquifyMarketingAndBurn() internal {
       address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 MarketAmount = (totalMarketingAndBurn * taxes.marketing)/(taxes.marketing + taxes.operationTax+taxes.buyback);
        uint256 operationAmount = (totalMarketingAndBurn * taxes.operationTax) / (taxes.marketing + taxes.operationTax+ taxes.buyback);
        uint256 buyback = (totalMarketingAndBurn * taxes.buyback) / (taxes.marketing + taxes.operationTax + taxes.buyback);
   
        _approve(address(this), address(router), totalMarketingAndBurn);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            MarketAmount,
            0, // accept any amount of ETH
            path,
            marketingAddress,
            block.timestamp + 1200
        );
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            operationAmount,
            0, // accept any amount of ETH
            path,
            operations,
            block.timestamp + 1200
        );
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            buyback,
            0, // accept any amount of ETH
            path,
            buyBackAddress,
            block.timestamp + 1200
        );
        totalMarketingAndBurn = 0;
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rbuyback,to_return.rMarketing, to_return.rBurn, to_return.roperationTax) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        } else {
            s.tRfi = (tAmount*taxes.rfi)/1000;
            s.tbuyback = (tAmount*taxes.buyback)/1000;
            s.tMarketing = tAmount*taxes.marketing/1000;
            s.tBurn = tAmount*taxes.burn/1000;
            s.toperationTax = tAmount*taxes.operationTax/1000;
            s.tTransferAmount = tAmount-s.tRfi-s.tbuyback-s.tMarketing-s.tBurn-s.toperationTax;
            return s;
        } 
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi,uint256 rbuyback,uint256 rMarketing,uint256 rBurn, uint256 roperationTax) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0,0);
        }else {
            rRfi = s.tRfi*currentRate;
            rbuyback = s.tbuyback*currentRate;
            rMarketing = s.tMarketing*currentRate;
            rBurn = s.tBurn*currentRate;
            roperationTax = s.toperationTax*currentRate;
            rTransferAmount =  rAmount-rRfi-rbuyback-rMarketing-rBurn-roperationTax;
            return (rAmount, rTransferAmount, rRfi,rbuyback,rMarketing,rBurn,roperationTax);
        }
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }

        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Zero amount");
        require(amount <= balanceOf(from),"Insufficient balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");
        require(amount <= maxTxAmount ,"Amount is exceeding maxTxAmount");
        bool takeFee = true;

        if (coolDownEnabled) {
            uint256 timePassed = block.timestamp - _lastTrade[from];
            require(timePassed > coolDownTime, "You must wait coolDownTime");
        }
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

        _lastTrade[from] = block.timestamp;


        if(from != pair && to != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            address[] memory path = new address[](3);
                path[0] = address(this);
                path[1] = router.WETH();
                path[2] = USDT;
            uint _amount1;

            if(totalMarketingAndBurn != 0){
                _amount1 = router.getAmountsOut(totalMarketingAndBurn,path)[2];
                if(_amount1 >= swapTokensAtAmount) liquifyMarketingAndBurn();
            } 
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender] - tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient] + s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
      
        if(s.rbuyback > 0 || s.tbuyback > 0){
            totalMarketingAndBurn +=  s.tbuyback;
            _takebuyback(s.rbuyback, s.tbuyback);
            emit Transfer(sender, address(this), s.tbuyback);
        }
        if(s.rMarketing > 0 || s.tMarketing > 0){
            totalMarketingAndBurn +=  s.tMarketing;
            _takeMarketing(s.rMarketing, s.tMarketing);
            emit Transfer(sender, address(this), s.tMarketing);
        }
        if(s.rBurn > 0 || s.tBurn > 0){
            _takeBurn(s.rBurn, s.tBurn);
            emit Transfer(sender, burnAddress, s.tBurn);
        }
        if( s.roperationTax > 0 || s.toperationTax > 0){
            totalMarketingAndBurn += s.toperationTax;  
            _takeoperation(s.roperationTax, s.toperationTax);   
            emit Transfer(sender,address(this), s.toperationTax);
        }  
        emit Transfer(sender, recipient, s.tTransferAmount);      
    }

    function updatebuybackWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(buyBackAddress != newWallet, 'SaitaRealty: Wallet already set');
        buyBackAddress = newWallet;
        _isExcludedFromFee[buyBackAddress];
    }

    function updateBurnWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(burnAddress != newWallet, 'SaitaRealty: Wallet already set');
        burnAddress = newWallet;
        _isExcludedFromFee[burnAddress];
    }

     function updateoperationWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(operations != newWallet, 'SaitaRealty: Wallet already set');
        operations = newWallet;
        _isExcludedFromFee[operations];
    }

    function updateMarketingWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(marketingAddress != newWallet, 'SaitaRealty: Wallet already set');
        marketingAddress = newWallet;
        _isExcludedFromFee[marketingAddress];
    }

    function updateStableCoin(address _usdt) external onlyOwner  addressValidation(_usdt) {
        require(USDT != _usdt, 'SaitaRealty: Wallet already set');
        USDT = _usdt;
    }

    function updateMaxTxAmt(uint256 amount) external onlyOwner {
        require(amount >= 100);
        maxTxAmount = amount * 10**_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner {
        require(amount > 0);
        swapTokensAtAmount = amount * 10**6;
    } 

    function updateCoolDownSettings(bool _enabled, uint256 _timeInSeconds) external onlyOwner{
        coolDownEnabled = _enabled;
        coolDownTime = _timeInSeconds * 1 seconds;
    }

    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, 'SaitaRealty: Value already set');
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner {
        require(accounts.length <= 100, "SaitaRealty: Invalid");
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner {
        router = IRouter(newRouter);
        pair = newPair;
        addPair(pair);
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }

//Length of the array shouldn't be greater than 50
    function airdropTokens(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length,"Invalid size");
        require(recipients.length <= 50, "50 addresses max at once");
         address sender = msg.sender;

         for(uint256 i; i<recipients.length; i++){
            address recipient = recipients[i];
            uint256 rAmount = amounts[i]*_getRate();
            _rOwned[sender] = _rOwned[sender]- rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rAmount;
            emit Transfer(sender, recipient, amounts[i]);
         }

        }

    //Use this in case ETH are sent to the contract by mistake
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(owner()).transfer(weiAmount);
    }
    
    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    // Owner cannot transfer out catecoin from this smart contract
    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable {
    }
}