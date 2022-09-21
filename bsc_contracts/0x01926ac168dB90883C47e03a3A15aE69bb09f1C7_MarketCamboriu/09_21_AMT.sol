// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AMT is ERC20Snapshot, Ownable{

    string nameForDeploy = "AutoMiningToken";
    string symbolForDeploy = "AMT";
    constructor (string memory _name, string memory _symbol) ERC20(nameForDeploy,symbolForDeploy){}
    
    function mint(address account, uint256 amount) public onlyOwner(){
        require(totalSupply()+amount<100000000*(10**18),"Total supply must not exceed 100.000.000 ATM");
		_mint(account,amount);		
    }
	
    function snapshot() public onlyOwner returns(uint256){
        return _snapshot();
    }

    function getCurrentSnapshotId() public view returns(uint256) {
        return _getCurrentSnapshotId();
    }

    // burning functions
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

}