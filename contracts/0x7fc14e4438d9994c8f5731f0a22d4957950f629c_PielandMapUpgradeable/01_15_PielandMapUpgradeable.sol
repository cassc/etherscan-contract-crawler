// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
-----------------------------------
  _____ _      _                 _ 
 |  __ (_)    | |               | |
 | |__) |  ___| | __ _ _ __   __| |
 |  ___/ |/ _ \ |/ _` | '_ \ / _` |
 | |   | |  __/ | (_| | | | | (_| |
 |_|   |_|\___|_|\__,_|_| |_|\__,_|

         https://pieland.io
            @PielandNFT
===================================
*/ 

// Smart contract by Bonfire
import "./ERC721BonfireBaseUpgradeable.sol";

contract PielandMapUpgradeable is ERC721BonfireBaseUpgradeable {
    // name, symbol, bURI, maxTotalSupply, maxPerTx, maxPerWallet, mintPrice
    function initialize() initializer public {
      // function init(string memory name, string memory symbol, string memory bURI, uint256 maxTotalSupply, uint256 maxPerTx, uint256 maxPerWallet, uint256 mintPrice ) initializer public {
      ERC721BonfireBaseUpgradeable.init("Pieland Map", "PIELAND_MAP", "https://", 0, 1, 1, 0 ether);
    }
}