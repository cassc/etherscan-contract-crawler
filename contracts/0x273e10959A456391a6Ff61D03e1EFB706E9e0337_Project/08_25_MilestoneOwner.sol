// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../milestone/MilestoneResult.sol";
import "../milestone/Milestone.sol";
import "../milestone/MilestoneApprover.sol";
import "../vault/IVault.sol";
import "../platform/IPlatform.sol";


abstract contract MilestoneOwner {

    using SafeCast for uint;

    uint32 private constant DUE_DATE_GRACE_PERIOD = 20 seconds;

    Milestone[] public milestoneArr;

    uint[] public successfulMilestoneIndexes;

    address public paymentTokenAddress;

    //-----


    event OnchainMilestoneNotYetReached( uint milestoneIndex_);

    event MilestoneSuccess( uint milestoneIndex_);

    event MilestoneResultChanged( MilestoneResult newResult, MilestoneResult oldResult);

    event MilestoneIsOverdueEvent(uint indexed milestoneIndex, uint indexed dueDate, uint blockTimestamp);

    event MilestoneSucceededNumPledgers( uint indexed numPledgersInMilestone, uint indexed numPledgersSofar);

    event MilestoneSucceededFunding(uint indexed fundingPTokTarget, uint currentBalance);

    event MilestoneSucceededByExternalApprover( uint milestoneIndex_, string reason);

    event MilestoneFailedByExternalApprover( uint milestoneIndex_, string reason);
    //-----


    error MilestoneIsAlreadyResolved(uint milestoneIndex);

    error NotAnExpernallyApprovedMilestone(uint milestoneIndex);

    error CanOnlyBeInvokedByAMilestoneApprover(uint milestoneIndex, address externalApprover, address msgSender);

    error PrerequisitesWasNotMet(int prerequisiteIndex, uint milestoneIndex);

    //----


    modifier openForAll() {
        _;
    }

    modifier onlyIfProjectNotCompleted() {
        require( _projectNotCompleted(), "no longer running");
        _;
    }

    modifier onlyIfOnchain( uint milestoneIndex_) {
        require( milestoneArr[milestoneIndex_].milestoneApprover.externalApprover == address(0), "milestone not onchain");
        _;
    }

    modifier onlyExternalApprover( uint milestoneIndex_) {
        MilestoneApprover storage approver_ = milestoneArr[ milestoneIndex_].milestoneApprover;

        if (approver_.externalApprover == address(0)) {
            revert NotAnExpernallyApprovedMilestone( milestoneIndex_);
        }

        if (msg.sender != approver_.externalApprover) {
            revert CanOnlyBeInvokedByAMilestoneApprover( milestoneIndex_, approver_.externalApprover, msg.sender);
        }

        _;
    }


/*
 * @title checkIfOnchainTargetWasReached()
 *
 * @dev Allows 'all' to check if a given onchain milestone (sum-target or num-pledger-target) has been reached
 *  project must be still running
 *  If the milestone has succeeded - mark it as such
 *  If not - check if target is overdue and, if so, failproject
 *
 * Note: function will be invoked event if project is paused
 *
 * @event: OnProjectFailed, MilestoneSuccess or OnchainMilestoneNotYetReached
 */
    function checkIfOnchainTargetWasReached(uint milestoneIndex_)
                                                external openForAll onlyIfProjectNotCompleted
                                                onlyIfOnchain( milestoneIndex_) /*even if paused*/ { //@PUBFUNC

        uint initial_numCompleted = successfulMilestoneIndexes.length;

        Milestone storage milestone_ = milestoneArr[milestoneIndex_];

        if (_failIfOverdue( milestoneIndex_, milestone_)) {
            _onProjectFailed();
        } else if (_onchainMilestoneSucceeded( milestoneIndex_, milestone_)) {
            _onMilestoneSuccess( milestone_, milestoneIndex_);
        } else {
            emit OnchainMilestoneNotYetReached( milestoneIndex_);
        }

        require( successfulMilestoneIndexes.length <= initial_numCompleted+1, "single milestone approved");
    }


/*
 * @title onExternalApproverResolve()
 *
 * @dev Allows an external approver (EOA, oracle) to vote on the external milestone assigned to him
 *  project must be still running
 *  if milestone is overdue; fail project
 *  If the milestone has succeeded - mark it as such
 *  If the milestone has failed - fail project
 *
 * Note:  function will be invoked event if project is paused
 * Note2: this function will not fail if overdue! rather it will change the entire project status to failed
 *
 * Note3: this function should be assumed successful if not revert! getProjectState() must be called toverify
 *        it had not failed due to an overdue milestone!
 *
 * @event: OnProjectFailed, MilestoneFailedByExternalApprover or MilestoneSucceededByExternalApprover
 */ //@DOC3
    function onExternalApproverResolve(uint milestoneIndex_, bool succeeded, string calldata reason)
                                external onlyIfProjectNotCompleted onlyExternalApprover( milestoneIndex_)
                                /*even if paused*/ { //@PUBFUNC

        uint initial_numCompleted = successfulMilestoneIndexes.length;

        Milestone storage milestone_ = milestoneArr[milestoneIndex_];

        if (_failIfOverdue( milestoneIndex_, milestone_)) {
            _onProjectFailed();
        } else {
            _handleExternalApproverDecision( milestoneIndex_, milestone_, succeeded, reason);
        }

        require( successfulMilestoneIndexes.length <= initial_numCompleted+1, "single milestone approved");
    }


    function _handleExternalApproverDecision( uint milestoneIndex_, Milestone storage milestone_,
                                              bool succeeded, string calldata reason) private {
        MilestoneApprover storage approver_ = milestone_.milestoneApprover;

        require( msg.sender == approver_.externalApprover, "not milestone approver");

        if (succeeded) {
            _onMilestoneSuccess( milestone_, milestoneIndex_);
            emit MilestoneSucceededByExternalApprover( milestoneIndex_, reason);
        } else {            
            _onMilestoneFailure( milestone_);
            emit MilestoneFailedByExternalApprover( milestoneIndex_, reason);
        } 
    }


    function _verifyUnresolved( uint milestoneIndex, Milestone storage milestone_) private view {
        if (milestone_.result != MilestoneResult.UNRESOLVED) {
            revert MilestoneIsAlreadyResolved(milestoneIndex);
        }
    }


    function _onchainMilestoneSucceeded( uint milestoneIndex_, Milestone storage milestone_)
                                                        private onlyIfOnchain( milestoneIndex_)
                                                        returns(bool) {
        MilestoneApprover storage approver_ = milestone_.milestoneApprover;
        require( approver_.fundingPTokTarget > 0 || approver_.targetNumPledgers > 0, "not on-chain");

        _verifyPrerequisiteWasMet( milestoneIndex_);

        if (approver_.fundingPTokTarget > 0) {
            uint vaultBalance_ = _getProjectVault().vaultBalance();
            if (vaultBalance_ >= approver_.fundingPTokTarget) {
                emit MilestoneSucceededFunding( approver_.fundingPTokTarget, vaultBalance_);
                return true;
            }
            return false;
        }

        require( approver_.targetNumPledgers > 0, "num-pledgers not ser");

        if (_getNumPledgersSofar() >= approver_.targetNumPledgers) {
            emit MilestoneSucceededNumPledgers( approver_.targetNumPledgers, _getNumPledgersSofar());
            return true;
        }
        return false;
    }


    function _onMilestoneSuccess( Milestone storage milestone_, uint milestoneIndex_) private {

        _verifyPrerequisiteWasMet( milestoneIndex_);

        _verifyEnoughFundsInVault( milestoneIndex_);

        _setMilestoneResult( milestone_, MilestoneResult.SUCCEEDED);

        // add to completed arr
        successfulMilestoneIndexes.push( milestoneIndex_);

        _transferMilestoneFundsToTeam( milestone_);

        if (successfulMilestoneIndexes.length == milestoneArr.length) { //@DETECT_PROJECT_SUCCESS
            _onProjectSucceeded();
        }

        emit MilestoneSuccess( milestoneIndex_);
    }


    function getNumberOfSuccessfulMilestones() external view returns(uint) {
        return successfulMilestoneIndexes.length;
    }

    function _transferMilestoneFundsToTeam( Milestone storage milestone_) private {
        uint value_ = milestone_.pTokValue;

        // pass milestone funds from vault to teamWallet
        require( address(this) == _getProjectVault().getOwner(), "proj contract must own vault");

        _transferPaymentTokenToTeam( value_, _getPlatformCutPromils());
    }


    function _transferPaymentTokenToTeam( uint value_, uint platformCutPromils_) internal {
        address platformAddr_ = _getPlatformAddress();

        (uint teamCut_, uint platformCut_) = _getProjectVault().transferPToksToTeamWallet( value_, platformCutPromils_, _getPlatformAddress());

        IPlatform( platformAddr_).onReceivePaymentTokens( paymentTokenAddress, platformCut_);
    }

    function _failIfOverdue( uint milestoneIndex_, Milestone storage milestone_) internal returns(bool) {

        _verifyUnresolved( milestoneIndex_, milestone_); // must check first!

        if (milestoneIsOverdue( milestoneIndex_)) {
            _setMilestoneResult( milestone_,  MilestoneResult.FAILED);
            emit MilestoneIsOverdueEvent(milestoneIndex_, milestone_.dueDate, block.timestamp);
            return true;
        }

        return false;
    }

    function _onMilestoneFailure( Milestone storage milestone_) private {
        _setMilestoneResult( milestone_,  MilestoneResult.FAILED);
        _onProjectFailed();
    }

    function _setMilestoneResult( Milestone storage milestone_,  MilestoneResult newResult) private {
        MilestoneResult oldResult = milestone_.result;
        milestone_.result = newResult;
        emit MilestoneResultChanged( milestone_.result, oldResult);
    }


    function _verifyEnoughFundsInVault(uint milestoneIndex) private view {
        uint milestoneValue =  milestoneArr[ milestoneIndex].pTokValue;
        uint fundsInVault_ = _getProjectVault().vaultBalance();
        require( fundsInVault_ >= milestoneValue, "not enough funds in vault");
        //TODO >> consider problem of e.g. number-of-pledgers milestone completed with not enough funds in vault
    }

    function _verifyPrerequisiteWasMet(uint milestoneIndex) private view {
        Milestone storage milestone_ = milestoneArr[milestoneIndex];
        int prerequisiteIndex_ = milestone_.prereqInd;
        if (_prerequisiteWasNotMet( prerequisiteIndex_)) {
            revert PrerequisitesWasNotMet( prerequisiteIndex_, milestoneIndex);
        }
    }

    function _prerequisiteWasNotMet(int prerequisiteIndex_) private view returns(bool) {
        if (prerequisiteIndex_ < 0) {
            return false;
        }

        return milestoneArr[ uint(prerequisiteIndex_)].result != MilestoneResult.SUCCEEDED;
    }

    function getNumberOfMilestones() external view returns(uint) {
        return milestoneArr.length;
    }

    function getMilestoneDetails(uint ind_) external view returns( MilestoneResult, uint32, int32, uint, address, uint32, uint) {
        Milestone storage mstone_ = milestoneArr[ind_];
        MilestoneApprover storage approver_ = mstone_.milestoneApprover;
        return (
            mstone_.result, mstone_.dueDate, mstone_.prereqInd, mstone_.pTokValue,
            approver_.externalApprover, approver_.targetNumPledgers, approver_.fundingPTokTarget );
    }

    function getPrerequisiteIndexForMilestone(uint milestoneIndex) external view returns(int) {
        return milestoneArr[milestoneIndex].prereqInd;
    }

    function backdoor_markMilestoneAsOverdue(uint milestoneIndex) external { //TODO @gilad hhhh remove after testing!!!!
        milestoneArr[ milestoneIndex].dueDate = block.timestamp.toUint32() - DUE_DATE_GRACE_PERIOD - 1;
    }


    function milestoneIsOverdue( uint milestoneIndex_) public view returns(bool) {
        // no action taken, just check
        return block.timestamp > (milestoneArr[ milestoneIndex_].dueDate + DUE_DATE_GRACE_PERIOD);
    }

    function getMilestoneOverdueTime(uint milestoneIndex) external view returns(uint) {
        return milestoneArr[ milestoneIndex].dueDate;
    }


    function getMilestoneResult(uint milestoneIndex) external view returns(MilestoneResult) {
        return milestoneArr[milestoneIndex].result;
    }

    function getMilestoneValueInPaymentTokens(uint milestoneIndex) external view returns(uint) {
        return milestoneArr[milestoneIndex].pTokValue;
    }

    //-----
    function _onProjectSucceeded() internal virtual;
    function _onProjectFailed() internal virtual;
    function _getProjectVault() internal virtual view returns(IVault);
    function _getNumPledgersSofar() internal virtual view returns(uint);
    function _getPlatformCutPromils() internal virtual view returns(uint);
    function _getPlatformAddress() internal virtual view returns(address);
    function _projectNotCompleted() internal virtual view returns(bool);


    function _setMilestones( Milestone[] memory newMilestones) internal {
        delete milestoneArr; // remove prior content
        unchecked {
            for (uint i = 0; i < newMilestones.length; i++) {
                milestoneArr.push( newMilestones[i]);
            }
        }
    }

}