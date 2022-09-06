/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.10;

// bbbbbbbb                                                                                                                                                        
// b::::::b                                                                   tttt                           kkkkkkkk                                              
// b::::::b                                                                ttt:::t                           k::::::k                                              
// b::::::b                                                                t:::::t                           k::::::k                                              
//  b:::::b                                                                t:::::t                           k::::::k                                              
//  b:::::bbbbbbbbb        ssssssssss      mmmmmmm    mmmmmmm        ttttttt:::::ttttttt       ooooooooooo    k:::::k    kkkkkkk eeeeeeeeeeee    nnnn  nnnnnnnn    
//  b::::::::::::::bb    ss::::::::::s   mm:::::::m  m:::::::mm      t:::::::::::::::::t     oo:::::::::::oo  k:::::k   k:::::kee::::::::::::ee  n:::nn::::::::nn  
//  b::::::::::::::::b ss:::::::::::::s m::::::::::mm::::::::::m     t:::::::::::::::::t    o:::::::::::::::o k:::::k  k:::::ke::::::eeeee:::::een::::::::::::::nn 
//  b:::::bbbbb:::::::bs::::::ssss:::::sm::::::::::::::::::::::m     tttttt:::::::tttttt    o:::::ooooo:::::o k:::::k k:::::ke::::::e     e:::::enn:::::::::::::::n
//  b:::::b    b::::::b s:::::s  ssssss m:::::mmm::::::mmm:::::m           t:::::t          o::::o     o::::o k::::::k:::::k e:::::::eeeee::::::e  n:::::nnnn:::::n
//  b:::::b     b:::::b   s::::::s      m::::m   m::::m   m::::m           t:::::t          o::::o     o::::o k:::::::::::k  e:::::::::::::::::e   n::::n    n::::n
//  b:::::b     b:::::b      s::::::s   m::::m   m::::m   m::::m           t:::::t          o::::o     o::::o k:::::::::::k  e::::::eeeeeeeeeee    n::::n    n::::n
//  b:::::b     b:::::bssssss   s:::::s m::::m   m::::m   m::::m           t:::::t    tttttto::::o     o::::o k::::::k:::::k e:::::::e             n::::n    n::::n
//  b:::::bbbbbb::::::bs:::::ssss::::::sm::::m   m::::m   m::::m           t::::::tttt:::::to:::::ooooo:::::ok::::::k k:::::ke::::::::e            n::::n    n::::n
//  b::::::::::::::::b s::::::::::::::s m::::m   m::::m   m::::m           tt::::::::::::::to:::::::::::::::ok::::::k  k:::::ke::::::::eeeeeeee    n::::n    n::::n
//  b:::::::::::::::b   s:::::::::::ss  m::::m   m::::m   m::::m             tt:::::::::::tt oo:::::::::::oo k::::::k   k:::::kee:::::::::::::e    n::::n    n::::n
//  bbbbbbbbbbbbbbbb     sssssssssss    mmmmmm   mmmmmm   mmmmmm               ttttttttttt     ooooooooooo   kkkkkkkk    kkkkkkk eeeeeeeeeeeeee    nnnnnn    nnnnnn
                                                                                                                                                                                                                                                                                                                                                                     

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
}

contract BSM is Context, IERC20, Ownable {

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBot;

    address[] private _excluded;
    
    bool public swapEnabled = false;
    bool private swapping;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 100e6 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    
    uint256 public swapTokensAtAmount = 5_000 * 10**_decimals;
    uint256 public maxTxAmount = 1_000_000 * 10**_decimals;
    
    // Anti Dump //
    mapping (address => uint256) public _lastTrade;
    bool public coolDownEnabled = false;
    uint256 public coolDownTime = 5 seconds;

    address public treasuryAddress = 0x3F1930d77eeC56F8b52dB6197a27156c36fd68E2;
    address public marketingAddress = 0x4DA2226Ac25155150932547abd3B5C788121c2fC;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public lpRecipient = 0xC59F51F358c0a56Af990C938933a3E16a0f444C9;


    string private constant _name = "BSM TOKEN";
    string private constant _symbol = "BSM";

    bool public FeeToETH = true;
    bool public swapLiquifyEnabled = true;

    struct Taxes {
      uint256 rfi;
      uint256 treasury;
      uint256 marketing;
      uint256 burn;
      uint256 liquidity;
    }

    Taxes public taxes = Taxes(10,0,20,10,10);

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 treasury;
        uint256 marketing;
        uint256 burn;
        uint256 liquidity;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rTreasury;
      uint256 rMarketing;
      uint256 rBurn;
      uint256 rLiquidity;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tTreasury;
      uint256 tMarketing;
      uint256 tBurn;
      uint256 tLiquidity;
    }

    event FeesChanged();
    event UpdatedRouter(address oldRouter, address newRouter);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor (address routerAddress) {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        
        excludeFromReward(pair);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[treasuryAddress]=true;
        _isExcludedFromFee[burnAddress] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[lpRecipient] = true;

        emit Transfer(address(0), owner(), _tTotal);
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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
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

    function setTaxes(uint256 _rfi, uint256 _treasury, uint256 _marketing, uint256 _burn, uint256 _liquidity) public onlyOwner {
        taxes.rfi = _rfi;
        taxes.treasury = _treasury;
        taxes.marketing = _marketing;
        taxes.burn = _burn;
        taxes.liquidity = _liquidity;
        emit FeesChanged();
    }


    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;
        if(_isExcluded[address(this)]) _tOwned[address(this)]+=tLiquidity;
        _rOwned[address(this)] +=rLiquidity;
    }

    function _takeTreasury(uint256 rTreasury, uint256 tTreasury) private {
        totFeesPaid.treasury +=tTreasury;
        if(_isExcluded[address(this)]) _tOwned[address(this)]+=tTreasury;
        _rOwned[address(this)] +=rTreasury;
    }
    
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private{
        totFeesPaid.marketing +=tMarketing;
        if(_isExcluded[address(this)]) _tOwned[address(this)]+=tMarketing;
        _rOwned[address(this)] +=rMarketing;
    }

    function _takeBurn(uint256 rBurn, uint256 tBurn) private{
        totFeesPaid.burn +=tBurn;
        if(_isExcluded[marketingAddress])_tOwned[burnAddress]+=tBurn;
        _rOwned[burnAddress] +=rBurn;
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rTreasury,to_return.rMarketing, to_return.rBurn, to_return.rLiquidity) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        
        s.tRfi = tAmount*taxes.rfi/1000;
        s.tTreasury = tAmount*taxes.treasury/1000;
        s.tMarketing = tAmount*taxes.marketing/1000;
        s.tBurn = tAmount*taxes.burn/1000;
        s.tLiquidity = tAmount*taxes.liquidity/1000;
        s.tTransferAmount = tAmount-s.tRfi-s.tTreasury-s.tLiquidity-s.tMarketing-s.tBurn;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi,uint256 rTreasury,uint256 rMarketing,uint256 rBurn,uint256 rLiquidity) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rTreasury = s.tTreasury*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rBurn = s.tBurn*currentRate;
        rTransferAmount =  rAmount-rRfi-rTreasury-rLiquidity-rMarketing-rBurn;
        return (rAmount, rTransferAmount, rRfi,rTreasury,rMarketing,rBurn,rLiquidity);
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
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");
        

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping){
            require(amount <= maxTxAmount ,"Amount is exceeding maxTxAmount");

            if(from != pair && coolDownEnabled){
                uint256 timePassed = block.timestamp - _lastTrade[from];
                require(timePassed > coolDownTime, "You must wait coolDownTime");
                _lastTrade[from] = block.timestamp;
            }
            if(to != pair && coolDownEnabled){
                uint256 timePassed2 = block.timestamp - _lastTrade[to];
                require(timePassed2 > coolDownTime, "You must wait coolDownTime");
                _lastTrade[to] = block.timestamp;
            }
        }
        
        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);

        valuesFromGetValues memory s = _getValues(amount, takeFee);

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = contractBalance >= swapTokensAtAmount;
        uint256 FeeAmount = s.tMarketing + s.tTreasury;
        uint256 LiquiditySwapAmount = swapTokensAtAmount - FeeAmount;

        if(!swapping && swapEnabled && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            
            if(canSwap && swapLiquifyEnabled){
               swapAndLiquify(LiquiditySwapAmount);
            }

            if(contractBalance >= FeeAmount && FeeToETH){
              swapTokensForETH(FeeAmount, marketingAddress);
            }
        }
        
        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
        
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if(s.rLiquidity > 0 || s.tLiquidity > 0) {
            _takeLiquidity(s.rLiquidity,s.tLiquidity);
        }
        if(s.rTreasury > 0 || s.tTreasury > 0){
            _takeTreasury(s.rTreasury, s.tTreasury);
            emit Transfer(sender, address(this), s.tTreasury);
        }
        if(s.rMarketing > 0 || s.tMarketing > 0){
            _takeMarketing(s.rMarketing, s.tMarketing);
            emit Transfer(sender, address(this), s.tMarketing);
        }
        if(s.rBurn > 0 || s.tBurn > 0){
            _takeBurn(s.rBurn, s.tBurn);
            emit Transfer(sender, burnAddress, s.tBurn);
        }
        
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tLiquidity);
        
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
       // Split the contract balance into halves
        uint256 tokensToAddLiquidityWith = tokens / 2;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap, address(this));
        uint256 ETHToAddLiquidityWith = address(this).balance - initialBalance;

        if(ETHToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);
        }

    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpRecipient,
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount, address payaddress) private {
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
            payaddress,
            block.timestamp
        );
    }

    function updateTreasuryWallet(address newWallet) external onlyOwner{
        require(treasuryAddress != newWallet ,'Wallet already set');
        treasuryAddress = newWallet;
        _isExcludedFromFee[treasuryAddress];
    }

    function updateBurnWallet(address newWallet) external onlyOwner{
        require(burnAddress != newWallet ,'Wallet already set');
        burnAddress = newWallet;
        _isExcludedFromFee[burnAddress];
    }

    function updateMarketingWallet(address newWallet) external onlyOwner{
        require(marketingAddress != newWallet ,'Wallet already set');
        marketingAddress = newWallet;
        _isExcludedFromFee[marketingAddress];
    }

    function updateLPRecipient(address newWallet) external onlyOwner{
        require(lpRecipient != newWallet ,'Wallet already set');
        lpRecipient = newWallet;
        _isExcludedFromFee[lpRecipient];
    }

    function updateMaxTxAmt(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }

    function updateCoolDownSettings(bool _enabled, uint256 _timeInSeconds) external onlyOwner{
        coolDownEnabled = _enabled;
        coolDownTime = _timeInSeconds * 1 seconds;
    }

    function updateFeeToETH(bool _enabled) external onlyOwner{
       FeeToETH  = _enabled;
    }

    function updateSwapLiquifyEnabled(bool _enabled) external onlyOwner {
        swapLiquifyEnabled = _enabled;
    }

    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, 'Value already set');
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }
    
    function airdropTokens(address[] memory recipients, uint256[] memory amounts) external onlyOwner{
         require(recipients.length == amounts.length,"Invalid size");
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

    receive() external payable{
    }
}