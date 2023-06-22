/**
 *Submitted for verification at Etherscan.io on 2020-07-14
*/

// SPDX-License-Identifier: BSD-3-Clause

/** 
*                                                                                                                                  
*       ##### /                                                             #######      /                                         
*    ######  /          #                                                 /       ###  #/                                          
*   /#   /  /          ###                                               /         ##  ##                                          
*  /    /  /            #                                                ##        #   ##                                          
*      /  /                                                               ###          ##                                          
*     ## ##           ###        /###    ###  /###         /###          ## ###        ##  /##      /###    ###  /###       /##    
*     ## ##            ###      / ###  /  ###/ #### /     / #### /        ### ###      ## / ###    / ###  /  ###/ #### /   / ###   
*     ## ##             ##     /   ###/    ##   ###/     ##  ###/           ### ###    ##/   ###  /   ###/    ##   ###/   /   ###  
*     ## ##             ##    ##    ##     ##    ##   k ####                  ### /##  ##     ## ##    ##     ##         ##    ### 
*     ## ##             ##    ##    ##     ##    ##   a   ###                   #/ /## ##     ## ##    ##     ##         ########  
*     #  ##             ##    ##    ##     ##    ##   i     ###                  #/ ## ##     ## ##    ##     ##         #######   
*        /              ##    ##    ##     ##    ##   z       ###                 # /  ##     ## ##    ##     ##         ##        
*    /##/           /   ##    ##    ##     ##    ##   e  /###  ##       /##        /   ##     ## ##    /#     ##         ####    / 
*   /  ############/    ### /  ######      ###   ###  n / #### /       /  ########/    ##     ##  ####/ ##    ###         ######/  
*  /     #########       ##/    ####        ###   ### -    ###/       /     #####       ##    ##   ###   ##    ###         #####   
*  #                                                  w               |                       /                                    
*   ##                                                e                \)                    /                                     
*                                                     b                                     /                                      
*                                                                                          /                                       
*
*
* Lion's Share is the very first true follow-me matrix smart contract ever created. 
* https://www.lionsshare.io
* Get your share, join today!
*/

pragma solidity 0.6.8;

contract LionShare {

  struct Account {
    uint32 id;
    uint32 directSales;
    uint8[] activeLevel;
    bool exists;
    address sponsor;
    mapping(uint8 => L1) x31Positions;
    mapping(uint8 => L2) x22Positions;
  }

  struct L1 {
    uint32 directSales;
    uint16 cycles;
    uint8 passup;
    uint8 reEntryCheck;
    uint8 placement;
    address sponsor;
  }

  struct L2 {
    uint32 directSales;
    uint16 cycles;
    uint8 passup;
    uint8 cycle;
    uint8 reEntryCheck;
    uint8 placementLastLevel;
    uint8 placementSide;
    address sponsor;
    address placedUnder;
    address[] placementFirstLevel;
  }

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;
  uint public constant REENTRY_REQ = 2;

  mapping(address => Account) public members;
  mapping(uint32 => address) public idToMember;
  mapping(uint8 => uint) public levelCost;
  
  uint internal reentry_status;
  uint32 public lastId;
  uint8 public topLevel;
  address internal owner;

  event Registration(address member, uint memberId, address sponsor);
  event Upgrade(address member, address sponsor, uint8 matrix, uint8 level);
  event PlacementL1(address member, address sponsor, uint8 level, uint8 placement, bool passup);  
  event PlacementL2(address member, address sponsor, uint8 level, uint8 placementSide, address placedUnder, bool passup);
  event Cycle(address indexed member, address fromPosition, uint8 matrix, uint8 level);
  event PlacementReEntry(address indexed member, address reEntryFrom, uint8 matrix, uint8 level);
  event FundsPayout(address indexed member, address payoutFrom, uint8 matrix, uint8 level);
  event FundsPassup(address indexed member, address passupFrom, uint8 matrix, uint8 level);

  modifier isOwner(address _account) {
    require(owner == _account, "Restricted Access!");
    _;
  }

  modifier isMember(address _addr) {
    require(members[_addr].exists, "Register Account First!");
    _;
  }
  
  modifier blockReEntry() {
    require(reentry_status != ENTRY_DISABLED, "Security Block");
    reentry_status = ENTRY_DISABLED;

    _;

    reentry_status = ENTRY_ENABLED;
  }

  constructor(address _addr) public {
    owner = msg.sender;

    reentry_status = ENTRY_ENABLED;

    levelCost[1] = 0.02 ether;
    topLevel = 1;

    createAccount(_addr, _addr, true);
    handlePositionL1(_addr, _addr, _addr, 1, true);
    handlePositionL2(_addr, _addr, _addr, 1, true);
  }

  fallback() external payable blockReEntry() {
    preRegistration(msg.sender, bytesToAddress(msg.data));
  }

  receive() external payable blockReEntry() {
    preRegistration(msg.sender, idToMember[1]);
  }

  function registration(address _sponsor) external payable blockReEntry() {
    preRegistration(msg.sender, _sponsor);
  }

  function preRegistration(address _addr, address _sponsor) internal {
    require((levelCost[1] * 2) == msg.value, "Require .04 eth to register!");

    createAccount(_addr, _sponsor, false);

    members[_sponsor].directSales++;
    
    handlePositionL1(_addr, _sponsor, _sponsor, 1, false);
    handlePositionL2(_addr, _sponsor, _sponsor, 1, false);
    
    handlePayout(_addr, 0, 1);
    handlePayout(_addr, 1, 1);
  }
  
  function createAccount(address _addr, address _sponsor, bool _initial) internal {
    require(!members[_addr].exists, "Already a member!");

    if (_initial == false) {
      require(members[_sponsor].exists, "Sponsor dont exist!");
    }

    lastId++;    

    members[_addr] = Account({id: lastId, sponsor: _sponsor, exists: true, directSales: 0, activeLevel: new uint8[](2)});
    idToMember[lastId] = _addr;
    
    emit Registration(_addr, lastId, _sponsor);
  }

  function purchaseLevel(uint8 _matrix, uint8 _level) external payable isMember(msg.sender) blockReEntry() {
    require((_matrix == 1 || _matrix == 2), "Invalid matrix identifier.");
    require((_level > 0 && _level <= topLevel), "Invalid matrix level.");    

    uint8 activeLevel = members[msg.sender].activeLevel[(_matrix - 1)];
    uint8 otherLevel = 1;

    if (_matrix == 2) {
      otherLevel = 0;
    }

    require((activeLevel < _level), "Already active at level!");
    require((activeLevel == (_level - 1)), "Level upgrade req. in order!");
    require(((members[msg.sender].activeLevel[otherLevel] * 2) >= _level), "Double upgrade exeeded.");
    require((msg.value == levelCost[_level]), "Wrong amount transferred.");
  
    address sponsor = members[msg.sender].sponsor;
    
    Upgrade(msg.sender, sponsor, _matrix, _level);

    if (_matrix == 1) {
      handlePositionL1(msg.sender, sponsor, findActiveSponsor(msg.sender, sponsor, 0, _level, true), _level, false);
    } else {
      handlePositionL2(msg.sender, sponsor, findActiveSponsor(msg.sender, sponsor, 1, _level, true), _level, false);
    }

    handlePayout(msg.sender, (_matrix - 1), _level);    
  }

  function handlePositionL1(address _addr, address _mainSponsor, address _sponsor, uint8 _level, bool _initial) internal {
    Account storage member = members[_addr];

    member.activeLevel[0] = _level;
    member.x31Positions[_level] = L1({sponsor: _sponsor, placement: 0, directSales: 0, cycles: 0, passup: 0, reEntryCheck: 0});

    if (_initial == true) {
      return;
    } else if (_mainSponsor == _sponsor) {
      members[_mainSponsor].x31Positions[_level].directSales++;
    } else {
      member.x31Positions[_level].reEntryCheck = 1;
    }
    
    sponsorPlaceL1(_addr, _sponsor, _level, false);
  }

  function sponsorPlaceL1(address _addr, address _sponsor, uint8 _level, bool passup) internal {
    L1 storage position = members[_sponsor].x31Positions[_level];

    emit PlacementL1(_addr, _sponsor, _level, (position.placement + 1), passup);

    if (position.placement >= 2) {
      emit Cycle(_sponsor, _addr, 1, _level);

      position.placement = 0;
      position.cycles++;

      if (_sponsor != idToMember[1]) {
        position.passup++;

        sponsorPlaceL1(_sponsor, position.sponsor, _level, true);
      }
    } else {
      position.placement++;
    }
  }

  function handlePositionL2(address _addr, address _mainSponsor, address _sponsor, uint8 _level, bool _initial) internal {
    Account storage member = members[_addr];
    
    member.activeLevel[1] = _level;
    member.x22Positions[_level] = L2({sponsor: _sponsor, directSales: 0, cycles: 0, passup: 0, cycle: 0, reEntryCheck: 0, placementSide: 0, placedUnder: _sponsor, placementFirstLevel: new address[](0), placementLastLevel: 0});

    if (_initial == true) {
      return;
    } else if (_mainSponsor == _sponsor) {
      members[_mainSponsor].x22Positions[_level].directSales++;
    } else {
      member.x22Positions[_level].reEntryCheck = 1;
    }

    sponsorPlaceL2(_addr, _sponsor, _level, false);
  }

  function sponsorPlaceL2(address _addr, address _sponsor, uint8 _level, bool passup) internal {
    L2 storage member = members[_addr].x22Positions[_level];
    L2 storage position = members[_sponsor].x22Positions[_level];

    if (position.placementFirstLevel.length < 2) {
      if (position.placementFirstLevel.length == 0) {
        member.placementSide = 1;
      } else {
        member.placementSide = 2;
      }
      
      member.placedUnder = _sponsor;
      position.placementFirstLevel.push(_addr);

      if (_sponsor != idToMember[1]) {
        position.passup++;
      }
      
      positionPlaceLastLevelL2(_addr, _sponsor, position.placedUnder, position.placementSide, _level);
    } else {

      if (position.placementLastLevel == 0) {
        member.placementSide = 1;
        member.placedUnder = position.placementFirstLevel[0];
        position.placementLastLevel += 1;      
      } else if ((position.placementLastLevel & 2) == 0) {
        member.placementSide = 2;
        member.placedUnder = position.placementFirstLevel[0];
        position.placementLastLevel += 2;
      } else if ((position.placementLastLevel & 4) == 0) {
        member.placementSide = 1;
        member.placedUnder = position.placementFirstLevel[1];
        position.placementLastLevel += 4;
      } else {
        member.placementSide = 2;
        member.placedUnder = position.placementFirstLevel[1];
        position.placementLastLevel += 8;
      }

      if (member.placedUnder != idToMember[1]) {
        members[member.placedUnder].x22Positions[_level].placementFirstLevel.push(_addr);        
      }
    }

    if ((position.placementLastLevel & 15) == 15) {
      emit Cycle(_sponsor, _addr, 2, _level);

      position.placementFirstLevel = new address[](0);
      position.placementLastLevel = 0;
      position.cycles++;

      if (_sponsor != idToMember[1]) {
        position.cycle++;

        sponsorPlaceL2(_sponsor, position.sponsor, _level, true);
      }
    }

    emit PlacementL2(_addr, _sponsor, _level, member.placementSide, member.placedUnder, passup);
  }

  function positionPlaceLastLevelL2(address _addr, address _sponsor, address _position, uint8 _placementSide, uint8 _level) internal {
    L2 storage position = members[_position].x22Positions[_level];

    if (position.placementSide == 0 && _sponsor == idToMember[1]) {
      return;
    }
    
    if (_placementSide == 1) {
      if ((position.placementLastLevel & 1) == 0) {
        position.placementLastLevel += 1;
      } else {
        position.placementLastLevel += 2;
      }
    } else {
      if ((position.placementLastLevel & 4) == 0) {
        position.placementLastLevel += 4;
      } else {
        position.placementLastLevel += 8;
      }
    }

    if ((position.placementLastLevel & 15) == 15) {
      emit Cycle(_position, _addr, 2, _level);

      position.placementFirstLevel = new address[](0);
      position.placementLastLevel = 0;
      position.cycles++;

      if (_position != idToMember[1]) {
        position.cycle++;

        sponsorPlaceL2(_position, position.sponsor, _level, true);
      }
    }
  }

  function findActiveSponsor(address _addr, address _sponsor, uint8 _matrix, uint8 _level, bool _emit) internal returns (address) {
    address sponsorAddress = _sponsor;

    while (true) {
      if (members[sponsorAddress].activeLevel[_matrix] >= _level) {
        return sponsorAddress;
      }

      if (_emit == true) {
        emit FundsPassup(sponsorAddress, _addr, (_matrix + 1), _level);
      }

      sponsorAddress = members[sponsorAddress].sponsor;
    }
  }

  function handleReEntryL1(address _addr, uint8 _level) internal {
    L1 storage member = members[_addr].x31Positions[_level];
    bool reentry = false;

    member.reEntryCheck++;

    if (member.reEntryCheck >= REENTRY_REQ) {
      address sponsor = members[_addr].sponsor;

      if (members[sponsor].activeLevel[0] >= _level) {
        member.reEntryCheck = 0;
        reentry = true;
      } else {
        sponsor = findActiveSponsor(_addr, sponsor, 0, _level, false);

        if (member.sponsor != sponsor && members[sponsor].activeLevel[0] >= _level) {        
          reentry = true;
        }
      }

      if (reentry == true) {
        member.sponsor = sponsor;

        emit PlacementReEntry(sponsor, _addr, 1, _level);
      }
    }
  }

  function handleReEntryL2(address _addr, uint8 _level) internal {
    L2 storage member = members[_addr].x22Positions[_level];
    bool reentry = false;

    member.reEntryCheck++;

    if (member.reEntryCheck >= REENTRY_REQ) {
      address sponsor = members[_addr].sponsor;

      if (members[sponsor].activeLevel[1] >= _level) {
        member.reEntryCheck = 0;
        member.sponsor = sponsor;
        reentry = true;
      } else {
        address active_sponsor = findActiveSponsor(_addr, sponsor, 1, _level, false);

        if (member.sponsor != active_sponsor && members[active_sponsor].activeLevel[1] >= _level) {
          member.sponsor = active_sponsor;
          reentry = true;
        }
      }

      if (reentry == true) {
        emit PlacementReEntry(member.sponsor, _addr, 2, _level);
      }
    }
  }

  function findPayoutReceiver(address _addr, uint8 _matrix, uint8 _level) internal returns (address) {    
    address from;
    address receiver;

    if (_matrix == 0) {      
      receiver = members[_addr].x31Positions[_level].sponsor;

      while (true) {
        L1 storage member = members[receiver].x31Positions[_level];

        if (member.passup == 0) {
          return receiver;
        }

        member.passup--;
        from = receiver;
        receiver = member.sponsor;

        if (_level > 1 && member.reEntryCheck > 0) {          
          handleReEntryL1(from, _level);
        }
      }
    } else {
      receiver = members[_addr].x22Positions[_level].sponsor;

      while (true) {
        L2 storage member = members[receiver].x22Positions[_level];

        if (member.passup == 0 && member.cycle == 0) {
          return receiver;
        }

        if (member.passup > 0) {
          member.passup--;
          receiver = member.placedUnder;
        } else {
          member.cycle--;
          from = receiver;
          receiver = member.sponsor;  

          if (_level > 1 && member.reEntryCheck > 0) {
            handleReEntryL2(from, _level);
          }
        }
      }
    }
  }

  function handlePayout(address _addr, uint8 _matrix, uint8 _level) internal {
    address receiver = findPayoutReceiver(_addr, _matrix, _level);

    emit FundsPayout(receiver, _addr, (_matrix + 1), _level);

    (bool success, ) = address(uint160(receiver)).call{ value: levelCost[_level], gas: 40000 }("");

    if (success == false) { //Failsafe to prevent malicious contracts from blocking matrix
      (success, ) = address(uint160(idToMember[1])).call{ value: levelCost[_level], gas: 40000 }("");
      require(success, 'Transfer Failed');
    }
  }

  function getAffiliateId() external view returns (uint) {
    return members[msg.sender].id;
  }

  function getAffiliateWallet(uint32 memberId) external view returns (address) {
    return idToMember[memberId];
  }

  function setupAccount(address _addr, address _sponsor, uint8 _level) external isOwner(msg.sender) {
    createAccount(_addr, _sponsor, false);
    compLevel(_addr, 1, _level);
    compLevel(_addr, 2, _level);
  }

  function compLevel(address _addr, uint8 _matrix, uint8 _level) public isOwner(msg.sender) isMember(_addr) {
    require((_matrix == 1 || _matrix == 2), "Invalid matrix identifier.");
    require((_level > 0 && _level <= topLevel), "Invalid matrix level.");

    uint8 matrix = _matrix - 1;
    uint8 activeLevel = members[_addr].activeLevel[matrix];
    address sponsor = members[_addr].sponsor;

    require((activeLevel < _level), "Already active at level!");

    for (uint8 num = (activeLevel + 1);num <= _level;num++) {
      Upgrade(_addr, sponsor, _matrix, num);

      if (matrix == 0) {
        handlePositionL1(_addr, sponsor, findActiveSponsor(_addr, sponsor, 0, num, true), num, false);
      } else {
        handlePositionL2(_addr, sponsor, findActiveSponsor(_addr, sponsor, 1, num, true), num, false);
      }
    }
  }

  function addLevel(uint _levelPrice) external isOwner(msg.sender) {
    require((levelCost[topLevel] < _levelPrice), "Check price point!");

    topLevel++;

    levelCost[topLevel] = _levelPrice;

    handlePositionL1(idToMember[1], idToMember[1], idToMember[1], topLevel, true);
    handlePositionL2(idToMember[1], idToMember[1], idToMember[1], topLevel, true);
  }

  function updateLevelCost(uint8 _level, uint _levelPrice) external isOwner(msg.sender) {
    require((_level > 0 && _level <= topLevel), "Invalid matrix level.");
    require((_levelPrice > 0), "Check price point!");

    if (_level > 1) {
      require((levelCost[(_level - 1)] < _levelPrice), "Check price point!");
    }

    if (_level < topLevel) {
      require((levelCost[(_level + 1)] > _levelPrice), "Check price point!");
    }

    levelCost[_level] = _levelPrice;
  }

  function bytesToAddress(bytes memory _source) private pure returns (address addr) {
    assembly {
      addr := mload(add(_source, 20))
    }
  }
}