// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Uroboros is ERC20,Ownable {

mapping (address=>uint256) burnedTokensAmount;
mapping (address=>uint256) burnedTokensTime;


 constructor() ERC20("Uroboros","UBS") {
     	_mint(0x015124c4BDBc5380e52A6B22df5f83f7B6C4E06C,1000000*10**decimals());
 }


function burn(uint amount) external {
    require(amount>0,"burn more then 0");
    _burn(msg.sender,amount*10**decimals());

if (getRewardsAmount(msg.sender)>0) {
    _mint(msg.sender,getRewardsAmount(msg.sender)*10**decimals());
}

burnedTokensAmount[msg.sender]+=amount;
burnedTokensTime[msg.sender]=block.timestamp;

}

function getRewardsAmount (address user) public view returns (uint256 rewards) {
         if (burnedTokensTime[user]>0 && burnedTokensAmount[user]>100)
            return ((block.timestamp-burnedTokensTime[user])/(24*60*60)*(burnedTokensAmount[user]/100));
         else 
            return 0;
}


function mintRewards() external {
    _mint(msg.sender,getRewardsAmount(msg.sender)*10**decimals());
    burnedTokensTime[msg.sender]=block.timestamp;
}
 
function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}