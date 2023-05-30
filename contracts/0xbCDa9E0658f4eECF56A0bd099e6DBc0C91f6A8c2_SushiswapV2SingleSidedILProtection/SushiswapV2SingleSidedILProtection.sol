/**
 *Submitted for verification at Etherscan.io on 2021-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Oracle {
    function getPriceUSD(address reserve) external view returns (uint);
}

interface ISushiswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISushiswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;
}

library SushiswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SushiswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SushiswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISushiswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SushiswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SushiswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }
}

contract SushiswapV2SingleSidedILProtection {
    using SafeERC20 for IERC20;

    /// @notice EIP-20 token name for this token
    string public constant name = "SushiswapV2 IL Protection";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "sil";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 8;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;

    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");
    bytes32 public immutable DOMAINSEPARATOR;

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);
    
    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);

    // Oracle used for price debt data (external to the AMM balance to avoid internal manipulation)
    Oracle public constant LINK = Oracle(0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a);
    ISushiswapV2Factory public constant FACTORY = ISushiswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    address public constant WYFI = address(0x017E71e96f2Ae777C679740d2D8Dc15Ed4231981);
    address public immutable PAIR;
    
    uint public constant FEE = 500;
    
    
    // user => token => borrowed
    mapping (address => mapping(address => uint)) public borrowed;
    // user => token => lp
    mapping (address => mapping(address => uint)) public lp;
    
    address[] private _markets;
    mapping (address => bool) pairs;
    
    event Deposit(address indexed owner, address indexed lp, uint amountIn, uint minted);
    event Withdraw(address indexed owner, address indexed lp, uint burned, uint amountOut);
    
    constructor () {
        DOMAINSEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
        PAIR = FACTORY.createPair(address(this), WYFI);
    }
    
    function markets() external view returns (address[] memory) {
        return _markets;
    }
    
    function _mint(address dst, uint amount) internal {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
    
    function _burn(address dst, uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount from the recipient
        balances[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }
    
    function depositAll(IERC20 token, uint minLiquidity) external {
        _deposit(token, token.balanceOf(msg.sender), minLiquidity);
    }
    
    function deposit(IERC20 token, uint amount, uint minLiquidity) external {
        _deposit(token, amount, minLiquidity);
    }
    
    function _addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired) internal returns (address pair, uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        pair = FACTORY.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = FACTORY.createPair(tokenA, tokenB);
            pairs[pair] = true;
            _markets.push(tokenA);
        } else if (!pairs[pair]) {
            pairs[pair] = true;
            _markets.push(tokenA);
        }
        
        (uint reserveA, uint reserveB) = SushiswapV2Library.getReserves(address(FACTORY), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SushiswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SushiswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    function pairFor(address token) public view returns (address) {
        return FACTORY.getPair(token, address(this));
    }
    
    function underlyingBalanceOf(address owner, address token) external view returns (uint) {
        address _pair = pairFor(token);
        uint _balance = IERC20(token).balanceOf(_pair);
        return _balance * lp[owner][token] / IERC20(_pair).totalSupply();
    }
    
    function getPriceOracle(address token) public view returns (uint) {
        return LINK.getPriceUSD(address(token));
    }
    
    function _deposit(IERC20 token, uint amount, uint minLiquidity) internal {
        uint _price = LINK.getPriceUSD(address(token));
        uint _value = _price * amount / uint(10)**token.decimals();
        require(_value > 0, "!value");
        
        (address _pair, uint amountA, uint amountB) = _addLiquidity(address(token), address(this), amount, _value);
        
        token.safeTransferFrom(msg.sender, _pair, amountA);
        
        _value = _price * amountA / uint(10)**token.decimals();
        require(amountB <= _value, "invalid oracle feed");
        
        _mint(_pair, amountB);
        borrowed[msg.sender][address(token)] += amountB;
        
        uint _liquidity = ISushiswapV2Pair(_pair).mint(address(this));
        require(_liquidity >= minLiquidity, "insufficient output liquidity");
        lp[msg.sender][address(token)] += _liquidity;
        
        emit Deposit(msg.sender, address(token), amountA, amountB);
    }
    
    function withdrawAll(IERC20 token, uint maxSettle) external {
        _withdraw(token, IERC20(address(this)).balanceOf(msg.sender), maxSettle);
    }
    
    function withdraw(IERC20 token, uint amount, uint maxSettle) external {
        _withdraw(token, amount, maxSettle);
    }
    
    function shortFall(IERC20 token, address owner, uint amount) public view returns (uint) {
        uint _lp = lp[owner][address(token)];
        uint _borrowed = borrowed[owner][address(token)];
        
        if (_lp < amount) {
            amount = _lp;
        }
        
        _borrowed = _borrowed * amount / _lp;
        address _pair = FACTORY.getPair(address(token), address(this));
        
        uint _returned = balances[_pair] * amount / IERC20(_pair).totalSupply();
        if (_returned < _borrowed) {
            return _borrowed - _returned;
        } else {
            return 0;
        }
    }
    
    function shortFallInToken(IERC20 token, address owner, uint amount) external view returns (uint) {
        uint _shortfall = shortFall(token, owner, amount);
        if (_shortfall > 0) {
            address _pair = FACTORY.getPair(address(token), address(this));
            (uint reserveA, uint reserveB,) = ISushiswapV2Pair(_pair).getReserves();
            (address token0,) = SushiswapV2Library.sortTokens(address(token), address(this));
            (reserveA, reserveB) = address(token) == token0 ? (reserveA, reserveB) : (reserveB, reserveA);
            return _getAmountIn(reserveA, reserveB, _shortfall);
        } else {
            return 0;
        }
        
    }
    
    function profit(IERC20 token, address owner, uint amount) external view returns (uint) {
        uint _lp = lp[owner][address(token)];
        uint _borrowed = borrowed[owner][address(token)];
        
        if (_lp < amount) {
            amount = _lp;
        }
        
        _borrowed = _borrowed * amount / _lp;
        address _pair = FACTORY.getPair(address(token), address(this));
        
        uint _returned = balances[_pair] * amount / IERC20(_pair).totalSupply();
        if (_returned > _borrowed) {
            return _returned - _borrowed;
        } else {
            return 0;
        }
    }
    
    function _getAmountIn(uint reserveA, uint reserveB, uint amountOut) internal pure returns (uint) {
        uint numerator = reserveA * amountOut * 1000;
        uint denominator = (reserveB - amountOut) * 997;
        return (numerator / denominator) + 1;
    }
    
    function _settle(IERC20 token, address token0, address pair, uint amountA, uint amountB, uint debt, uint maxSettle) internal returns (uint, uint) {
        if (balances[msg.sender]+amountB < debt) {
            uint _shortfall = debt - (balances[msg.sender]+amountB);
            
            (uint reserveA, uint reserveB,) = ISushiswapV2Pair(pair).getReserves();
            (reserveA, reserveB) = address(token) == token0 ? (reserveA, reserveB) : (reserveB, reserveA);
            
            uint amountIn = _getAmountIn(reserveA, reserveB, _shortfall);
            
            require(amountIn <= amountA && amountIn <= maxSettle, 'ADDITIONAL_SETTLEMENT_REQUIRED');
            token.safeTransfer(pair, amountIn);
            (uint amount0Out, uint amount1Out) = address(token) == token0 ? (uint(0), _shortfall) : (_shortfall, uint(0));
            ISushiswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
            amountA -= amountIn;
            amountB += _shortfall;
        }
        return (amountA, amountB);
    }
    
    function _unwrap(address pair, IERC20 token, uint burned, uint debt, uint maxSettle) internal returns (uint, uint) {
        IERC20(pair).safeTransfer(pair, burned); // send liquidity to pair
        (uint amountA, uint amountB) = ISushiswapV2Pair(pair).burn(address(this));
        (address token0,) = SushiswapV2Library.sortTokens(address(token), address(this));
        (amountA, amountB) = address(token) == token0 ? (amountA, amountB) : (amountB, amountA);
        return _settle(token, token0, pair, amountA, amountB, debt, maxSettle);
    }
    
    function _withdraw(IERC20 token, uint amount, uint maxSettle) internal {
        uint _lp = lp[msg.sender][address(token)];
        uint _borrowed = borrowed[msg.sender][address(token)];
        
        if (_lp < amount) {
            amount = _lp;
        }
        
        // Calculate % of collateral to release
        _borrowed = _borrowed * amount / _lp;
        address _pair = FACTORY.getPair(address(token), address(this));
        
        (uint amountA, uint amountB) = _unwrap(_pair, token, amount, _borrowed, maxSettle);
        
        lp[msg.sender][address(token)] -= amount;
        borrowed[msg.sender][address(token)] -= _borrowed;
        
        token.safeTransfer(msg.sender, amountA);
        _transferTokens(address(this), msg.sender, amountB);
        _burn(msg.sender, _borrowed);
        
        emit Withdraw(msg.sender, address(token), amount, amountB);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAINSEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "permit: signature");
        require(signatory == owner, "permit: unauthorized");
        require(block.timestamp <= deadline, "permit: expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;
        
        emit Transfer(src, dst, amount);
                
        if ((pairs[src] && dst != address(this))||(pairs[dst] && src != address(this))) {
            _transferTokens(dst, PAIR, amount / FEE);
            ISushiswapV2Pair(PAIR).sync();
        }
    }

    function _getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}