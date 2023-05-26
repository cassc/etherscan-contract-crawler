// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'Math.sol';
import 'SafeMath.sol';
import 'TransferHelper.sol';
import 'IERC20.sol';
import 'IIntegralMerkleTimeRelease.sol';
import 'Votes.sol';
import 'MerkleProof.sol';

contract IntegralMerkleTimeRelease is IIntegralMerkleTimeRelease, Votes {
    using SafeMath for uint256;
    using SafeMath for uint96;

    address public immutable token;
    bytes32 public immutable merkleRoot;
    address public owner;

    uint96 public option1TotalAllocations;
    uint96 public option2TotalAllocations;
    uint96 public option1TotalClaimed;
    uint96 public option2TotalClaimed;

    struct Option {
        uint96 allocation;
        uint96 claimed;
        uint32 initBlock;
    }

    mapping(address => Option) public option1;
    mapping(address => Option) public option2;

    uint256 public option1StartBlock;
    uint256 public option1EndBlock;
    uint256 public option1StopBlock;

    uint256 public option2StartBlock;
    uint256 public option2EndBlock;
    uint256 public option2StopBlock;

    uint256 public option1StopSetBlock;
    uint256 public option2StopSetBlock;

    constructor(
        address _token,
        bytes32 _merkleRoot,
        uint256 _option1StartBlock,
        uint256 _option1EndBlock,
        uint256 _option2StartBlock,
        uint256 _option2EndBlock
    ) {
        owner = msg.sender;
        emit OwnerSet(owner);
        token = _token;
        merkleRoot = _merkleRoot;
        _setOption1Timeframe(_option1StartBlock, _option1EndBlock);
        _setOption2Timeframe(_option2StartBlock, _option2EndBlock);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function _setOption1Timeframe(uint256 _option1StartBlock, uint256 _option1EndBlock) internal {
        require(_option1EndBlock > _option1StartBlock, 'MR_INVALID_OPTION1_TIME_FRAME');
        option1StartBlock = _option1StartBlock;
        option1EndBlock = _option1EndBlock;
        option1StopBlock = _option1EndBlock;
        option1StopSetBlock = _option1EndBlock;
    }

    function _setOption2Timeframe(uint256 _option2StartBlock, uint256 _option2EndBlock) internal {
        require(_option2EndBlock > _option2StartBlock, 'MR_INVALID_OPTION2_TIME_FRAME');
        option2StartBlock = _option2StartBlock;
        option2EndBlock = _option2EndBlock;
        option2StopBlock = _option2EndBlock;
        option2StopSetBlock = _option2EndBlock;
    }

    function initializeAndClaim(
        address to,
        uint96 amount1,
        uint96 amount2,
        bytes32[] calldata merkleProof
    ) external {
        if (option1[msg.sender].allocation == 0 && option2[msg.sender].allocation == 0) {
            initializeAllocations(msg.sender, amount1, amount2, merkleProof);
        }

        claim(to);
    }

    function initializeAllocations(
        address wallet,
        uint96 amount1,
        uint96 amount2,
        bytes32[] calldata merkleProof
    ) public {
        require(
            option1StopSetBlock == option1EndBlock && option2StopSetBlock == option2EndBlock,
            'MR_STOP_ALREADY_SET'
        );
        require(
            option1[wallet].allocation == 0 && option2[wallet].allocation == 0,
            'MR_ALLOCATION_ALREADY_INITIALIZED'
        );

        bytes32 node = keccak256(abi.encodePacked(wallet, uint256(amount1), uint256(amount2)));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MR_INVALID_PROOF');

        uint32 initBlock = safe32(block.number);
        if (amount1 > 0) {
            option1[wallet].allocation = amount1;
            option1[wallet].initBlock = initBlock;
            option1TotalAllocations = option1TotalAllocations.add96(amount1);
        }
        if (amount2 > 0) {
            option2[wallet].allocation = amount2;
            option2[wallet].initBlock = initBlock;
            option2TotalAllocations = option2TotalAllocations.add96(amount2);
        }
        require(IERC20(token).balanceOf(address(this)) >= getTokensLeft(), 'MR_INSUFFICIENT_BALANCE');
    }

    function updateOption1Allocations(address[] calldata wallets, uint96[] calldata amounts) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(option1StopSetBlock == option1EndBlock, 'MR_STOP_ALREADY_SET');
        require(wallets.length == amounts.length, 'MR_INVALID_LENGTHS');
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint96 amount = amounts[i];
            uint96 oldAmount = option1[wallet].allocation;
            require(oldAmount > 0, 'MR_ALLOCATION_NOT_SET');
            require(getReleasedOption1(wallet) <= amount, 'MR_ALLOCATION_TOO_SMALL');
            option1TotalAllocations = option1TotalAllocations.sub96(oldAmount).add96(amount);
            option1[wallet].allocation = amount;
            uint96 claimed = option1[wallet].claimed;
            if (checkpointsLength[wallet] != 0) {
                _updateVotes(wallet, address(0), oldAmount.sub96(claimed));
            }
            _updateVotes(address(0), wallet, amount.sub96(claimed));
        }
        require(IERC20(token).balanceOf(address(this)) >= getTokensLeft(), 'MR_INSUFFICIENT_BALANCE');
    }

    function updateOption2Allocations(address[] calldata wallets, uint96[] calldata amounts) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(option2StopSetBlock == option2EndBlock, 'MR_STOP_ALREADY_SET');
        require(wallets.length == amounts.length, 'MR_INVALID_LENGTHS');
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint96 amount = amounts[i];
            uint96 oldAmount = option2[wallet].allocation;
            require(oldAmount > 0, 'MR_ALLOCATION_NOT_SET');
            require(getReleasedOption2(wallet) <= amount, 'MR_ALLOCATION_TOO_SMALL');
            option2TotalAllocations = option2TotalAllocations.sub96(oldAmount).add96(amount);
            option2[wallet].allocation = amount;
            uint96 claimed = option2[wallet].claimed;
            if (checkpointsLength[wallet] != 0) {
                _updateVotes(wallet, address(0), oldAmount.sub96(claimed));
            }
            _updateVotes(address(0), wallet, amount.sub96(claimed));
        }
        require(IERC20(token).balanceOf(address(this)) >= getTokensLeft(), 'MR_INSUFFICIENT_BALANCE');
    }

    function getTokensLeft() public view returns (uint96) {
        uint256 allocationTime1 = option1EndBlock.sub(option1StartBlock);
        uint256 claimableTime1 = option1StopBlock.sub(option1StartBlock);
        uint256 allocation1 = option1TotalAllocations.mul(claimableTime1).div(allocationTime1);

        uint256 allocationTime2 = option2EndBlock.sub(option2StartBlock);
        uint256 claimableTime2 = option2StopBlock.sub(option2StartBlock);
        uint256 allocation2 = option2TotalAllocations.mul(claimableTime2).div(allocationTime2);

        return allocation1.add(allocation2).sub(option1TotalClaimed).sub(option2TotalClaimed).toUint96();
    }

    function setOption1StopBlock(uint256 _option1StopBlock) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(option1StopSetBlock == option1EndBlock, 'MR_STOP_ALREADY_SET');
        require(_option1StopBlock >= block.number && _option1StopBlock < option1EndBlock, 'MR_INVALID_BLOCK_NUMBER');
        option1StopBlock = _option1StopBlock;
        option1StopSetBlock = block.number;
        emit Option1StopBlockSet(_option1StopBlock);
    }

    function setOption2StopBlock(uint256 _option2StopBlock) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(option2StopSetBlock == option2EndBlock, 'MR_STOP_ALREADY_SET');
        require(_option2StopBlock >= block.number && _option2StopBlock < option2EndBlock, 'MR_INVALID_BLOCK_NUMBER');
        option2StopBlock = _option2StopBlock;
        option2StopSetBlock = block.number;
        emit Option2StopBlockSet(_option2StopBlock);
    }

    function skim(address to) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(to != address(0), 'MR_ADDRESS_ZERO');

        uint256 amount = getExcessTokens();
        TransferHelper.safeTransfer(token, to, amount);
        emit Skim(to, amount);
    }

    function getExcessTokens() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this)).sub(getTokensLeft());
    }

    function getReleasedOption1(address wallet) public view returns (uint96) {
        return _getReleasedOption1ForBlock(wallet, block.number);
    }

    function _getReleasedOption1ForBlock(address wallet, uint256 blockNumber) internal view returns (uint96) {
        if (blockNumber <= option1StartBlock) {
            return 0;
        }
        uint256 elapsed = Math.min(blockNumber, option1StopBlock).sub(option1StartBlock);
        uint256 allocationTime = option1EndBlock.sub(option1StartBlock);
        return option1[wallet].allocation.mul(elapsed).div(allocationTime).toUint96();
    }

    function getReleasedOption2(address wallet) public view returns (uint96) {
        return _getReleasedOption2ForBlock(wallet, block.number);
    }

    function _getReleasedOption2ForBlock(address wallet, uint256 blockNumber) internal view returns (uint96) {
        if (blockNumber <= option2StartBlock) {
            return 0;
        }
        uint256 elapsed = Math.min(blockNumber, option2StopBlock).sub(option2StartBlock);
        uint256 allocationTime = option2EndBlock.sub(option2StartBlock);
        return option2[wallet].allocation.mul(elapsed).div(allocationTime).toUint96();
    }

    function getClaimableOption1(address wallet) external view returns (uint256) {
        return getReleasedOption1(wallet).sub(option1[wallet].claimed);
    }

    function getClaimableOption2(address wallet) external view returns (uint256) {
        return getReleasedOption2(wallet).sub(option2[wallet].claimed);
    }

    function getOption1Allocation(address wallet) external view returns (uint256) {
        return option1[wallet].allocation;
    }

    function getOption1Claimed(address wallet) external view returns (uint256) {
        return option1[wallet].claimed;
    }

    function getOption2Allocation(address wallet) external view returns (uint256) {
        return option2[wallet].allocation;
    }

    function getOption2Claimed(address wallet) external view returns (uint256) {
        return option2[wallet].claimed;
    }

    function claim(address to) public {
        address sender = msg.sender;
        Option memory _option1 = option1[sender];
        Option memory _option2 = option2[sender];
        uint96 _option1Claimed = _option1.claimed;
        uint96 _option2Claimed = _option2.claimed;
        uint96 option1Amount = getReleasedOption1(sender).sub96(_option1Claimed);
        uint96 option2Amount = getReleasedOption2(sender).sub96(_option2Claimed);

        option1[sender].claimed = _option1Claimed.add96(option1Amount);
        option2[sender].claimed = _option2Claimed.add96(option2Amount);
        option1TotalClaimed = option1TotalClaimed.add96(option1Amount);
        option2TotalClaimed = option2TotalClaimed.add96(option2Amount);

        uint96 totalClaimed = option1Amount.add96(option2Amount);
        if (checkpointsLength[sender] == 0) {
            _updateVotes(address(0), sender, _option1.allocation.add96(_option2.allocation));
        }
        _updateVotes(sender, address(0), totalClaimed);

        TransferHelper.safeTransfer(token, to, totalClaimed);
        emit Claim(sender, to, option1Amount, option2Amount);
    }

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96) {
        uint96 option1TotalAllocation = option1[account].allocation;
        uint96 option2TotalAllocation = option2[account].allocation;

        uint256 votes = 0;
        if (checkpointsLength[account] == 0 || checkpoints[account][0].fromBlock > blockNumber) {
            if (option1[account].initBlock <= blockNumber) {
                votes = votes.add(option1TotalAllocation);
            }
            if (option2[account].initBlock <= blockNumber) {
                votes = votes.add(option2TotalAllocation);
            }
        } else {
            votes = _getPriorVotes(account, blockNumber);
        }

        if (option1StopBlock == option1EndBlock && option2StopBlock == option2EndBlock) {
            return votes.toUint96();
        }
        if (option1StopSetBlock > blockNumber && option2StopSetBlock > blockNumber) {
            return votes.toUint96();
        }

        uint256 lockedAllocation1;
        uint256 lockedAllocation2;
        if (blockNumber >= option1StopSetBlock) {
            uint256 allocationTime = option1EndBlock.sub(option1StartBlock);
            uint256 haltedTime = option1EndBlock.sub(option1StopBlock);
            lockedAllocation1 = option1TotalAllocation.mul(haltedTime).div(allocationTime);
        }
        if (blockNumber >= option2StopSetBlock) {
            uint256 allocationTime = option2EndBlock.sub(option2StartBlock);
            uint256 haltedTime = option2EndBlock.sub(option2StopBlock);
            lockedAllocation2 = option2TotalAllocation.mul(haltedTime).div(allocationTime);
        }
        return votes.sub(lockedAllocation1).sub(lockedAllocation2).toUint96();
    }
}