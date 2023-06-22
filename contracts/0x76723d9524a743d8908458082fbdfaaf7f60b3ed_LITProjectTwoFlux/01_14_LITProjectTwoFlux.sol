// SPDX-License-Identifier: MIT

/**
*   @title LIT Project Two: Flux
*   @author Transient Labs, Copyright (C) 2021
*   @notice ERC721 smart contract with ownership and optimized for airdrop
*/

/**
 (      (                 (                                                                            (                        
 )\ )   )\ )    *   )     )\ )                                     )      *   )                        )\ )   (                 
(()/(  (()/(  ` )  /(    (()/(   (            (      (          ( /(    ` )  /(   (  (                (()/(   )\     (       )  
 /(_))  /(_))  ( )(_))    /(_))  )(     (     )\    ))\    (    )\())    ( )(_))  )\))(     (          /(_)) ((_)   ))\   ( /(  
(_))   (_))   (_(_())    (_))   (()\    )\   ((_)  /((_)   )\  (_))/    (_(_())  ((_)()\    )\   _    (_))_|  _    /((_)  )\()) 
| |    |_ _|  |_   _|    | _ \   ((_)  ((_)    !  (_))    ((_) | |_     |_   _|  _(()((_)  ((_) (_)   | |_   | |  (_))(  ((_)\  
| |__   | |     | |      |  _/  | '_| / _ \   | | / -_)  / _|  |  _|      | |    \ V  V / / _ \  _    | __|  | |  | || | \ \ /  
|____| |___|    |_|      |_|    |_|   \___/  _/ | \___|  \__|   \__|      |_|     \_/\_/  \___/ (_)   |_|    |_|   \_,_| /_\_\  
                                            |__/                                                                                      
   ___                            __  ___         ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "Counters.sol";
import "EIP2981.sol";

contract LITProjectTwoFlux is EIP2981, ERC721, Ownable {
    string private _baseTokenURI;
    uint256 public supply;

    /**
    *   @notice constructor for this contract
    *   @dev increments the next token counter
    *   @dev name and symbol are hardcoded in from the start
    */
    constructor(address _royaltyRecipient, uint256 _royaltyAmount) EIP2981(_royaltyRecipient, _royaltyAmount) ERC721("LIT Project Two: Flux", "LP2F") {}

    /**
    *   @notice overrides supportsInterface function
    *   @param _interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, EIP2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
    *   @notice function to view total supply
    *   @return uint256 with supply
    */
    function totalSupply() public view returns(uint256) {
        return supply;
    }

    /**
    *   @notice function to change the royalty recipient
    *   @dev requires owner
    *   @dev this is useful if an account gets compromised or anything like that
    *   @param _newRecipient is the new royalty recipient
    */
    function changeRoyaltyRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "Error: new recipient is the zero address");
        royaltyAddr = _newRecipient;
    }

    /**
    *   @notice function to change the royalty percentage
    *   @dev requires owner
    *   @dev this is useful if the amount was set improperly at contract creation. This can in fact happen... humans are prone to mistakes :) 
    *   @param _newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function changeRoyaltyPercentage(uint256 _newPerc) public onlyOwner {
        require(_newPerc <= 10000, "Error: new percentage is greater than 10,0000");
        royaltyPerc = _newPerc;
    }

    /**
    *   @notice sets the baseURI for the ERC721 tokens
    *   @dev requires ownership
    *   @param uri is the base URI set for each token
    */
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    /**
    *   @notice override standard ERC721 base URI
    *   @dev doesn't require access control since it's internal
    *   @return string representing base URI
    */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    *   @notice mint function in batches
    *   @dev requires ADMIN access
    *   @dev converts token id to the appropriate tokenURI string
    *   @param addresses is an array of addresses to mint to
    *   @param id is the token id to start at
    */
    function mint(address[] calldata addresses, uint256 id) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], id + i);
        }
        supply += addresses.length;
    }

    /**
    *   @notice burn function for owners to use at their discretion
    *   @dev requires the msg sender to be the owner or an approved delegate
    *   @param tokenId is the token ID to burn
    */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Error: Caller for burning is not approved nor owner");
        _burn(tokenId);
    }
}