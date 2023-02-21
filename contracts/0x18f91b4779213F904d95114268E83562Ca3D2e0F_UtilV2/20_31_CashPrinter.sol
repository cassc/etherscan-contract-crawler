// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../foundation/FoundBank.sol";
import "../art/ArtToken.sol";
import "./Cash.sol";

struct CashStake {
    uint id;
    uint artId;
    uint shares;
    uint amount;
    uint interest;
    address delegate;
    uint[] coinIds;
    uint[] amounts;
    uint stakedAt;
    uint unstakedAt;
}

struct CashStakeParams {
    address depositor;
    address minter;
    address delegate;
    uint artId;
    uint[] coinIds;
    uint[] amounts;
}

contract CashPrinter is ArtToken {
    Cash private _cash;
    DailyMint private _bank;
    FoundNote private _note;

    uint private _totalCash;
    uint private _tokenCount;
    uint private _totalShares;
    uint private _totalStaked;

    uint public constant EXTRA_COINS = 10;
    uint public constant DAY_DURATION = 1 days;
    uint public constant MAX_DURATION = 365 days;

    mapping(uint => CashStake) private _stakes;

    event Stake(
        uint indexed tokenId,
        address indexed minter,
        address indexed depositor,
        uint artId,
        uint shares,
        uint amount,
        address delegate,
        uint timestamp
    );

     event Unstake(
        uint indexed tokenId,
        address indexed minter,
        address indexed withdrawer,
        uint artId,
        uint shares,
        uint amount,
        uint interest,
        address delegate,
        uint timestamp
    );

    event Delegate(
        uint indexed tokenId,
        address indexed delegate,
        uint timestamp
    );

    function cash() external view returns (Cash) {
        return _cash;
    }

    function bank() external view returns (DailyMint) {
        return _bank;
    }

    function note() external view returns (FoundNote) {
        return _note;
    }

    function tokenCount() external view returns (uint) {
        return _tokenCount;
    }

    function totalCash() external view returns (uint) {
        return _totalCash;
    }

    function totalShares() external view returns (uint) {
        return _totalShares;
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }

    function tokenToArt(uint tokenId) external view returns (uint) {
        return _tokenToArt(tokenId);
    }

    function getStake(uint tokenId) external view returns (CashStake memory) {
        _requireStakeId(tokenId);
        return _stakes[tokenId];
    }

    function stake(CashStakeParams calldata params) external returns (uint) {
        _requireArt(params.artId);

        require(
            params.coinIds.length == params.amounts.length,
            "Invalid stake"
        );

        uint amount; uint count;
        (amount, count) = _sumAmounts(params.amounts);
        uint shares = calculateShares(amount, count);

        require(
            amount > 0 && count > 0,
            "Invalid stake"
        );

        _bank.safeBatchTransferFrom(
            params.depositor,
            address(this),
            params.coinIds,
            params.amounts,
            new bytes(0)
        );

        CashStake storage d = _stakes[++_tokenCount];

        d.id = _tokenCount;
        d.artId = params.artId;
        d.shares = shares;
        d.amount = amount;
        d.delegate = params.delegate;
        d.coinIds = params.coinIds;
        d.amounts = params.amounts;
        d.stakedAt = block.timestamp;

        _totalShares += shares;
        _totalStaked += amount;

        _safeMint(
            params.minter,
            _tokenCount
        );

        emit Stake(
            _tokenCount,
            params.minter,
            params.depositor,
            params.artId,
            shares,
            amount,
            params.delegate,
            block.timestamp
        );

        return _tokenCount;
    }

    function unstake(uint id, address minter, address withdrawer) external returns (uint) {
        _requireStakeId(id);

        address owner = ownerOf(id);
        CashStake storage d = _stakes[id];

        require(
            msg.sender == owner || msg.sender == d.delegate,
            "Caller is not the owner or delegate"
        );

        require(
            d.unstakedAt == 0,
            "Stake already withdrawn"
        );

        uint duration = block.timestamp - d.stakedAt;
        uint interest = calculateInterest(d.shares, duration);

        d.interest = interest;
        d.unstakedAt = block.timestamp;

        _totalCash += d.interest;
        _totalStaked -= d.amount;
        _totalShares -= d.shares;

        _bank.safeBatchTransferFrom(
            address(this),
            withdrawer,
            d.coinIds,
            d.amounts,
            new bytes(0)
        );

        _cash.mint(minter, d.interest);

        emit Unstake(
            id,
            minter,
            withdrawer,
            d.artId,
            d.shares,
            d.amount,
            interest,
            d.delegate,
            block.timestamp
        );

        return d.interest;
    }

    function delegate(uint tokenId, address to) external {
        _requireStakeId(tokenId);

        CashStake storage d = _stakes[tokenId];

        require(
            msg.sender == ownerOf(tokenId) ||
            msg.sender == d.delegate,
            "Caller is not the owner or delegate"
        );

        d.delegate = to;

        emit Delegate(
            tokenId,
            to,
            block.timestamp
        );
    }

    function calculateInterest(uint shares, uint duration) public pure returns (uint) {
        if (duration > MAX_DURATION) {
            return shares * MAX_DURATION / DAY_DURATION;
        }

        return shares * duration / DAY_DURATION;
    }

    function calculateShares(uint total, uint count) public pure returns (uint) {
        uint shares = total / 10000;
        uint bonus = _calculateBonus(shares, count);
        return shares + bonus;
    }

    function _calculateBonus(uint interest, uint coinCount) internal pure returns (uint) {
        uint bonus = coinCount < EXTRA_COINS
            ? interest * coinCount / EXTRA_COINS
            : interest;

        return bonus * 2 / 10;
    }

    function _sumAmounts(uint[] memory amounts) internal pure returns (uint, uint) {
        uint count = amounts.length;
        uint total = 0;

        for (uint i = 0; i < count; i++) {
            total += amounts[i];
        }

        return (total, count);
    }

    function _tokenToArt(uint tokenId) override internal view returns (uint) {
        _requireStakeId(tokenId);
        return _stakes[tokenId].artId;
    }

    function _requireStakeId(uint id) internal view {
        require(
            id > 0 && id <= _tokenCount,
            "Stake not found"
        );
    }

    function _requireArt(uint id) internal view {
        require(
            id > 0 && id <= _data.tokenCount(),
            "Art not found"
        );
    }

    constructor(FoundBank bank_, ArtData data_)
    ArtToken("Namespace Stake", "STAKE", data_) {
        _cash = new Cash(address(this));
        _bank = bank_.bank();
        _note = bank_.note();
    }
}