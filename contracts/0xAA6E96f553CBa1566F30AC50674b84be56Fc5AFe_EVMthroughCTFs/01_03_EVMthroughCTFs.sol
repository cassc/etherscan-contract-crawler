// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ctfs/ICTF.sol";
import "./InternalHelpers.sol";

contract EVMthroughCTFs is InternalHelpers {
    uint256 public challengeCost;

    constructor(uint256 _challengeCost) {
        challengeCost = _challengeCost;
    }

    function updateChallengeCost(uint256 _challengeCost) external onlyOwner {
        challengeCost = _challengeCost;
    }

    struct CTF {
        address ctfContract;
        uint16 weight;
    }

    CTF[] public ctfs;

    function updateCTFs(CTF[] memory _ctfs) external onlyOwner {
        uint256 numberOfExistingCTFs = ctfs.length;
        if (_ctfs.length < numberOfExistingCTFs) {
            revert CTFsQuantityDecreased();
        }
        for (uint256 i = 0; i < numberOfExistingCTFs; i++) {
            ctfs[i] = _ctfs[i];
        }
        for (uint256 i = numberOfExistingCTFs; i < _ctfs.length; i++) {
            ctfs.push(_ctfs[i]);
        }
    }

    function getAllCTFs() external view returns (CTF[] memory) {
        return ctfs;
    }

    struct Commitment {
        uint192 lockedValue;
        uint64 timestamp;
    }
    mapping(address => Commitment) public commitment;

    function becomeEVMWizard() external payable {
        uint256 existingLockedValue = commitment[msg.sender].lockedValue;
        if (existingLockedValue == 0) {
            if (msg.value < 2 * challengeCost) {
                revert NotEnoughValueLocked();
            }
            commitment[msg.sender] = Commitment({
                lockedValue: uint192(msg.value),
                timestamp: uint64(block.timestamp)
            });
        } else {
            // if you have already entered, can contribute however much you want
            // but don't necessarily need to contribute to solve newly added CTFs
            commitment[msg.sender].lockedValue = uint192(
                existingLockedValue + msg.value
            );
        }
    }

    function isStudent(address student) external view returns (bool) {
        // once lockedValue becomes >0, it will never return to 0
        // because during withdraw, we leave at least 1 in the balance
        return commitment[student].lockedValue > 0;
    }

    function bornEVMWizards(address[] memory students) external onlyOwner {
        // used to get the student in via backdoor.
        // born EVM wizards don't need to pay
        uint64 blockTimestamp = uint64(block.timestamp);
        for (uint256 i = 0; i < students.length; i++) {
            commitment[students[i]] = Commitment({
                lockedValue: 1,
                timestamp: blockTimestamp
            });
        }
    }

    function refund(address student) external onlyOwner {
        uint256 existingLockedValue = commitment[student].lockedValue;
        // need this if check so that I can't rug people who have
        // purchased and already solved everything
        if (existingLockedValue > 1) {
            delete commitment[student];
            _safeSend(student, existingLockedValue);
        }
    }

    // the uint256 in this mapping is bitpacked. i'th bit represents
    // whether the deposit for i'th CTF has been claimed by the student
    mapping(address => uint256) public claimed;

    function hasClaimedDeposit(address student, uint256 ctfIndex)
        external
        view
        returns (bool)
    {
        return hasClaimed(claimed[student], ctfIndex);
    }

    function withdraw(address student, uint256[] memory solvedCTFIndices)
        external
    {
        // cache ctfs in memory
        CTF[] memory cachedCTFs = ctfs;

        uint256 unclaimedWeight = 0;
        uint256 claimedCTFs = claimed[student];
        for (uint256 i = 0; i < cachedCTFs.length; i++) {
            if (!hasClaimed(claimedCTFs, i)) {
                unclaimedWeight += cachedCTFs[i].weight;
            }
        }
        if (unclaimedWeight == 0) {
            revert AlreadyClaimedEverything();
        }

        uint256 solvedWeight = 0;
        for (uint256 i = 0; i < solvedCTFIndices.length; i++) {
            uint256 solvedCTFIdx = solvedCTFIndices[i];
            CTF memory solvedCTF = cachedCTFs[solvedCTFIdx];
            if (!ICTF(solvedCTF.ctfContract).solved(student)) {
                revert CTFNotSolved(solvedCTFIdx);
            }
            if (hasClaimed(claimedCTFs, i)) {
                revert AlreadyClaimed(solvedCTFIdx);
            }
            claimedCTFs = markClaimed(claimedCTFs, i);
            solvedWeight += solvedCTF.weight;
        }
        claimed[student] = claimedCTFs;

        uint256 currentlyLocked = commitment[student].lockedValue;
        uint256 unlockedPortion = (currentlyLocked * solvedWeight) /
            unclaimedWeight;
        if (unlockedPortion == currentlyLocked) {
            // leave 1 to serve as a "boolean" that student has already entered the challenge
            unlockedPortion -= 1;
        }
        commitment[student].lockedValue = uint192(
            currentlyLocked - unlockedPortion
        );

        uint256 unlockedForOwner = unlockedPortion / 2;
        availableToClaimByOwner += unlockedForOwner;
        _safeSend(student, unlockedPortion - unlockedForOwner);
    }

    uint256 private availableToClaimByOwner = 1;

    function withdrawOwner() external onlyOwner {
        uint256 availableToClaimByOwnerCached = availableToClaimByOwner;
        availableToClaimByOwner = 1; // leave 1 for gas savings
        _safeSend(_owner, availableToClaimByOwnerCached - 1);
    }

    function outOfTime(address student) external onlyOwner {
        Commitment memory studentCommitment = commitment[student];
        if (block.timestamp - studentCommitment.timestamp < 12 weeks) {
            revert HasNotRunOutOfTime();
        }
        commitment[student].lockedValue = 1;
        availableToClaimByOwner += studentCommitment.lockedValue - 1;
    }
}