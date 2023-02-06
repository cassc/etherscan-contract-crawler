//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract Metabet is ERC20, AccessControl {

    //create a mapping so other addresses can interact with this wallet. 
    mapping(address => bool) private _admins;

    // Restricted to authorised accounts.
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), 
        "Metabet:Restricted to only authorized accounts.");
        _;
    }

    constructor(address _admin) ERC20("Metabet Token", "METABET") {
        _setupRole("admin", _admin); 
        _admins[_admin] = true;
    }

    function isAuthorized(address account)
        public view returns (bool)
    {
        if(hasRole("admin",account)) return true;
    }


    function addAdmin(address admin) 
        onlyAuthorized
        public {
       _admins[admin] = true;
        _grantRole("admin", admin);
    }
    

    function removeAdmin(address admin)
        onlyAuthorized
        public {
        _admins[admin] = false;   
        _revokeRole("admin", admin);
    }

    function airdrop(address _to, uint256 _amount) external onlyAuthorized {
        _mint(_to, _amount);
    }
}