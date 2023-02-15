// SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9.0;


import "Ownable.sol";
import "IERC20.sol";
import "Pausable.sol";




contract BurnPage is Pausable, Ownable {
  struct Campaign {
    uint256 startAt;
    uint256 endAt;
    mapping(address => uint256) voteCount;
  }

struct ProjectVotes{
address projectAddress;
uint256 voteCount;
uint256 chainId;
}

  struct Project {
    address addr;
    uint chainId;
    bool isKnown;
  }

mapping(address => bool) isProjectKnown;
mapping(address => uint) projectsIndex;
  Campaign public currentCampaign;
  Campaign[] public campaigns;
  Project[] public projects;
  address constant public DEAD = address(0x000000000000000000000000000000000000dEaD);

  IERC20 public _oburn; 

  constructor(address oburnAddr) {
    require(oburnAddr != address(0x0), "Zero address detected");
    _oburn = IERC20(oburnAddr);
//    _oburn.approve(initRouterAddress, type(uint256).max);
  }

  function vote(uint256 amount, uint chainId, address addr) public {
    require(addr != address(0x0), "Zero address detected");
    require(currentCampaign.endAt >= block.timestamp, "Campaign ended");

    if(!isProjectKnown[addr]) {
      
      projects.push (Project({
        addr: addr,
        chainId: chainId,
        isKnown: true
      }));
      isProjectKnown[addr] = true;
      projectsIndex[addr] = projects.length-1;
    }

   _oburn.transferFrom(msg.sender, DEAD, amount);
    
    currentCampaign.voteCount[addr] += amount;
    emit LogVote(amount, chainId, addr);
  }

  function createNewCampaign(uint256 _startAt, uint256 _endAt) public onlyOwner {
    require(_endAt > _startAt, "Invalid end at");
    require(_endAt > block.timestamp, "End at can not be in past");

Campaign storage c = campaigns.push();
c.endAt = _endAt;
c.startAt= _startAt;

    if(c.startAt <= block.timestamp) {

      currentCampaign.endAt = _endAt;
      currentCampaign.startAt= _startAt;
      wipeCampaign();

    }
    emit LogNewCampaign(_startAt,_endAt);
  }

  function setCurrentCampaign(uint id) public onlyOwner {
    require(id < campaigns.length, "invalid campaign");
    currentCampaign.endAt =campaigns[id].endAt;
    currentCampaign.startAt= campaigns[id].startAt;
    wipeCampaign();
    emit LogsetcurrentCampaign(id);
  }



function getPastCampaign(uint id) public view returns(uint startAt,uint endAt, ProjectVotes[] memory) {
ProjectVotes[] memory projectVotes = new ProjectVotes[](projects.length);
uint256 campaignStartAt = campaigns[id].startAt;
uint256 campaignEndAt = campaigns[id].endAt;
for (uint i = 0; i < projects.length; i++) {
  projectVotes[i]= ProjectVotes({
    projectAddress: projects[i].addr,
    voteCount: campaigns[id].voteCount[projects[i].addr],
    chainId: projects[i].chainId
  });
}
return (campaignStartAt, campaignEndAt, projectVotes);
}


function getCurrentCampaign() public view returns(ProjectVotes[] memory) {
ProjectVotes[] memory projectVotes = new ProjectVotes[](projects.length);
for (uint i = 0; i < projects.length; i++) {
  projectVotes[i]= ProjectVotes({
    projectAddress: projects[i].addr,
    voteCount: currentCampaign.voteCount[projects[i].addr],
    chainId: projects[i].chainId
  });
}
return projectVotes;
}

function wipeCampaign() private {
  for (uint i = 0; i < projects.length; i++) {
  currentCampaign.voteCount[projects[i].addr] = 0;
}
}

event LogVote( uint256 amount, uint chainId, address projectAddress);
event LogNewCampaign( uint256 startAt, uint endAt);
event LogsetcurrentCampaign(uint id);
}