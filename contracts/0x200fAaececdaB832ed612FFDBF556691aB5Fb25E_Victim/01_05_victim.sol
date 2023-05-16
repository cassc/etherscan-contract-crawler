// SPDX-License-Identifier: UNLICENSED
//    _  _  ____   ___  ____  ____  __  __      ____  _____  _  _  ____  _  _ 
//   ( \/ )(_  _) / __)(_  _)(_  _)(  \/  )    (_  _)(  _  )( )/ )( ___)( \( )
//    \  /  _)(_ ( (__   )(   _)(_  )    (       )(   )(_)(  )  (  )__)  )  ( 
//     \/  (____) \___) (__) (____)(_/\/\_)     (__) (_____)(_)\_)(____)(_)\_)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Victim is ERC20{
    constructor() ERC20("Crypto Victim Token", "VIC"){
         _mint(msg.sender,420690000000*10**18);
    }
}