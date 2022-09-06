pragma solidity >=0.4.21 <0.7.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Pausable.sol";


//pausable
contract ERC20WithPausable is ERC20, ERC20Detailed, ERC20Pausable {
    constructor(
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        uint256 totalSupply, 
        address adminAddress
    ) public ERC20Detailed(name, symbol, decimals) {
        _mint(adminAddress, totalSupply * (10**uint256(decimals)));
    }
}

