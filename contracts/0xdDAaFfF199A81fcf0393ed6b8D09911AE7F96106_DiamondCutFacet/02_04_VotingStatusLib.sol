// SPDX-License-Identifier: BSL
pragma solidity ^0.8.17;

/**
*   [BSL License]
*   @title Library of the Proxy Contract
*   @notice Proxy contracts use variables from this libriary. 
*   @dev The proxy uses Diamond Pattern for modularity. Relevant code was borrowed from  
    Nick Mudge.    
*   @author Ismailov Altynbek <[email protected]>
*/

library VoteProposalLib {
    bytes32 constant VT_STORAGE_POSITION =
        keccak256("waverimplementation.VoteTracking.Lib"); //Storing position of the variables

    struct VoteProposal {
        uint24 id;
        address proposer;
        uint8 voteType;
        uint256 tokenVoteQuantity;
        string voteProposalText;
        uint8 voteStatus;
        uint256 voteends;
        address receiver;
        address tokenID;
        uint256 amount;
        uint8 votersLeft;
    }

    event VoteStatus(
        uint24 indexed id,
        address sender,
        uint8 voteStatus,
        uint256 timestamp
    );

    struct VoteTracking {
        uint8 familyMembers;
        MarriageStatus marriageStatus;
        uint24 voteid; //Tracking voting proposals by VOTEID
        address proposer;
        address proposed;
        address payable addressWaveContract;
        uint nonce;
        uint256 threshold;
        uint256 id;
        uint256 cmFee;
        uint256 marryDate;
        uint256 policyDays;
        uint256 setDeadline;
        uint256 divideShare;
        uint256 promoDays;
        address [] subAccounts; //an Array of Subaccounts; 
        mapping(address => bool) hasAccess; //Addresses that are alowed to use Proxy contract
        mapping(uint24 => VoteProposal) voteProposalAttributes; //Storage of voting proposals
        mapping(uint24 => mapping(address => bool)) votingStatus; // Tracking whether address has voted for particular voteid
        mapping(uint24 => uint256) numTokenFor; //Number of tokens voted for the proposal
        mapping(uint24 => uint256) numTokenAgainst; //Number of tokens voted against the proposal
        mapping (uint => uint) indexBook; //Keeping track of indexes 
        mapping(uint => address) addressBook; //To keep Addresses inside
        mapping(address => uint) subAccountIndex;//To keep track of subAccounts
        mapping(bytes32 => uint256) signedMessages;
        mapping(address => mapping(bytes32 => uint256)) approvedHashes;
    }

    function VoteTrackingStorage()
        internal
        pure
        returns (VoteTracking storage vt)
    {
        bytes32 position = VT_STORAGE_POSITION;
        assembly {
            vt.slot := position
        }
    }

    error ALREADY_VOTED();

    function enforceNotVoted(uint24 _voteid, address msgSender_) internal view {
        if (VoteTrackingStorage().votingStatus[_voteid][msgSender_] == true) {
            revert ALREADY_VOTED();
        }
    }

    error VOTE_IS_CLOSED();

    function enforceProposedStatus(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            1
        ) {
            revert VOTE_IS_CLOSED();
        }
    }

    error VOTE_IS_NOT_PASSED();

    function enforceAcceptedStatus(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            2 &&
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            7
        ) {
            revert VOTE_IS_NOT_PASSED();
        }
    }

    error VOTE_PROPOSER_ONLY();

    function enforceOnlyProposer(uint24 _voteid, address msgSender_)
        internal
        view
    {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].proposer !=
            msgSender_
        ) {
            revert VOTE_PROPOSER_ONLY();
        }
    }

    error DEADLINE_NOT_PASSED();

    function enforceDeadlinePassed(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteends >
            block.timestamp
        ) {
            revert DEADLINE_NOT_PASSED();
        }
    }

    /* Enum Statuses of the Marriage*/
    enum MarriageStatus {
        Proposed,
        Declined,
        Cancelled,
        Married,
        Divorced
    }

    /* Listening to whether ETH has been received/sent from the contract*/
    event AddStake(
        address indexed from,
        address indexed to,
        uint256 timestamp,
        uint256 amount
    );

    error USER_HAS_NO_ACCESS(address user);

    function enforceUserHasAccess(address msgSender_) internal view {
        if (VoteTrackingStorage().hasAccess[msgSender_] != true) {
            revert USER_HAS_NO_ACCESS(msgSender_);
        }
    }

    error USER_IS_NOT_PARTNER(address user);

    function enforceOnlyPartners(address msgSender_) internal view {
       
        if (
            VoteTrackingStorage().proposed != msgSender_ &&
            VoteTrackingStorage().proposer != msgSender_
        ) {
            revert USER_IS_NOT_PARTNER(msgSender_);
        } 
    }

    error CANNOT_USE_PARTNERS_ADDRESS();

    function enforceNotPartnerAddr(address _member) internal view {
        if (
            VoteTrackingStorage().proposed == _member &&
            VoteTrackingStorage().proposer == _member
        ) {
            revert CANNOT_USE_PARTNERS_ADDRESS();
        }
    }

    error CANNOT_PERFORM_WHEN_PARTNERSHIP_IS_ACTIVE();

    function enforceNotYetMarried() internal view {
        if (
            VoteTrackingStorage().marriageStatus != MarriageStatus.Proposed &&
            VoteTrackingStorage().marriageStatus != MarriageStatus.Declined && 
            VoteTrackingStorage().marriageStatus != MarriageStatus.Cancelled 
        ) {
            revert CANNOT_PERFORM_WHEN_PARTNERSHIP_IS_ACTIVE();
        }
    }

    error PARNERSHIP_IS_NOT_ESTABLISHED();

    function enforceMarried() internal view {
        if (VoteTrackingStorage().marriageStatus != MarriageStatus.Married) {
            revert PARNERSHIP_IS_NOT_ESTABLISHED();
        }
    }

    error PARNERSHIP_IS_DISSOLUTED();

    function enforceNotDivorced() internal view {
        if (VoteTrackingStorage().marriageStatus == MarriageStatus.Divorced) {
            revert PARNERSHIP_IS_DISSOLUTED();
        }
    }

    error PARTNERSHIP_IS_NOT_DISSOLUTED();

    function enforceDivorced() internal view {
        if (VoteTrackingStorage().marriageStatus != MarriageStatus.Divorced) {
            revert PARTNERSHIP_IS_NOT_DISSOLUTED();
        }
    }

    error CONTRACT_NOT_AUTHORIZED(address contractAddress);

    function enforceContractHasAccess() internal view {
        if (msg.sender != VoteTrackingStorage().addressWaveContract) {
            revert CONTRACT_NOT_AUTHORIZED(msg.sender);
        }
    }

    error COULD_NOT_PROCESS(address _to, uint256 amount);

    /**
     * @notice Internal function to process payments.
     * @dev call method is used to keep process gas limit higher than 2300. Amount of 0 will be skipped,
     * @param _to Address that will be reveiving payment
     * @param _amount the amount of payment
     */

    function processtxn(address payable _to, uint256 _amount) internal {
        if (_amount > 0) {
            (bool success, ) = _to.call{value: _amount}("");
            if (!success) {
                revert COULD_NOT_PROCESS(_to, _amount);
            }
            emit AddStake(address(this), _to, block.timestamp, _amount);
        }
    }
}