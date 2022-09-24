// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {RLBTRFLY} from "contracts/core/RLBTRFLY.sol";

library Common {
    struct Claim {
        address token;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }
}

interface IRewardDistributor {
    function claim(Common.Claim[] calldata claims) external;
}

contract Relocker {
    using SafeTransferLib for ERC20;

    ERC20 public immutable btrfly;
    RLBTRFLY public immutable rlBtrfly;
    IRewardDistributor public immutable rewardDistributor;

    event Relock(address indexed account, uint256 amount);

    error ZeroAddress();
    error ZeroAmount();

    constructor(
        address _btrfly,
        address _rlBtrfly,
        address _rewardDistributor
    ) {
        if (_btrfly == address(0)) revert ZeroAddress();
        if (_rlBtrfly == address(0)) revert ZeroAddress();
        if (_rewardDistributor == address(0)) revert ZeroAddress();

        btrfly = ERC20(_btrfly);
        rlBtrfly = RLBTRFLY(_rlBtrfly);
        rewardDistributor = IRewardDistributor(_rewardDistributor);

        btrfly.approve(_rlBtrfly, type(uint256).max);
    }

    /**
        @notice Claim rewards based on the specified metadata and lock amount as rlBtrfly
        @notice Use msg.sender not account parameter since relock is explicit action
        @param  claims  Claim[]  List of claim metadata 
        @param  amount  uint256  Amount to relock, cheaper to calculate offchain
     */
    function claimAndLock(Common.Claim[] calldata claims, uint256 amount)
        external
    {
        if (amount == 0) revert ZeroAmount();

        rewardDistributor.claim(claims);
        btrfly.safeTransferFrom(msg.sender, address(this), amount);
        rlBtrfly.lock(msg.sender, amount);

        emit Relock(msg.sender, amount);
    }
}