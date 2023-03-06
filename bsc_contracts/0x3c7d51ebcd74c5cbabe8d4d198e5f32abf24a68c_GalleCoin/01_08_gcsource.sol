/**
 *  SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

 
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDexRouter {
     function factory() external pure returns (address);
     function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
     
} 

interface IDexPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract FeeDelegate {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

contract GalleCoin is IERC20,Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _initSupply;
    string private _name;
    string private _symbol;
    
    uint256 public minToSell; 
    uint256 public minToDividen; 

    uint256 public tokenToDividen; 

    mapping(uint256=>address) public tokenDividenQueue; 
    uint256 public tokenDividenQueueMaxIndex; 
    uint256 public tokenDividenQueueOffset; 
    uint256[] private tokenDividenQueueSlot; 
    uint256 private tokenDividenQueueSlotIndex; 

    mapping(uint256=>address) public lpDividenQueue;
    uint256 public lpDividenQueueMaxIndex;
    uint256 public lpDividenQueueOffset;
    uint256[] private lpDividenQueueSlot;
    uint256 private lpDividenQueueSlotIndex;
    mapping(address=>uint256) public tokenDividenQueuedIndex;
    mapping(address=>uint256) public lpDividenQueuedIndex;

    uint256 public sellTaxFee; 
    uint256 public buyTaxFee;
    address public taxAddress0;
    address public taxAddress1;
    address public feeDelegate;

    uint256 public marketPart;
    uint256 public tokenPart;
    uint256 public lpPart;
    
    address public tokenPair;
    address public swapRouter;
    address public usdt;

    event SwapTokens(
        uint256 amountIn,
        address[] path
    );
    
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromDividen; 
    mapping(address => bool) public _blackLists;
    mapping(address => bool) public _buyWhiteLists;
    bool public buyStatus; 

    uint256 public lpDividenMaxCount;  
    uint256 public tokenDividenMaxCount; 

    uint256 public excludeLpShare;      
    uint256 public excludeTokenShare;   


    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        _name = "GalleCoin";
        _symbol = "GC";
        sellTaxFee = 500; 
        buyTaxFee = 500;
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
        address _usdt = 0x55d398326f99059fF775485246999027B3197955;  
        feeDelegate = address(new FeeDelegate(_usdt)); 
        
        _totalSupply = 100000000*10**18;        
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromDividen[_msgSender()] = true;
        _isExcludedFromDividen[address(this)] = true;
        _buyWhiteLists[_msgSender()] = true;
        _buyWhiteLists[address(this)] = true;

        marketPart = 100; 
        tokenPart = 0; 
        lpPart = 9900; 
        minToSell = 5000*10**18; 
        minToDividen = 100*10**18; 
        tokenToDividen = 5000*10**18; 
        lpDividenMaxCount = 10;  
        tokenDividenMaxCount = 10;  

        taxAddress0 = _msgSender();
        taxAddress1 = _msgSender();
        setDex(_router,_usdt);

        
        _approve(_msgSender(), _router, uint(~uint256(0)));
    }
    
       
    function setDex(address _router,address _usdt) internal{
        IDexRouter dexRouter = IDexRouter(_router);
        address tokenA = address(this);
        address tokenB = _usdt;
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if(IDexFactory(dexRouter.factory()).getPair(token0,token1)==address(0)){
            tokenPair = IDexFactory(dexRouter.factory())
            .createPair(tokenA, tokenB);
        }
        else{
            tokenPair = IDexFactory(dexRouter.factory()).getPair(token0,token1);
        }
        _isExcludedFromDividen[tokenPair] = true;
        _buyWhiteLists[tokenPair] = true;
        swapRouter = _router;
        usdt = _usdt;
    }   
    
    
    
    function setExcludeFromFee(address[] memory accounts,bool status) external onlyOwner{
        for(uint256 i=0;i<accounts.length;i++)
            _isExcludedFromFee[accounts[i]] = status;
    }

    
    function setExcludeFromDividen(address[] memory accounts,bool status) external onlyOwner{
        for(uint256 i=0;i<accounts.length;i++)
            _isExcludedFromDividen[accounts[i]] = status;
    }


    
    function setBlackLists(address[] memory accounts,bool status) external onlyOwner{
        for(uint256 i=0;i<accounts.length;i++)
            _blackLists[accounts[i]] = status;
    }

   
    function setBuyWhiteLists(address[] memory accounts,bool status) external onlyOwner{
        for(uint256 i=0;i<accounts.length;i++)
            _buyWhiteLists[accounts[i]] = status;
    }
    
    function setTaxAddress(address _taxAddress0,address _taxAddress1) external onlyOwner{
        taxAddress0 = _taxAddress0;
        taxAddress1 = _taxAddress1;
    }

    
    function setMinToSell(uint256 _min) external onlyOwner{
        minToSell = _min;
    }

    
    function setMinToDividen(uint256 _min) external onlyOwner{
        minToDividen = _min;
    }
    
   
    function setTokenToDividen(uint256 _minHold) external onlyOwner{
        tokenToDividen = _minHold;
    }

    function setTax(uint256 _sellFee,uint256 _buyFee) external onlyOwner{
        require(_sellFee<=10000,"invalid sellFee");
        require(_buyFee<=10000,"infalid buyFee");
        sellTaxFee = _sellFee;
        buyTaxFee = _buyFee;
    }

    function setDividen(uint256 _marketPart,uint256 _tokenPart,uint256 _lpPart) external onlyOwner{
        require(_marketPart+_tokenPart+_lpPart==10000,"invalid percent");
        marketPart = _marketPart;
        tokenPart = _tokenPart;
        lpPart = _lpPart;
    }

    function setBuyStatus(bool status) external onlyOwner{
        buyStatus = status;
    }

    function setMaxCount(uint256 _lpDividenMaxCount,uint256 _tokenDividenMaxCount) external onlyOwner{
        lpDividenMaxCount = _lpDividenMaxCount;
        tokenDividenMaxCount = _tokenDividenMaxCount;
    }

    function setExcludedFromLpDividenShare(uint256 _excludeLpShare) external onlyOwner{
        excludeLpShare = _excludeLpShare;
    }

    function setExcludedFromTokenDividenShare(uint256 _excludeTokenShare) external onlyOwner{
        excludeTokenShare = _excludeTokenShare;
    }    
  
    function withdrawExternalToken(address _tokenAddress) external onlyOwner{        
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));
        if(amount > 0){
            IERC20(_tokenAddress).safeTransfer(msg.sender,amount);
        }
    }

    function sendTaxFee(uint256 taxAmount) internal{
        uint256 fee0 = taxAmount.mul(5000).div(10000);
        IERC20(usdt).safeTransfer(taxAddress0,fee0);
        uint256 fee1 = taxAmount.sub(fee0);
        IERC20(usdt).safeTransfer(taxAddress1,fee1);
    }

    function _isAddLiquidity() internal view returns (bool isAdd){
        (uint r0,uint256 r1,) = IDexPair(tokenPair).getReserves();
        uint256 rUsdt;
        if (usdt < address(this)) {
            rUsdt = r0;
        } else {
            rUsdt = r1;
        }

        uint balUsdt = IERC20(usdt).balanceOf(tokenPair);
        isAdd = balUsdt > rUsdt;        
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        (uint r0,uint256 r1,) = IDexPair(tokenPair).getReserves();
        uint256 rUsdt;
        if (usdt < address(this)) {
            rUsdt = r0;
        } else {
            rUsdt = r1;
        }

        uint balUsdt = IERC20(usdt).balanceOf(tokenPair);
        isRemove = rUsdt >= balUsdt;
    }

    function swapTokens(uint256 tokenAmount) private returns(uint256 usdtAmount){
        IDexRouter _router = IDexRouter(swapRouter);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;

        _approve(address(this), swapRouter, tokenAmount);

        uint256 usdtBefore = IERC20(usdt).balanceOf(feeDelegate);
        _router.swapExactTokensForTokens(
            tokenAmount,
            0, 
            path,
            feeDelegate, 
            block.timestamp
        );        
        uint256 usdtAfter = IERC20(usdt).balanceOf(feeDelegate);
        usdtAmount = usdtAfter.sub(usdtBefore);
        IERC20(usdt).safeTransferFrom(feeDelegate,address(this),usdtAmount);
        emit SwapTokens(tokenAmount, path);
    }


    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_blackLists[sender]&&!_blackLists[recipient],"black list");
                
        bool doProcessDividen = true;  
        bool takeSellFee = false;
        if(recipient==tokenPair){ //sell or add
            if(!_isAddLiquidity()){
                takeSellFee = true;
            }  
            else{                
                doProcessDividen = false; //add liquid not div
                if(!_isExcludedFromDividen[sender]&&lpDividenQueuedIndex[sender]==0){ 
                    addToQueue(sender,true);
                }
            }          
        }
        if (_isExcludedFromFee[sender]) {
            takeSellFee = false;
        }

        bool takeBuyFee = false;
        if(sender==tokenPair){ // buy or remove
            if(!_isRemoveLiquidity()){
                if(!buyStatus&&!_buyWhiteLists[recipient]){
                    revert("buy disable");
                }
                takeBuyFee = true;
            }           
            doProcessDividen = false; //remove liquid or buy not div                    
        }
        if (_isExcludedFromFee[recipient]) {
            takeBuyFee = false;
        }
                
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance.sub(amount);
        }   
        
        if(takeSellFee&&sellTaxFee>0){
            uint256  _sellTaxFee = amount.mul(sellTaxFee).div(10000);
            _balances[address(this)] =_balances[address(this)].add(_sellTaxFee);                
            emit Transfer(sender, address(this), _sellTaxFee);
            amount = amount.sub(_sellTaxFee);
        }

        if(takeBuyFee&&buyTaxFee>0){
            uint256  _buyTaxFee = amount.mul(buyTaxFee).div(10000);
            _balances[address(this)] =_balances[address(this)].add(_buyTaxFee);
            emit Transfer(sender, address(this), _buyTaxFee);
            amount = amount.sub(_buyTaxFee);
        }

        if(doProcessDividen){
            if(_balances[address(this)]>=minToSell){
               uint256 usdtIncome = swapTokens(_balances[address(this)]);
               sendTaxFee(usdtIncome.mul(marketPart).div(10000)); //send maketing fee       
            }
            processDividen();         
        }
          
        
        _balances[recipient] = _balances[recipient].add(amount);    
        if(!_isExcludedFromDividen[recipient]&&_balances[recipient]>=tokenToDividen&&tokenDividenQueuedIndex[recipient]==0){ 
            addToQueue(recipient,false);
        }
        emit Transfer(sender, recipient, amount);
    }

    function addToQueue(address user,bool isLp) internal{
        if(isLp){
                uint256 _index = 0;
                if(lpDividenQueueSlotIndex<lpDividenQueueSlot.length){
                    _index = lpDividenQueueSlot[lpDividenQueueSlotIndex];
                    lpDividenQueueSlotIndex++;                    
                }
                else{
                    lpDividenQueueMaxIndex++;
                    _index = lpDividenQueueMaxIndex;
                }
                lpDividenQueue[_index] = user;
                lpDividenQueuedIndex[user] = _index;
        }
        else{
                uint256 _index = 0;
                if(tokenDividenQueueSlotIndex<tokenDividenQueueSlot.length){
                    _index = tokenDividenQueueSlot[tokenDividenQueueSlotIndex];
                    tokenDividenQueueSlotIndex++;                    
                }
                else{
                    tokenDividenQueueMaxIndex++;
                    _index = tokenDividenQueueMaxIndex;
                }
                tokenDividenQueue[_index] = user;
                tokenDividenQueuedIndex[user] = _index;              
        }        
    }

    function removeFromQueue(address user,bool isLp) internal{     
        if(isLp){
                uint256 _index = lpDividenQueuedIndex[user];
                lpDividenQueuedIndex[user] = 0;
                lpDividenQueue[_index] = address(0);
                lpDividenQueueSlot.push(_index);
        }
        else{
                uint256 _index = tokenDividenQueuedIndex[user];
                tokenDividenQueuedIndex[user] = 0;
                tokenDividenQueue[_index] = address(0);
                tokenDividenQueueSlot.push(_index);            
        }
    }

    function processDividen() internal{
        uint256 usdtBalance = IERC20(usdt).balanceOf(address(this));
        if(usdtBalance>=minToDividen){
            //process dividen
            //LP dividen        
            if(lpPart>0){
                if(lpDividenQueueOffset==lpDividenQueueMaxIndex){
                    lpDividenQueueOffset = 0;
                }
                uint256 lpDivideCounter = 0;
                uint256 totalLP = IERC20(tokenPair).totalSupply();
                totalLP = totalLP.sub(excludeLpShare);
                while(lpDivideCounter<lpDividenMaxCount&&lpDividenQueueOffset<lpDividenQueueMaxIndex){
                    lpDividenQueueOffset++;
                    lpDivideCounter++;
                    address user = lpDividenQueue[lpDividenQueueOffset];
                    uint256 userLp = IERC20(tokenPair).balanceOf(user);
                    if(!_isExcludedFromDividen[user]&&userLp>0){
                        uint256 lpBonus = usdtBalance.mul(lpPart).div(10000).mul(userLp).div(totalLP);
                        IERC20(usdt).safeTransfer(user,lpBonus);
                    }
                    else{
                        removeFromQueue(user,true);
                    }
                }    
            }    
            

            //token dividen    
            if(tokenPart>0){
               if(tokenDividenQueueOffset==tokenDividenQueueMaxIndex){
                    tokenDividenQueueOffset = 0;
                }
                uint256 tokenDivideCounter = 0;
                uint256 totalToken = _totalSupply.sub(excludeTokenShare).sub(_balances[tokenPair]);
                while(tokenDivideCounter<tokenDividenMaxCount&&tokenDividenQueueOffset<tokenDividenQueueMaxIndex){
                    tokenDividenQueueOffset++;
                    tokenDivideCounter++;
                    address user = tokenDividenQueue[tokenDividenQueueOffset];
                    uint256 userToken = _balances[user];
                    if(!_isExcludedFromDividen[user]&&userToken>=tokenToDividen){
                        uint256 tokenBonus = usdtBalance.mul(tokenPart).div(10000).mul(userToken).div(totalToken);
                        IERC20(usdt).safeTransfer(user,tokenBonus);
                    }
                    else{
                        removeFromQueue(user,false);
                    }
                }     
            } 
        }
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        }

        return true;
    }
    

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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
}