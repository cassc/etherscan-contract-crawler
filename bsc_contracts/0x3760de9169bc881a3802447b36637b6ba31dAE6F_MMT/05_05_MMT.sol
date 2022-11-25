// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MMT is ERC20{

    address burnAddress;

    modifier  checkBurn(){
        require(burnAddress==msg.sender,"The address permission is insufficient and cannot be destroyed");
        _;
    }

    constructor(uint256 initSupply,address _to) ERC20("Ms Meta","MMT"){
        _mint(_to, initSupply);
        burnAddress=_to;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }


    function burn(uint256 amount)public checkBurn{
        _burn(msg.sender,amount);
    }
    
}