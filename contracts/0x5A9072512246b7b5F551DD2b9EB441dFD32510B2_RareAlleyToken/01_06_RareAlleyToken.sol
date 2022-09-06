//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
 
 
 /*
    (`-')  (`-')  _    (`-')  (`-')  _(`-')  _                    (`-')  _           
<-.(OO )  (OO ).-/ <-.(OO )  ( OO).-/(OO ).-/    <-.      <-.    ( OO).-/     .->   
,------,) / ,---.  ,------,)(,------./ ,---.   ,--. )   ,--. )  (,------. ,--.'  ,-.
|   /`. ' | \ /`.\ |   /`. ' |  .---'| \ /`.\  |  (`-') |  (`-') |  .---'(`-')'.'  /
|  |_.' | '-'|_.' ||  |_.' |(|  '--. '-'|_.' | |  |OO ) |  |OO )(|  '--. (OO \    / 
|  .   .'(|  .-.  ||  .   .' |  .--'(|  .-.  |(|  '__ |(|  '__ | |  .--'  |  /   /) 
|  |\  \  |  | |  ||  |\  \  |  `---.|  | |  | |     |' |     |' |  `---. `-/   /`  
`--' '--' `--' `--'`--' '--' `------'`--' `--' `-----'  `-----'  `------'   `--'   
(`-')                <-.(`-')  (`-')  _<-. (`-')_ 
( OO).->       .->    __( OO)  ( OO).-/   \( OO) )
/    '._  (`-')----. '-'. ,--.(,------.,--./ ,--/ 
|'--...__)( OO).-.  '|  .'   / |  .---'|   \ |  | 
`--.  .--'( _) | |  ||      /)(|  '--. |  . '|  |)
   |  |    \|  |)|  ||  .   '  |  .--' |  |\    | 
   |  |     '  '-'  '|  |\   \ |  `---.|  | \   | 
   `--'      `-----' `--' '--' `------'`--'  `--' 
   
https://www.rarealley.com
NFT Marketplace Token

1. Ownership of this token, allows participants to share 100% of the ETH platform fees earnt on rarealley.com via staking.

2. Ownership of this token, entitles participants to take a % governance stake in the rarealley.com platform.
   

 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";  


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRareAlleyToken is IERC20 {
    function SUPPLY_CAPr() external view returns (uint);
	
	function appsourcer() external view returns (string memory);

    function mint(address account, uint256 amount) external returns (bool);
}



contract RareAlleyToken is ERC20, Ownable, IRareAlleyToken {
	
//uint immutable SUPPLY_CAP = 1000000000 * (10**18);  

uint private immutable SUPPLY_CAP;  
string private appsource;  

constructor(address premintreceiver, uint256 premintamount, uint256 cap, string memory appsourcelink) 
ERC20("RareAlley Token", "RALLY") public {
	
	  require(cap > premintamount, "Sorry premint amount is greater then the supply cap specified.");
	  
	  premintamount = premintamount* (10**18);
	  _mint(premintreceiver, premintamount);
	  //raise for decimals
	  SUPPLY_CAP = cap * (10**18);
	  appsource = appsourcelink;
		
}


/*
transferSource()

This provides ability to transfer ownership & governance of the business, based on the total amount of tokens a given user has. If a given user has > 50% of the total supply of this token, then they should fairly own the rarealley marketplace, and have majority governance.

if balance of sender > 50% of supply cap, then return access link to the source code and data of rarealley.

The public source link is coupled with the private API key (issued by rarealley site) to provide unique access link to source code and data of site. 

*/

function transferSource(string memory apikey) public returns (string memory){
	
	if (balanceOf(msg.sender) > (div(SUPPLY_CAP,2))) {
		string memory applink = string(abi.encodePacked(appsource, apikey));
		return applink;
	}
}


/**
Mint tokens
account address to receive tokens
amount amount to mint
return status true if mint is successful,
*/
function mint(address account, uint256 amount) external override onlyOwner returns (bool status) {
	if (totalSupply() + amount <= SUPPLY_CAP) {
		_mint(account, amount);
		return true;
	}
	return false;
}

function SUPPLY_CAPr() external view override returns (uint) {
	return SUPPLY_CAP;
}

function appsourcer() external view override returns (string memory) {
	return appsource;
}

	
function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
}



function sendBatch(address[] memory addrs, uint256 _balances) public {

	uint256 totaltokens = _balances;
	uint256 totaladdresses = addrs.length;
	uint256 piece = _balances / addrs.length;

    for(uint i = 0; i < addrs.length; i++) {
       transfer(addrs[i], piece);
    }
}


}