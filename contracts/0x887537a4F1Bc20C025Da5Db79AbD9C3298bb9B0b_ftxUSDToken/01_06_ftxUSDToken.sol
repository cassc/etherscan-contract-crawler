// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";  
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract ftxUSDToken is ERC20, Ownable {
    uint8 private _decimals;
    address private _admin;
    constructor(
        string memory name_,
        string memory symbol,
        uint256 supply,
        uint8 decimals_,
        address admin
    ) ERC20(name_, symbol) {
        _decimals = decimals_;
        _admin = admin;
        transferOwnership(_admin);
        _mint(msg.sender, supply);
    }

      
     function decimals() public view override returns (uint8) {
        return _decimals;
     }
     
     function setAdmin(address admin) external onlyOwner {
        _admin = admin;
     }

     function mint(uint256 _amount) external {
        require(msg.sender == _admin);
        _mint(msg.sender, _amount);
     }
     
     
}