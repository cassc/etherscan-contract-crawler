pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";

contract Multisig {
    using SafeCast for *;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    enum ProposalStatus {
        Inactive,
        Active,
        Executed
    }

    struct Proposal {
        ProposalStatus _status;
        uint16 _yesVotes; // bitmap, 16 maximum votes
        uint8 _yesVotesTotal;
    }

    address public owner;
    uint8 public threshold;
    EnumerableSet.AddressSet subAccounts;

    mapping(bytes32 => Proposal) public proposals;

    event ProposalExecuted(bytes32 indexed proposalId);

    constructor(address[] memory _initialSubAccounts, uint256 _initialThreshold) {
        require(_initialSubAccounts.length >= _initialThreshold && _initialThreshold > 0, "invalid threshold");
        require(threshold == 0, "already initizlized");
        threshold = _initialThreshold.toUint8();
        uint256 initialSubAccountCount = _initialSubAccounts.length;
        for (uint256 i; i < initialSubAccountCount; i++) {
            subAccounts.add(_initialSubAccounts[i]);
        }
        owner = msg.sender;
    }

    modifier onlySubAccount() {
        require(subAccounts.contains(msg.sender));
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "new owner is the zero address");
        owner = _newOwner;
    }

    function addSubAccount(address _subAccount) public onlyOwner {
        subAccounts.add(_subAccount);
    }

    function removeSubAccount(address _subAccount) public onlyOwner {
        subAccounts.remove(_subAccount);
    }

    function changeThreshold(uint256 _newThreshold) external onlyOwner {
        require(subAccounts.length() >= _newThreshold && _newThreshold > 0, "invalid threshold");
        threshold = _newThreshold.toUint8();
    }

    function getSubAccountIndex(address _subAccount) public view returns (uint256) {
        return subAccounts._inner._indexes[bytes32(uint256(_subAccount))];
    }

    function subAccountBit(address _subAccount) internal view returns (uint256) {
        return uint256(1) << getSubAccountIndex(_subAccount).sub(1);
    }

    function _hasVoted(Proposal memory _proposal, address _subAccount) internal view returns (bool) {
        return (subAccountBit(_subAccount) & uint256(_proposal._yesVotes)) > 0;
    }

    function hasVoted(bytes32 _proposalId, address _subAccount) public view returns (bool) {
        Proposal memory proposal = proposals[_proposalId];
        return _hasVoted(proposal, _subAccount);
    }
}