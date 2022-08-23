//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Sourcery is Ownable {
  struct Member {
    string name;
    string email;
    address wallet;
  }

  struct Project {
    uint256 id;
    string name;
    string description;
    uint256 date;
    uint256 votes;
    address wallet;
    bool approved;
  }

  uint256 public quorum = 80;
  uint256 public memberCount;
  uint256 public projectCount;

  uint256 public constant VOTING_PERIOD = 1 weeks;

  mapping(uint256 => Member) private members;
  mapping(uint256 => Project) private projects;
  mapping(uint256 => address[]) private votes;

  modifier onlyMembers(address _wallet) {
    for (uint256 i = 0; i < memberCount; ++i) {
      if (members[i].wallet == _wallet) {
        _;
        return;
      }
    }

    revert("Not a member");
  }

  event NewProjectProposed(
    address indexed _from,
    uint256 indexed _projectId,
    string _name,
    string _description
  );

  event ProjectApproved(uint256 indexed _projectId);

  function propose(string calldata _name, string calldata _description)
    external
    onlyMembers(msg.sender)
  {
    projects[projectCount] = Project(
      projectCount,
      _name,
      _description,
      block.timestamp,
      0,
      msg.sender,
      false
    );

    emit NewProjectProposed(msg.sender, projectCount, _name, _description);

    projectCount++;
  }

  function vote(uint256 _projectId) external onlyMembers(msg.sender) {
    require(
      keccak256(abi.encodePacked(projects[_projectId].name)) !=
        keccak256(abi.encodePacked("")),
      "Project does not exist"
    );
    require(projects[_projectId].approved == false, "Project already approved");
    require(
      projects[_projectId].date + VOTING_PERIOD > block.timestamp,
      "Vote period has ended"
    );
    require(
      projects[_projectId].wallet != msg.sender,
      "Cannot vote for your own project"
    );

    for (uint256 i = 0; i < projects[_projectId].votes; ++i) {
      if (votes[_projectId][i] == msg.sender) {
        revert("Already voted");
      }
    }

    projects[_projectId].votes += 1;
    votes[_projectId].push(msg.sender);

    if (
      memberCount > 1 &&
      (projects[_projectId].votes / (memberCount - 1)) * 100 >= quorum
    ) {
      projects[_projectId].approved = true;

      emit ProjectApproved(_projectId);
    }
  }

  function getProjects() external view returns (Project[] memory) {
    Project[] memory result = new Project[](projectCount);

    for (uint256 i = 0; i < projectCount; ++i) {
      Project memory project = projects[i];
      result[i] = project;
    }

    return result;
  }

  function getMembers() external view returns (Member[] memory) {
    Member[] memory result = new Member[](memberCount);

    for (uint256 i = 0; i < memberCount; ++i) {
      Member memory member = members[i];
      result[i] = member;
    }

    return result;
  }

  function getProject(uint256 _projectId) public view returns (Project memory) {
    require(
      keccak256(abi.encodePacked(projects[_projectId].name)) !=
        keccak256(abi.encodePacked("")),
      "Project does not exist"
    );

    return projects[_projectId];
  }

  function getMember(address _wallet) public view returns (Member memory) {
    for (uint256 i = 0; i < memberCount; ++i) {
      if (members[i].wallet == _wallet) {
        return members[i];
      }
    }

    revert("Not a member");
  }

  function register(
    string calldata _name,
    string calldata _email,
    address _wallet
  ) external onlyOwner {
    members[memberCount] = Member(_name, _email, _wallet);
    memberCount++;
  }

  function remove(address _wallet) external onlyOwner onlyMembers(_wallet) {
    for (uint256 i = 0; i < memberCount; ++i) {
      if (members[i].wallet == _wallet) {
        members[i] = members[memberCount - 1];
        delete members[memberCount - 1];
        memberCount--;
      }
    }
  }

  function setQuorum(uint256 _quorum) external onlyOwner {
    quorum = _quorum;
  }
}