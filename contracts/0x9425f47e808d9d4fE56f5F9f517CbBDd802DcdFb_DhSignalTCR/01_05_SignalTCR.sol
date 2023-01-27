pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

pragma solidity >=0.8.4 <0.9.0;

//SPDX-License-Identifier: MIT

interface IBAAL {
    function sharesToken() external returns (address);

    function lootToken() external returns (address);
}

interface IBAALTOKEN {
    function getCurrentSnapshotId() external returns (uint256);

    function balanceOfAt(address account, uint256 snapshotId)
        external
        returns (uint256);
}

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_AMOUNT();
error NOT_OWNER();
error TOKENS_ALREADY_RELAEASED();
error TOKENS_ALREADY_CLAIMED();
error ENDED();

/**
@title DAO Signal Conviction Contract
@notice Signal with a snapshot of current loot and shares on a MolochV3 DAO
naive TCR implementation
A dao should deploy and initialize this after taking a snapshot on shares/loot
choice ids can map to a offchain db or onchain dhdb

TODO: PLCR secret voting, add actions and zodiac module for execution
*/
contract DhSignalTCR is Initializable {
    event VoteCasted(
        uint56 voteId,
        address indexed voter,
        uint152 amount,
        uint48 choiceId
    );

    event TokensReleased(
        uint56 voteId,
        address indexed voter,
        uint152 amount,
        uint48 choiceId
    );

    event ClaimTokens(address indexed voter, uint256 amount);

    event Init(uint256 sharesSnapshotId, uint256 lootSnapshotId);

    /// @notice dao staking token contract instance.
    IBAAL public baal;
    IBAALTOKEN public baalShares;
    IBAALTOKEN public baalLoot;
    uint256 public sharesSnapshotId;
    uint256 public lootSnapshotId;
    uint256 public endDate;

    /// @notice vote struct array.
    Vote[] public votes;

    /// @notice Vote struct.
    struct Vote {
        bool released;
        address voter;
        uint152 amount;
        uint48 choiceId;
        uint56 voteId;
    }

    /// @notice BatchVote struct.
    struct BatchVoteParam {
        uint48 choiceId;
        uint152 amount;
    }

    /// @notice UserBalance struct.
    struct UserBalance {
        bool claimed;
        uint256 balance;
    }

    /// @notice mapping which tracks the votes for a particular user.
    mapping(address => uint56[]) public voterToVoteIds;

    /// @notice mapping which tracks the claimed balance for a particular user.
    mapping(address => UserBalance) public voterBalances;

    modifier notEnded() {
        if (isComplete()) {
            revert ENDED();
        }
        _;
    }

    /**
    @dev initializer.
    @param _baalAddress dao staking baal address.
    */
    function setUp(address _baalAddress, uint256 _endDate) public initializer {
        baal = IBAAL(_baalAddress);
        baalShares = IBAALTOKEN(baal.sharesToken());
        baalLoot = IBAALTOKEN(baal.lootToken());
        // get current snapshot ids
        sharesSnapshotId = baalShares.getCurrentSnapshotId();
        lootSnapshotId = baalLoot.getCurrentSnapshotId();
        endDate = _endDate;
        // emit event with snapshot ids
        emit Init(sharesSnapshotId, lootSnapshotId);
    }

    /**
    @dev Checks if the contract is ended or not.
    @return bool is completed.
    */
    function isComplete() public view returns (bool) {
        return endDate < block.timestamp;
    }

    /**
    @dev User claims balance at snapshot.
    @return snapshot total balance.
    */
    function claim(address account) public notEnded returns (uint256) {
        if (voterBalances[account].claimed) {
            revert TOKENS_ALREADY_CLAIMED();
        }
        voterBalances[account].claimed = true;
        voterBalances[account].balance =
            baalShares.balanceOfAt(account, sharesSnapshotId) +
            baalLoot.balanceOfAt(account, lootSnapshotId);
        emit ClaimTokens(account, voterBalances[account].balance);
        return voterBalances[account].balance;
    }

    /**
    @dev Checks if tokens are locked or not.
    @return status of the tokens.
    */
    function areTokensLocked(uint56 _voteId) external view returns (bool) {
        return !votes[_voteId].released;
    }

    /**
    @dev Vote Info for a user.
    @param _voter address of voter
    @return Vote struct for the particular user id.
    */
    function getVotesForAddress(address _voter)
        external
        view
        returns (Vote[] memory)
    {
        uint56[] memory voteIds = voterToVoteIds[_voter];
        Vote[] memory votesForAddress = new Vote[](voteIds.length);
        for (uint256 i = 0; i < voteIds.length; i++) {
            votesForAddress[i] = votes[voteIds[i]];
        }
        return votesForAddress;
    }

    /**
    @dev Stake and get Voting rights.
    @param _choiceId choice id.
    @param _amount amount of tokens to lock.
    */
    function _vote(uint48 _choiceId, uint152 _amount) internal {
        if (
            _amount == 0 ||
            voterBalances[msg.sender].balance == 0 ||
            voterBalances[msg.sender].balance < _amount
        ) {
            revert INVALID_AMOUNT();
        }

        voterBalances[msg.sender].balance -= _amount;

        uint56 voteId = uint56(votes.length);

        votes.push(
            Vote({
                voteId: voteId,
                voter: msg.sender,
                amount: _amount,
                choiceId: _choiceId,
                released: false
            })
        );

        voterToVoteIds[msg.sender].push(voteId);

        // todo: index, maybe push choice id to dhdb
        emit VoteCasted(voteId, msg.sender, _amount, _choiceId);
    }

    /**
    @dev Stake and get Voting rights in batch.
    @param _batch array of struct to stake into multiple choices.
    */
    function vote(BatchVoteParam[] calldata _batch) external notEnded {
        for (uint256 i = 0; i < _batch.length; i++) {
            _vote(_batch[i].choiceId, _batch[i].amount);
        }
    }

    /**
    @dev Sender claim and stake in batch
    @param _batch array of struct to stake into multiple choices.
    */
    function claimAndVote(BatchVoteParam[] calldata _batch) external notEnded {
        claim(msg.sender);
        for (uint256 i = 0; i < _batch.length; i++) {
            _vote(_batch[i].choiceId, _batch[i].amount);
        }
    }

    /**
    @dev Release tokens and give up votes.
    @param _voteIds array of vote ids in order to release tokens.
    */
    function releaseTokens(uint256[] calldata _voteIds) external notEnded {
        for (uint256 i = 0; i < _voteIds.length; i++) {
            if (votes[_voteIds[i]].voter != msg.sender) {
                revert NOT_OWNER();
            }
            if (votes[_voteIds[i]].released) {
                // UI can send the same vote multiple times, ignore it
                continue;
            }
            votes[_voteIds[i]].released = true;

            voterBalances[msg.sender].balance += votes[_voteIds[i]].amount;

            emit TokensReleased(
                uint56(_voteIds[i]),
                msg.sender,
                votes[_voteIds[i]].amount,
                votes[_voteIds[i]].choiceId
            );
        }
    }
}

contract DhSignalTCRSumoner {
    address public immutable _template;

    event SummonDaoStake(
        address indexed signal,
        address indexed baal,
        uint256 date,
        uint256 endDate,
        string details
    );

    constructor(address template) {
        _template = template;
    }

    function summonSignalTCR(
        address baal,
        uint256 endDate,
        string calldata details
    ) external returns (address) {
        DhSignalTCR signal = DhSignalTCR(Clones.clone(_template));

        signal.setUp(baal, endDate);

        // todo: set as module on baal avatar

        emit SummonDaoStake(
            address(signal),
            address(baal),
            block.timestamp,
            endDate,
            details
        );

        return (address(signal));
    }
}