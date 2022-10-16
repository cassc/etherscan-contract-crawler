// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/IUniswapV2Router02.sol';
import '../interfaces/IUniswapV2Factory.sol';
import '../interfaces/IUniswapV2Pair.sol';

contract BabyRichCoin is Context, IERC20, Ownable, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    event Claim(address user, IERC721 token, uint tokenId, uint amount);

    uint constant public PERCENT_BASE = 100;
    address constant public HOLE_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint constant public HOLE_PERCENT = 40;
    address immutable public BWC_CLAIM_HOLDER = address(uint(keccak256(abi.encodePacked(address(this), "BWC_CLAIM_HOLDER"))));
    IERC721 constant BWC_NFT = IERC721(0xb7F7c7D91Ede27b019e265F8ba04c63333991e02);
    uint constant public BWC_CLAIM_PERCENT = 30;
    uint immutable public BWC_VALUE;
    address immutable public BBF_CLAIM_HOLDER = address(uint(keccak256(abi.encodePacked(address(this), "BBF_CLAIM_HOLDER"))));
    IERC721 constant BBF_NFT = IERC721(0x8c27103eeE75eed8801B808ff23eB02c9876Fa7C);
    uint constant public BBF_CLAIM_PERCENT = 15;
    uint immutable public BBF_VALUE;
    uint constant public LIQUIDITY_PERCENT = 10;
    uint constant public FUND_PERCENT = 5;

    mapping(IERC721 => mapping(uint => uint)) public claimed;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    
    uint256 public _taxFee;
    uint256 private _previousTaxFee;
    
    uint256 public _liquidityFee;
    uint256 private _previousLiquidityFee;


    IUniswapV2Router02 public immutable pancakeRouter;
    IUniswapV2Router02 public immutable babyRouter;
    address public immutable pancakePair;
    address public immutable babyPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount;
    uint256 public numTokensSellToAddToLiquidity;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        IUniswapV2Router02 router,
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (string memory _NAME, string memory _SYMBOL, uint256 _DECIMALS, uint256 _supply, uint256 _txFee, uint256 _lpFee, uint256 _MAXAMOUNT, uint256 _SELLMAXAMOUNT, IUniswapV2Router02 _pancakeRouter, IUniswapV2Router02 _babyRouter) {
        _name = _NAME;
        _symbol = _SYMBOL;
        _decimals = _DECIMALS;
        _tTotal = _supply * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        _taxFee = _txFee;
        _liquidityFee = _lpFee;
        _previousTaxFee = _txFee;
        _previousLiquidityFee = _lpFee;
        _maxTxAmount = _MAXAMOUNT * 10 ** _decimals;
        numTokensSellToAddToLiquidity = _SELLMAXAMOUNT * 10 ** _decimals;

        pancakeRouter = _pancakeRouter;
        pancakePair = IUniswapV2Factory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());

        babyRouter = _babyRouter;
        babyPair = IUniswapV2Factory(_babyRouter.factory()).createPair(address(this), _babyRouter.WETH());

        BWC_VALUE = 30000000000 * 10 ** _DECIMALS;
        BBF_VALUE = 15000000000 * 10 ** _DECIMALS;

        
        _rOwned[owner()] = _rTotal;
         
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    
        emit Transfer(address(0), owner(), _tTotal);

        //_transfer(owner(), 
    }

    function dispatch(address _liquidityReceiver, address _fundReceiver) external initializer {
        _transfer(_msgSender(), HOLE_ADDRESS, _tTotal.mul(HOLE_PERCENT).div(PERCENT_BASE));
        _transfer(_msgSender(), BWC_CLAIM_HOLDER, _tTotal.mul(BWC_CLAIM_PERCENT).div(PERCENT_BASE));
        _transfer(_msgSender(), BBF_CLAIM_HOLDER, _tTotal.mul(BBF_CLAIM_PERCENT).div(PERCENT_BASE));
        _transfer(_msgSender(), _liquidityReceiver, _tTotal.mul(LIQUIDITY_PERCENT).div(PERCENT_BASE));
        _transfer(_msgSender(), _fundReceiver, _tTotal.mul(FUND_PERCENT).div(PERCENT_BASE));
        _isExcludedFromFee[_msgSender()] = false;
        _isExcludedFromFee[BWC_CLAIM_HOLDER] = true;
        _isExcludedFromFee[BBF_CLAIM_HOLDER] = true;
        excludeFromReward(BWC_CLAIM_HOLDER);
        excludeFromReward(BBF_CLAIM_HOLDER);
    }

    function claim(IERC721 _token, uint _tokenId) external nonReentrant {
        require(_token == BWC_NFT || _token == BBF_NFT, "illegal token");
        require(_token.ownerOf(_tokenId) == _msgSender(), "illegal owner");
        uint value = 0;
        if (_token == BWC_NFT) {
            value = BWC_VALUE;
        } else if (_token == BBF_NFT) {
            value = BBF_VALUE;
        }
        uint remain = value.sub(claimed[_token][_tokenId]);
        require(remain > 0, "already claimed");
        if (_token == BWC_NFT) {
            _transfer(BWC_CLAIM_HOLDER, _msgSender(), remain);
        } else if(_token == BBF_NFT) {
            _transfer(BBF_CLAIM_HOLDER, _msgSender(), remain);
        }
        claimed[_token][_tokenId] = claimed[_token][_tokenId].add(remain);
        emit Claim(_msgSender(), _token, _tokenId, remain);
    }

    struct NftItem {
        IERC721 token;
        uint tokenId;
    }

    function available(address _user, NftItem[] memory items) external view returns (uint totalRemain) {
        for (uint i = 0; i < items.length; i ++) {
            if (items[i].token != BWC_NFT && items[i].token != BBF_NFT) {
                continue;
            }
            if (items[i].token.ownerOf(items[i].tokenId) != _user) {
                continue;
            }
            uint value = 0;
            if (items[i].token == BWC_NFT) {
                value = BWC_VALUE;
            } else if (items[i].token == BBF_NFT) {
                value = BBF_VALUE;
            }
            uint remain = value.sub(claimed[items[i].token][items[i].tokenId]);
            totalRemain = totalRemain.add(remain);
        }
        return totalRemain;
    }

    function claimAll(NftItem[] memory items) external nonReentrant {
        require(items.length > 0, "illegal item");
        uint totalBwcRemain = 0;
        uint totalBbfRemain = 0;
        for (uint i = 0; i < items.length; i ++) {
            require(items[i].token == BWC_NFT || items[i].token == BBF_NFT, "illegal token");
            require(items[i].token.ownerOf(items[i].tokenId) == _msgSender(), "illegal owner");
            uint value = 0;
            if (items[i].token == BWC_NFT) {
                value = BWC_VALUE;
            } else if(items[i].token == BBF_NFT) {
                value = BBF_VALUE;
            }
            uint remain = value.sub(claimed[items[i].token][items[i].tokenId]);
            if (remain > 0) {
                if (items[i].token == BWC_NFT) {
                    totalBwcRemain = totalBwcRemain.add(remain);
                } else if(items[i].token == BBF_NFT) {
                    totalBbfRemain = totalBbfRemain.add(remain);
                }
                claimed[items[i].token][items[i].tokenId] = claimed[items[i].token][items[i].tokenId].add(remain);
                emit Claim(_msgSender(), items[i].token, items[i].tokenId, remain);
            }
        }
        if (totalBwcRemain > 0) {
            _transfer(BWC_CLAIM_HOLDER, _msgSender(), totalBwcRemain);
        }
        if (totalBbfRemain > 0) {
            _transfer(BBF_CLAIM_HOLDER, _msgSender(), totalBbfRemain);
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    
    function setNumTokensSellToAddToLiquidity(uint256 swapNumber) public onlyOwner {
        numTokensSellToAddToLiquidity = swapNumber * 10 ** _decimals;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
        _maxTxAmount = maxTxPercent  * 10 ** _decimals;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
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
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    
    function claimTokens() public onlyOwner {
            payable(owner()).transfer(address(this).balance);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
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
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            from != babyPair &&
            balanceOf(pancakePair) > 0 && 
            balanceOf(babyPair) > 0 &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            uint pancakeAmount = contractTokenBalance.mul(5).div(7);
            uint babyAmount = contractTokenBalance.mul(2).div(7);

            //add liquidity
            //swapAndLiquify(contractTokenBalance);
            swapAndLiquify(pancakeRouter, pancakePair, pancakeAmount);
            swapAndLiquify(babyRouter, babyPair, babyAmount);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(IUniswapV2Router02 router, address pair, uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(router, pair, half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(router, pair, otherHalf, newBalance);
        
        emit SwapAndLiquify(router, half, newBalance, otherHalf);
    }

    function swapTokensForEth(IUniswapV2Router02 router, address pair, uint256 tokenAmount) private {
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
    }

    function addLiquidity(IUniswapV2Router02 router, address pair, uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}