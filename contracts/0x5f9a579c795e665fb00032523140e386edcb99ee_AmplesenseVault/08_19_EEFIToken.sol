// SPDX-License-Identifier: NONE
pragma solidity 0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ERC20Burnable.sol';

//Note: Only the Amplesense vault contract (AmplesenseVault.sol) is authorized to mint or burn EEFI 

contract EEFIToken is ERC20Burnable, Ownable {
    constructor() 
    ERC20("Amplesense Elastic Finance token", "EEFI")
    Ownable() {
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}