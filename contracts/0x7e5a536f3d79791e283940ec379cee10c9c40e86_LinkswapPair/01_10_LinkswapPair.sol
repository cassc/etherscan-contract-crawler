pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./libraries/Math.sol";
import "./libraries/SafeMathLinkswap.sol";
import "./libraries/UQ112x112.sol";
import "./interfaces/ILinkswapCallee.sol";
import "./interfaces/ILinkswapFactory.sol";
import "./interfaces/ILinkswapPair.sol";

contract LinkswapPair is ILinkswapPair, ReentrancyGuard {
    using SafeMathLinkswap for uint256;
    using UQ112x112 for uint224;

    string public constant override name = "LinkSwap LP Token";
    string public constant override symbol = "LSLP";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32
        public constant
        override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    mapping(address => uint256) public override addressToLockupExpiry;
    mapping(address => uint256) public override addressToLockupAmount;

    address public override factory;
    address public override token0;
    address public override token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;
    uint256 public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 public override tradingFeePercent; // need to divide by 1,000,000, e.g. 3000 = 0.3%
    uint256 public override lastSlippageBlocks;
    uint256 public override priceAtLastSlippageBlocks;
    uint256 public override lastSwapPrice;

    modifier onlyGovernance() {
        require(msg.sender == ILinkswapFactory(factory).governance(), "Pair: FORBIDDEN");
        _;
    }

    constructor() public {
        factory = msg.sender;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        uint256 _tradingFeePercent
    ) external override {
        require(msg.sender == factory, "Pair: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        tradingFeePercent = _tradingFeePercent;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "Pair: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Pair: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function getReserves()
        public
        view
        override
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

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Pair: TRANSFER_FAILED");
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), "Pair: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        uint256 protocolFeeFractionInverse = ILinkswapFactory(factory).protocolFeeFractionInverse();
        feeOn = protocolFeeFractionInverse != 0;
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 liquidity = totalSupply.mul(rootK.sub(rootKLast)).mul(1000) /
                        ((rootK.mul(protocolFeeFractionInverse.sub(1000))).add(rootKLast.mul(1000)));
                    if (liquidity > 0) {
                        ILinkswapFactory linkswapFactory = ILinkswapFactory(factory);
                        uint256 treasuryProtocolFeeShare = linkswapFactory.treasuryProtocolFeeShare();
                        _mint(linkswapFactory.treasury(), liquidity.mul(treasuryProtocolFeeShare) / 1000000);
                        _mint(
                            linkswapFactory.governance(),
                            liquidity.mul(uint256(1000000).sub(treasuryProtocolFeeShare)) / 1000000
                        );
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) public override nonReentrant returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, "Pair: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    function _lock(
        address locker,
        uint256 lockupPeriod,
        uint256 liquidityLockupAmount
    ) private {
        if (lockupPeriod == 0 && liquidityLockupAmount == 0) return;
        if (addressToLockupExpiry[locker] == 0) {
            // not currently locked
            require(lockupPeriod > 0, "Pair: ZERO_LOCKUP_PERIOD");
            require(liquidityLockupAmount > 0, "Pair: ZERO_LOCKUP_AMOUNT");
            addressToLockupExpiry[locker] = block.timestamp.add(lockupPeriod);
        } else {
            // locking when already locked will extend lockup period
            addressToLockupExpiry[locker] = addressToLockupExpiry[locker].add(lockupPeriod);
        }
        addressToLockupAmount[locker] = addressToLockupAmount[locker].add(liquidityLockupAmount);
        _transfer(locker, address(this), liquidityLockupAmount);
        emit Lock(locker, lockupPeriod, liquidityLockupAmount);
    }

    // called once by the factory at time of deployment
    function listingLock(
        address lister,
        uint256 lockupPeriod,
        uint256 liquidityLockupAmount
    ) external override {
        require(msg.sender == factory, "Pair: FORBIDDEN");
        _lock(lister, lockupPeriod, liquidityLockupAmount);
    }

    function lock(uint256 lockupPeriod, uint256 liquidityLockupAmount) external override {
        _lock(msg.sender, lockupPeriod, liquidityLockupAmount);
    }

    function unlock() external override {
        require(addressToLockupExpiry[msg.sender] <= block.timestamp, "Pair: BEFORE_EXPIRY");
        _transfer(address(this), msg.sender, addressToLockupAmount[msg.sender]);
        emit Unlock(msg.sender, addressToLockupAmount[msg.sender]);
        addressToLockupAmount[msg.sender] = 0;
        addressToLockupExpiry[msg.sender] = 0;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "Pair: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "Pair: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "Pair: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Pair: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) ILinkswapCallee(to).linkswapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
            if (ILinkswapFactory(factory).maxSlippagePercent() > 0) {
                uint256 currentPrice = balance0.mul(1e18) / balance1;
                if (priceAtLastSlippageBlocks == 0) {
                    priceAtLastSlippageBlocks = currentPrice;
                    lastSlippageBlocks = block.number;
                } else {
                    bool resetSlippage = lastSlippageBlocks.add(ILinkswapFactory(factory).maxSlippageBlocks()) <
                        block.number;
                    uint256 lastPrice = resetSlippage ? lastSwapPrice : priceAtLastSlippageBlocks;
                    require(
                        currentPrice >=
                            lastPrice.mul(uint256(100).sub(ILinkswapFactory(factory).maxSlippagePercent())) / 100 &&
                            currentPrice <=
                            lastPrice.mul(uint256(100).add(ILinkswapFactory(factory).maxSlippagePercent())) / 100,
                        "Pair: SlipLock"
                    );
                    if (resetSlippage) {
                        priceAtLastSlippageBlocks = currentPrice;
                        lastSlippageBlocks = block.number;
                    }
                }
                lastSwapPrice = currentPrice;
            }
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "Pair: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for balance{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1e6).sub(amount0In.mul(tradingFeePercent));
            uint256 balance1Adjusted = balance1.mul(1e6).sub(amount1In.mul(tradingFeePercent));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(1e6**2), "Pair: K");
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external override nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _setTradingFeePercent(uint256 _tradingFeePercent) private {
        // max 1%
        require(_tradingFeePercent <= 10000, "Pair: INVALID_TRADING_FEE_PERCENT");
        tradingFeePercent = _tradingFeePercent;
    }

    function setTradingFeePercent(uint256 _tradingFeePercent) external override onlyGovernance {
        _setTradingFeePercent(_tradingFeePercent);
    }
}