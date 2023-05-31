// SPDX-License-Identifier: MIT

/**
*   @title Waiting
*   @notice Waiting by Archan Nair
*   @author Transient Labs
*/

/**
 __     __     ______     __     ______   __     __   __     ______    
/\ \  _ \ \   /\  __ \   /\ \   /\__  _\ /\ \   /\ "-.\ \   /\  ___\   
\ \ \/ ".\ \  \ \  __ \  \ \ \  \/_/\ \/ \ \ \  \ \ \-.  \  \ \ \__ \  
 \ \__/".~\_\  \ \_\ \_\  \ \_\    \ \_\  \ \_\  \ \_\\"\_\  \ \_____\ 
  \/_/   \/_/   \/_/\/_/   \/_/     \/_/   \/_/   \/_/ \/_/   \/_____/ 
                                                                        
   ___                            __  ___         ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.0;

import "ERC721TLCreator.sol";

contract Waiting is ERC721TLCreator {

    constructor(address royaltyRecp, uint256 roayltyPerc, address admin) 
    ERC721TLCreator("Waiting", "WAIT", royaltyRecp, royaltyPerc, admin) {}
}