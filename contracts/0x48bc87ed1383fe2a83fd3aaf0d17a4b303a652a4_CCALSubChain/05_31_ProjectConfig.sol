/**************************
  ___  ____  ____  ____   ___   ___  ____    ___    
|_  ||_  _||_  _||_  _|.'   `.|_  ||_  _| .'   `.  
  | |_/ /    \ \  / / /  .-.  \ | |_/ /  /  .-.  \ 
  |  __'.     \ \/ /  | |   | | |  __'.  | |   | | 
 _| |  \ \_   _|  |_  \  `-'  /_| |  \ \_\  `-'  / 
|____||____| |______|  `.___.'|____||____|`.___.'  

 **************************/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./LayerZero/ILayerZeroEndpoint.sol";
import "./interface.sol";

contract ProjectConfig {
    uint public constant GAS_FOR_DEST_LZ_RECEIVE = 350000;

    ILayerZeroEndpoint public layerZeroEndpoint;

    mapping(uint16 => bytes) public remotes;

    mapping(address => ICCAL.TokenInfo) public tokenInfos;

    uint16 public constant VERSION = 1;
}