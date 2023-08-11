/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/interfaces/IUniswapV2ERC20.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


// File contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-overflow");
        z = x / y;
    }
}


// File contracts/InedibleXV1ERC20.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.5.16;


contract InedibleXV1ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant name = "inedibleX V1";
    string public constant symbol = "ineX-V1";
    uint public totalSupply;

    uint112 internal reserve0; // uses single storage slot, accessible via getReserves
    uint112 internal reserve1; // uses single storage slot, accessible via getReserves

    // pack variables to use single slot
    uint8 public constant decimals = 18;
    uint32 internal blockTimestampLast; //
    uint8 private unlocked = 1;

    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    // Added by Inedible
    mapping(address => uint) public lockedUntil;
    // Last cumulative fee per token amount a user has withdrawn.
    mapping(address => uint) public lastUserCumulative;
    // Fees ready to be claimed by user.
    mapping(address => uint256) public unclaimed;
    // Cumulative amount of fees generated per single full token.
    uint public cumulativeFees;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        _updateFees(to);
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _updateFees(from);
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint value,
        bool fromClaimFees
    ) private {
        // Here we need to give users more fees and update
        require(lockedUntil[from] < block.timestamp, "User balance is locked.");

        if (!fromClaimFees) {
            _mintFee(reserve0, reserve1);

            _updateFees(from);
            _updateFees(to);
        }
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(from, to, value);
    }

    // Virtual function to be called on the V2Pair contract.
    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    ) internal returns (bool feeOn) {}

    function _updateFees(address _user) internal {
        // Div buffer is because cumulative fees is based on a full token value.
        uint256 balance = balanceOf[_user];
        uint lastCumulative = lastUserCumulative[_user];
        // update cumulative fees here because we need to take care of transfer
        lastUserCumulative[_user] = cumulativeFees;

        if (balance == 0) return;

        uint256 feeAmount = balance
            .mul((cumulativeFees).sub(lastCumulative))
            .div(1e18);
        unclaimed[_user] = unclaimed[_user].add(feeAmount);
    }

    // Added by Inedible
    function claimFees(address _user) public lock {
        _mintFee(reserve0, reserve1);

        // Div buffer is because cumulative fees is based on a full token value.
        uint256 feeAmount = balanceOf[_user]
            .mul((cumulativeFees).sub(lastUserCumulative[_user]))
            .div(1e18);
        uint256 _unclaimed = unclaimed[_user];

        lastUserCumulative[_user] = cumulativeFees;
        if (feeAmount.add(_unclaimed) > 0) {
            _transfer(
                address(1),
                address(this),
                feeAmount.add(_unclaimed),
                true
            );
            unclaimed[_user] = 0;
            _burnHelper(_user, true);
        } else {
            kLast = uint(reserve0).mul(reserve1);
        }
    }

    // Added by Inedible
    function viewFees(address _user) public view returns (uint256) {
        // Div buffer is because cumulative fees is based on a full token value.
        uint256 feeAmount = balanceOf[_user]
            .mul((cumulativeFees).sub(lastUserCumulative[_user]))
            .div(1e18);
        uint256 _unclaimed = unclaimed[_user];

        return feeAmount.add(_unclaimed);
    }

    // Virtual function to be called on the V2Pair contract.
    function _burnHelper(
        address _user,
        bool _fromClaim
    ) private returns (uint amount0, uint amount1) {}

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value, false);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value, false);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "UniswapV2: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}


// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/interfaces/IInedibleXV1Factory.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IInedibleXV1Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint pairLength
    );

    event InedibleCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint pairLength,
        bool launch,
        uint lock,
        uint vesting
    );

    function treasury() external view returns (address);

    function feeTo() external view returns (address);

    function dao() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB,
        bool launch,
        uint16 launchFeePct,
        uint40 lock,
        uint40 vesting
    ) external returns (address pair);

    function setFeeTo(address) external;

    // added by inedible
    function setLaunchFeePct(uint16 _launchFeePct) external;

    function setMinSupplyPct(uint16 _minSupplyPct) external;

    function transferOwnership(address _newDao) external;

    function renounceOwnership() external;

    function acceptOwnership() external;
}


// File contracts/interfaces/IInedibleXV1Pair.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IInedibleXV1Pair {
    struct Balance {
        uint balance0;
        uint balance1;
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        address operator,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _router,
        uint16 _minSupplyPct,
        uint16 _launchFeePct,
        bool _launch,
        uint40 _lockDuration,
        uint40 _vestingDuration
    ) external;
}


// File contracts/interfaces/IRewards.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IRewards {
    function payFee(address _token, uint256 _amount) external;
}


// File contracts/interfaces/IUniswapV2Callee.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}


// File contracts/libraries/Math.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.5.16;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// File contracts/libraries/UQ112x112.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}


// File contracts/InedibleXV1Pair.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.5.16;








contract InedibleXV1Pair is IInedibleXV1Pair, InedibleXV1ERC20 {
    using SafeMath for uint;
    using SafeMath for uint40;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    // Variables below added by Inedible
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // router address
    address public router;
    // Denominator for percent math. Numerator of 1,000 == 10%.
    uint256 public constant DENOM = 10000;
    // Whether or not this was a launch of a token.
    bool public launch;
    // This will equal block.timestamp once 2 trades have occurred on the block.
    uint40 private twoTrades;
    // The time that token vesting ends.
    uint40 public vestingEnd;
    // Minimum percent of a token that must be initially supplied.
    uint40 public initialLockDuration;
    uint16 public minSupplyPct;
    // Percent of tokens to send to the treasury from initial supply.
    uint16 public launchFeePct;
    // Amount of tokens bought from the dex. Avoids dumping.
    mapping(address => uint256) private buyBalance;

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "UniswapV2: TRANSFER_FAILED"
        );
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        address _router,
        uint16 _minSupplyPct,
        uint16 _launchFeePct,
        bool _launch,
        uint40 _lockDuration,
        uint40 _vestingDuration
    ) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;

        // Add launch variable
        if (_launch) {
            router = _router;
            launch = true;

            // Added by Inedible
            minSupplyPct = _minSupplyPct;
            launchFeePct = _launchFeePct;
            uint40 timestamp = uint40(block.timestamp);
            // won't overflow, router restricts vesting < 365 days
            vestingEnd = timestamp + _vestingDuration;
            initialLockDuration = _lockDuration;
        }
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint balance0,
        uint balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= uint112(-1) && balance1 <= uint112(-1),
            "UniswapV2: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
                uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        // Added by Inedible
        // If 1 trade has already been made, save that a second trade is happening.
        // If a second trade has already occurred this block, revert.
        if (timeElapsed == 0) {
            if (twoTrades < block.timestamp) {
                twoTrades = uint40(block.timestamp);
            } else if (
                // This is an exception for a HoneyBot contract
                token0 != 0x0A127232C33cd61Dc838293aEb1Bfa6d51C89D78 &&
                token1 != 0x0A127232C33cd61Dc838293aEb1Bfa6d51C89D78
            ) {
                revert("Two trades have already occurred on this block.");
            }
        }

        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    ) internal returns (bool feeOn) {
        address treasury = IInedibleXV1Factory(factory).treasury();
        feeOn = treasury != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 _totalSupply = totalSupply;
                    uint numerator = _totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) {
                        // address1 is where we store lp fees and
                        // that balance should not be owed fees
                        uint addr1BalBefore = balanceOf[address(1)];

                        cumulativeFees = cumulativeFees.add(
                            liquidity.mul(5).mul(1e18).div(
                                _totalSupply - addr1BalBefore
                            )
                        );

                        // protocol fees
                        _mint(treasury, liquidity);

                        // liquidity provider fees
                        // This is a storage address to hold the rest of the fees.
                        // It's not the most efficient way to distribute fees separately from
                        // initial tokens, but it's the one that requires the least code changes.
                        _mint(address(1), liquidity.mul(5));
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        // Added by Inedible
        // Specific actions on adding first liquidity, must come before amounts are counted
        if (totalSupply == 0 && launch) {
            IERC20 launchToken = token0 == WETH
                ? IERC20(token1)
                : IERC20(token0);
            uint launchAmount = token0 == WETH ? amount1 : amount0;
            uint256 tokenSupply = launchToken.totalSupply();
            uint256 launchFee = (tokenSupply * launchFeePct) / DENOM;
            uint256 minSupply = (tokenSupply * minSupplyPct) / DENOM;
            // Ends with tokens in pool actually less than amount0 because the treasury is sent a %
            require(minSupply <= launchAmount, "Not enough tokens supplied.");

            lockedUntil[to] = block.timestamp.add(initialLockDuration);
            address feeTo = IInedibleXV1Factory(factory).feeTo();
            launchToken.approve(feeTo, launchFee);
            IRewards(feeTo).payFee(address(launchToken), launchFee);

            // update amount0 and balance0 because the treasury took a fee
            if (token0 != WETH) {
                amount0 = amount0.sub(launchFee);
                balance0 = balance0.sub(launchFee);
            } else {
                amount1 = amount1.sub(launchFee);
                balance1 = balance1.sub(launchFee);
            }
        }

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) public lock returns (uint amount0, uint amount1) {
        (amount0, amount1) = _burnHelper(to, false);
    }

    function _burnHelper(
        address to,
        bool fromClaim
    ) private returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        bool feeOn = true;

        if (!fromClaim) {
            feeOn = _mintFee(_reserve0, _reserve1);
        }

        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        address transactor,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "UniswapV2: INSUFFICIENT_LIQUIDITY"
        );
        Balance memory bal;

        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "UniswapV2: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                IUniswapV2Callee(to).uniswapV2Call(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            bal.balance0 = IERC20(_token0).balanceOf(address(this));
            bal.balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = bal.balance0 > _reserve0 - amount0Out
            ? bal.balance0 - (_reserve0 - amount0Out)
            : 0;
        uint amount1In = bal.balance1 > _reserve1 - amount1Out
            ? bal.balance1 - (_reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "UniswapV2: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = bal.balance0.mul(10000).sub(
                amount0In.mul(36)
            );
            uint balance1Adjusted = bal.balance1.mul(10000).sub(
                amount1In.mul(36)
            );
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint(_reserve0).mul(_reserve1).mul(10000 ** 2),
                "UniswapV2: K"
            );
        }

        {
            // scope for inedible, avoids stack too deep errors

            // Added by Inedible
            // This could technically be used to grief, but only by sending money to the person being "griefed"
            if (launch && block.timestamp < vestingEnd) {
                // If token0 is not WETH, it's the launch token that we need to restrict sells on.
                bool token0IsLaunch = token0 != WETH;

                // we check for tokenIn to be equal to zero because this low
                // level function can be used to bypass vesting by sending
                // vested token to contract and calling swap which will
                // update buyBalance and allow for a sell.
                if (
                    token0IsLaunch
                        ? amount0Out > 0 && amount0In == 0
                        : amount1Out > 0 && amount1In == 0
                ) {
                    buyBalance[to] = buyBalance[to].add(
                        token0IsLaunch ? amount0Out : amount1Out
                    );
                } else {
                    if (msg.sender == router) {
                        buyBalance[transactor] = buyBalance[transactor].sub(
                            token0IsLaunch ? amount0In : amount1In
                        );
                    } else {
                        buyBalance[to] = buyBalance[to].sub(
                            token0IsLaunch ? amount0In : amount1In
                        );
                    }
                }
            }
            _update(bal.balance0, bal.balance1, _reserve0, _reserve1);
            emit Swap(
                msg.sender,
                amount0In,
                amount1In,
                amount0Out,
                amount1Out,
                to
            );
        }
    }

    // Added by Inedible
    function extendLock(uint256 _extension) external {
        lockedUntil[msg.sender] = lockedUntil[msg.sender].add(_extension);
    }

    /**
     * @dev Admin multisig can unlock liquidity for 1 month after MVP launch.
     *      If we find any bugs, we need to be able to migrate.
     **/
    function adminUnlock(address _user) external {
        require(
            msg.sender == 0x1f28eD9D4792a567DaD779235c2b766Ab84D8E33,
            "only admin"
        );
        require(
            block.timestamp < 1691390687,
            "May not unlock after August 6th."
        );
        delete lockedUntil[_user];
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}