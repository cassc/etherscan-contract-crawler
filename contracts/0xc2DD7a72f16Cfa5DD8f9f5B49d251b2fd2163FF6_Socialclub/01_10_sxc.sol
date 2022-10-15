// SPDX-License-Identifier: MIT
/*
🆂🅾🅲🅸🅰🅻 🆇 🅲🅻🆄🅱
🅹🅾🅸🅽 🆃🅷🅴 🅼🅾🆅🅴🅼🅴🅽🆃

Site http://socialxclub.org
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Socialclub is IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) public isExcluded;
    address[] private _excluded;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * (10**18);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    string private _name = "Social Club";
    string private _symbol = "SXC";
    uint8 private _decimals = 18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public projectWalletAddress = payable(0xA06063b2Ce7C282B3e3C99F015A6Fa8d0581Aa76);

    
    uint256 public maxTransactionAmount = _tTotal / 1000 * 5;
    uint256 public maxWalletAmount = _tTotal / 100 * 2;
    uint256 public swapTokensAtAmount = _tTotal / 10000;

    mapping(address => bool) public isBlacklist;

    uint256 public reflectionFee = 1;    
    uint256 public projectFee = 3;
    uint256 public liquidityFee = 1;
    uint256 public burnFee = 1;    

    uint256 public reflectionFee_OnTransfer = 1;    
    uint256 public projectFee_OnTransfer = 3;
    uint256 public liquidityFee_OnTransfer = 1;
    uint256 public burnFee_OnTransfer = 1;    

    // once set to true can never be set false again
    bool public tradingOpen = false;
    uint256 public launchTime;    

    uint256 public lastATH = 0;
    uint256 public priceImpactLimit = 200;   //   2%    

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event LogReserve(uint256 amt0, uint256 amt1);

    constructor() {    	

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;        

        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);        

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function reflectionFromToken(uint256 tAmount) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        uint256 currentRate =  _getRate();
        return tAmount.mul(currentRate);        
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _excludeFromReward(address account) private {
        require(!isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        isExcluded[account] = true;
        _excluded.push(account);        
    }

    function _includeInReward(address account) private {
        require(isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _rOwned[account] = reflectionFromToken(_tOwned[account]);
                isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }       
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);        
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable {

  	}    

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }    

    function setMaxTransactionAmount(uint256 newAmount) public onlyOwner {
        maxTransactionAmount = newAmount;
    }

    function setMaxWalletAmount(uint256 newAmount) public onlyOwner {
        maxWalletAmount = newAmount;
    }
    
    function setSwapTokensAtAmount(uint256 newAmount) public onlyOwner {
        swapTokensAtAmount = newAmount;
    }    

    function updateProjectWalletAddress(address payable newAddress) public onlyOwner {
        projectWalletAddress = newAddress;
    }

    function updateFees(uint256 _refletionFee, uint256 _projectFee, uint256 _liquidityFee, uint256 _burnFee) public onlyOwner {
        reflectionFee = _refletionFee;        
        projectFee = _projectFee;
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
    }   

    function updateFees_OnTransfer(uint256 _refletionFee, uint256 _projectFee, uint256 _liquidityFee, uint256 _burnFee) public onlyOwner {
        reflectionFee_OnTransfer = _refletionFee;        
        projectFee_OnTransfer = _projectFee;
        liquidityFee_OnTransfer = _liquidityFee;
        burnFee_OnTransfer = _burnFee;
    } 

    function updatePriceImpactLimit(uint256 val) public onlyOwner {
        require(val > 0 || val < 10000, "Please set correct number!");
        priceImpactLimit = val;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(!swapping)
        {              
            if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                require(amount <= maxTransactionAmount, "Transfer amount exceeds the maxTransactionAmount.");            
                require(!isBlacklist[from] || !isBlacklist[to], 'Bots not allowed here! Play fair.');  //antibot 
            }
            
            // buy
            if ((from == uniswapV2Pair ||
                to == uniswapV2Pair) &&
                !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                require(tradingOpen, "Trading not yet enabled.");

                //antibot: block zero bots will be added to bot blacklist
                if (block.timestamp == launchTime) {
                    isBlacklist[to] = true;                
                }
            }                   
        
    		uint256 contractTokenBalance = balanceOf(address(this));    
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;            

            if( canSwap &&
            from != uniswapV2Pair &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] )
            {
                swapping = true;
                swapAndDistribute();
                swapping = false;
            }          
            
            if((!_isExcludedFromFees[from] && !_isExcludedFromFees[to])) {
                uint reflectionFee_tmp = reflectionFee;
                uint projectFee_tmp = projectFee;
                uint liquidityFee_tmp = liquidityFee;
                uint burnFee_tmp = burnFee;                
                if (from != uniswapV2Pair && to != uniswapV2Pair){
                    reflectionFee_tmp = reflectionFee_OnTransfer;
                    projectFee_tmp = projectFee_OnTransfer;
                    liquidityFee_tmp = liquidityFee_OnTransfer;
                    burnFee_tmp = burnFee_OnTransfer;
                }
                uint256 reflectionAmt = amount.div(100).mul(reflectionFee_tmp);
                uint256 projectAmt = amount.div(100).mul(projectFee_tmp);
                uint256 liquidityAmt = amount.div(100).mul(liquidityFee_tmp);
                uint256 burnAmt = amount.div(100).mul(burnFee_tmp);
                amount = amount.sub(reflectionAmt).sub(projectAmt);
                amount = amount.sub(liquidityAmt).sub(burnAmt);
                _basicTransfer(from, to, amount);
                _basicTransfer(from, address(0), burnAmt);
                _basicTransfer(from, address(this), projectAmt.add(liquidityAmt));
                _reflectFee(reflectionAmt.mul(_getRate()));
            } else {
                _basicTransfer(from, to, amount);
            }   
            if (to != uniswapV2Pair && !_isExcludedFromFees[to]){
                require(balanceOf(to) <= maxWalletAmount, "Max wallet amount exceeds!");
            }     
            if (tradingOpen && (from == uniswapV2Pair || to == uniswapV2Pair)) {
                checkATH(from, to, amount);
            }         
        }else{
            _basicTransfer(from, to, amount);
        }        
    }

    function checkATH(address from, address to, uint256 amount) private {
        address tmpAddr = IUniswapV2Pair(uniswapV2Pair).token0(); 
        if (tmpAddr == address(this)){
            (uint256 res0, uint256 res1, ) = IUniswapV2Pair(uniswapV2Pair).getReserves(); 
            emit LogReserve(res0, res1);       
            uint256 result = res1 * 1e18 / res0;
            if (result > lastATH) {
                lastATH = result;                
            }        
            if (!_isExcludedFromFees[from] && to == uniswapV2Pair){
                res0 = res0.add(amount);
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = uniswapV2Router.WETH();
                res1 = res1.sub(uniswapV2Router.getAmountsOut(amount, path)[1]);
                emit LogReserve(res0, res1);
                uint256 result1 = res1 * 1e18 / res0;
                if (result1 < lastATH / 10000 * (10000 - priceImpactLimit)){
                    require(false, "Price impact is higher than Anti dumping limit!");
                }
            }
        } else {
            (uint256 res0, uint256 res1, ) = IUniswapV2Pair(uniswapV2Pair).getReserves(); 
            emit LogReserve(res0, res1);       
            uint256 result = res0 * 1e18 / res1;
            if (result > lastATH) {
                lastATH = result;            
                return;
            }        
            if (!_isExcludedFromFees[from] && to == uniswapV2Pair){
                res1 = res1.add(amount);
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = uniswapV2Router.WETH();
                res0 = res0.sub(uniswapV2Router.getAmountsOut(amount, path)[1]);
                emit LogReserve(res0, res1);
                uint256 result2 = res0 * 1e18 / res1;
                if (result2 < lastATH / 10000 * (10000 - priceImpactLimit)){
                    require(false, "Price impact is higher than Anti dumping limit!");
                }
            }
        }        
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        if (isExcluded[sender]){
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (isExcluded[recipient]){
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }

    function _reflectFee(uint256 rFee) private {
        _rTotal = _rTotal.sub(rFee);        
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

    function swapEthForTokens(uint256 ethAmount, uint256 minTokens, address account) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uint256 balanceBefore = balanceOf(account);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            minTokens,
            path,
            account,
            block.timestamp
        );

        uint256 tokenAmount = balanceOf(account).sub(balanceBefore);
        return tokenAmount;
    }

    function swapAndDistribute() private {
        bool retVal = false;
        if (address(this).balance > 0){
            (retVal,) = address(projectWalletAddress).call{value: address(this).balance}("");            
        }
        
        uint256 amountToLiquify = balanceOf(address(this)).mul(liquidityFee).div(liquidityFee.add(projectFee)).div(2);
        swapTokensForEth(amountToLiquify);
        if(amountToLiquify > 0){
            _approve(address(this), address(uniswapV2Router), amountToLiquify);
            uniswapV2Router.addLiquidityETH{value: address(this).balance}(
                address(this),
                amountToLiquify,
                0,
                0,
                deadAddress,
                block.timestamp
            );            
        }
        uint256 amountToSwap = balanceOf(address(this));
        swapTokensForEth(amountToSwap);
        uint256 ethBalance = address(this).balance;
        (retVal,) = address(projectWalletAddress).call{value: ethBalance}("");   
    }    

    function getDay() internal view returns(uint256){
        return block.timestamp.div(1 days);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "Trading already Opened!");
        tradingOpen = true;
        launchTime = block.timestamp;
    }

    function isBot(address account) public view returns (bool) {
        return isBlacklist[account];
    }
    //manual antibot, play fair!
    function _blacklistBot(address account) external onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We cannot blacklist Uniswap');
        require(!isBlacklist[account], "Account is already blacklisted");
        isBlacklist[account] = true;        
    }

    function _amnestyBot(address account) external onlyOwner() {
        require(isBlacklist[account], "Account is not blacklisted");
        isBlacklist[account] = false;        
    }
}