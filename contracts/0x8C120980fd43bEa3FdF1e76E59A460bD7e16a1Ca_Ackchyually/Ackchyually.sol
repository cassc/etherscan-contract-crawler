/**
 *Submitted for verification at Etherscan.io on 2023-05-12
*/

/**
Ackchyually.. I know it all baby.        
Twitter: https://twitter.com/Ackchyuallycoin     
Telegram: https://t.me/+rFw9YvF2Z-80ODQ5 

                                                                                                   
                                           .^~7????77!~^:                                           
                                       .~?JYYY5PBB#&GYJ5GBGY!^.                                     
                                    .~??7J?JPG#&#PPYJY5P55JJY5P?!:                                  
                                  :7?!: ^JPG5GY~.!PGBGGBBP?JY55YP5J?^                               
                                ~J?^  .YJ7^. .^JPP5GPGG5J777?JY5PPPGGP?^                            
                              ^J?.    ~~     [email protected]#?~YP!:..^!J5555YJJJJJ5P5?~                          
                             7Y:           :Y5!.~Y5: ^PG55JJ?YP55555555J!5P~                        
                            ?J             J~ :Y7.   7GJJPYYYYJ!~~~~~~~~^^^?J.                      
                          :P#~                ..  :7J7^ 7P!:                !5.                     
                          [email protected]@@5                   ^~.   .                    ~5.                    
                          [email protected]@@@B7^^                                           ?Y                    
                         .#@@@@@@@@G~.                                        .G:                   
                         ^&@@@@@@@@@@#GY!                                      5!                   
                        Y&@@@&GG#&@@@@@@@5^                                    5~                   
                       :[email protected]@@@5.^[email protected]@@@@@@&:                                   5!                   
                      :#@@@@@!. :! [email protected]@@@@@@~         .~!~7!~!~         JY55Y55^G!                   
                    :[email protected]@@@@@!J5J7 [email protected]@@@@B????!^:.   [email protected]##PG5^^^^^^^~~PG55PPBJ~                    
                 .:?&@@@@@@@@YJY~  [email protected]@@@G:   :~!???7!^?GYJYJJ5G7~~~~~~5P~^!!^?J                     
:^~~~~~~!!7777?5?7Y&&&@@@@@@P~7?: .#@@@#.         .:~P5..:^:  !P~7777JB:::. .:YJ                    
??77777!!!~~~~^P? .:::~JYPP^.     [email protected]@@@J             !P7!: .:^~B~..  .5J:.:~~~J5                    
^^^^^^^^^^^^^^^!G.                ^Y55!               :7??7??JY! :~~~~^7?7???G!.                    
^^^^^^^^^^^^^^^^YJ                                        ....  7P~~~~75^    P~                     
^^^^^^^^^^^^^^^^~B^                                             ?Y^! .77!    !P.                    
^^^^^^^^^^^^^^^^^JP                                              :..  :       75                    
^^^^^^^^^^^^^^^^^^5J                                         .^7?777???77^.    P!                   
^^^^^^^^^^^^^^^^^^^P?                                       [email protected]&:   J7 [email protected]#Y.  !5                   
^^^^^^^^^^^^^^^^^^^~5J                                      5Y7#~   P? .?#5#~  ^G                   
^^^^^^^^^^^^^^^^^^^^^Y5:                                    :G~~??7?5J??7:.B^  ^G                   
^^^^^^^^^^^^^^^^^^^^^^7P~                                    :5?^..     .^5J   75                   
^^^^^^^^^^^^^^^^^^^^^^^~5J.                                    ~7????77??7^   ?5.                   
^^^^^^^^^^^^^^^^^^^^^^^^^?57                                       .....    ~Y?                     
^^^^^^^^^^^^^^^^^^^^^^^^^^~J5~                                      :.   .!J7.                      
^^^^^^^^^^^^^^^^^^^^^^^^^^^^~JY?~.             ^:.                 :J7:~?YY7:                       
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~7?JJ?!^:.       ~7???7!~~^^^^^~7??JJJ????!^~!JJ!.                    
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~7?JJ??7!~~^:..:^~~!7?JY5PPPY7~^^^^^^^^^^^~?Y7.                  
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~!777??J?????????7!~^^^^^^^^^^^^^^^^^^^?5~                 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!G~                
^^^^^^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!P!               
^^^^^^P!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~P~                                                  

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^ 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Ackchyually is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMax; 
    
    string private constant _name = "ACKCHYUALLY";
    string private constant _symbol = "ACK";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 6900000000 * 10 ** 9;

    uint256 private constant _maxFee = 5; 
    uint256 private _taxFeeOnBuy = 5;
    uint256 private _taxFeeOnSell = 5; 

    address payable private constant _devAddy = payable(0x98CF44571B8deF729730EE8659B51281A1d88297);
    address payable private constant _ackTeam = payable(0xB3dD9aF4CF916a93e9ba8c17DF08AC15f4ADe41d);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private inSwap = false;
    uint256 public _maxTxAmount = 6900000000 * 10 ** 9;
    uint256 public _maxWalletSize = 6900000000 * 10 ** 9;
    uint256 public _swapTokensAtAmount = 10000000 * 10 ** 9;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
//Prepare for liftoff
    constructor() {
        _balances[_msgSender()] = _totalSupply;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router
                        .factory())
                        .createPair(address(this),uniswapV2Router.WETH());

        _isExcludedFromMax[owner()] = true;
        _isExcludedFromMax[address(this)] = true;
        _isExcludedFromMax[_devAddy] = true;
        _isExcludedFromMax[_ackTeam] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddy] = true;
        _isExcludedFromFee[_ackTeam] = true;
        

        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
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
        require(amount != 0, "Transfer amount must be greater than zero");


        if (!_isExcludedFromMax[from] && !_isExcludedFromMax[to]) {
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount <= _maxWalletSize,"TOKEN: Balance exceeds wallet size!");
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool canSwap = contractTokenBalance >= _swapTokensAtAmount && from != owner() && to != owner();

        if (
            canSwap &&
            !inSwap &&
            from != uniswapV2Pair &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            swapTokensForEth(contractTokenBalance);

            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance != 0) {
                _ackTeam.transfer(address(this).balance);
            }
        }

        //Transfer Tokens
        uint256 _taxFee = _getTaxFee(from, to);

        _tokenTransfer(from, to, amount, _taxFee);
    }

    function _getTaxFee(
        address _from, 
        address _to
    ) internal view returns(uint256) {
        uint256 _taxFee;

        if(_from != uniswapV2Pair && _to != uniswapV2Pair){
            _taxFee = 0;
        } else if(_from == uniswapV2Pair && _to != uniswapV2Pair) {
            _taxFee = _taxFeeOnBuy;
        } else if(_to == uniswapV2Pair && _from != uniswapV2Pair) {
            _taxFee = _taxFeeOnSell;
        }


        if(_isExcludedFromFee[_from] || _isExcludedFromFee[_to]) 
        {
            _taxFee = 0;
        }

        return _taxFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tax
    ) private {
        uint256 tTeam = (amount * tax) / 100;
        uint256 tTransferAmount = amount - tTeam;
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + tTransferAmount;
        if (tTeam != 0) {
            _balances[address(this)] = _balances[address(this)] + tTeam;
            emit Transfer(sender, address(this), tTeam);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }



    //Set minimum tokens required to swap.
    event UpdateMinSwapTokenThreshold(uint256 swapTokensAtAmount);
    function setMinSwapTokensThreshold(
        uint256 swapTokensAtAmount
    ) external onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
        emit UpdateMinSwapTokenThreshold(swapTokensAtAmount);
    }

    // onlyOwner external
    event UpdateTaxFee(uint256 taxFeeOnBuy, uint256 taxFeeOnSell);
    function setFee(
        uint256 taxFeeOnBuy,
        uint256 taxFeeOnSell
    ) external onlyOwner {
        require(taxFeeOnBuy <= _maxFee, "Fee is too high");
        require(taxFeeOnSell <= _maxFee, "Fee is too high");
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
        emit UpdateTaxFee(taxFeeOnBuy, taxFeeOnSell);
    }

    event UpdatedMaxTxAmount(uint256 _amount);
    function setMaxTxAmount(
        uint256 _amount
    ) external onlyOwner {
        _maxTxAmount = _amount;
        emit UpdatedMaxTxAmount(_amount);
    }

    event ExcludedFromMax(address indexed account, bool _exclude);
    function excludeMultipleAccountsFromMax(
        address[] memory accounts,
        bool _exclude
    ) external onlyOwner {
        for(uint256 i; i < accounts.length; i++) {
            _isExcludedFromMax[accounts[i]] = _exclude;
            emit ExcludedFromMax(accounts[i], _exclude);
        }
    }

    event UpdatedMaxWalletSize(uint256 _maxSizeAmount);
    function setMaxWalletSize(
        uint256 _maxSizeAmount
    ) external onlyOwner {
        _maxWalletSize = _maxSizeAmount;
        emit UpdatedMaxWalletSize(_maxSizeAmount);
    }

    event ExcludedFromFee(address indexed account, bool _exclude);
    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
            emit ExcludedFromFee(accounts[i], excluded);
        }
    }
    
    receive() external payable {}
}