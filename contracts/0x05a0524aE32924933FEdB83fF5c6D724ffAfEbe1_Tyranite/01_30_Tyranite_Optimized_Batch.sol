// SPDX-License-Identifier: MIT


/*__/\\\\\\\\\\\\\\\__/\\\________/\\\____/\\\\\\\\\_________/\\\\\\\\\_____/\\\\\_____/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\\\\_        
 _\///////\\\/////__\///\\\____/\\\/___/\\\///////\\\_____/\\\\\\\\\\\\\__\/\\\\\\___\/\\\_\/////\\\///__\///////\\\/////__\/\\\///////////__       
  _______\/\\\_________\///\\\/\\\/____\/\\\_____\/\\\____/\\\/////////\\\_\/\\\/\\\__\/\\\_____\/\\\___________\/\\\_______\/\\\_____________      
   _______\/\\\___________\///\\\/______\/\\\\\\\\\\\/____\/\\\_______\/\\\_\/\\\//\\\_\/\\\_____\/\\\___________\/\\\_______\/\\\\\\\\\\\_____     
    _______\/\\\_____________\/\\\_______\/\\\//////\\\____\/\\\\\\\\\\\\\\\_\/\\\\//\\\\/\\\_____\/\\\___________\/\\\_______\/\\\///////______    
     _______\/\\\_____________\/\\\_______\/\\\____\//\\\___\/\\\/////////\\\_\/\\\_\//\\\/\\\_____\/\\\___________\/\\\_______\/\\\_____________   
      _______\/\\\_____________\/\\\_______\/\\\_____\//\\\__\/\\\_______\/\\\_\/\\\__\//\\\\\\_____\/\\\___________\/\\\_______\/\\\_____________  
       _______\/\\\_____________\/\\\_______\/\\\______\//\\\_\/\\\_______\/\\\_\/\\\___\//\\\\\__/\\\\\\\\\\\_______\/\\\_______\/\\\\\\\\\\\\\\\_ 
        _______\///______________\///________\///________\///__\///________\///__\///_____\/////__\///////////________\///________\///////////////__
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/Tyranz_Genesis_721FAT.sol";
import "contracts/Drill_1155.sol";

contract Tyranite is ERC20 {

    struct token_ids{uint256 ids;}
    
    mapping(address => mapping(uint256 => uint256)) private checkpoints;
    mapping(address => token_ids[]) private deposited_ids;
    mapping(address => mapping(uint256 => bool)) private has_deposited;
    mapping(uint256 => uint256) private token_mined;
    mapping(address => bool) public Owner;
    
    TyranzGenesis public nft;
    TyraniteDrill public item;
    
    uint256 public blockReward = 0.0007 ether;    
    uint256 public maxSupply = 60644750 ether;
    uint256 public maxreward = 18250 ether;
    uint256 public maxreward2 = 27375 ether;
     
       

    constructor(address drillContract,address GenesisContract) ERC20("Tyranite", "TNT") { 
        Owner[msg.sender] = true;
        item = TyraniteDrill(drillContract);
        nft = TyranzGenesis(GenesisContract);
       
         
    }

    function deposit(uint256 tokenid) public {

        
      unchecked{
        address depositary = msg.sender;
        

        if(totalSupply() >= maxSupply) revert ("Max Supply Reached");

        if(nft.legendary(tokenid) == true){
          if(nft.revlegendary(tokenid) == false) {
            revert ("Primal not Revealed");
          }else{if(token_mined[tokenid] >= maxreward2) revert ("Max Reward Reached");}
        }else{if(token_mined[tokenid] >= maxreward) revert ("Max Reward Reached");}   
        
        nft.transferFrom(depositary, address(this),tokenid);
        checkpoints[depositary][tokenid] = block.number;
        has_deposited[depositary][tokenid] = true;
        deposited_ids[depositary].push(token_ids(tokenid));
      }
    }

    
    function batch_deposit(uint256[]memory tokenid) public {
 
      unchecked{
        address depositary = msg.sender;
        
        if(totalSupply() >= maxSupply) revert ("Max Supply Reached");

        for(uint256 i = 0;i<tokenid.length;i++){
          uint256 id = tokenid[i];
          if(nft.legendary(id) == true){
          if(nft.revlegendary(id) == false) {
            revert ("Primal not Revealed");
          }else{if(token_mined[id] >= maxreward2) revert ("Max Reward Reached");}
        }else{if(token_mined[id] >= maxreward) revert ("Max Reward Reached");}   
        
        nft.transferFrom(depositary, address(this),id);
        checkpoints[depositary][id] = block.number;
        has_deposited[depositary][id] = true;
        deposited_ids[depositary].push(token_ids(id));
        }
      }
    }

    function withdraw(uint256 tokenid) public{
      unchecked{
       address depositary = msg.sender;

        if(has_deposited[depositary][tokenid] == false) revert ("Invalid Token Id");

        collect(tokenid);
        nft.transferFrom(address(this), depositary,tokenid);
        has_deposited[depositary][tokenid] = false;
        
        
          uint256 length = deposited_ids[depositary].length;
          for(uint256 i = 0;i<length;i++){
          
          if(tokenid == deposited_ids[depositary][i].ids){
            
                deposited_ids[depositary][i].ids = deposited_ids[depositary][length-1].ids;
                deposited_ids[depositary].pop();
                break;    
            }
            
          }
        }
          

      }

    function batch_withdraw(uint256[] memory tokenid) public{
      unchecked{

       address depositary = msg.sender;

        for(uint256 z = 0;z<tokenid.length;z++){
          uint256 id = tokenid[z];
          if(has_deposited[depositary][id] == false) revert ("Invalid Token Id");

          collect(id);
          nft.transferFrom(address(this), depositary,id);
          has_deposited[depositary][id] = false;
        
        
          uint256 length = deposited_ids[depositary].length;

          for(uint256 i = 0;i<length;i++){
          
            if(id == deposited_ids[depositary][i].ids){
            
              deposited_ids[depositary][i].ids = deposited_ids[depositary][length-1].ids;
              deposited_ids[depositary].pop();
              break;    
            }
            
          }
          
        }
          

      }
        
    }      
    


    function collect(uint256 tokenid) public {
      unchecked{
        
          address depositary = msg.sender;

          if(has_deposited[depositary][tokenid] != true) revert ("No Tokens to Withdarw");
          uint256 reward = calculateReward(tokenid);
          token_mined[tokenid] += reward;
          _mint(depositary, reward);
          checkpoints[depositary][tokenid] = block.number;
          
      }  
        

    }

    function batch_collect(uint256[] memory tokenid) public {
      unchecked{
        address depositary = msg.sender;

        for(uint256 i = 0;i<tokenid.length;i++){
          uint256 id = tokenid[i];
          if(has_deposited[depositary][id] != true) revert ("No Tokens to Withdarw");
        
        
          uint256 reward = calculateReward(id);
        

          token_mined[id] += reward;
          _mint(depositary, reward);
          checkpoints[depositary][id] = block.number;
        }  
      }  
        

    }


//Admin Pannel---------------------------------------------------------------------    

    function update_blockReward(uint256 new_blockReward) public {
      if(Owner[msg.sender] != true) revert ("Staff Use Only");
      blockReward = new_blockReward;//remember to type value in wei

    }

    function airdrop(address beneficiary,uint256 amount) public {
       if(Owner[msg.sender] != true) revert ("Staff Use Only");
        _mint(beneficiary,amount);//remember to type value in wei
    }

    function multisender (address[] memory address_list, uint256[] memory amounts) public {
        if(Owner[msg.sender] != true) revert ("Staff Use Only");
          for(uint256 i=0;i<address_list.length;i++){
            _mint(address_list[i],amounts[i]);
          }
    }
    function adminrole(address new_admin,bool role) public {
      if(Owner[msg.sender] != true) revert ("Staff Use Only");
        Owner[new_admin] = role;
    }

    function set_maxRewards(uint256 new_maxrw,uint256 new_maxrw2) public {
      if(Owner[msg.sender] != true) revert ("Staff Use Only");
      //remember to type value in wei
        maxreward = new_maxrw;
        maxreward2 = new_maxrw2;
    }

    
//METRICS-----------------------------------------------------------------------
     function calculateReward(uint256 tokenid) public view returns(uint256 rewards) {
      unchecked{
        address depositary = msg.sender;
        if(has_deposited[depositary][tokenid] == false||totalSupply() >= maxSupply) {return 0;}

        uint256 Drill = item.balanceOf(depositary,1);
        uint256 reward = (block.number - checkpoints[depositary][tokenid]) * blockReward;
        uint256 temp_mined = token_mined[tokenid];
        uint256 temp_maxreward = 18250 ether;

        if(nft.Injected(tokenid) == true){
          
          if(temp_mined >= temp_maxreward) {return 0;}

          if(Drill == 0) 
          {if((reward*2) + temp_mined >= temp_maxreward) 
           {return temp_maxreward - temp_mined;}return reward *2;}  

          if(Drill == 1) 
          {if(((reward/4) + reward) + reward + temp_mined >= temp_maxreward) 
           {return temp_maxreward - temp_mined;}return ((reward/4) + reward) + reward;}

          if(Drill == 2) 
          {if(((reward/2) + reward) + reward + temp_mined >= temp_maxreward) 
           {return temp_maxreward - temp_mined;}return ((reward/2) + reward) + reward;}

          if(Drill >= 3) 
          {if((reward *2) + reward + temp_mined >= temp_maxreward) 
           {return temp_maxreward - temp_mined;}return (reward *2) + reward;}


        }

        
        if(nft.revlegendary(tokenid) == false){
          
          if(temp_mined >= temp_maxreward) {return 0;}
          
          if(Drill == 0) 
          {if(reward + temp_mined >= temp_maxreward) {return temp_maxreward - temp_mined;}return reward;}  

          if(Drill == 1) 
          {if(((reward/4) + reward)  + temp_mined >= temp_maxreward) 
           {return temp_maxreward - temp_mined;}return ((reward/4) + reward);}

          if(Drill == 2) 
          {if(((reward/2) + reward)  + temp_mined >= temp_maxreward) 
           {return temp_maxreward - temp_mined;}return ((reward/2) + reward);}

          if(Drill >= 3) 
          {if((reward *2)  + temp_mined >= temp_maxreward) 
           {return temp_maxreward - temp_mined;}return (reward *2);}

        }else
        
        {
          uint256 temp_maxreward2 = 27375 ether; 
          if(temp_mined >= temp_maxreward2) {return 0;}
          
          if(Drill == 0) 
           {if((reward*2) + temp_mined >= temp_maxreward2) 
           {return temp_maxreward2 - temp_mined;}return reward*2;}  

          if(Drill == 1) 
          {if(((reward/4) + reward) + reward + temp_mined >= temp_maxreward2) 
           {return temp_maxreward2 - temp_mined;}return ((reward/4) + reward) + reward;}

          if(Drill == 2) 
          {if(((reward/2) + reward) + reward + temp_mined >= temp_maxreward2) 
           {return temp_maxreward2 - temp_mined;}return ((reward/2) + reward) + reward;}

          if(Drill >= 3) 
          {if((reward *2) + reward + temp_mined >= temp_maxreward2) 
           {return temp_maxreward2 - temp_mined;}return (reward *2) + reward;}
  
        }
      }

   
    }



    function nft_isDelegated(uint256 tokenid) public view returns(bool)
    {
      return has_deposited[msg.sender][tokenid];
   
    }

    function nft_tokenclaimed(uint256 tokenid) public view returns(uint256)
    {
      return token_mined[tokenid];
   
    }

    function nft_id_in_Staking(address Staker) public view returns(token_ids[] memory)
    {
      
      return deposited_ids[Staker];
   
    }

    
    function nft_id_in_Wallet(address Staker) public view returns(uint256[] memory)
    {
      return nft.tokensOfOwner(Staker);
   
    }

    function drill_in_Wallet(address Staker) public view returns(uint256)
    {
      return item.balanceOf(Staker,1);
   
    }

    function isInjected(uint256 tokenid) public view returns(bool) {
      return nft.Injected(tokenid);
    }

    

    

    

  

    

    
    
}