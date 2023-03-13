/**
 *Submitted for verification at BscScan.com on 2023-03-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// File: abstract/PoolDeployer.sol



pragma solidity >=0.8.0;

/// @dev Custom Errors
error UnauthorisedDeployer();
error ZeroAddress();
error InvalidTokenOrder();

/// @notice Ratio pool deployer for whitelisted template factories.
abstract contract PoolDeployer {
    address public immutable masterDeployer;

    mapping(address => mapping(address => address[])) public pools;
    mapping(bytes32 => address) public configAddress;

    modifier onlyMaster() {
        if (msg.sender != masterDeployer) revert UnauthorisedDeployer();
        _;
    }

    constructor(address _masterDeployer) {
        if (_masterDeployer == address(0)) revert ZeroAddress();
        masterDeployer = _masterDeployer;
    }

    function _registerPool(
        address pool,
        address[] memory tokens,
        bytes32 salt
    ) internal onlyMaster {
        // Store the address of the deployed contract.
        configAddress[salt] = pool;
        // Attacker used underflow, it was not very effective. poolimon!
        // null token array would cause deployment to fail via out of bounds memory axis/gas limit.
        unchecked {
            for (uint256 i; i < tokens.length - 1; ++i) {
                if (tokens[i] >= tokens[i + 1]) revert InvalidTokenOrder();
                for (uint256 j = i + 1; j < tokens.length; ++j) {
                    pools[tokens[i]][tokens[j]].push(pool);
                    pools[tokens[j]][tokens[i]].push(pool);
                }
            }
        }
    }

    function poolsCount(address token0, address token1) external view returns (uint256 count) {
        count = pools[token0][token1].length;
    }

    function getPools(
        address token0,
        address token1,
        uint256 startIndex,
        uint256 count
    ) external view returns (address[] memory pairPools) {
        pairPools = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            pairPools[i] = pools[token0][token1][startIndex + i];
        }
    }
}
// File: @rari-capital/solmate/src/utils/ReentrancyGuard.sol


pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// File: @rari-capital/solmate/src/tokens/ERC20.sol


pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// File: interfaces/IRatioCallee.sol



pragma solidity >=0.8.0;

/// @notice Ratio pool callback interface.
interface IRatioCallee {
    function ratioSwapCallback(bytes calldata data) external;

    function ratioMintCallback(bytes calldata data) external;
}
// File: interfaces/IPool.sol



pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @notice Ratio pool interface.
interface IPool {
    /// @notice Executes a swap from one token to another.
    /// @dev The input tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function swap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Executes a swap from one token to another with a callback.
    /// @dev This function allows borrowing the output tokens and sending the input tokens in the callback.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function flashSwap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Mints liquidity tokens.
    /// @param data ABI-encoded params that the pool requires.
    /// @return liquidity The amount of liquidity tokens that were minted for the user.
    function mint(bytes calldata data) external returns (uint256 liquidity);

    /// @notice Burns liquidity tokens.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return withdrawnAmounts The amount of various output tokens that were sent to the user.
    function burn(bytes calldata data) external returns (TokenAmount[] memory withdrawnAmounts);

    /// @notice Burns liquidity tokens for a single output token.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return amountOut The amount of output tokens that were sent to the user.
    function burnSingle(bytes calldata data) external returns (uint256 amountOut);

    /// @return A unique identifier for the pool type.
    function poolIdentifier() external pure returns (bytes32);

    /// @return An array of tokens supported by the pool.
    function getAssets() external view returns (address[] memory);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
    function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
    function getAmountIn(bytes calldata data) external view returns (uint256 finalAmountIn);

    /// @dev This event must be emitted on all swaps.
    event Swap(address indexed recipient, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// @dev This struct frames output tokens for burns.
    struct TokenAmount {
        address token;
        uint256 amount;
    }
}
// File: interfaces/IMasterDeployer.sol



pragma solidity >=0.8.0;

/// @notice Ratio pool deployer interface.
interface IMasterDeployer {
    function barFee() external view returns (uint256);

    function barFeeTo() external view returns (address);

    function gni() external view returns (address);

    function migrator() external view returns (address);

    function pools(address pool) external view returns (bool);

    function deployPool(address factory, bytes calldata deployData) external returns (address);
}
// File: libraries/RebaseLibrary.sol



pragma solidity ^0.8;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(Rebase memory total, uint256 elastic) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(Rebase memory total, uint256 base) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
        }
    }
}
// File: interfaces/IGniLampMinimal.sol



pragma solidity >=0.8.0;


/// @notice Minimal GniLamp vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IGniLampMinimal {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for GniLamp.
    function registerProtocol() external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    /// @dev Reads the Rebase `totals`from storage for a given token
    function totals(address token) external view returns (Rebase memory total);

    /// @dev Approves users' GniLamp assets to a "master" contract.
    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function harvest(
        address token,
        bool balance,
        uint256 maxChangeAmount
    ) external;
}
// File: IndexPool.sol



pragma solidity >=0.8.0;







/// @notice Ratio exchange pool template with constant mean formula for swapping among an array of ERC-20 tokens.
/// @dev The reserves are stored as gni shares.
///      The curve is applied to shares as well. This pool does not care about the underlying amounts.
contract IndexPool is IPool, ERC20, ReentrancyGuard {
    event Mint(address indexed sender, address tokenIn, uint256 amountIn, address indexed recipient);
    event Burn(address indexed sender, address tokenOut, uint256 amountOut, address indexed recipient);

    uint256 public immutable swapFee;

    address public immutable barFeeTo;
    IGniLampMinimal public immutable gni;
    IMasterDeployer public immutable masterDeployer;

    uint256 internal constant BASE = 10**18;
    uint256 internal constant MIN_TOKENS = 2;
    uint256 internal constant MAX_TOKENS = 8;
    uint256 internal constant MIN_FEE = BASE / 10**6;
    uint256 internal constant MAX_FEE = BASE / 10;
    uint256 internal constant MIN_WEIGHT = BASE;
    uint256 internal constant MAX_WEIGHT = BASE * 50;
    uint256 internal constant MAX_TOTAL_WEIGHT = BASE * 50;
    uint256 internal constant MIN_BALANCE = BASE / 10**12;
    uint256 internal constant INIT_POOL_SUPPLY = BASE * 100;
    uint256 internal constant MIN_POW_BASE = 1;
    uint256 internal constant MAX_POW_BASE = (2 * BASE) - 1;
    uint256 internal constant POW_PRECISION = BASE / 10**10;
    uint256 internal constant MAX_IN_RATIO = BASE / 2;
    uint256 internal constant MAX_OUT_RATIO = (BASE / 3) + 1;

    uint136 internal totalWeight;
    address[] internal tokens;

    uint256 public barFee;

    bytes32 public constant override poolIdentifier = "Ratio:Index";

    mapping(address => Record) public records;
    struct Record {
        uint120 reserve;
        uint136 weight;
    }

    constructor(bytes memory _deployData, address _masterDeployer) ERC20("Kami LP Token", "KLP", 18) {
        (address[] memory _tokens, uint136[] memory _weights, uint256 _swapFee) = abi.decode(_deployData, (address[], uint136[], uint256));
        // @dev Factory ensures that the tokens are sorted.
        require(_tokens.length == _weights.length, "INVALID_ARRAYS");
        require(MIN_FEE <= _swapFee && _swapFee <= MAX_FEE, "INVALID_SWAP_FEE");
        require(MIN_TOKENS <= _tokens.length && _tokens.length <= MAX_TOKENS, "INVALID_TOKENS_LENGTH");

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "ZERO_ADDRESS");
            require(MIN_WEIGHT <= _weights[i] && _weights[i] <= MAX_WEIGHT, "INVALID_WEIGHT");
            records[_tokens[i]] = Record({reserve: 0, weight: _weights[i]});
            tokens.push(_tokens[i]);
            totalWeight += _weights[i];
        }

        require(totalWeight <= MAX_TOTAL_WEIGHT, "MAX_TOTAL_WEIGHT");
        // @dev This burns initial LP supply.
        _mint(address(0), INIT_POOL_SUPPLY);

        swapFee = _swapFee;
        barFee = IMasterDeployer(_masterDeployer).barFee();
        barFeeTo = IMasterDeployer(_masterDeployer).barFeeTo();
        gni = IGniLampMinimal(IMasterDeployer(_masterDeployer).gni());
        masterDeployer = IMasterDeployer(_masterDeployer);
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `gni` tokens.
    /// The router must ensure that sufficient LP tokens are minted by using the return value.
    function mint(bytes calldata data) public override nonReentrant returns (uint256 liquidity) {
        (address recipient, uint256 toMint) = abi.decode(data, (address, uint256));

        uint120 ratio = uint120(_div(toMint, totalSupply));

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenIn = tokens[i];
            uint120 reserve = records[tokenIn].reserve;
            // @dev If token balance is '0', initialize with `ratio`.
            uint120 amountIn = reserve != 0 ? uint120(_mul(ratio, reserve)) : ratio;
            require(amountIn >= MIN_BALANCE, "MIN_BALANCE");
            // @dev Check Ratio router has sent `amountIn` for skim into pool.
            unchecked {
                // @dev This is safe from overflow - only logged amounts handled.
                require(_balance(tokenIn) >= amountIn + reserve, "NOT_RECEIVED");
                records[tokenIn].reserve += amountIn;
            }
            emit Mint(msg.sender, tokenIn, amountIn, recipient);
        }
        _mint(recipient, toMint);
        liquidity = toMint;
    }

    /// @dev Burns LP tokens sent to this contract. The router must ensure that the user gets sufficient output tokens.
    function burn(bytes calldata data) public override nonReentrant returns (IPool.TokenAmount[] memory withdrawnAmounts) {
        (address recipient, bool unwrapGni, uint256 toBurn) = abi.decode(data, (address, bool, uint256));

        uint256 ratio = _div(toBurn, totalSupply);

        withdrawnAmounts = new TokenAmount[](tokens.length);

        _burn(address(this), toBurn);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOut = tokens[i];
            uint256 balance = records[tokenOut].reserve;
            uint120 amountOut = uint120(_mul(ratio, balance));
            require(amountOut != 0, "ZERO_OUT");
            // @dev This is safe from underflow - only logged amounts handled.
            unchecked {
                records[tokenOut].reserve -= amountOut;
            }
            _transfer(tokenOut, amountOut, recipient, unwrapGni);
            withdrawnAmounts[i] = TokenAmount({token: tokenOut, amount: amountOut});
            emit Burn(msg.sender, tokenOut, amountOut, recipient);
        }
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override nonReentrant returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapGni, uint256 toBurn) = abi.decode(data, (address, address, bool, uint256));

        Record storage outRecord = records[tokenOut];

        amountOut = _computeSingleOutGivenPoolIn(outRecord.reserve, outRecord.weight, totalSupply, totalWeight, toBurn, swapFee);

        require(amountOut <= _mul(outRecord.reserve, MAX_OUT_RATIO), "MAX_OUT_RATIO");
        // @dev This is safe from underflow - only logged amounts handled.
        unchecked {
            outRecord.reserve -= uint120(amountOut);
        }
        _burn(address(this), toBurn);
        _transfer(tokenOut, amountOut, recipient, unwrapGni);
        emit Burn(msg.sender, tokenOut, amountOut, recipient);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(bytes calldata data) public override nonReentrant returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, address recipient, bool unwrapGni, uint256 amountIn) = abi.decode(
            data,
            (address, address, address, bool, uint256)
        );

        Record storage inRecord = records[tokenIn];
        Record storage outRecord = records[tokenOut];

        require(amountIn <= _mul(inRecord.reserve, MAX_IN_RATIO), "MAX_IN_RATIO");

        amountOut = _getAmountOut(amountIn, inRecord.reserve, inRecord.weight, outRecord.reserve, outRecord.weight);
        // @dev Check Ratio router has sent `amountIn` for skim into pool.
        unchecked {
            // @dev This is safe from under/overflow - only logged amounts handled.
            require(_balance(tokenIn) >= amountIn + inRecord.reserve, "NOT_RECEIVED");
            inRecord.reserve += uint120(amountIn);
            outRecord.reserve -= uint120(amountOut);
        }
        _transfer(tokenOut, amountOut, recipient, unwrapGni);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Swaps one token for another. The router must support swap callbacks and ensure there isn't too much slippage.
    function flashSwap(bytes calldata data) public override nonReentrant returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, address recipient, bool unwrapGni, uint256 amountIn, bytes memory context) = abi.decode(
            data,
            (address, address, address, bool, uint256, bytes)
        );

        Record storage inRecord = records[tokenIn];
        Record storage outRecord = records[tokenOut];

        require(amountIn <= _mul(inRecord.reserve, MAX_IN_RATIO), "MAX_IN_RATIO");

        amountOut = _getAmountOut(amountIn, inRecord.reserve, inRecord.weight, outRecord.reserve, outRecord.weight);

        IRatioCallee(msg.sender).ratioSwapCallback(context);
        // @dev Check Ratio router has sent `amountIn` for skim into pool.
        unchecked {
            // @dev This is safe from under/overflow - only logged amounts handled.
            require(_balance(tokenIn) >= amountIn + inRecord.reserve, "NOT_RECEIVED");
            inRecord.reserve += uint120(amountIn);
            outRecord.reserve -= uint120(amountOut);
        }
        _transfer(tokenOut, amountOut, recipient, unwrapGni);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Updates `barFee` for Ratio protocol.
    function updateBarFee() public {
        barFee = IMasterDeployer(masterDeployer).barFee();
    }

    function _balance(address token) internal view returns (uint256 balance) {
        balance = gni.balanceOf(token, address(this));
    }

    function _getAmountOut(
        uint256 tokenInAmount,
        uint256 tokenInBalance,
        uint256 tokenInWeight,
        uint256 tokenOutBalance,
        uint256 tokenOutWeight
    ) internal view returns (uint256 amountOut) {
        uint256 weightRatio = _div(tokenInWeight, tokenOutWeight);
        // @dev This is safe from under/overflow - only logged amounts handled.
        unchecked {
            uint256 adjustedIn = _mul(tokenInAmount, (BASE - swapFee));
            uint256 a = _div(tokenInBalance, tokenInBalance + adjustedIn);
            uint256 b = _compute(a, weightRatio);
            uint256 c = BASE - b;
            amountOut = _mul(tokenOutBalance, c);
        }
    }

    function _compute(uint256 base, uint256 exp) internal pure returns (uint256 output) {
        require(MIN_POW_BASE <= base && base <= MAX_POW_BASE, "INVALID_BASE");

        uint256 whole = (exp / BASE) * BASE;
        uint256 remain = exp - whole;
        uint256 wholePow = _pow(base, whole / BASE);

        if (remain == 0) output = wholePow;

        uint256 partialResult = _powApprox(base, remain, POW_PRECISION);
        output = _mul(wholePow, partialResult);
    }

    function _computeSingleOutGivenPoolIn(
        uint256 tokenOutBalance,
        uint256 tokenOutWeight,
        uint256 _totalSupply,
        uint256 _totalWeight,
        uint256 toBurn,
        uint256 _swapFee
    ) internal pure returns (uint256 amountOut) {
        uint256 normalizedWeight = _div(tokenOutWeight, _totalWeight);
        uint256 newPoolSupply = _totalSupply - toBurn;
        uint256 poolRatio = _div(newPoolSupply, _totalSupply);
        uint256 tokenOutRatio = _pow(poolRatio, _div(BASE, normalizedWeight));
        uint256 newBalanceOut = _mul(tokenOutRatio, tokenOutBalance);
        uint256 tokenAmountOutBeforeSwapFee = tokenOutBalance - newBalanceOut;
        uint256 zaz = (BASE - normalizedWeight) * _swapFee;
        amountOut = _mul(tokenAmountOutBeforeSwapFee, (BASE - zaz));
    }

    function _pow(uint256 a, uint256 n) internal pure returns (uint256 output) {
        output = n % 2 != 0 ? a : BASE;
        for (n /= 2; n != 0; n /= 2) a = a * a;
        if (n % 2 != 0) output = output * a;
    }

    function _powApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256 sum) {
        uint256 a = exp;
        (uint256 x, bool xneg) = _subFlag(base, BASE);
        uint256 term = BASE;
        sum = term;
        bool negative;

        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BASE;
            (uint256 c, bool cneg) = _subFlag(a, (bigK - BASE));
            term = _mul(term, _mul(c, x));
            term = _div(term, bigK);
            if (term == 0) break;
            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sum - term;
            } else {
                sum = sum + term;
            }
        }
    }

    function _subFlag(uint256 a, uint256 b) internal pure returns (uint256 difference, bool flag) {
        // @dev This is safe from underflow - if/else flow performs checks.
        unchecked {
            if (a >= b) {
                (difference, flag) = (a - b, false);
            } else {
                (difference, flag) = (b - a, true);
            }
        }
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256 c2) {
        uint256 c0 = a * b;
        uint256 c1 = c0 + (BASE / 2);
        c2 = c1 / BASE;
    }

    function _div(uint256 a, uint256 b) internal pure returns (uint256 c2) {
        uint256 c0 = a * BASE;
        uint256 c1 = c0 + (b / 2);
        c2 = c1 / b;
    }

    function _transfer(
        address token,
        uint256 shares,
        address to,
        bool unwrapGni
    ) internal {
        if (unwrapGni) {
            gni.withdraw(token, address(this), to, 0, shares);
        } else {
            gni.transfer(token, address(this), to, shares);
        }
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = tokens;
    }

    function getAmountOut(bytes calldata data) public view override returns (uint256 amountOut) {
        (uint256 tokenInAmount, uint256 tokenInBalance, uint256 tokenInWeight, uint256 tokenOutBalance, uint256 tokenOutWeight) = abi
            .decode(data, (uint256, uint256, uint256, uint256, uint256));
        amountOut = _getAmountOut(tokenInAmount, tokenInBalance, tokenInWeight, tokenOutBalance, tokenOutWeight);
    }

    function getAmountIn(bytes calldata) public pure override returns (uint256) {
        revert();
    }

    function getReservesAndWeights() public view returns (uint256[] memory reserves, uint136[] memory weights) {
        uint256 length = tokens.length;
        reserves = new uint256[](length);
        weights = new uint136[](length);
        // @dev This is safe from overflow - `tokens` `length` is bound to '8'.
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                reserves[i] = records[tokens[i]].reserve;
                weights[i] = records[tokens[i]].weight;
            }
        }
    }
}
// File: IndexPoolFactory.sol



pragma solidity >=0.8.0;



/// @notice Contract for deploying Ratio exchange Index Pool with configurations.
contract IndexPoolFactory is PoolDeployer {
    constructor(address _masterDeployer) PoolDeployer(_masterDeployer) {}

    function deployPool(bytes memory _deployData) external returns (address pool) {
        (address[] memory tokens, uint136[] memory weights, uint256 swapFee) = abi.decode(_deployData, (address[], uint136[], uint256));

        // @dev Strips any extra data.
        _deployData = abi.encode(tokens, weights, swapFee);

        // @dev Salt is not actually needed since `_deployData` is part of creationCode and already contains the salt.
        bytes32 salt = keccak256(_deployData);
        pool = address(new IndexPool{salt: salt}(_deployData, masterDeployer));
        _registerPool(pool, tokens, salt);
    }
}