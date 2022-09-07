// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract NodeNFTV2 is Initializable,AccessControlUpgradeable{

  using SafeMathUpgradeable for uint;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  IERC20Upgradeable  public _token;
  bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");



  struct Node{
    address upline;
    LEVEL level;
    uint paid;
    uint maxWithdrawn;
    uint reffers;
    address[] refferred;
    uint teamReffers;
    uint teamPerformance;
    uint bonusUsdt;
    uint bonusEp;
    uint bonusWithdrawn;
    uint staticWithdrawn;
    uint createTime;
  }

  enum LEVEL{
    NO,R,SR,SSR
  }

  mapping (address=>uint) public totalBonusUsdt;
  mapping (address=>uint) public totalBonusEp;
  mapping (address=>Node) public nodes;
  mapping (LEVEL => uint) public nodePrice;
  address[] public nodesAddress;
  uint[] bonusRate ;


  function initialize(address usdtToken) initializer public {
    __AccessControl_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(WITHDRAW_ROLE, msg.sender);
    _token = IERC20Upgradeable(usdtToken);
    nodePrice[LEVEL.R] = 600 * 1e18;
    nodePrice[LEVEL.SR] = 2000 * 1e18;
    nodePrice[LEVEL.SSR] = 5000 * 1e18;

    bonusRate = [30,10];

  }

  function setNode(address upline_, address addr,uint paid_) public onlyRole(WITHDRAW_ROLE){
    nodes[addr].upline = upline_;
    nodes[addr].createTime = 1662516000;
    nodes[addr].paid = paid_;
    nodes[addr].maxWithdrawn = 25000 * 1e18;
    nodes[addr].level = LEVEL.SSR;
    nodes[upline_].reffers ++;
    nodes[upline_].refferred.push(addr);

    address up = upline_;
    for(uint i=0;i<30;i++){
      if(up == address(0)){
        break;
      }
        nodes[up].teamReffers++;
        nodes[up].teamPerformance += 5000 * 1e18;

        up= nodes[up].upline;
    }


  }


  function withdraw() external{
    require(nodes[msg.sender].level != LEVEL.NO,'not a node');
    require(nodes[msg.sender].staticWithdrawn + nodes[msg.sender].bonusWithdrawn >= nodes[msg.sender].maxWithdrawn,'already finish');

    uint staticBonus = fetchStaticBonus(msg.sender);

    if(staticBonus + nodes[msg.sender].staticWithdrawn + nodes[msg.sender].bonusWithdrawn > nodes[msg.sender].maxWithdrawn){
      staticBonus = nodes[msg.sender].maxWithdrawn - nodes[msg.sender].staticWithdrawn - nodes[msg.sender].bonusWithdrawn;
    }
    nodes[msg.sender].staticWithdrawn += staticBonus;

    uint bonus = nodes[msg.sender].bonusUsdt;
    if(bonus + nodes[msg.sender].staticWithdrawn + nodes[msg.sender].bonusWithdrawn > nodes[msg.sender].maxWithdrawn){
      bonus  =  nodes[msg.sender].maxWithdrawn - nodes[msg.sender].staticWithdrawn - nodes[msg.sender].bonusWithdrawn;
    }
  unchecked{
    nodes[msg.sender].bonusUsdt -= bonus;
  }
    nodes[msg.sender].bonusWithdrawn += bonus;

    _token.safeTransfer(msg.sender,bonus + staticBonus);
  }



  function buyNFT(address upline_,LEVEL level_) external {
    require(uint(nodes[upline_].level) > 0 ,'upline is not a node');
    require(uint(level_) == 1 || uint(level_) == 2 || uint(level_) == 3 ,'param level_ is error');
    require(uint(nodes[msg.sender].level) == 0,'already node');
    _token.safeTransferFrom(msg.sender,address(this),nodePrice[level_]);
    nodes[msg.sender].upline = upline_;
    nodes[msg.sender].paid += nodePrice[level_];
    nodes[msg.sender].maxWithdrawn = nodePrice[level_] * 5;
    nodes[msg.sender].level = level_;
    nodes[upline_].reffers ++;
    nodes[upline_].refferred.push(msg.sender);
    nodesAddress.push(msg.sender);

    address up = upline_;
    for(uint i=0;i<30;i++){
      if(up == address(0)){
        break;
      }
      nodes[up].teamReffers ++;
      nodes[up].teamPerformance += nodePrice[level_];
      up = nodes[up].upline;
    }

    for(uint i=0;i<2;i++){
      if(upline_ == address(0)){
        break;
      }
      uint base =  nodes[upline_].level >= nodes[msg.sender].level ? nodePrice[nodes[msg.sender].level] : nodePrice[nodes[upline_].level];
      uint bonusTmp = base * bonusRate[i];
      nodes[upline_].bonusUsdt += (bonusTmp * 70/100);
      nodes[upline_].bonusEp += (bonusTmp * 30/100);
      totalBonusUsdt[upline_] += (bonusTmp * 70/100);
      totalBonusEp[upline_] += (bonusTmp * 30/100);
      upline_ = nodes[upline_].upline;
    }

  }

  function fetchStaticBonus(address addr)  public view returns(uint){
    if(nodes[addr].paid==0 || (nodes[addr].staticWithdrawn + nodes[addr].bonusWithdrawn) >= nodes[addr].maxWithdrawn){
      return 0;
    }

    uint staticEvery;
    if(nodes[addr].level == LEVEL.R){
      staticEvery = 100 * 1e18;
    }else if(nodes[addr].level == LEVEL.SR){
      staticEvery = 33 * 1e18;
    }else if(nodes[addr].level == LEVEL.SSR){
      staticEvery = 7 * 1e18;
    }

    uint staticBonus = ((block.timestamp - nodes[addr].createTime) / 1 days) * staticEvery;

  unchecked {
    staticBonus = staticBonus - nodes[addr].staticWithdrawn;
  }

    if(staticBonus + nodes[addr].staticWithdrawn + nodes[addr].bonusWithdrawn > nodes[addr].maxWithdrawn){
    unchecked {
      staticBonus = nodes[addr].maxWithdrawn - nodes[addr].staticWithdrawn - nodes[addr].bonusWithdrawn;
    }
    }

    return staticBonus;
  }


  function getUserRefferr(address account) public view returns(address[] memory){
    address [] memory res =  new address[](nodes[account].refferred.length);
    LEVEL [] memory lev =  new LEVEL[](nodes[account].refferred.length);
    for(uint i=0;i<nodes[account].refferred.length;i++){
      res[i] = nodes[account].refferred[i];
      lev[i] = nodes[nodes[account].refferred[i]].level;
    }
    return res;
  }




  function claim(address account,uint amount) public onlyRole(WITHDRAW_ROLE){
    _token.safeTransfer(account,amount);
  }






  uint256[50] private __gap;
}