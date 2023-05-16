/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract AMSToken is Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _feeWhiteList;
    mapping(address => bool) private _blackList;

    address public fundAddress;
    address public flowAddress;

   
    string private _name = "AMS";
    string private _symbol = "AMS";
    uint8 private _decimals = 18;

    uint256 public buyDestroyFee = 200;
    uint256 public sellDestroyFee = 200;
    uint256 public DestroyFeeBase = 10000;

    uint256 public buyFlowFee = 300;
    uint256 public sellFlowFee = 300;
    uint256 public FlowFeeBase = 10000;



    address public mainPair;
    uint256 private _tTotal;
    ISwapRouter public _swapRouter;

    address private usdt;
    address private dead;

    bool public inSwap;
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
       
        _swapRouter = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955); 
        dead = address(0x000000000000000000000000000000000000dEaD);
     
        fundAddress = address(0x9060AA22eE5c7AB6410067C506D9e946d064b6AE);
        flowAddress = address(0x3E0930C2d8F74a04eF94904BAB50572CA16689Ce);
       
   
        _tTotal = 21000000 * 10**_decimals;

        mainPair = ISwapFactory(_swapRouter.factory()).createPair(
            address(this),
            usdt
        );
        _balances[fundAddress] = _tTotal;
        emit Transfer(address(0), fundAddress, _tTotal);

        _feeWhiteList[fundAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;

        inSwap = false;

       
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }
        _transfer(sender, recipient, amount);
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(!_blackList[from], "Transfer from the blackList address");

        bool takeFee = false;
        if (from == mainPair || to == mainPair) {
            takeFee = true;
            if (_feeWhiteList[from] || _feeWhiteList[to]) {
                takeFee = false;
            }
        } else {
           
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 balanceAcmount = balanceOf(sender);
        require(balanceAcmount >= tAmount, "Insufficient wallet balance");
        unchecked {
            _balances[sender] = _balances[sender] - tAmount;
        }

        uint256 feeAmount;
        if (takeFee) {
            if (sender == mainPair && !inSwap) {
                feeAmount = (tAmount * (buyFlowFee+buyDestroyFee)) /DestroyFeeBase ;
                unchecked {
                    _balances[dead] =
                        _balances[dead] +
                        (tAmount * buyDestroyFee) /
                        DestroyFeeBase;
                }
                emit Transfer(
                    sender,
                    dead,
                    (tAmount * buyDestroyFee) /
                        DestroyFeeBase
                );

                 unchecked {
                    _balances[flowAddress] =
                        _balances[flowAddress] +
                        (tAmount * buyFlowFee) /
                        FlowFeeBase;
                }
                emit Transfer(
                    sender,
                    flowAddress,
                   (tAmount * buyFlowFee) /
                        FlowFeeBase
                );
            }

            if (recipient == mainPair && !inSwap) {
               feeAmount = (tAmount * (sellDestroyFee+sellFlowFee)) /DestroyFeeBase ;
                unchecked {
                    _balances[dead] =
                        _balances[dead] +
                        (tAmount * sellDestroyFee) /
                        DestroyFeeBase;
                }
                emit Transfer(
                    sender,
                    dead,
                    (tAmount * sellDestroyFee) /
                        DestroyFeeBase
                );

                unchecked {
                    _balances[flowAddress] =
                        _balances[flowAddress] +
                        (tAmount * sellFlowFee) /
                        FlowFeeBase;
                }
                emit Transfer(
                    sender,
                    flowAddress,
                   (tAmount * sellFlowFee) /
                        FlowFeeBase
                );
            }

            
        }

        uint256 rTAmount = tAmount - feeAmount;
        _balances[recipient] = _balances[recipient] + rTAmount;
        emit Transfer(sender, recipient, rTAmount);
    }

    
    
   

    

    
    receive() external payable {}

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function isFeeWhiteList(address addr) external view returns (bool) {
        return _feeWhiteList[addr];
    }

    function addBlackList(address addr) external onlyOwner {
        _blackList[addr] = true;
    }

    function removeBlackList(address addr) external onlyOwner {
        _blackList[addr] = false;
    }

    function isBlackList(address addr) external view returns (bool) {
        return _blackList[addr];
    }
function setFlowAddress(address _flowAddress) external onlyOwner {
        flowAddress = _flowAddress;
    }

    

    function claimBalance() public onlyOwner {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(fundAddress, amount);
    }



    
    function setBuyFee(uint256 _buyDestroyFee, uint256 _buyFlowFee,uint256 _DestroyFeeBase, uint256 _FlowFeeBase) public onlyOwner {
        require(_buyDestroyFee != 0, "value is zero");
        require(_buyFlowFee != 0, "value is zero");
        require(_DestroyFeeBase != 0, "value is zero");
        require(_FlowFeeBase != 0, "value is zero");
        require(_buyDestroyFee / _DestroyFeeBase < 1, "error value");
        require(_buyFlowFee / _FlowFeeBase < 1, "error value");
        buyDestroyFee = _buyDestroyFee;
        buyFlowFee = _buyFlowFee;
        DestroyFeeBase = _DestroyFeeBase;
        FlowFeeBase = _FlowFeeBase;
    }
    


     function setSellFee(uint256 _sellDestroyFee, uint256 _sellFlowFee,uint256 _DestroyFeeBase, uint256 _FlowFeeBase) public onlyOwner {
        require(_sellDestroyFee != 0, "value is zero");
        require(_sellFlowFee != 0, "value is zero");
        require(_DestroyFeeBase != 0, "value is zero");
        require(_FlowFeeBase != 0, "value is zero");
        require(_sellDestroyFee / _DestroyFeeBase < 1, "error value");
        require(_sellFlowFee / _FlowFeeBase < 1, "error value");
        sellDestroyFee = _sellDestroyFee;
        sellFlowFee = _sellFlowFee;
        DestroyFeeBase = _DestroyFeeBase;
        FlowFeeBase = _FlowFeeBase;
    }








   
    
}