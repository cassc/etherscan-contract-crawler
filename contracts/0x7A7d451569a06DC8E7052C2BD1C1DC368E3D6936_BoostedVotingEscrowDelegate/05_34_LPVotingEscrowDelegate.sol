// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./VotingEscrowDelegate.sol";
import "./interfaces/IVotingEscrowMigrator.sol";

contract LPVotingEscrowDelegate is VotingEscrowDelegate {
    using SafeERC20 for IERC20;

    bool internal immutable isToken1;
    uint256 public immutable minAmount;
    uint256 public immutable maxBoost;

    uint256 public lockedTotal;
    mapping(address => uint256) public locked;

    event Withdraw(address indexed account, uint256 amount);

    constructor(
        address _lpToken,
        address _ve,
        address _discountToken,
        bool _isToken1,
        uint256 _minAmount,
        uint256 _maxBoost
    ) VotingEscrowDelegate(_lpToken, _ve, _discountToken) {
        isToken1 = _isToken1;
        minAmount = _minAmount;
        maxBoost = _maxBoost;
    }

    function _createLock(
        uint256 amount,
        uint256 duration,
        bool discounted
    ) internal override {
        require(amount >= minAmount, "LSVED: AMOUNT_TOO_LOW");

        super._createLock(amount, duration, discounted);

        lockedTotal += amount;
        locked[msg.sender] += amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _increaseAmount(uint256 amount, bool discounted) internal override {
        require(amount >= minAmount, "LSVED: AMOUNT_TOO_LOW");

        super._increaseAmount(amount, discounted);

        lockedTotal += amount;
        locked[msg.sender] += amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _getAmounts(uint256 amount, uint256)
        internal
        view
        override
        returns (uint256 amountVE, uint256 amountToken)
    {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(token).getReserves();
        uint256 reserve = isToken1 ? uint256(reserve1) : uint256(reserve0);

        uint256 totalSupply = IUniswapV2Pair(token).totalSupply();
        uint256 _amountToken = (amount * reserve) / totalSupply;

        amountVE = _amountToken + (_amountToken * maxBoost * (totalSupply - lockedTotal)) / totalSupply / totalSupply;
        uint256 upperBound = (_amountToken * 333) / 10;
        if (amountVE > upperBound) {
            amountVE = upperBound;
        }
        amountToken = 0;
    }

    function withdraw() external {
        uint256 unlockTime;
        if (IVotingEscrow(ve).migrated(msg.sender)) {
            unlockTime = IVotingEscrowMigrator(IVotingEscrow(ve).migrator()).unlockTime(msg.sender);
        } else {
            unlockTime = IVotingEscrow(ve).unlockTime(msg.sender);
        }
        require(unlockTime == 0, "LSVED: EXISTING_LOCK_FOUND");

        uint256 amount = locked[msg.sender];
        require(amount > 0, "LSVED: LOCK_NOT_FOUND");

        lockedTotal -= amount;
        locked[msg.sender] = 0;
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }
}