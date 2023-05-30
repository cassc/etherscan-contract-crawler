// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Administrable is Ownable {
  uint8 adminCount = 0;
  mapping(address => bool) admins;

  mapping(address => PendingAdminVote) pendingAdminVotes;
  mapping(address => mapping(address => bool)) votedAddresses;

  struct PendingAdminVote {
    string voteType;
    address nominatedAddress;
    address[] votedAddresses;
  }

  event AdminVoteStarted (
    string voteType,
    address nominatedAddress,
    address nominatingAddress
  );

  event AdminVoteConcluded (
    string voteType,
    address approvedAddress
  );

  event AdminVoteCast (
    string voteType,
    address nominatedAddress,
    address voteAddress
  );

  modifier onlyAdmin() {
    require(admins[msg.sender], "wPPC: sender is not an admin");
    _;
  }

  function castAdminVote(string memory _type, address _address) public {
    bool isAdding = isAddingVote(_type);
    if (pendingAdminVotes[_address].nominatedAddress != _address) {
      if (isAdding) {
        return nominateAddressForAdmin(_address);
      } else {
        return nominateAddressForRemoval(_address);
      }
    }

    castVote(_type, _address);

    if (calculatePercentage(pendingAdminVotes[_address].votedAddresses.length, adminCount, 3) <= 500) {
      return;
    }

    if (isAdding) {
      admins[_address] = true;
      adminCount += 1;
    } else {
      delete admins[_address];
      adminCount -= 1;
    }

    emit AdminVoteConcluded(_type, _address);

    for(uint i = 0; i < pendingAdminVotes[_address].votedAddresses.length; i++) {
      delete votedAddresses[_address][pendingAdminVotes[_address].votedAddresses[i]];
    }
    delete pendingAdminVotes[_address];
  }

  function isAddingVote(string memory _type) internal pure returns (bool) {
    if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("add"))) {
      return true;
    } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("remove"))) {
      return false;
    } else {
      revert(string(abi.encodePacked(_type, " is not a valid vote type")));
    }
  }

  function nominateAddressForAdmin(address _address) internal {
    require(senderIsOwner() || isAdmin(msg.sender), "wPPC: sender is neither owner nor admin");
    require(!isAdmin(_address), "wPPC: address is already an admin");
    require(pendingAdminVotes[_address].nominatedAddress == address(0x0), "wPPC: address nominated and pending vote");

    if (senderIsOwner() && adminCount == 0) {
      admins[_address] = true;
      adminCount += 1;

      emit AdminVoteConcluded("add", _address);

      return;
    }

    require(!senderIsOwner(), "wPPC: Owner cannot add more admins!");

    startAdminVote("add", _address);
    castAdminVote("add", _address);
  }

  function nominateAddressForRemoval(address _address) internal onlyAdmin {
    require(isAdmin(_address), "wPPC: address is not an admin");
    require(pendingAdminVotes[_address].nominatedAddress == address(0x0), "wPPC: address nominated and pending vote");

    startAdminVote("remove", _address);
    castAdminVote("remove", _address);
  }

  function startAdminVote(string memory _type, address _address) internal onlyAdmin {
    address[] memory emptyAddressList;
    pendingAdminVotes[_address] = PendingAdminVote(
      {
        voteType: _type,
        nominatedAddress: _address,
        votedAddresses: emptyAddressList
      }
    );

    emit AdminVoteStarted(_type, _address, msg.sender);
  }

  function castVote(string memory _type, address _address) internal onlyAdmin {
    address senderAddress = msg.sender;

    require(pendingAdminVotes[_address].nominatedAddress == _address, "wPPC: address is not nominated");
    require(!votedAddresses[_address][senderAddress], "wPPC: sender has already voted");
    require(keccak256(abi.encodePacked(pendingAdminVotes[_address].voteType)) == keccak256(abi.encodePacked(_type)), "wPPC: wrong vote type");

    pendingAdminVotes[_address].votedAddresses.push(senderAddress);
    votedAddresses[_address][senderAddress] = true;

    emit AdminVoteCast(_type, _address, senderAddress);
  }

  function calculatePercentage(uint numerator, uint denominator, uint precision) internal pure returns (uint quotient) {
    uint _numerator  = (denominator == 1 ? 1 : numerator) * 10 ** (precision+1);
    uint _quotient =  ((_numerator / denominator)) / 10;

    return ( _quotient);
  }

  function senderIsOwner() internal view returns (bool) {
    return owner() == msg.sender;
  }

  function isAdmin(address _address) internal view returns (bool) {
    return admins[_address];
  }
}