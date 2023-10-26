//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
 

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IGaugeController.sol";
import "../libraries/QuestDataTypes.sol";
import "../QuestBoard.sol";
import "../libraries/Errors.sol";

/** @title Quest Bias Calculator Module  */
/// @author Paladin
/*
    Contract to calculate the bias of a given Quest based on the Gauge & Quest parameters
*/
contract BiasCalculator {

    /** @notice Seconds in a Week */
    uint256 private constant WEEK = 604800;
    /** @notice Max VoterList size */
    uint256 private constant MAX_VOTERLIST_SIZE = 10;

    /** @notice Address of the Curve Gauge Controller */
    address public immutable GAUGE_CONTROLLER;

    /** @notice Address of the QuestBoard contract */
    address public immutable questBoard;

    /** @notice Mapping of voter list (blacklist or whitelist) for each Quest */
    // ID => VoterList
    mapping(uint256 => address[]) private questVoterList;
    /** @notice Mapping of valid Quests */
    mapping(uint256 => bool) private validQuests;


    // Events

    /** @notice Event emitted when an address is added to a Quest voter list */
    event AddToVoterList(uint256 indexed questID, address indexed account);
    /** @notice Event emitted when an address is removed from a Quest voter list */
    event RemoveFromVoterList(uint256 indexed questID, address indexed account);


    // Modifier

    /** @notice Check the caller is the QuestBoard contract */
    modifier onlyBoard(){
        if(msg.sender != questBoard) revert Errors.CallerNotAllowed();
        _;
    }


    // Constructor
    constructor(address _gaugeController, address _questBoard) {
        if(_gaugeController == address(0) || _questBoard == address(0)) revert Errors.AddressZero();

        questBoard = _questBoard;
        GAUGE_CONTROLLER = _gaugeController;
    }

    /**
    * @notice Returns the current Period for the contract
    */
    function getCurrentPeriod() public view returns(uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }

    /**
    * @notice Returns the voter list for a given Quest
    * @param questID ID of the Quest
    * @return address[] : vote list
    */
    function getQuestVoterList(uint256 questID) external view returns(address[] memory){
        return questVoterList[questID];
    }

    /**
    * @notice Returns the current reduced bias for a given gauge (based on a Quest's voter list)
    * @param questID ID of the Quest
    * @param gauge address of the gauge
    * @param questType Vote type of the Quest
    * @return uint256 : current reduced bias
    */
    function getCurrentReducedBias(uint256 questID, address gauge, QuestDataTypes.QuestVoteType questType) external view returns(uint256) {
        uint256 nextPeriod = getCurrentPeriod() + WEEK;

        return getReducedBias(nextPeriod, questID, gauge, questType);
    }

    /**
    * @notice Returns the reduced bias for a given gauge for a given period (based on a Quest's voter list)
    * @param period timestamp of the period
    * @param questID ID of the Quest
    * @param gauge address of the gauge
    * @param questType Vote type of the Quest
    * @return uint256 : current reduced bias
    */
    function getReducedBias(uint256 period, uint256 questID, address gauge, QuestDataTypes.QuestVoteType questType) public view returns(uint256) {
        address[] memory voterList = questVoterList[questID];

        IGaugeController gaugeController = IGaugeController(GAUGE_CONTROLLER);

        uint256 voterListSumBias;

        uint256 voterListLength = voterList.length;
            for(uint256 i; i < voterListLength;) {
                voterListSumBias += _getVoterBias(gauge, voterList[i], period);

                unchecked { i++; }
            }

        // For a WHITELIST type, simply return the sum of voters bias
        if(questType == QuestDataTypes.QuestVoteType.WHITELIST) return voterListSumBias;

        // Get the bias of the Gauge for the given period
        uint256 periodAdjustedBias = gaugeController.points_weight(gauge, period).bias;

        // If the Quest is a Blacklist, we need to remove the bias of the voters
        if(questType == QuestDataTypes.QuestVoteType.BLACKLIST) {
            periodAdjustedBias = voterListSumBias >= periodAdjustedBias ? 0 : periodAdjustedBias - voterListSumBias;
        }
        
        return periodAdjustedBias;
    }

    /**
    * @notice Returns the bias for a given voter for a given gauge, at a given period
    * @param gauge address of the gauge
    * @param voter address of the voter
    * @param period timestamp of the period
    * @return userBias (uint256) : voter bias
    */
    function _getVoterBias(address gauge, address voter, uint256 period) internal view returns(uint256 userBias) {
        IGaugeController gaugeController = IGaugeController(GAUGE_CONTROLLER);
        uint256 lastUserVote = gaugeController.last_user_vote(voter, gauge);
        IGaugeController.VotedSlope memory voteUserSlope = gaugeController.vote_user_slopes(voter, gauge);

        if(lastUserVote >= period) return 0;
        if(voteUserSlope.end <= period) return 0;
        if(voteUserSlope.slope == 0) return 0;

        userBias = voteUserSlope.slope * (voteUserSlope.end - period);
    }

    /**
    * @notice Adds a given address to a Quest's voter list
    * @dev Adds a given address to a Quest's voter list
    * @param questID ID of the Quest
    * @param account address of the voter
    */
    function _addToVoterList(uint256 questID, address account) internal {
        //We don't want to have 2x the same address in the list
        address[] memory _list = questVoterList[questID];
        uint256 length = _list.length;
        for(uint256 i; i < length;){
            if(_list[i] == account) revert Errors.AlreadyListed();
            unchecked {
                ++i;
            }
        }

        questVoterList[questID].push(account);

        emit AddToVoterList(questID, account);
    }

    /**
    * @notice Sets the initial voter list for a given Quest
    * @param questID ID of the Quest
    * @param accounts list of voters
    */
    function setQuestVoterList(uint256 questID, address[] calldata accounts) external onlyBoard {
        uint256 length = accounts.length;
        if(length > MAX_VOTERLIST_SIZE) revert Errors.MaxListSize();

        for(uint256 i; i < length;){
            if(accounts[i] == address(0)) revert Errors.AddressZero();

            _addToVoterList(questID, accounts[i]);

            unchecked {
                ++i;
            }
        }

        validQuests[questID] = true;
    }

    /**
    * @notice Adds a given list of addresses to a Quest's voter list
    * @param questID ID of the Quest
    * @param accounts list of voters
    */
    function addToVoterList(uint256 questID, address[] calldata accounts) external {
        uint256 length = accounts.length;
        if(length == 0) revert Errors.EmptyArray();
        if(!validQuests[questID]) revert Errors.InvalidQuestID();
        if(msg.sender != QuestBoard(questBoard).getQuestCreator(questID)) revert Errors.CallerNotAllowed();
        if(length + questVoterList[questID].length > MAX_VOTERLIST_SIZE) revert Errors.MaxListSize();


        for(uint256 i = 0; i < length;){
            if(accounts[i] == address(0)) revert Errors.AddressZero();

            _addToVoterList(questID, accounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
    * @notice Removes a given address from a Quest's voter list
    * @param questID ID of the Quest
    * @param account address of the voter
    */
    function removeFromVoterList(uint256 questID, address account) external {
        if(!validQuests[questID]) revert Errors.InvalidQuestID();
        if(msg.sender != QuestBoard(questBoard).getQuestCreator(questID)) revert Errors.CallerNotAllowed();
        if(account == address(0)) revert Errors.AddressZero();

        address[] memory _list = questVoterList[questID];
        uint256 length = _list.length;

        for(uint256 i; i < length;){
            if(_list[i] == account){
                if(i != length - 1){
                    questVoterList[questID][i] = _list[length - 1];
                }
                questVoterList[questID].pop();

                emit RemoveFromVoterList(questID, account);

                return;
            }

            unchecked {
                ++i;
            }
        }
    }

}