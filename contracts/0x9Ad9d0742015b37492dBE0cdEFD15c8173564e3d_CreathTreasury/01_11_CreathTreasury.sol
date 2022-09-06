//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// A Smart-contract that holds the Creath Marketplace funds
contract CreathTreasury is AccessControl{
    using SafeERC20 for IERC20;

    //marketplace address
    address public marketplace;
    // usdt address
    IERC20 public USDT;

    //create a mapping so other addresses can interact with this wallet. 
    mapping(address => bool) private _admins;

    // Event triggered once an address withdraws from the contract
    event Withdraw(address indexed user, uint amount);

    // Emitted when marketplace address is set
    event MarketplaceSet( address _address);

    // Restricted to authorised accounts.
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), 
        "Treasury:Restricted to only authorized accounts.");
        _;
    }


    constructor(address _admin, address _usdt){
        _setupRole("admin", _admin); 
        _admins[_admin] = true;
        USDT = IERC20(_usdt);
    }


    /**
     * @notice check if address is authorized 
     * @param account the address of account to be checked
     * @return bool return true if account is authorized and false otherwise
     */
    function isAuthorized(address account)
        public view returns (bool)
    {
        if(hasRole("admin",account)) return true;

        else if(hasRole("marketplace", account)) return true;

        return false;
    }



    //this function is used to add admin of the treasury.  OnlyOwner can add addresses.
    function addAdmin(address admin) 
        onlyRole("admin")
        public {
       _admins[admin] = true;
        _grantRole("admin", admin);
    }
    
    //remove an admin from the treasury.
    function removeAdmin(address admin)
        onlyRole("admin")
        public {
        _admins[admin] = false;   
        _revokeRole("admin", admin);
    }


    /**
     * @notice withdraw cro
     * @param _amount the withdrawal amount
     */
    function withdraw(address _to, uint _amount) public onlyAuthorized{
        USDT.safeTransfer(_to, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function updateToken(address _token) external onlyRole("admin") {
      USDT = IERC20(_token);
    } 

    receive () external payable{
        
    }
    
}