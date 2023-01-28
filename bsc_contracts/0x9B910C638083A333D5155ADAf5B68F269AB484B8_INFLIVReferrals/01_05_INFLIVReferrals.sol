// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract INFLIVReferrals is Initializable, OwnableUpgradeable{
	bool private initialized;
	
	struct mapMyTeam {
	   address sponsor;
    }
	
	struct sponsoredTeam {
	  address referrer;
	  uint256 joinTime;
    }
	
	struct Team{
      uint256 member;
    }
	
	mapping(address => mapping(uint256 => sponsoredTeam)) public mapSponsoredTeam;
	mapping(address => mapMyTeam) public mapTeamAllData;
	mapping(address => Team[21]) public mapTeam;
    mapping(address => bool) public moderators;
	mapping(address => uint256) public downline;
	
    function initialize() public initializer{
	   require(!initialized, "Contract instance has already been initialized");
	   initialized = true;
	   
	   __Ownable_init();
	}
	
	function addModerator(address _moderators, bool _status) external onlyOwner {
        moderators[_moderators] = _status;
    }
	
    modifier isModerator() {
        require(moderators[msg.sender] , "!isModOrOwner");
        _;
    }

    function addMember(address teamMember, address sponsor) public isModerator{
	   require(teamMember != address(0), "zero address");
	   require(sponsor != address(0), "zero address");
	   require(teamMember != sponsor, "ERR: referrer different required");
	   require(mapTeamAllData[teamMember].sponsor == address(0), "sponsor already exits");
	   
	   mapSponsoredTeam[sponsor][downline[sponsor]].referrer = teamMember;
	   mapSponsoredTeam[sponsor][downline[sponsor]].joinTime = block.timestamp;
	   
	   mapTeamAllData[teamMember].sponsor = sponsor;
	   enterTeam(teamMember);
    }
    
	function getSponsor(address teamMember) public view returns (address) {
       return mapTeamAllData[teamMember].sponsor;
    }
	
    function enterTeam(address sender) internal{
		address nextSponsor = mapTeamAllData[sender].sponsor;
		uint256 i;
        for(i=0; i < 21; i++) {
			if(nextSponsor != address(0)) 
			{
				downline[nextSponsor] += 1;
				mapTeam[nextSponsor][i].member += 1; 
			}
			else 
			{
				 break;
			}
			nextSponsor = mapTeamAllData[nextSponsor].sponsor;
		}
	}
	
    function getTeam(address sponsor, uint256 level) external view returns(uint256){
       return mapTeam[sponsor][level].member;
    }   
}