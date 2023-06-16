// SPDX-License-Identifier: MIT
/*
   ____    _             __  __                                                 _____   _                                 _                                 _     
  / __ \  | |           |  \/  |                                               |_   _| ( )                               | |                               | |    
 | |  | | | |__         | \  / |   ___    _ __ ___    _ __ ___    _   _          | |   |/   _ __ ___      ___    ___     | |__     ___    _ __    ___    __| |    
 | |  | | | '_ \        | |\/| |  / _ \  | '_ ` _ \  | '_ ` _ \  | | | |         | |       | '_ ` _ \    / __|  / _ \    | '_ \   / _ \  | '__|  / _ \  / _` |    
 | |__| | | | | |  _    | |  | | | (_) | | | | | | | | | | | | | | |_| |  _     _| |_      | | | | | |   \__ \ | (_) |   | |_) | | (_) | | |    |  __/ | (_| |  _ 
  \____/  |_| |_| ( )   |_|  |_|  \___/  |_| |_| |_| |_| |_| |_|  \__, | ( )   |_____|     |_| |_| |_|   |___/  \___/    |_.__/   \___/  |_|     \___|  \__,_| (_)
                  |/                                               __/ | |/                                                                                       
                                                                  |___/                                                                                         

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BoringToken is ERC20, Ownable {

    constructor() ERC20("BoringToken", "BT") {
        _mint(msg.sender, 26900 * 10000 * 10 ** decimals());
    }


    function renounceOwnership() public override onlyOwner {
        transferOwnership(address(0));
    }
}