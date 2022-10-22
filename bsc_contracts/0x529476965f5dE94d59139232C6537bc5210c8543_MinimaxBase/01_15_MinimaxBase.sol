// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../pool/IPoolAdapter.sol";
import "../ProxyCaller.sol";
import "./ProxyLib.sol";
import "../IProxyOwner.sol";
import "./IToken.sol";
import "./IMinimaxBase.sol";
import "../helpers/RevertLib.sol";

contract MinimaxBase is OwnableUpgradeable, ReentrancyGuardUpgradeable, IMinimaxBase {
    using SafeERC20Upgradeable for IToken;
    using ProxyLib for IProxyOwner;

    struct Position {
        bool open;
        address owner;
        address pool;
        bytes poolArgs;
        ProxyCaller proxy;
        uint stakeAmount;
        uint feeAmount;
        IToken stakeToken;
        IToken[] rewardTokens;
    }

    struct PositionBalance {
        uint stakeAmount;
        uint poolStakeAmount;
        uint[] poolRewardAmounts;
    }

    // store

    uint public minimaxFee;
    uint public constant FEE_MULTIPLIER = 1e8;

    uint public lastPositionIndex;
    mapping(uint => Position) public positions;
    mapping(uint => IPoolAdapter) public poolAdapters;

    IProxyOwner public proxyOwner;

    // modifiers
    modifier onlyPositionOwner(uint positionIndex) {
        require(positions[positionIndex].owner != address(0), "position not created");
        require(positions[positionIndex].owner == msg.sender, "not position owner");
        require(positions[positionIndex].open, "position closed");
        _;
    }

    // initializer
    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    // management functions

    function setMinimaxFee(uint val) external onlyOwner {
        minimaxFee = val;
    }

    function getPoolAdapter(address pool) public view returns (IPoolAdapter) {
        uint key = uint(keccak256(pool.code));
        IPoolAdapter adapter = poolAdapters[key];
        require(address(adapter) != address(0), "getPoolAdapter: zero address");
        return adapter;
    }

    function getPoolAdapters(address[] calldata pools)
        public
        view
        returns (IPoolAdapter[] memory adapters, uint[] memory keys)
    {
        keys = new uint[](pools.length);
        adapters = new IPoolAdapter[](pools.length);

        for (uint i = 0; i < pools.length; i++) {
            uint key = uint(keccak256(pools[i].code));
            keys[i] = key;
            adapters[i] = poolAdapters[key];
        }
    }

    function setPoolAdapters(address[] calldata pools, IPoolAdapter[] calldata adapters) external onlyOwner {
        require(pools.length == adapters.length, "pools and adapters parameters should have the same length");
        for (uint32 i = 0; i < pools.length; i++) {
            uint key = uint(keccak256(pools[i].code));
            poolAdapters[key] = adapters[i];
        }
    }

    function setLastPositionIndex(uint value) external onlyOwner {
        require(value >= lastPositionIndex, "lastPositionIndex can only be increased");
        lastPositionIndex = value;
    }

    function setProxyOwner(IProxyOwner _proxyOwner) external onlyOwner {
        proxyOwner = _proxyOwner;
    }

    // getters

    function getPosition(uint positionIndex) public view returns (Position memory) {
        return positions[positionIndex];
    }

    function getBalanceRevert(uint positionIndex) external {
        Position storage position = positions[positionIndex];

        PositionBalance memory balance;
        if (position.open) {
            IPoolAdapter adapter = getPoolAdapter(position.pool);
            balance.stakeAmount = position.stakeAmount;
            balance.poolStakeAmount = proxyOwner.stakeBalance(
                position.proxy,
                adapter,
                position.pool,
                position.poolArgs
            );
            balance.poolRewardAmounts = proxyOwner.rewardBalances(
                position.proxy,
                adapter,
                position.pool,
                position.poolArgs
            );
        }

        RevertLib.revertBytes(abi.encode(balance));
    }

    function getBalance(uint positionIndex) external returns (PositionBalance memory balance) {
        try this.getBalanceRevert(positionIndex) {} catch (bytes memory revertData) {
            return abi.decode(revertData, (PositionBalance));
        }
    }

    function getFee(uint amount) public view returns (uint) {
        return (amount * minimaxFee) / FEE_MULTIPLIER;
    }

    function getPoolTokens(address pool, bytes calldata poolArgs) private returns (IToken, IToken[] memory) {
        IPoolAdapter adapter = getPoolAdapter(pool);
        IToken stakeToken = IToken(adapter.stakedToken(pool, poolArgs));

        IToken[] memory rewardTokens;
        address[] memory rewardAddresses = adapter.rewardTokens(pool, poolArgs);
        // use assembly to force type cast address[] to IToken[]
        assembly {
            rewardTokens := rewardAddresses
        }

        return (stakeToken, rewardTokens);
    }

    // position functions

    function create(
        address pool,
        bytes calldata poolArgs,
        IToken token,
        uint amount
    ) public nonReentrant returns (uint) {
        require(amount > 0, "create: amount");

        // get pool adapter and validate that staked tokens match
        IPoolAdapter adapter = getPoolAdapter(pool);
        (IToken stakeToken, IToken[] memory rewardTokens) = getPoolTokens(pool, poolArgs);
        require(stakeToken == token, "create: stake token mismatch");

        // transfer from sender
        token.safeTransferFrom(msg.sender, address(this), amount);

        // apply fee
        uint fee = getFee(amount);
        amount = amount - fee;

        // create proxy and deposit pool on behalf of that proxy
        ProxyCaller proxy = proxyOwner.acquireProxy();
        _depositProxy(proxy, token, amount, pool, poolArgs);

        // save position
        lastPositionIndex += 1;
        positions[lastPositionIndex] = Position({
            open: true,
            owner: msg.sender,
            pool: pool,
            poolArgs: poolArgs,
            proxy: proxy,
            stakeAmount: amount,
            feeAmount: fee,
            stakeToken: token,
            rewardTokens: rewardTokens
        });

        return lastPositionIndex;
    }

    function deposit(uint positionIndex, uint amount) public nonReentrant onlyPositionOwner(positionIndex) {
        Position storage position = positions[positionIndex];

        // transfer from sender
        position.stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        // apply fee
        uint fee = getFee(amount);
        amount = amount - fee;

        // transfer to pool
        IPoolAdapter adapter = getPoolAdapter(position.pool);
        _depositProxy(position.proxy, position.stakeToken, amount, position.pool, position.poolArgs);

        position.stakeAmount += amount;
        position.feeAmount += fee;

        _drainProxyTokens(position);
    }

    function _depositProxy(
        ProxyCaller proxy,
        IToken token,
        uint amount,
        address pool,
        bytes memory poolArgs
    ) private {
        IPoolAdapter adapter = getPoolAdapter(pool);
        token.transfer(address(proxy), amount);
        proxyOwner.approve(proxy, token, pool, amount);
        proxyOwner.deposit(proxy, adapter, pool, poolArgs, amount);
    }

    // Withdraws specified amount from pool to msg.sender
    // If pool balance after withdraw equals zero then position is closed
    function withdraw(
        uint positionIndex,
        uint amount,
        bool amountAll
    ) public nonReentrant onlyPositionOwner(positionIndex) returns (bool closed) {
        Position storage position = positions[positionIndex];

        IPoolAdapter adapter = getPoolAdapter(position.pool);
        if (amountAll) {
            proxyOwner.withdrawAll(position.proxy, adapter, position.pool, position.poolArgs);
            _drainProxyTokens(position);
            _closePosition(position);
            return true;
        }

        proxyOwner.withdraw(position.proxy, adapter, position.pool, position.poolArgs, amount);
        _drainProxyTokens(position);

        uint poolBalance = proxyOwner.stakeBalance(position.proxy, adapter, position.pool, position.poolArgs);
        if (poolBalance == 0) {
            _closePosition(position);
            return true;
        }

        // When user withdraws partially, stakedAmount should only decrease
        //
        // Consider the following case:
        // position.stakedAmount = 100
        // pool.stakingBalance = 120
        //
        // If user withdraws 10, then:
        // position.stakedAmount = 100
        // pool.stakingBalance = 110
        //
        // If user withdraws 30, then:
        // position.stakedAmount = 90
        // pool.stakingBalance = 90
        //
        if (poolBalance < position.stakeAmount) {
            position.stakeAmount = poolBalance;
        }

        return false;
    }

    // private

    function _drainProxyTokens(Position storage position) private {
        proxyOwner.transferAll(position.proxy, position.stakeToken, msg.sender);
        IToken[] memory rewardTokens = position.rewardTokens;
        for (uint i = 0; i < rewardTokens.length; i++) {
            proxyOwner.transferAll(position.proxy, rewardTokens[i], msg.sender);
        }
    }

    function _closePosition(Position storage position) private {
        position.open = false;

        // When position is closed stakeAmount should store the value before the last withdraw
        // Frontend relies on that
        // position.stakeAmount = 0;

        proxyOwner.releaseProxy(position.proxy);
    }
}