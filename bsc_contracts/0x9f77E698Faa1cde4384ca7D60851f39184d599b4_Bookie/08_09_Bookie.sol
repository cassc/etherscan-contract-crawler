// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract Bookie is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    enum Outcome {
        None,
        One,
        Two,
        Tie
    }

    enum PoolStatus {
        Open,
        Settled,
        Canceled
    }

    struct MatchData {
        string outcomeOne;
        string outcomeTwo;
        string description;
        uint256 startTime;
        uint256 endTime;
    }

    struct Pool {
        uint256 index;
        uint256 opensAt;
        uint256 closesAt;
        bool tiePossible;
        MatchData matchData;
        PoolStatus status;
        Outcome outcome;
        address currency;
        uint256 totalBets;
        uint256 totalWithdrawn;
    }
    Pool[] public pools;

    struct PoolOdds {
        uint256 one;
        uint256 two;
        uint256 tie;
    }

    // playerBets[address][poolIndex][outcome] -> amount
    mapping(address => mapping(uint256 => mapping(Outcome => uint256)))
        public playerBets;

    //playerPoolWithdrawn[address][poolIndex] -> withdrawn
    mapping(address => mapping(uint256 => bool)) public playerPoolWithdrawn;

    // poolBets[poolIndex][outcome] -> amount
    mapping(uint256 => mapping(Outcome => uint256)) public poolBets;

    event PoolCreated(
        uint256 indexed index,
        address currency,
        uint256 opensAt,
        uint256 closesAt
    );
    event PoolSettled(uint256 indexed index, uint256 outcome);
    event PoolCanceled(uint256 indexed index);

    event PoolClosesAtChanged(uint256 indexed index, uint256 time);
    event PoolOpensAtChanged(uint256 indexed index, uint256 time);

    event BetPlaced(
        address indexed by,
        uint256 indexed poolIndex,
        uint256 outcome,
        uint256 amount
    );

    event WinningsClaimed(
        address indexed by,
        uint256 indexed poolIndex,
        uint256 amount
    );

    event ReturnsClaimed(
        address indexed by,
        uint256 indexed poolIndex,
        uint256 amount
    );

    mapping(address => uint256) public totalBetAmount;
    mapping(address => mapping(address => uint256)) public userTotalBetAmount;

    /*
     * Pools
     */
    function createPool(
        MatchData calldata _matchData,
        uint256 _opensAt,
        uint256 _closesAt,
        bool _tiePossible,
        address _currency
    ) public onlyOwner {
        Pool memory _pool;

        _pool.opensAt = _opensAt;
        _pool.closesAt = _closesAt;
        _pool.tiePossible = _tiePossible;
        _pool.matchData = _matchData;
        _pool.index = pools.length;
        _pool.currency = _currency;

        pools.push(_pool);

        emit PoolCreated(_pool.index, _currency, _opensAt, _closesAt);
    }

    // TODO: comment unsafe if array is large
    function getAllPools() public view returns (Pool[] memory) {
        return pools;
    }

    function getPoolsLength() public view returns (uint256) {
        return pools.length;
    }

    function setClosesAt(uint256 _index, uint256 _time) external onlyOwner {
        Pool storage _pool = pools[_index];
        _pool.closesAt = _time;
        emit PoolClosesAtChanged(_index, _time);
    }

    function setOpensAt(uint256 _index, uint256 _time) external onlyOwner {
        Pool storage _pool = pools[_index];
        _pool.opensAt = _time;
        emit PoolOpensAtChanged(_index, _time);
    }

    function settlePool(uint256 _index, Outcome _outcome) public onlyOwner {
        Pool storage _pool = pools[_index];
        require(
            _pool.tiePossible || _outcome != Outcome.Tie,
            "Tie not possible"
        );
        require(_pool.status != PoolStatus.Canceled, "Pool already canceled");

        _pool.outcome = _outcome;
        _pool.status = PoolStatus.Settled;

        emit PoolSettled(_index, uint256(_outcome));
    }

    function cancelPool(uint256 _index) public onlyOwner {
        Pool storage _pool = pools[_index];

        require(_pool.status != PoolStatus.Settled, "Pool already settled");
        _pool.status = PoolStatus.Canceled;

        emit PoolCanceled(_index);
    }

    function placeBet(
        uint256 _index,
        Outcome _outcome,
        uint256 _amount
    ) public payable nonReentrant {
        Pool storage pool = pools[_index];

        require(block.timestamp > pool.opensAt, "Pool not open yet");
        require(block.timestamp < pool.closesAt, "Pool closed");
        require(pool.status == PoolStatus.Open, "Pool not active");
        require(_outcome != Outcome.None, "Invalid outcome");
        require(
            pool.tiePossible || _outcome != Outcome.Tie,
            "Tie not possible"
        );

        _transferFromSender(pool.currency, _amount);

        poolBets[_index][_outcome] += _amount;
        playerBets[msg.sender][_index][_outcome] += _amount;
        pool.totalBets += _amount;

        totalBetAmount[pool.currency] += _amount;
        userTotalBetAmount[msg.sender][pool.currency] += _amount;

        emit BetPlaced(msg.sender, _index, uint256(_outcome), _amount);
    }

    function getPlayerBets(
        address _address,
        uint256 _index
    ) public view returns (uint256 one, uint256 two, uint256 tie) {
        one = playerBets[_address][_index][Outcome.One];
        two = playerBets[_address][_index][Outcome.Two];
        tie = playerBets[_address][_index][Outcome.Tie];
    }

    function getPoolBets(
        uint256 _index
    ) public view returns (uint256 one, uint256 two, uint256 tie) {
        one = poolBets[_index][Outcome.One];
        two = poolBets[_index][Outcome.Two];
        tie = poolBets[_index][Outcome.Tie];
    }

    function claim(uint256 _index) public nonReentrant {
        Pool storage pool = pools[_index];

        require(
            pool.status == PoolStatus.Settled ||
                pool.status == PoolStatus.Canceled,
            "Not in claimable state"
        );

        require(!playerPoolWithdrawn[msg.sender][_index], "Already withdrawn");

        pool.status == PoolStatus.Settled
            ? _claimWinnings(pool)
            : _claimCanceled(pool);

        playerPoolWithdrawn[msg.sender][_index] = true;
    }

    function getWinnings(
        address _address,
        uint256 _index
    ) public view returns (uint256) {
        Pool storage pool = pools[_index];
        return _getWinnings(_address, pool);
    }

    function _claimWinnings(Pool storage pool) internal {
        uint256 winningAmount = _getWinnings(msg.sender, pool);

        pool.totalWithdrawn += winningAmount;
        _transferToSender(pool.currency, winningAmount);

        emit WinningsClaimed(msg.sender, pool.index, winningAmount);
    }

    function _getWinnings(
        address _address,
        Pool storage pool
    ) internal view returns (uint256) {
        if (pool.status != PoolStatus.Settled) return 0;

        uint256 betAmount = playerBets[_address][pool.index][pool.outcome];

        uint256 totalBetsOnWinningOutcome = poolBets[pool.index][pool.outcome];

        uint256 winningAmount = (betAmount * pool.totalBets) /
            totalBetsOnWinningOutcome;

        return winningAmount;
    }

    function _claimCanceled(Pool storage pool) internal {
        mapping(Bookie.Outcome => uint256) storage playerPoolBets = playerBets[
            msg.sender
        ][pool.index];

        uint256 returnAmount = playerPoolBets[Outcome.One] +
            playerPoolBets[Outcome.Two] +
            playerPoolBets[Outcome.Tie];

        pool.totalWithdrawn += returnAmount;
        _transferToSender(pool.currency, returnAmount);

        emit ReturnsClaimed(msg.sender, pool.index, returnAmount);
    }

    function _transferFromSender(address currency, uint256 amount) internal {
        if (currency == NATIVE) {
            require(msg.value == amount, "Value mismatch");
            return;
        }

        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _transferToSender(address currency, uint256 amount) internal {
        if (currency == NATIVE) {
            (bool sent, ) = msg.sender.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20(currency).safeTransfer(
                msg.sender,
                amount
            );
        }
    }

    //////////
    // Token withdrawals
    //////////
    function withdrawERC20(
        IERC20 _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        uint256 _toWithdraw = _amount == 0
            ? _tokenAddress.balanceOf(address(this))
            : _amount;
        _tokenAddress.safeTransfer(_to, _toWithdraw);
    }

    function withdrawNative(address _to, uint256 _amount) external onlyOwner {
        uint256 _toWithdraw = _amount == 0 ? address(this).balance : _amount;
        (bool sent, ) = payable(_to).call{value: _toWithdraw}("");
        require(sent, "Failed to send Ether");
    }
}