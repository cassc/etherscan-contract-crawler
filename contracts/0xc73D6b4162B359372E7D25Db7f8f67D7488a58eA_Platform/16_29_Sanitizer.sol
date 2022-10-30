// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../milestone/Milestone.sol";
import "../milestone/MilestoneApprover.sol";
import "../milestone/MilestoneResult.sol";


/*
    TODO: hhhh

tokens:   https://www.youtube.com/watch?v=gc7e90MHvl8

    find erc20 asset price via chainlink callback or API:
            https://blog.chain.link/fetch-current-crypto-price-data-solidity/
            https://www.quora.com/How-do-I-get-the-price-of-an-ERC20-token-from-a-solidity-smart-contract
            https://blog.logrocket.com/create-oracle-ethereum-smart-contract/
            https://noahliechti.hashnode.dev/an-effective-way-to-build-your-own-oracle-with-solidity

    use timelock?

    truffle network switcher

    deploy in testnet -- rinkbey

    a couple of basic tests
            deploy 2 ms + 3 bidders
            try get eth - fail
            try get tokens fail
            success
            try get eth - fail
            try get tokens fail
            success
            try get eth - success
            try get tokens success
---

    IProject IPlatform + supprit-itf
    clone contract for existing template address

    https://www.youtube.com/watch?v=LZ3XPhV7I1Q
            openz token types

    go over openzeppelin relevant utils

   refund nft receipt from any1 (not only orig ownner); avoid reuse (burn??)

   refund PTok for leaving pledgr -- grace/failure

   allow prj erc20 frorpldgr on prj success

   inject vault and rpjtoken rather than deploy

   write some tests

   create nft

   when transfer platform token??

   deal with nft cashing

   deal with completed_indexes list after change -- maybe just remove it?

   problem with updating project --how keep info on completedList and pundedStartingIndex

   who holds the erc20 project-token funds of this token? should pre-invoke to make sure has funds?
-------

Guice - box bonding curvse :  A bonding curve describes the relationship between the price and supply of an asset

    what is market-makers?

    startProj, endProj, pledGer.enterTime  // project.projectStartTime, project.projectEndTime
    compensate with erc20 only if proj success
    maybe receipt == erc721?;

    reserved sum === by frequency calculation;

*/

library Sanitizer {

    //@gilad: allow configuration?
    uint constant public MIN_MILESTONE_INTERVAL = 1 days;
    uint constant public MAX_MILESTONE_INTERVAL = 365 days;


    error IllegalMilestoneDueDate( uint index, uint32 dueDate, uint timestamp);

    error NoMilestoneApproverWasSet(uint index);

    error AmbiguousMilestoneApprover(uint index, address externalApprover, uint fundingPTokTarget, uint numPledgers);


    function _sanitizeMilestones( Milestone[] memory milestones_, uint now_, uint minNumMilestones_, uint maxNumMilestones_) internal pure {
        // assuming low milestone count
        require( minNumMilestones_ == 0 || milestones_.length >= minNumMilestones_, "not enough milestones");
        require( maxNumMilestones_ == 0 || milestones_.length <= maxNumMilestones_, "too many milestones");

        for (uint i = 0; i < milestones_.length; i++) {
            _validateDueDate(i, milestones_[i].dueDate, now_);
            _validateApprover(i, milestones_[i].milestoneApprover);
            milestones_[i].result = MilestoneResult.UNRESOLVED;
        }
    }

    function _validateDueDate( uint index, uint32 dueDate, uint now_) private pure {
        if ( (dueDate < now_ + MIN_MILESTONE_INTERVAL) || (dueDate > now_ + MAX_MILESTONE_INTERVAL) ) {
            revert IllegalMilestoneDueDate(index, dueDate, now_);
        }
    }

    function _validateApprover(uint index, MilestoneApprover memory approver_) private pure {
        bool approverIsSet_ = (approver_.externalApprover != address(0) || approver_.fundingPTokTarget > 0 || approver_.targetNumPledgers > 0);
        if ( !approverIsSet_) {
            revert NoMilestoneApproverWasSet(index);
        }
        bool extApproverUnique = (approver_.externalApprover == address(0) || (approver_.fundingPTokTarget == 0 && approver_.targetNumPledgers == 0));
        bool fundingTargetUnique = (approver_.fundingPTokTarget == 0  || (approver_.externalApprover == address(0) && approver_.targetNumPledgers == 0));
        bool numPledgersUnique = (approver_.targetNumPledgers == 0  || (approver_.externalApprover == address(0) && approver_.fundingPTokTarget == 0));

        if ( !extApproverUnique || !fundingTargetUnique || !numPledgersUnique) {
            revert AmbiguousMilestoneApprover(index, approver_.externalApprover, approver_.fundingPTokTarget, approver_.targetNumPledgers);
        }
    }

}