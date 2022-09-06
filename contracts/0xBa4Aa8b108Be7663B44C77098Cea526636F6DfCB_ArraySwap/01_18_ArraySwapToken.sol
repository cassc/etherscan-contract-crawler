// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*                                                                                                                                                                                                       
                                                                                                                                                                                                       
               AAA                                                                                               SSSSSSSSSSSSSSS                                                                       
              A:::A                                                                                            SS:::::::::::::::S                                                                      
             A:::::A                                                                                          S:::::SSSSSS::::::S                                                                      
            A:::::::A                                                                                         S:::::S     SSSSSSS                                                                      
           A:::::::::A          rrrrr   rrrrrrrrr   rrrrr   rrrrrrrrr   aaaaaaaaaaaaayyyyyyy           yyyyyyyS:::::S      wwwwwww           wwwww           wwwwwwwaaaaaaaaaaaaa  ppppp   ppppppppp   
          A:::::A:::::A         r::::rrr:::::::::r  r::::rrr:::::::::r  a::::::::::::ay:::::y         y:::::y S:::::S       w:::::w         w:::::w         w:::::w a::::::::::::a p::::ppp:::::::::p  
         A:::::A A:::::A        r:::::::::::::::::r r:::::::::::::::::r aaaaaaaaa:::::ay:::::y       y:::::y   S::::SSSS     w:::::w       w:::::::w       w:::::w  aaaaaaaaa:::::ap:::::::::::::::::p 
        A:::::A   A:::::A       rr::::::rrrrr::::::rrr::::::rrrrr::::::r         a::::a y:::::y     y:::::y     SS::::::SSSSS w:::::w     w:::::::::w     w:::::w            a::::app::::::ppppp::::::p
       A:::::A     A:::::A       r:::::r     r:::::r r:::::r     r:::::r  aaaaaaa:::::a  y:::::y   y:::::y        SSS::::::::SSw:::::w   w:::::w:::::w   w:::::w      aaaaaaa:::::a p:::::p     p:::::p
      A:::::AAAAAAAAA:::::A      r:::::r     rrrrrrr r:::::r     rrrrrrraa::::::::::::a   y:::::y y:::::y            SSSSSS::::Sw:::::w w:::::w w:::::w w:::::w     aa::::::::::::a p:::::p     p:::::p
     A:::::::::::::::::::::A     r:::::r             r:::::r           a::::aaaa::::::a    y:::::y:::::y                  S:::::Sw:::::w:::::w   w:::::w:::::w     a::::aaaa::::::a p:::::p     p:::::p
    A:::::AAAAAAAAAAAAA:::::A    r:::::r             r:::::r          a::::a    a:::::a     y:::::::::y                   S:::::S w:::::::::w     w:::::::::w     a::::a    a:::::a p:::::p    p::::::p
   A:::::A             A:::::A   r:::::r             r:::::r          a::::a    a:::::a      y:::::::y        SSSSSSS     S:::::S  w:::::::w       w:::::::w      a::::a    a:::::a p:::::ppppp:::::::p
  A:::::A               A:::::A  r:::::r             r:::::r          a:::::aaaa::::::a       y:::::y         S::::::SSSSSS:::::S   w:::::w         w:::::w       a:::::aaaa::::::a p::::::::::::::::p 
 A:::::A                 A:::::A r:::::r             r:::::r           a::::::::::aa:::a     y:::::y          S:::::::::::::::SS     w:::w           w:::w         a::::::::::aa:::ap::::::::::::::pp  
AAAAAAA                   AAAAAAArrrrrrr             rrrrrrr            aaaaaaaaaa  aaaa    y:::::y            SSSSSSSSSSSSSSS        www             www           aaaaaaaaaa  aaaap::::::pppppppp    
                                                                                           y:::::y                                                                                  p:::::p            
                                                                                          y:::::y                                                                                   p:::::p            
                                                                                         y:::::y                                                                                   p:::::::p           
                                                                                        y:::::y                                                                                    p:::::::p           
                                                                                       yyyyyyy                                                                                     p:::::::p           
                                                                                                                                                                                   ppppppppp                                                                                                                                                                                                                
*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract ArraySwap is ERC20, ERC20Snapshot, Ownable, ERC20Permit, ERC20Votes {
    constructor() ERC20("ArraySwap", "ARS") ERC20Permit("ArraySwap") {
        _mint(msg.sender, 200000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}