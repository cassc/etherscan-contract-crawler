// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IEtherFiNode.sol";
import "./interfaces/IEtherFiNodesManager.sol";
import "./interfaces/IProtocolRevenueManager.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";


contract EtherFiNode is IEtherFiNode {
    address public etherFiNodesManager;

    // TODO: reduce the size of these variables
    uint256 public localRevenueIndex;
    uint256 public vestedAuctionRewards;
    string public ipfsHashForEncryptedValidatorKey;
    uint32 public exitRequestTimestamp;
    uint32 public exitTimestamp;
    uint32 public stakingStartTimestamp;
    VALIDATOR_PHASE public phase;

    //--------------------------------------------------------------------------------------
    //----------------------------------  CONSTRUCTOR   ------------------------------------
    //--------------------------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        stakingStartTimestamp = type(uint32).max;
    }

    /// @notice Based on the sources where they come from, the staking rewards are split into
    ///  - those from the execution layer: transaction fees and MEV
    ///  - those from the consensus layer: staking rewards for attesting the state of the chain, 
    ///    proposing a new block, or being selected in a validator sync committee
    ///  To receive the rewards from the execution layer, it should have 'receive()' function.
    receive() external payable {}

    function initialize(address _etherFiNodesManager) public {
        require(stakingStartTimestamp == 0, "already initialized");
        require(_etherFiNodesManager != address(0), "No zero addresses");
        stakingStartTimestamp = uint32(block.timestamp);
        etherFiNodesManager = _etherFiNodesManager;
    }    

    //--------------------------------------------------------------------------------------
    //-------------------------------------  SETTER   --------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Set the validator phase
    /// @param _phase the new phase
    function setPhase(
        VALIDATOR_PHASE _phase
    ) external onlyEtherFiNodeManagerContract {
        _validatePhaseTransition(_phase);
        phase = _phase;
    }

    /// @notice Set the deposit data
    /// @param _ipfsHash the deposit data
    function setIpfsHashForEncryptedValidatorKey(
        string calldata _ipfsHash
    ) external onlyEtherFiNodeManagerContract {
        ipfsHashForEncryptedValidatorKey = _ipfsHash;
    }

    /// @notice Set the local revenue index
    /// @param _localRevenueIndex the value of the local index to set
    function setLocalRevenueIndex(
        uint256 _localRevenueIndex
    ) external payable onlyEtherFiNodeManagerContract {
        localRevenueIndex = _localRevenueIndex;
    }

    /// @notice Sets the exit request timestamp
    /// @dev Called when a TNFT holder submits an exit request
    function setExitRequestTimestamp() external onlyEtherFiNodeManagerContract {
        require(exitRequestTimestamp == 0, "Exit request was already sent.");
        exitRequestTimestamp = uint32(block.timestamp);
    }

    /// @notice Set the validators phase to exited
    /// @param _exitTimestamp the time the exit was complete
    function markExited(
        uint32 _exitTimestamp
    ) external onlyEtherFiNodeManagerContract {
        require(_exitTimestamp <= block.timestamp, "Invalid exit timestamp");
        _validatePhaseTransition(VALIDATOR_PHASE.EXITED);
        phase = VALIDATOR_PHASE.EXITED;
        exitTimestamp = _exitTimestamp;
    }

    /// @notice Set the validators phase to EVICTED
    function markEvicted() external onlyEtherFiNodeManagerContract {
        _validatePhaseTransition(VALIDATOR_PHASE.EVICTED);
        phase = VALIDATOR_PHASE.EVICTED;
        exitTimestamp = uint32(block.timestamp);
    }

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    function receiveVestedRewardsForStakers()
        external
        payable
        onlyProtocolRevenueManagerContract
    {
        require(
            vestedAuctionRewards == 0,
            "already received the vested auction fee reward"
        );
        vestedAuctionRewards = msg.value;
    }

    /// @notice Sets the vested auction rewards variable to 0 to show the auction fee has been withdrawn
    function processVestedAuctionFeeWithdrawal() external onlyEtherFiNodeManagerContract {
        if (_getClaimableVestedRewards(false) > 0) {
            vestedAuctionRewards = 0;
        }
    }

    /// @notice Sends funds to the rewards manager
    /// @param _amount The value calculated in the etherfi node manager to send to the rewards manager
    function moveRewardsToManager(
        uint256 _amount
    ) external onlyEtherFiNodeManagerContract {
        (bool sent, ) = payable(etherFiNodesManager).call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawFunds(
        address _treasury,
        uint256 _treasuryAmount,
        address _operator,
        uint256 _operatorAmount,
        address _tnftHolder,
        uint256 _tnftAmount,
        address _bnftHolder,
        uint256 _bnftAmount
    ) external onlyEtherFiNodeManagerContract {
        // the recipients of the funds must be able to receive the fund
        // For example, if it is a smart contract, 
        // they should implement either receive() or fallback() properly
        // It's designed to prevent malicious actors from pausing the withdrawals
        bool sent;
        (sent, ) = payable(_operator).call{value: _operatorAmount, gas: 2300}("");
        _treasuryAmount += (!sent) ? _operatorAmount : 0;
        (sent, ) = payable(_bnftHolder).call{value: _bnftAmount, gas: 2300}("");
        _treasuryAmount += (!sent) ? _bnftAmount : 0;
        (sent, ) = payable(_tnftHolder).call{value: _tnftAmount, gas: 12000}(""); // to support 'receive' of LP
        _treasuryAmount += (!sent) ? _tnftAmount : 0;
        (sent, ) = _treasury.call{value: _treasuryAmount, gas: 2300}("");
        require(sent, "Failed to send Ether");
    }

    //--------------------------------------------------------------------------------------
    //--------------------------------------  GETTER  --------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Compute the payouts for {staking, protocol} rewards and vested auction fee to the individuals
    /// @param _beaconBalance the balance of the validator in Consensus Layer
    /// @param _stakingRewards a flag to be set if the caller wants to compute the payouts for the staking rewards
    /// @param _protocolRewards a flag to be set if the caller wants to compute the payouts for the protocol rewards
    /// @param _vestedAuctionFee a flag to be set if the caller wants to compute the payouts for the vested auction fee
    /// @param _assumeFullyVested a flag to include the vested rewards assuming the vesting schedules are completed
    /// @param _SRsplits the splits for the Staking Rewards
    /// @param _PRsplits the splits for the Protocol Rewards
    /// @param _scale the scale
    ///
    /// @return toNodeOperator  the payout to the Node Operator
    /// @return toTnft          the payout to the T-NFT holder
    /// @return toBnft          the payout to the B-NFT holder
    /// @return toTreasury      the payout to the Treasury
    function getRewardsPayouts(
        uint256 _beaconBalance,
        bool _stakingRewards,
        bool _protocolRewards,
        bool _vestedAuctionFee,
        bool _assumeFullyVested,
        IEtherFiNodesManager.RewardsSplit memory _SRsplits,
        IEtherFiNodesManager.RewardsSplit memory _PRsplits,
        uint256 _scale
    )
        public
        view
        returns (uint256 toNodeOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury)
    {
        // (operator, tnft, bnft, treasury)
        uint256[] memory payouts = new uint256[](4);
        uint256[] memory tmps = new uint256[](4);

        if (_stakingRewards) {
            (tmps[0], tmps[1], tmps[2], tmps[3]) = getStakingRewardsPayouts(
                _beaconBalance,
                _SRsplits,
                _scale
            );
            payouts[0] += tmps[0];
            payouts[1] += tmps[1];
            payouts[2] += tmps[2];
            payouts[3] += tmps[3];
        }

        if (_protocolRewards) {
            (tmps[0], tmps[1], tmps[2], tmps[3]) = getProtocolRewardsPayouts(
                _PRsplits,
                _scale
            );
            payouts[0] += tmps[0];
            payouts[1] += tmps[1];
            payouts[2] += tmps[2];
            payouts[3] += tmps[3];
        }

        if (_vestedAuctionFee) {
            uint256 rewards = _getClaimableVestedRewards(_assumeFullyVested);
            uint256 toTnft = (rewards * 29) / 32;
            payouts[1] += toTnft; // 29 / 32
            payouts[2] += rewards - toTnft; // 3 / 32
        }

        return (payouts[0], payouts[1], payouts[2], payouts[3]);
    }

    /// @notice Fetch the accrued staking rewards payouts to (toNodeOperator, toTnft, toBnft, toTreasury)
    /// @param _beaconBalance the balance of the validator in Consensus Layer
    /// @param _splits the splits for the staking rewards
    /// @param _scale the scale = SUM(_splits)
    ///
    /// Note that since the smart contract running in the execution layer does not know the consensus layer data
    /// such as the status and balance of the validator, 
    /// the partial withdrawal assumes that the validator is in active & not being slashed + the beacon balance is 32 ether.
    /// Therefore, you need to set _beaconBalance = 32 ether to see the same payouts for the partial withdrawal
    ///
    /// @return toNodeOperator  the payout to the Node Operator
    /// @return toTnft          the payout to the T-NFT holder
    /// @return toBnft          the payout to the B-NFT holder
    /// @return toTreasury      the payout to the Treasury
    function getStakingRewardsPayouts(
        uint256 _beaconBalance,
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    )
        public
        view
        returns (
            uint256 toNodeOperator,
            uint256 toTnft,
            uint256 toBnft,
            uint256 toTreasury
        )
    {
        uint256 stakingBalance = _beaconBalance + getWithdrawableAmount(true, false, false, false);
        uint256 rewards;

        // If (Staking Principal + Staking Rewards >= 32 ether), the validator is running in a normal state
        // Else, the validator is getting slashed
        if (stakingBalance >= 32 ether) {
            rewards = stakingBalance - 32 ether;
        } else {
            // Without the Oracle, the exact staking rewards cannot be computed
            // Assume that there is no staking rewards.
            return (0, 0, 0, 0);
        }

        (
            uint256 operator,
            uint256 tnft,
            uint256 bnft,
            uint256 treasury
        ) = calculatePayouts(rewards, _splits, _scale);

        // If there was the exit request from the T-NFT holder,
        // but the B-NFT holder did not serve it by sending the voluntary exit message for more than 14 days
        // it incentivize's the node operator to do so instead
        // by
        //  - not sharing the staking rewards anymore with the node operator (see the below logic)
        //  - sharing the non-exit penalty with the node operator instead (~ 0.2 eth)
        if (exitRequestTimestamp > 0) {
            uint256 daysPassedSinceExitRequest = _getDaysPassedSince(
                exitRequestTimestamp,
                uint32(block.timestamp)
            );
            if (daysPassedSinceExitRequest >= 14) {
                treasury += operator;
                operator = 0;
            }
        }

        return (operator, tnft, bnft, treasury);
    }

    /// @notice Fetch the accrued protocol rewards payouts to (toNodeOperator, toTnft, toBnft, toTreasury)
    /// @param _splits the splits for the protocol rewards
    /// @param _scale the scale = SUM(_splits)
    ///
    /// @return toNodeOperator  the payout to the Node Operator
    /// @return toTnft          the payout to the T-NFT holder
    /// @return toBnft          the payout to the B-NFT holder
    /// @return toTreasury      the payout to the Treasury
    function getProtocolRewardsPayouts(
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    )
        public
        view
        returns (
            uint256 toNodeOperator,
            uint256 toTnft,
            uint256 toBnft,
            uint256 toTreasury
        )
    {
        uint256 rewards = getWithdrawableAmount(false, true, false, false);
        if (rewards == 0) {
            return (0, 0, 0, 0);
        }
        return calculatePayouts(rewards, _splits, _scale);
    }

    /// @notice Compute the non exit penalty for the b-nft holder
    /// @param _tNftExitRequestTimestamp the timestamp when the T-NFT holder asked the B-NFT holder to exit the node
    /// @param _bNftExitRequestTimestamp the timestamp when the B-NFT holder submitted the exit request to the beacon network
    function getNonExitPenalty(
        uint32 _tNftExitRequestTimestamp, 
        uint32 _bNftExitRequestTimestamp
    ) public view returns (uint256) {
        if (_tNftExitRequestTimestamp == 0) {
            return 0;
        }
        uint128 _principal = IEtherFiNodesManager(etherFiNodesManager).nonExitPenaltyPrincipal();
        uint64 _dailyPenalty = IEtherFiNodesManager(etherFiNodesManager).nonExitPenaltyDailyRate();
        uint256 daysElapsed = _getDaysPassedSince(
            _tNftExitRequestTimestamp,
            _bNftExitRequestTimestamp
        );

        // full penalty
        if (daysElapsed > 365) {
            return _principal;
        }

        uint256 remaining = _principal;
        while (daysElapsed > 0) {
            uint256 exponent = Math.min(7, daysElapsed);
            remaining = (remaining * (100 - uint256(_dailyPenalty)) ** exponent) / (100 ** exponent);
            daysElapsed -= Math.min(7, daysElapsed);
        }

        return _principal - remaining;
    }

    /// @notice Given
    ///         - the current balance of the validator in Consensus Layer
    ///         - the current balance of the ether fi node,
    ///         Compute the TVLs for {node operator, t-nft holder, b-nft holder, treasury}
    /// @param _beaconBalance the balance of the validator in Consensus Layer
    /// @param _SRsplits the splits for the Staking Rewards
    /// @param _PRsplits the splits for the Protocol Rewards
    /// @param _scale the scale
    ///
    /// @return toNodeOperator  the payout to the Node Operator
    /// @return toTnft          the payout to the T-NFT holder
    /// @return toBnft          `the payout to the B-NFT holder
    /// @return toTreasury      the payout to the Treasury
    function calculateTVL(
        uint256 _beaconBalance,
        bool _stakingRewards,
        bool _protocolRewards,
        bool _vestedAuctionFee,
        bool _assumeFullyVested,
        IEtherFiNodesManager.RewardsSplit memory _SRsplits,
        IEtherFiNodesManager.RewardsSplit memory _PRsplits,
        uint256 _scale
    ) public view returns (uint256 toNodeOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury) {
        uint256 balance = _beaconBalance + getWithdrawableAmount(_stakingRewards, _protocolRewards, _vestedAuctionFee, _assumeFullyVested);

        // Compute the payouts for the rewards = (staking rewards + vested auction fee rewards)
        // the protocol rewards must be paid off already in 'processNodeExit'
        uint256[] memory payouts = new uint256[](4); // (toNodeOperator, toTnft, toBnft, toTreasury)
        (payouts[0], payouts[1], payouts[2], payouts[3]) = getRewardsPayouts(_beaconBalance, 
                                                                            _stakingRewards, _protocolRewards, _vestedAuctionFee, _assumeFullyVested,
                                                                             _SRsplits, _PRsplits, _scale);
        balance -= (payouts[0] + payouts[1] + payouts[2] + payouts[3]);

        // Compute the payouts for the principals to {B, T}-NFTs
        {
            (uint256 toBnftPrincipal, uint256 toTnftPrincipal) = calculatePrincipals(balance);
            payouts[1] += toTnftPrincipal;
            payouts[2] += toBnftPrincipal;
        }

        // Apply the non-exit penalty to the B-NFT
        {
            uint256 bnftNonExitPenalty = getNonExitPenalty(exitRequestTimestamp, exitTimestamp);
            uint256 appliedPenalty = Math.min(payouts[2], bnftNonExitPenalty);
            payouts[2] -= appliedPenalty;

            // While the NonExitPenalty keeps growing till 1 ether,
            //  the incentive to the node operator stops growing at 0.2 ether
            //  the rest goes to the treasury
            // - Cap the incentive to the operator under 0.2 ether.
            if (appliedPenalty > 0.2 ether) {
                payouts[0] += 0.2 ether;
                payouts[3] += appliedPenalty - 0.2 ether;
            } else {
                payouts[0] += appliedPenalty;
            }
        }

        require(
            payouts[0] + payouts[1] + payouts[2] + payouts[3] ==
                _beaconBalance + getWithdrawableAmount(_stakingRewards, _protocolRewards, _vestedAuctionFee, _assumeFullyVested),
            "Incorrect Amount"
        );
        return (payouts[0], payouts[1], payouts[2], payouts[3]);
    }

    /// @notice Calculates values for payouts based on certain parameters
    /// @param _totalAmount The total amount to split
    /// @param _splits The splits for the staking rewards
    /// @param _scale The scale = SUM(_splits)
    ///
    /// @return toNodeOperator  the payout to the Node Operator
    /// @return toTnft          the payout to the T-NFT holder
    /// @return toBnft          the payout to the B-NFT holder
    /// @return toTreasury      the payout to the Treasury
    function calculatePayouts(
        uint256 _totalAmount,
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    ) public pure returns (uint256 toNodeOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury) {
        require(
            _splits.nodeOperator +
                _splits.tnft +
                _splits.bnft +
                _splits.treasury ==
                _scale,
            "Incorrect Splits"
        );
        toNodeOperator = (_totalAmount * _splits.nodeOperator) / _scale;
        toTnft = (_totalAmount * _splits.tnft) / _scale;
        toBnft = (_totalAmount * _splits.bnft) / _scale;
        toTreasury = _totalAmount - (toBnft + toTnft + toNodeOperator);
        return (toNodeOperator, toTnft, toBnft, toTreasury);
    }

    /// @notice Calculate the principal for the T-NFT and B-NFT holders based on the balance
    /// @param _balance The balance of the node
    /// @return toBnftPrincipal the principal for the B-NFT holder
    /// @return toTnftPrincipal the principal for the T-NFT holder
    function calculatePrincipals(
        uint256 _balance
    ) public pure returns (uint256 , uint256) {
        require(_balance <= 32 ether, "the total principal must be lower than 32 ether");
        uint256 toBnftPrincipal;
        uint256 toTnftPrincipal;
        if (_balance > 31.5 ether) {
            // 31.5 ether < balance <= 32 ether
            toBnftPrincipal = _balance - 30 ether;
        } else if (_balance > 26 ether) {
            // 26 ether < balance <= 31.5 ether
            toBnftPrincipal = 1.5 ether;
        } else if (_balance > 25.5 ether) {
            // 25.5 ether < balance <= 26 ether
            toBnftPrincipal = 1.5 ether - (26 ether - _balance);
        } else if (_balance > 16 ether) {
            // 16 ether <= balance <= 25.5 ether
            toBnftPrincipal = 1 ether;
        } else {
            // balance < 16 ether
            // The T-NFT and B-NFT holder's principals decrease 
            // starting from 15 ether and 1 ether respectively.
            toBnftPrincipal = 625 * _balance / 10_000;
        }
        toTnftPrincipal = _balance - toBnftPrincipal;
        return (toBnftPrincipal, toTnftPrincipal);
    }

    /// @notice Compute the withdrawable amount from the node
    /// @param _stakingRewards a flag to include the withdrawable amount for the staking principal + rewards
    /// @param _protocolRewards a flag to include the withdrawable amount for the protocol rewards
    /// @param _vestedAuctionFee a flag to include the withdrawable amount for the vested auction fee
    /// @param _assumeFullyVested a flag to include the vested rewards assuming the vesting schedules are completed
    function getWithdrawableAmount(bool _stakingRewards, bool _protocolRewards, bool _vestedAuctionFee, bool _assumeFullyVested) public view returns (uint256) {
        uint256 balance = 0;
        if (_stakingRewards) {
            balance += address(this).balance - vestedAuctionRewards;
        }
        if (_protocolRewards && localRevenueIndex > 0) {
            uint256 globalRevenueIndex = IProtocolRevenueManager(_protocolRevenueManagerAddress()).globalRevenueIndex();
            balance += globalRevenueIndex - localRevenueIndex;
        }
        if (_vestedAuctionFee) {
            balance += _getClaimableVestedRewards(_assumeFullyVested);
        }
        return balance;
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS  ---------------------------------
    //--------------------------------------------------------------------------------------

    function _validatePhaseTransition(VALIDATOR_PHASE _newPhase) internal view returns (bool) {
        VALIDATOR_PHASE currentPhase = phase;
        bool pass = true;

        // Transition rules
        if (currentPhase == VALIDATOR_PHASE.NOT_INITIALIZED) {
            pass = (_newPhase == VALIDATOR_PHASE.STAKE_DEPOSITED);
        } else if (currentPhase == VALIDATOR_PHASE.STAKE_DEPOSITED) {
            pass = (_newPhase == VALIDATOR_PHASE.LIVE || _newPhase == VALIDATOR_PHASE.CANCELLED);
        } else if (currentPhase == VALIDATOR_PHASE.LIVE) {
            pass = (_newPhase == VALIDATOR_PHASE.EXITED || _newPhase == VALIDATOR_PHASE.BEING_SLASHED || _newPhase == VALIDATOR_PHASE.EVICTED);
        } else if (currentPhase == VALIDATOR_PHASE.BEING_SLASHED) {
            pass = (_newPhase == VALIDATOR_PHASE.EXITED);
        } else if (currentPhase == VALIDATOR_PHASE.EXITED) {
            pass = (_newPhase == VALIDATOR_PHASE.FULLY_WITHDRAWN);
        } else {
            pass = false;
        }

        require(pass, "Invalid phase transition");
    }
    
    function _getClaimableVestedRewards(bool _assumeFullyVested) internal view returns (uint256) {
        if (vestedAuctionRewards == 0) {
            return 0;
        }
        uint256 vestingPeriodInDays = IProtocolRevenueManager(
            _protocolRevenueManagerAddress()
        ).auctionFeeVestingPeriodForStakersInDays();
        uint256 daysPassed = _getDaysPassedSince(
            stakingStartTimestamp,
            uint32(block.timestamp)
        );
        bool fullyVested = _assumeFullyVested || daysPassed >= vestingPeriodInDays;
        if (fullyVested || phase == VALIDATOR_PHASE.EVICTED) {
            return vestedAuctionRewards;
        } else {
            return 0;
        }
    }

    function _getDaysPassedSince(
        uint32 _startTimestamp,
        uint32 _endTimestamp
    ) public pure returns (uint256) {
        if (_endTimestamp <= _startTimestamp) {
            return 0;
        }
        uint256 timeElapsed = _endTimestamp - _startTimestamp;
        return uint256(timeElapsed / (24 * 3_600));
    }

    function _protocolRevenueManagerAddress() internal view returns (address) {
        return
            IEtherFiNodesManager(etherFiNodesManager)
                .protocolRevenueManagerContract();
    }

    function implementation() external view returns (address) {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1);
        address implementationVariable;
        assembly {
            implementationVariable := sload(slot)
        }

        IBeacon beacon = IBeacon(implementationVariable);
        return beacon.implementation();
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier onlyEtherFiNodeManagerContract() {
        require(
            msg.sender == etherFiNodesManager,
            "Only EtherFiNodeManager Contract"
        );
        _;
    }

    modifier onlyProtocolRevenueManagerContract() {
        require(
            msg.sender == _protocolRevenueManagerAddress(),
            "Only protocol revenue manager contract function"
        );
        _;
    }
}