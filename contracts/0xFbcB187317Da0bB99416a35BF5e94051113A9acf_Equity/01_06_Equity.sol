// SPDX-License-Identifier: MIT

/**
      _____                    _____                    _____                            _____                    _____                _____                    _____                _____                    _____                    _____          
     /\    \                  /\    \                  /\    \                          /\    \                  /\    \              /\    \                  /\    \              /\    \                  /\    \                  /\    \         
    /::\    \                /::\____\                /::\    \                        /::\    \                /::\    \            /::\    \                /::\    \            /::\    \                /::\    \                /::\    \        
    \:::\    \              /:::/    /               /::::\    \                      /::::\    \              /::::\    \           \:::\    \              /::::\    \           \:::\    \              /::::\    \              /::::\    \       
     \:::\    \            /:::/    /               /::::::\    \                    /::::::\    \            /::::::\    \           \:::\    \            /::::::\    \           \:::\    \            /::::::\    \            /::::::\    \      
      \:::\    \          /:::/    /               /:::/\:::\    \                  /:::/\:::\    \          /:::/\:::\    \           \:::\    \          /:::/\:::\    \           \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
       \:::\    \        /:::/____/               /:::/__\:::\    \                /:::/__\:::\    \        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
       /::::\    \      /::::\    \              /::::\   \:::\    \              /::::\   \:::\    \       \:::\   \:::\    \          /::::\    \      /::::\   \:::\    \          /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
      /::::::\    \    /::::::\    \   _____    /::::::\   \:::\    \            /::::::\   \:::\    \    ___\:::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /:::/\:::\    \  /:::/\:::\    \ /\    \  /:::/\:::\   \:::\    \          /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /:::/  \:::\____\/:::/  \:::\    /::\____\/:::/__\:::\   \:::\____\        /:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\    /:::/  \:::\____\/:::/  \:::\   \:::\____\    /:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/    \::/    /\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /        \:::\   \:::\   \::/    /\:::\   \:::\   \::/    /   /:::/    \::/    /\::/    \:::\  /:::/    /   /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    / \/____/  \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/          \:::\   \:::\   \/____/  \:::\   \:::\   \/____/   /:::/    / \/____/  \/____/ \:::\/:::/    /   /:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /                    \::::::/    /    \:::\   \:::\    \               \:::\   \:::\    \       \:::\   \:::\    \      /:::/    /                    \::::::/    /   /:::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /                      \::::/    /      \:::\   \:::\____\               \:::\   \:::\____\       \:::\   \:::\____\    /:::/    /                      \::::/    /   /:::/    /              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                       /:::/    /        \:::\   \::/    /                \:::\   \::/    /        \:::\  /:::/    /    \::/    /                       /:::/    /    \::/    /                \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                       /:::/    /          \:::\   \/____/                  \:::\   \/____/          \:::\/:::/    /      \/____/                       /:::/    /      \/____/                  \:::\   \/____/          \:::\/:::/    /     
                              /:::/    /            \:::\    \                       \:::\    \               \::::::/    /                                    /:::/    /                                 \:::\    \               \::::::/    /      
                             /:::/    /              \:::\____\                       \:::\____\               \::::/    /                                    /:::/    /                                   \:::\____\               \::::/    /       
                             \::/    /                \::/    /                        \::/    /                \::/    /                                     \::/    /                                     \::/    /                \::/    /        
                              \/____/                  \/____/                          \/____/                  \/____/                                       \/____/                                       \/____/                  \/____/         

 * @title Equity
 * $EQUITY IS A UTILITY TOKEN FOR THE THE ESTATES ECOSYSTEM.
 * $EQUITY is NOT an investment and has NO economic value.
 */


pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface iEstate {
    function balanceOf(address owner) external view returns (uint256);
}

contract Equity is ERC20, Ownable {
	// Events
	event EquityGranted(address user, uint256 amount);
	event EquityBurnt(address user, uint256 amount);

    // Permissions mapping system
    struct Perms {
        bool Grantee;
        bool Burner;
    }
    mapping(address => Perms) public permsMap;

    constructor(address _estatesContract) ERC20("EQUITY", "EQY") {
    }

    function grantEquity(address _address, uint256 _amount) external {
        require(
            permsMap[msg.sender].Grantee,
            "Address does not have permission to distribute tokens"
        );
        _mint(_address, _amount);
        emit EquityGranted(_address, _amount);
    }

    function burn(address _address, uint256 _amount) external {
        require(
            permsMap[msg.sender].Burner,
            "Address does not have permission to burn tokens"
        );
        _burn(_address, _amount);
		emit EquityBurnt(_address, _amount);
    }

	/** *********************************** **/
	/** ********* Owner Functions ****** **/
	/** *********************************** **/

	// Staking contract will need to be added as a grantee and burner
	// Estates contract will need to be added as burner
    function setAllowedAddresses(
        address _address,
        bool _grant,
        bool _burn
    ) external onlyOwner {
        permsMap[_address].Grantee = _grant;
        permsMap[_address].Burner = _burn;
    }	
}