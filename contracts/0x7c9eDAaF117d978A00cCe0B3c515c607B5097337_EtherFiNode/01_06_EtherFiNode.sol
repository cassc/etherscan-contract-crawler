// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IEtherFiNode.sol";
import "./interfaces/IEtherFiNodesManager.sol";
import "./interfaces/IProtocolRevenueManager.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract EtherFiNode is IEtherFiNode {
    address public etherFiNodesManager;

    // TODO: reduce the size of these varaibles
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

    function initialize(address _etherFiNodesManager) public {
        require(stakingStartTimestamp == 0, "already initialised");
        require(_etherFiNodesManager != address(0), "No zero addresses");
        stakingStartTimestamp = uint32(block.timestamp);
        etherFiNodesManager = _etherFiNodesManager;
    }

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Based on the sources where they come from, the staking rewards are split into
    ///  - those from the execution layer: transaction fees and MEV
    ///  - those from the consensus layer: Pstaking rewards for attesting the state of the chain, 
    ///    proposing a new block, or being selected in a validator sync committe
    ///  To receive the rewards from the execution layer, it should have 'receive()' function.
    receive() external payable {}

    /// @notice Set the validator phase
    /// @param _phase the new phase
    function setPhase(
        VALIDATOR_PHASE _phase
    ) external onlyEtherFiNodeManagerContract {
        phase = _phase;
    }

    /// @notice Set the deposit data
    /// @param _ipfsHash the deposit data
    function setIpfsHashForEncryptedValidatorKey(
        string calldata _ipfsHash
    ) external onlyEtherFiNodeManagerContract {
        ipfsHashForEncryptedValidatorKey = _ipfsHash;
    }

    function setLocalRevenueIndex(
        uint256 _localRevenueIndex
    ) external payable onlyEtherFiNodeManagerContract {
        localRevenueIndex = _localRevenueIndex;
    }

    function setExitRequestTimestamp() external onlyEtherFiNodeManagerContract {
        require(exitRequestTimestamp == 0, "Exit request was already sent.");
        exitRequestTimestamp = uint32(block.timestamp);
    }

    function markExited(
        uint32 _exitTimestamp
    ) external onlyEtherFiNodeManagerContract {
        require(_exitTimestamp <= block.timestamp, "Invalid exit timesamp");
        phase = VALIDATOR_PHASE.EXITED;
        exitTimestamp = _exitTimestamp;
    }

    function markBeingSlahsed() external onlyEtherFiNodeManagerContract {
        phase = VALIDATOR_PHASE.BEING_SLASHED;
    }

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

    function processVestedAuctionFeeWithdrawal() external onlyEtherFiNodeManagerContract {
        if (_getClaimableVestedRewards() > 0) {
            vestedAuctionRewards = 0;
        }
    }

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
        // they should implement either recieve() or fallback() properly
        // It's designed to prevent malicious actors from pausing the withdrawals
        bool sent;
        (sent, ) = payable(_operator).call{value: _operatorAmount}("");
        _treasuryAmount += (!sent) ? _operatorAmount : 0;
        (sent, ) = payable(_tnftHolder).call{value: _tnftAmount}("");
        _treasuryAmount += (!sent) ? _tnftAmount : 0;
        (sent, ) = payable(_bnftHolder).call{value: _bnftAmount}("");
        _treasuryAmount += (!sent) ? _bnftAmount : 0;
        (sent, ) = _treasury.call{value: _treasuryAmount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice compute the payouts for {staking, protocol} rewards and vested auction fee to the individuals
    /// @param _stakingRewards a flag to be set if the caller wants to compute the payouts for the stkaing rewards
    /// @param _protocolRewards a flag to be set if the caller wants to compute the payouts for the protocol rewards
    /// @param _vestedAuctionFee a flag to be set if the caller wants to compute the payouts for the vested auction fee
    /// @param _SRsplits the splits for the Staking Rewards
    /// @param _SRscale the scale
    /// @param _PRsplits the splits for the Protocol Rewards
    /// @param _PRscale the scale
    ///
    /// @return toNodeOperator  the payout to the Node Operator
    /// @return toTnft          the payout to the T-NFT holder
    /// @return toBnft          the payout to the B-NFT holder
    /// @return toTreasury      the payout to the Treasury
    function getRewardsPayouts(
        bool _stakingRewards,
        bool _protocolRewards,
        bool _vestedAuctionFee,
        IEtherFiNodesManager.RewardsSplit memory _SRsplits,
        uint256 _SRscale,
        IEtherFiNodesManager.RewardsSplit memory _PRsplits,
        uint256 _PRscale
    )
        public
        view
        onlyEtherFiNodeManagerContract
        returns (uint256, uint256, uint256, uint256)
    {
        uint256 operator;
        uint256 tnft;
        uint256 bnft;
        uint256 treasury;

        uint256[] memory tmps = new uint256[](4);
        if (_stakingRewards) {
            (tmps[0], tmps[1], tmps[2], tmps[3]) = getStakingRewardsPayouts(
                _SRsplits,
                _SRscale
            );
            operator += tmps[0];
            tnft += tmps[1];
            bnft += tmps[2];
            treasury += tmps[3];
        }

        if (_protocolRewards) {
            (tmps[0], tmps[1], tmps[2], tmps[3]) = getProtocolRewardsPayouts(
                _PRsplits,
                _PRscale
            );
            operator += tmps[0];
            tnft += tmps[1];
            bnft += tmps[2];
            treasury += tmps[3];
        }

        if (_vestedAuctionFee) {
            uint256 rewards = _getClaimableVestedRewards();
            uint256 toTnft = (rewards * 29) / 32;
            tnft += toTnft; // 29 / 32
            bnft += rewards - toTnft; // 3 / 32
        }

        return (operator, tnft, bnft, treasury);
    }

    /// @notice get the accrued staking rewards payouts to (toNodeOperator, toTnft, toBnft, toTreasury)
    /// @param _splits the splits for the staking rewards
    /// @param _scale the scale = SUM(_splits)
    ///
    /// @return toNodeOperator  the payout to the Node Operator
    /// @return toTnft          the payout to the T-NFT holder
    /// @return toBnft          the payout to the B-NFT holder
    /// @return toTreasury      the payout to the Treasury
    function getStakingRewardsPayouts(
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    )
        public
        view
        onlyEtherFiNodeManagerContract
        returns (
            uint256 toNodeOperator,
            uint256 toTnft,
            uint256 toBnft,
            uint256 toTreasury
        )
    {
        uint256 balance = address(this).balance;
        uint256 rewards = (balance > vestedAuctionRewards)
            ? balance - vestedAuctionRewards
            : 0;
        
        if (rewards >= 32 ether) {
            rewards -= 32 ether;
        } else if (rewards >= 8 ether) {
            // In a case of Slashing, without the Oracle, the exact staking rewards cannot be computed in this case
            // Assume no staking rewards in this case.
            return (0, 0, 0, 0);
        }

        (
            uint256 operator,
            uint256 tnft,
            uint256 bnft,
            uint256 treasury
        ) = calculatePayouts(rewards, _splits, _scale);

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

    /// @notice get the accrued protocol rewards payouts to (toNodeOperator, toTnft, toBnft, toTreasury)
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
        onlyEtherFiNodeManagerContract
        returns (
            uint256 toNodeOperator,
            uint256 toTnft,
            uint256 toBnft,
            uint256 toTreasury
        )
    {
        if (localRevenueIndex == 0) {
            return (0, 0, 0, 0);
        }
        uint256 globalRevenueIndex = IProtocolRevenueManager(
            protocolRevenueManagerAddress()
        ).globalRevenueIndex();
        uint256 rewards = globalRevenueIndex - localRevenueIndex;
        return calculatePayouts(rewards, _splits, _scale);
    }

    /// @notice compute the non exit penalty for the b-nft holder
    /// @param _principal the principal for the non exit penalty (e.g., 1 ether)
    /// @param _dailyPenalty the dailty penalty for the non exit penalty
    /// @param _exitTimestamp the exit timestamp for the validator node
    function getNonExitPenalty(
        uint128 _principal,
        uint64 _dailyPenalty,
        uint32 _exitTimestamp
    ) public view onlyEtherFiNodeManagerContract returns (uint256) {
        if (exitRequestTimestamp == 0) {
            return 0;
        }
        uint256 daysElapsed = _getDaysPassedSince(
            exitRequestTimestamp,
            _exitTimestamp
        );

        // full penalty
        if (daysElapsed > 365) {
            return _principal;
        }

        uint256 remaining = _principal;
        while (daysElapsed > 0) {
            uint256 exponent = Math.min(7, daysElapsed); // TODO: Re-calculate bounds
            remaining = (remaining * (100 - uint256(_dailyPenalty)) ** exponent) / (100 ** exponent);
            daysElapsed -= Math.min(7, daysElapsed);
        }

        return _principal - remaining;
    }

    /// @notice Given the current balance of the ether fi node after its EXIT,
    ///         Compute the payouts to {node operator, t-nft holder, b-nft holder, treasury}
    /// @param _splits the splits for the staking rewards
    /// @param _scale the scale = SUM(_splits)
    /// @param _principal the principal for the non exit penalty (e.g., 1 ether)
    /// @param _dailyPenalty the dailty penalty for the non exit penalty
    ///
    /// @return toNodeOperator  the payout to the Node Operator
    /// @return toTnft          the payout to the T-NFT holder
    /// @return toBnft          the payout to the B-NFT holder
    /// @return toTreasury      the payout to the Treasury
    function getFullWithdrawalPayouts(
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale,
        uint128 _principal,
        uint64 _dailyPenalty
    )
        external
        view
        returns (
            uint256 toNodeOperator,
            uint256 toTnft,
            uint256 toBnft,
            uint256 toTreasury
        )
    {
        uint256 balance = address(this).balance - (vestedAuctionRewards - _getClaimableVestedRewards());
        require(
            balance >= 16 ether,
            "not enough balance for full withdrawal"
        );
        require(
            phase == VALIDATOR_PHASE.EXITED,
            "validator node is not exited"
        );

        // (toNodeOperator, toTnft, toBnft, toTreasury)
        uint256[] memory payouts = new uint256[](4);

        // Compute the payouts for the rewards = (staking rewards + vested auction fee rewards)
        // the protocol rewards must be paid off already in 'processNodeExit'
        (
            payouts[0],
            payouts[1],
            payouts[2],
            payouts[3]
        ) = getRewardsPayouts(
            true,
            false,
            true,
            _splits,
            _scale,
            _splits,
            _scale
        );
        balance -= (payouts[0] + payouts[1] + payouts[2] + payouts[3]);

        // Compute the payouts for the principals to {B, T}-NFTs
        uint256 toBnftPrincipal;
        uint256 toTnftPrincipal;
        if (balance > 31.5 ether) {
            // 31.5 ether < balance <= 32 ether
            toBnftPrincipal = balance - 30 ether;
        } else if (balance > 26 ether) {
            // 26 ether < balance <= 31.5 ether
            toBnftPrincipal = 1.5 ether;
        } else if (balance > 25.5 ether) {
            // 25.5 ether < balance <= 26 ether
            toBnftPrincipal = 1.5 ether - (26 ether - balance);
        } else {
            // 16 ether <= balance <= 25.5 ether
            toBnftPrincipal = 1 ether;
        }
        toTnftPrincipal = balance - toBnftPrincipal;
        payouts[1] += toTnftPrincipal;
        payouts[2] += toBnftPrincipal;

        // Deduct the NonExitPenalty from the payout to the B-NFT
        uint256 bnftNonExitPenalty = getNonExitPenalty(
            _principal,
            _dailyPenalty,
            exitTimestamp
        );
        payouts[2] -= bnftNonExitPenalty;

        // While the NonExitPenalty keeps growing till 1 ether,
        //  the incentive to the node operator stops growing at 0.5 ether
        //  the rest goes to the treasury
        if (bnftNonExitPenalty > 0.5 ether) {
            payouts[0] += 0.5 ether;
            payouts[3] += bnftNonExitPenalty - 0.5 ether;
        } else {
            payouts[0] += bnftNonExitPenalty;
        }

        require(
            payouts[0] + payouts[1] + payouts[2] + payouts[3] ==
                address(this).balance -
                    (vestedAuctionRewards - _getClaimableVestedRewards()),
            "Incorrect Amount"
        );
        return (payouts[0], payouts[1], payouts[2], payouts[3]);
    }

    function _getClaimableVestedRewards() internal view returns (uint256) {
        if (vestedAuctionRewards == 0) {
            return 0;
        }
        uint256 vestingPeriodInDays = IProtocolRevenueManager(
            protocolRevenueManagerAddress()
        ).auctionFeeVestingPeriodForStakersInDays();
        uint256 daysPassed = _getDaysPassedSince(
            stakingStartTimestamp,
            uint32(block.timestamp)
        );
        if (daysPassed >= vestingPeriodInDays) {
            return vestedAuctionRewards;
        } else {
            return 0;
        }
    }

    function _getDaysPassedSince(
        uint32 _startTimestamp,
        uint32 _endTimestamp
    ) internal pure returns (uint256) {
        if (_endTimestamp <= _startTimestamp) {
            return 0;
        }
        uint256 timeElapsed = _endTimestamp - _startTimestamp;
        return uint256(timeElapsed / (24 * 3_600));
    }

    function calculatePayouts(
        uint256 _totalAmount,
        IEtherFiNodesManager.RewardsSplit memory _splits,
        uint256 _scale
    ) public pure returns (uint256, uint256, uint256, uint256) {
        require(
            _splits.nodeOperator +
                _splits.tnft +
                _splits.bnft +
                _splits.treasury ==
                _scale,
            "Incorrect Splits"
        );
        uint256 operator = (_totalAmount * _splits.nodeOperator) / _scale;
        uint256 tnft = (_totalAmount * _splits.tnft) / _scale;
        uint256 bnft = (_totalAmount * _splits.bnft) / _scale;
        uint256 treasury = _totalAmount - (bnft + tnft + operator);
        return (operator, tnft, bnft, treasury);
    }

    function protocolRevenueManagerAddress() internal view returns (address) {
        return
            IEtherFiNodesManager(etherFiNodesManager)
                .protocolRevenueManagerContract();
    }

    function implementation() external view returns (address) {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1);
        address implementation;
        assembly {
            implementation := sload(slot)
        }

        IBeacon beacon = IBeacon(implementation);
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
            msg.sender == protocolRevenueManagerAddress(),
            "Only protocol revenue manager contract function"
        );
        _;
    }
}