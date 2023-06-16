/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: UniswapV2 Fork - XchangeFactory and XchangePair

The factory contract maintains a number of "trusted" addresses and the pair contract has a number of additional features:

    * failsafe reserve minimums
    * failsafe pair token burning (liquidity withdrawal)
    * trustless and guarenteed fee collection
    * tokens may swap themselves

This contract will NOT be renounced.

The following are the only functions that can be called on the factory contract that affect the contract:

    function setFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != feeTo);
        address oldFeeToo = feeTo;
        feeTo = _feeTo;
        emit FeeToSet(oldFeeToo, _feeTo);
    }

    function setDiscountAuthority(address _discountAuthority) external onlyOwner {
        require(_discountAuthority != discountAuthority);
        address oldDiscountAuthority = discountAuthority;
        discountAuthority = _discountAuthority;
        emit DiscountAuthoritySet(oldDiscountAuthority, _discountAuthority);
    }

    function setTrusted(address trustAddress, bool shouldTrustAddress) external onlyOwner {
        require(_isTrusted[trustAddress] != shouldTrustAddress);
        _isTrusted[trustAddress] = shouldTrustAddress;
        emit TrustedSet(trustAddress, shouldTrustAddress);
    }

    function setFailsafeLiquidator(address trustAddress, bool shouldTrustAddress) external onlyOwner {
        require(_isFailSafeLiquidator[trustAddress] != shouldTrustAddress);
        _isFailSafeLiquidator[trustAddress] = shouldTrustAddress;
        emit FailsafeLiquidatorSet(trustAddress, shouldTrustAddress);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IXchangeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event TrustedSet(address indexed trustedPrincipal, bool isTrusted);
    event FailsafeLiquidatorSet(address indexed trustedPrincipal, bool isTrusted);
    event DiscountAuthoritySet(address indexed oldAddress, address indexed newAddress);
    event FeeToSet(address indexed oldAddress, address indexed newAddress);

    function feeTo() external view returns (address);
    function discountAuthority() external view returns (address);
    function isTrusted(address) external view returns (bool);
    function isFailsafeLiquidator(address) external view returns (bool);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function isPair(address pairAddress) external view returns (bool);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function pairTokens(address pairAddress, address tokenAddress) external view returns (bool);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setTrusted(address, bool) external;
    function setDiscountAuthority(address) external;
    function setFailsafeLiquidator(address, bool) external;
}

interface IXchangePair {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function mintFee() external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;

    function mustBurn(address to, uint256 gasAmount) external returns (uint256 amount0, uint256 amount1);
    function swapWithDiscount(uint amount0Out, uint amount1Out, address to, uint feeAmountOverride, bytes calldata data) external;
    function syncSafe(uint256 gasAmountToken0, uint256 gasAmountToken1) external;

    function withdrawTokensAgainstMinimumBalance(address tokenAddress, address to, uint112 amount) external returns (uint112);
    function setMinimumBalance(address tokenAddress, uint112 minimumAmount) external;
}

interface IXchangeERC20 {
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

interface IXchangeDiscountAuthority {
    function fee(address) external view returns (uint8);
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract XchangeERC20 is IXchangeERC20 {
    string public constant name = 'Xchange AMM V1';
    string public constant symbol = 'X7-AMM-V1';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Xchange: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Xchange: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}

contract XchangePair is IXchangePair, XchangeERC20 {
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    IXchangeFactory _factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    bool public hasMinimums;
    mapping(address => uint112) public tokenMinimumBalance;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Xchange: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function factory() public view returns (address) {
        return address(_factory);
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    constructor() {
        _factory = IXchangeFactory(msg.sender);
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == address(_factory), 'Xchange: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    function mintFee() external {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        _mintFee(_reserve0, _reserve1);
    }

    function setMinimumBalance(address tokenAddress, uint112 minimumAmount) external {
        require(_factory.isTrusted(msg.sender),'Xchange: FORBIDDEN');
        tokenMinimumBalance[tokenAddress] = minimumAmount;

        if (tokenMinimumBalance[token0] == 0 && tokenMinimumBalance[token1] == 0) {
            hasMinimums = false;
        } else {
            hasMinimums = true;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    // The caller should try to call `sync` or `syncSafe`
    function withdrawTokensAgainstMinimumBalance(address tokenAddress, address to, uint112 amount) external returns (uint112) {
        require(_factory.isTrusted(msg.sender),'Xchange: FORBIDDEN');
        if (amount > tokenMinimumBalance[tokenAddress]) {
            amount = tokenMinimumBalance[tokenAddress];
        }
        tokenMinimumBalance[tokenAddress] -= amount;
        _safeTransfer(tokenAddress, to,  amount);

        if (tokenMinimumBalance[token0] == 0 && tokenMinimumBalance[token1] == 0) {
            hasMinimums = false;
        }

        return amount;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0, 'Xchange: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Xchange: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        if (hasMinimums) {
            require(balance0 >= tokenMinimumBalance[_token0], 'Xchange: INSUFFICIENT_TOKEN0_BALANCE');
            require(balance1 >= tokenMinimumBalance[_token1], 'Xchange: INSUFFICIENT_TOKEN1_BALANCE');
        }
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function mustBurn(address to, uint256 gasAmount) external lock returns (uint amount0, uint amount1) {
        require(_factory.isFailsafeLiquidator(msg.sender));
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings

        uint balance0 = _reserve0;
        uint balance1 = _reserve1;
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Xchange: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        amount0 = _trySafeTransfer(_token0, to, amount0, gasAmount);
        amount1 = _trySafeTransfer(_token1, to, amount1, gasAmount);

        if (gasAmount > 0) {
            try IERC20(_token0).balanceOf{gas: gasAmount}(address(this)) returns (uint256 balance0_) {
                balance0 = balance0_;
            } catch {}

            try IERC20(_token1).balanceOf{gas: gasAmount}(address(this)) returns (uint256 balance1_) {
                balance1 = balance1_;
            } catch {}
        } else {
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        if (hasMinimums) {
            require(balance0 >= tokenMinimumBalance[_token0], 'Xchange: INSUFFICIENT_TOKEN0_BALANCE');
            require(balance1 >= tokenMinimumBalance[_token1], 'Xchange: INSUFFICIENT_TOKEN1_BALANCE');
        }
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        _swap(amount0Out, amount1Out, to, 200, data);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swapWithDiscount(uint amount0Out, uint amount1Out, address to, uint feeAmountOverride, bytes calldata data) external lock {
        _swap(amount0Out, amount1Out, to, feeAmountOverride, data);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
        if (hasMinimums) {
            require(IERC20(_token0).balanceOf(address(this)) >= tokenMinimumBalance[_token0], 'Xchange: INSUFFICIENT_TOKEN0_BALANCE');
            require(IERC20(_token1).balanceOf(address(this)) >= tokenMinimumBalance[_token1], 'Xchange: INSUFFICIENT_TOKEN1_BALANCE');
        }
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    // attempt to force reserves to match balances
    function syncSafe(uint256 gasAmountToken0, uint256 gasAmountToken1) external lock {
        require(_factory.isTrusted(msg.sender), 'Xchange: FORBIDDEN');
        _update(IERC20(token0).balanceOf{gas: gasAmountToken0}(address(this)), IERC20(token1).balanceOf{gas: gasAmountToken1}(address(this)), reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/2th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = _factory.feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * _reserve1);
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = rootK + rootKLast;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _swap(uint amount0Out, uint amount1Out, address to, uint feeAmountOverride, bytes calldata data) internal {
        require(amount0Out > 0 || amount1Out > 0, 'Xchange: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Xchange: INSUFFICIENT_LIQUIDITY');

        uint[2] memory balances;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            balances[0] = IERC20(_token0).balanceOf(address(this));
            balances[1] = IERC20(_token1).balanceOf(address(this));
            if (hasMinimums) {
                require(balances[0] >= tokenMinimumBalance[_token0], 'Xchange: INSUFFICIENT_TOKEN0_BALANCE');
                require(balances[1] >= tokenMinimumBalance[_token1], 'Xchange: INSUFFICIENT_TOKEN1_BALANCE');
            }
        }
        uint amount0In = balances[0] > _reserve0 - amount0Out ? balances[0] - (_reserve0 - amount0Out) : 0;
        uint amount1In = balances[1] > _reserve1 - amount1Out ? balances[1] - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Xchange: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint feeAmount = 200;
            if (feeAmountOverride != 200) {
                if (_factory.isTrusted(msg.sender)) {
                    feeAmount = feeAmountOverride;
                } else {
                    feeAmount = IXchangeDiscountAuthority(_factory.discountAuthority()).fee(msg.sender);
                }
                feeAmount = feeAmount <= 200 ? feeAmount : 200;
            }

            uint balance0Adjusted = (balances[0] * 100000) - (amount0In * feeAmount);
            uint balance1Adjusted = (balances[1] * 100000) - (amount1In * feeAmount);
            require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * _reserve1 * 100000**2, 'Xchange: K');
        }

        _update(balances[0], balances[1], _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'Xchange: OVERFLOW');

        unchecked {
            uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast; // overflow is desired
            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                // * never overflows, and + overflow is desired
                price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
        emit Sync(reserve0, reserve1);
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Xchange: TRANSFER_FAILED');
    }

    function _trySafeTransfer(address token, address to, uint value, uint gasAmount) private returns (uint) {
        (bool ok,) = token.call{gas: gasAmount}(abi.encodeWithSelector(SELECTOR, to, value));
        if (ok) {
            return value;
        } else {
            return 0;
        }
    }
}

contract XchangeFactory is IXchangeFactory, Ownable {
    address public feeTo;
    address public discountAuthority;
    mapping(address => bool) _isTrusted;
    mapping(address => bool) _isFailSafeLiquidator;

    mapping(address => mapping(address => address)) public getPair;
    mapping(address => bool) public isPair;
    address[] public allPairs;

    // Pair Address => token address => Is in the pair
    mapping(address => mapping(address => bool)) public pairTokens;

    constructor() Ownable(msg.sender) {
        _isTrusted[address(this)] = true;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function isTrusted(address checkAddress) external view returns (bool) {
        return _isTrusted[checkAddress];
    }

    function isFailsafeLiquidator(address checkAddress) external view returns (bool) {
        return _isFailSafeLiquidator[checkAddress];
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != feeTo);
        address oldFeeToo = feeTo;
        feeTo = _feeTo;
        emit FeeToSet(oldFeeToo, _feeTo);
    }

    function setDiscountAuthority(address _discountAuthority) external onlyOwner {
        require(_discountAuthority != discountAuthority);
        address oldDiscountAuthority = discountAuthority;
        discountAuthority = _discountAuthority;
        emit DiscountAuthoritySet(oldDiscountAuthority, _discountAuthority);
    }

    function setTrusted(address trustAddress, bool shouldTrustAddress) external onlyOwner {
        require(_isTrusted[trustAddress] != shouldTrustAddress);
        _isTrusted[trustAddress] = shouldTrustAddress;
        emit TrustedSet(trustAddress, shouldTrustAddress);
    }

    function setFailsafeLiquidator(address trustAddress, bool shouldTrustAddress) external onlyOwner {
        require(_isFailSafeLiquidator[trustAddress] != shouldTrustAddress);
        _isFailSafeLiquidator[trustAddress] = shouldTrustAddress;
        emit FailsafeLiquidatorSet(trustAddress, shouldTrustAddress);
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Xchange: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Xchange: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Xchange: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(XchangePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IXchangePair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        pairTokens[pair][token0] = true;
        pairTokens[pair][token1] = true;
        isPair[pair] = true;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}

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