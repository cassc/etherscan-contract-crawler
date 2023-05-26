// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'Math.sol';
import 'SafeMath.sol';
import 'TransferHelper.sol';
import 'Votes.sol';
import 'IIntegralStaking.sol';
import 'IIntegralToken.sol';

contract IntegralStaking is IIntegralStaking, Votes {
    using SafeMath for uint32;
    using SafeMath for uint96;
    using SafeMath for uint256;
    using TransferHelper for address;

    address public override owner;
    address public immutable override integralToken;
    uint32 public immutable override durationInBlocks;
    uint32 public override stopBlock;
    uint32 public immutable override ratePerBlockNumerator;
    uint32 public immutable override ratePerBlockDenominator;

    mapping(address => UserStake[]) public userStakes;

    constructor(
        address _integralToken,
        uint32 _durationInBlocks,
        uint32 _ratePerBlockNumerator,
        uint32 _ratePerBlockDenominator
    ) {
        owner = msg.sender;
        integralToken = _integralToken;
        durationInBlocks = _durationInBlocks;
        ratePerBlockNumerator = _ratePerBlockNumerator;
        ratePerBlockDenominator = _ratePerBlockDenominator;
    }

    function getUserStakes(address _user) external view override returns (UserStake[] memory) {
        return userStakes[_user];
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'IS_FORBIDDEN');
        owner = _owner;
    }

    function stopIssuance(uint32 _stopBlock) external override {
        require(msg.sender == owner, 'IS_FORBIDDEN');
        require(_stopBlock >= block.number, 'IS_INVALID_INPUT');
        require(stopBlock == 0, 'IS_ALREADY_STOPPED');

        stopBlock = _stopBlock;
        emit StopIssuance(_stopBlock);
    }

    function deposit(uint96 _amount) external override returns (uint256 stakeId) {
        require(_amount > 0, 'IS_INVALID_AMOUNT');
        require(stopBlock == 0 || stopBlock > block.number, 'IS_ALREADY_STOPPED');

        address user = msg.sender;

        // deposit token to contract
        integralToken.safeTransferFrom(user, address(this), _amount);

        // add a new stake
        UserStake memory userStake;
        userStake.startBlock = block.number.toUint32();
        userStake.lockedAmount = _amount;
        userStakes[user].push(userStake);

        stakeId = userStakes[user].length - 1;

        _updateVotes(address(0), user, _amount);

        emit Deposit(user, stakeId, _amount);
    }

    function withdrawAll(address _to) external override {
        require(_to != address(0), 'IS_ADDRESS_ZERO');

        address user = msg.sender;
        uint96 withdrawnAmount;
        uint256 length = userStakes[user].length;
        for (uint256 i = 0; i < length; i++) {
            UserStake memory userStake = userStakes[user][i];
            uint256 endBlock = _calculateStopBlock(userStake.startBlock);
            if (endBlock < block.number && userStake.withdrawn == false) {
                withdrawnAmount = withdrawnAmount.add96(userStake.lockedAmount);
                userStakes[user][i].withdrawn = true;
            }
        }

        _finalizeWithdraw(user, _to, withdrawnAmount);

        emit WithdrawAll(user, withdrawnAmount, _to);
    }

    function withdraw(uint256 _stakeId, address _to) external override {
        require(_to != address(0), 'IS_ADDRESS_ZERO');

        address user = msg.sender;
        require(userStakes[user].length > _stakeId, 'IS_INVALID_ID');

        UserStake memory userStake = userStakes[user][_stakeId];

        uint256 endBlock = _calculateStopBlock(userStake.startBlock);
        require(endBlock <= block.number, 'IS_LOCKED');
        require(userStake.withdrawn == false, 'IS_ALREADY_WITHDRAWN');

        uint96 withdrawnAmount = userStake.lockedAmount;

        userStakes[user][_stakeId].withdrawn = true;

        _finalizeWithdraw(user, _to, withdrawnAmount);

        emit Withdraw(user, _stakeId, withdrawnAmount, _to);
    }

    function _finalizeWithdraw(
        address user,
        address to,
        uint96 withdrawnAmount
    ) internal {
        _updateVotes(user, address(0), withdrawnAmount);
        integralToken.safeTransfer(to, withdrawnAmount);
    }

    function claimAll(address _to) external override {
        require(_to != address(0), 'IS_ADDRESS_ZERO');

        address user = msg.sender;
        uint96 claimedAmount;
        uint32 currentBlock = block.number.toUint32();
        uint256 length = userStakes[user].length;
        for (uint256 i = 0; i < length; i++) {
            uint96 _getClaimableAmount = _getClaimable(user, i);
            if (_getClaimableAmount != 0) {
                claimedAmount = claimedAmount.add96(_getClaimableAmount);
                userStakes[user][i].claimedBlock = currentBlock;
            }
        }

        IIntegralToken(integralToken).mint(_to, claimedAmount);

        emit ClaimAll(user, claimedAmount, _to);
    }

    function claim(uint256 _stakeId, address _to) external override {
        require(_to != address(0), 'IS_ADDRESS_ZERO');

        address user = msg.sender;
        require(userStakes[user].length > _stakeId, 'IS_INVALID_ID');

        uint96 claimedAmount = _getClaimable(user, _stakeId);
        require(claimedAmount != 0, 'IS_ALREADY_CLAIMED');

        userStakes[user][_stakeId].claimedBlock = block.number.toUint32();

        IIntegralToken(integralToken).mint(_to, claimedAmount);

        emit Claim(user, _stakeId, claimedAmount, _to);
    }

    function getAllClaimable(address user) external view override returns (uint96 claimableAmount) {
        uint256 length = userStakes[user].length;
        for (uint256 i = 0; i < length; i++) {
            claimableAmount = claimableAmount.add96(_getClaimable(user, i));
        }
    }

    function getClaimable(address _user, uint256 _stakeId) external view override returns (uint96) {
        require(userStakes[_user].length > _stakeId, 'IS_INVALID_ID');

        return _getClaimable(_user, _stakeId);
    }

    function getUserStakesCount(address user) external view returns (uint256) {
        return userStakes[user].length;
    }

    function getTotalStaked(address user) external view returns (uint96) {
        return checkpoints[user][checkpointsLength[user] - 1].votes;
    }

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96) {
        return _getPriorVotes(account, blockNumber);
    }

    function _getClaimable(address user, uint256 stakeId) internal view returns (uint96 claimableAmount) {
        UserStake memory userStake = userStakes[user][stakeId];

        uint256 fromBlock = Math.max(userStake.startBlock, userStake.claimedBlock);
        uint256 toBlock = Math.min(block.number, _calculateStopBlock(userStake.startBlock));

        if (fromBlock < toBlock) {
            claimableAmount = userStake
                .lockedAmount
                .mul(ratePerBlockNumerator)
                .mul(toBlock.sub(fromBlock))
                .div(ratePerBlockDenominator)
                .toUint96();
        }
    }

    function _calculateStopBlock(uint32 startBlock) internal view returns (uint256) {
        uint256 endBlock = startBlock.add(durationInBlocks);
        return (stopBlock == 0 || endBlock < stopBlock) ? endBlock : stopBlock;
    }
}