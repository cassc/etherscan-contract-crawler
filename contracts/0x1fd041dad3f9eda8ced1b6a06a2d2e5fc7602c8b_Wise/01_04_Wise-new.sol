// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wise is Ownable {

    enum Status { SUBMITTED, ACCEPTED, MERGED, REJECTED, SPAM }

    struct Submission {
        string data_cid;
        address submitter;
        Status status;
        uint256 stake;
    }

    Submission[] public submissions;
    IERC20 public tkn;
    uint256 public stakeRequired = 0;

    event StatusChanged(uint indexed _index, Status indexed _status);

    constructor() {
        tkn = IERC20(0x98F219b94D0BC0948D0Cc15D42A8497540F3747f);
    }

    function createSubmission(string calldata data) public payable {
        require(msg.value >= stakeRequired, "Stake Ether to create a submission.");
        submissions.push(Submission(data, msg.sender, Status.SUBMITTED, msg.value));
        emit StatusChanged(submissions.length - 1, Status.SUBMITTED);
    }

    function approveSubmission(uint256 submissionIndex) public onlyOwner {
        submissions[submissionIndex].status = Status.ACCEPTED;
        emit StatusChanged(submissionIndex, Status.ACCEPTED);
    }

    function rejectSubmission(uint256 submissionIndex) public onlyOwner {
        submissions[submissionIndex].status = Status.REJECTED;
        emit StatusChanged(submissionIndex, Status.REJECTED);

    }

    function mergeSubmission(uint256 submissionIndex) public onlyOwner {
        mergeSubmissionAndPayout(submissionIndex, 0);
    }

    function mergeSubmissionAndPayout(uint256 submissionIndex, uint256 reward) public payable onlyOwner {
        submissions[submissionIndex].status = Status.MERGED;
        emit StatusChanged(submissionIndex, Status.MERGED);

        if (reward != 0) {
            Submission memory submission = submissions[submissionIndex];
            tkn.transfer(payable(submission.submitter), reward);
        }
    }

    // View Functions
    function getSubmissionsAtPage(uint256 page) public view returns (Submission[] memory) {
        uint pageLength = 10;
        uint paginationIndex = page * pageLength;
        uint submissionLength = submissions.length;
        uint remainingIndex = submissionLength - paginationIndex;
        uint arrAlloc = pageLength;
        if (remainingIndex < pageLength) {
            arrAlloc = remainingIndex;
        }
        Submission[] memory id = new Submission[](arrAlloc);

        uint index = 0;
        for (uint i = paginationIndex; i < paginationIndex + arrAlloc; i++) {
            Submission storage submission = submissions[i];
            id[index] = submission;
            index = index + 1;
        }
        return id;
    }

    function getDescSubmissionsAtPage(uint256 page) public view returns (Submission[] memory) {
        uint pageLength = 5;
        uint submissionLength = submissions.length;
        uint paginationIndex = submissionLength - (pageLength * (page + 1));
        Submission[] memory id = new Submission[](pageLength);

        uint index = 0;
        for (uint i = paginationIndex; i < paginationIndex + pageLength; i++) {
            Submission storage submission = submissions[i];
            if (submission.status != Status.SPAM) {
                id[index] = submission;
                index = index + 1;
            }
        }
        return id;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    function retrieveTokens() public onlyOwner {
        uint256 balance = tkn.balanceOf(address(this));
        tkn.transfer(payable(owner()), balance);
    }

    function markSubmissionAsSpam(uint256 submissionIndex) public onlyOwner {
        submissions[submissionIndex].status = Status.SPAM;
        emit StatusChanged(submissionIndex, Status.SPAM);
    }

    function changeSubmissionStake(uint256 _stakeRequired) public onlyOwner {
        stakeRequired = _stakeRequired;
    }

    // TESTS
    function getSubmissionAtIndex(uint256 submissionIndex) public view returns(Submission memory) {
        return submissions[submissionIndex];
    }
}