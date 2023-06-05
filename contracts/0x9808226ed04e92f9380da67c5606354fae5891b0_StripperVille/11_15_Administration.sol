// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Administration is Ownable {
    
    event SetAdmin(address indexed admin, bool active);
    
    mapping (address => bool) private admins;
    
    modifier onlyAdmin(){
        require(admins[_msgSender()] || owner() == _msgSender(), "Admin: caller is not an admin");
        _;
    }
    
    function setAdmin(address admin, bool active) external onlyOwner {
        admins[admin] = active;
        emit SetAdmin(admin, active);
    }
    
}