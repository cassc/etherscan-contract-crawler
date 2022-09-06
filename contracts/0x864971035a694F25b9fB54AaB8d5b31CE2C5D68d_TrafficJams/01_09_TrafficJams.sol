// SPDX-License-Identifier: GPL-3.0-or-later

/// @title Traffic Jams
/// @notice A custom version of Shatter where the shattered pieces are 1 of 1's. No Fuse functionality and collector doesn't choose number to shatter.
/// @author Transient Labs

pragma solidity ^0.8.9;

/*
 ______   ______     ______     ______   ______   __     ______          __     ______     __    __     ______    
/\__  _\ /\  == \   /\  __ \   /\  ___\ /\  ___\ /\ \   /\  ___\        /\ \   /\  __ \   /\ "-./  \   /\  ___\   
\/_/\ \/ \ \  __<   \ \  __ \  \ \  __\ \ \  __\ \ \ \  \ \ \____      _\_\ \  \ \  __ \  \ \ \-./\ \  \ \___  \  
   \ \_\  \ \_\ \_\  \ \_\ \_\  \ \_\    \ \_\    \ \_\  \ \_____\    /\_____\  \ \_\ \_\  \ \_\ \ \_\  \/\_____\ 
    \/_/   \/_/ /_/   \/_/\/_/   \/_/     \/_/     \/_/   \/_____/    \/_____/   \/_/\/_/   \/_/  \/_/   \/_____/ 
                                                                                                                  
   ___       _ __   __  ___  _ ______                 __ 
  / _ )__ __(_) /__/ / / _ \(_) _/ _/__ _______ ___  / /_
 / _  / // / / / _  / / // / / _/ _/ -_) __/ -_) _ \/ __/
/____/\_,_/_/_/\_,_/ /____/_/_//_/ \__/_/  \__/_//_/\__/                                                          
 ______                  _          __    __        __     
/_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/                                                           
*/

import "ERC721A.sol";
import "EIP2981AllToken.sol";
import "Ownable.sol";

contract TrafficJams is ERC721A, EIP2981AllToken, Ownable {

    bool public isShattered;
    uint256 public numShatters;
    uint256 public shatters;
    uint256 public shatterTime;
    address public admin;
    string internal baseURI;

    event Shattered(address indexed _user, uint256 indexed _numShatters, uint256 indexed _shatterTime);

    modifier adminOrOwner {
        require(msg.sender == admin || msg.sender == owner(), "Address not admin or owner");
        _;
    }

    /// @param _royaltyRecipient is the royalty recipient
    /// @param _royaltyPercentage is the royalty percentage to set
    /// @param _admin is the admin address
    /// @param _numShatters is the number of shatters that will happen
    /// @param _shatterTime is time after which shatter can occur
    constructor (address _royaltyRecipient, uint256 _royaltyPercentage, address _admin,
        uint256 _numShatters, uint256 _shatterTime)
        ERC721A("Traffic Jams by Bryan Brinkman and Rich Caldwell", "JAM") Ownable() 
    {  
        royaltyAddr = _royaltyRecipient;
        royaltyPerc = _royaltyPercentage;
        admin = _admin;
        numShatters = _numShatters;
        shatterTime = _shatterTime;
    }

    /// @notice function to change the royalty info
    /// @dev requires admin or owner
    /// @dev this is useful if the amount was set improperly at contract creation.
    /// @param newAddr is the new royalty payout addresss
    /// @param newPerc is the new royalty percentage, in basis points (out of 10,000)
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external adminOrOwner {
        _setRoyaltyInfo(newAddr, newPerc);
    }

    /// @notice function to set the admin address on the contract
    /// @dev requires owner
    /// @param _admin is the new admin address
    function setAdminAddress(address _admin) external onlyOwner {
        require(_admin != address(0), "New admin cannot be the zero address");
        admin = _admin;
    }

    /// @notice function for minting the 1/1 to the owner's address
    /// @dev requires contract owner or admin
    /// @dev sets the description, image, animation url (if exists), and traits for the piece
    /// @dev requires that shatters is equal to 0 -> meaning no piece has been minted
    /// @dev using _mint function as owner() should always be an EOA or trusted entity
    function mint() external adminOrOwner {
        require(shatters == 0, "Already minted the first piece");
        shatters = 1;
        _mint(owner(), 1);
    }

    /// @notice function for owner of token 0 to unlock the pieces
    /// @dev requires msg.sender to be the owner of token 0
    /// @dev shatters to specified number of shatters
    /// @dev requires isShattered to be false
    /// @dev requires block timestamp to be greater than or equal to shatterTime
    /// @dev purposefully not letting approved addresses shatter as we want owner to be the only one to shatter the token
    function shatter() external {
        require(!isShattered, "Already is shattered");
        require(msg.sender == ownerOf(0), "Caller is not owner of token 0");
        require(block.timestamp >= shatterTime, "Cannot shatter prior to shatterTime");

        isShattered = true;
        shatters = numShatters;
        _burn(0);
        _mint(msg.sender, numShatters);
        emit Shattered(msg.sender, numShatters, block.timestamp);
    }

    /// @notice function to set base uri
    /// @dev requires admin or owner
    function setBaseURI(string memory _uri) external adminOrOwner {
        baseURI = _uri;
    }

    /// @notice override _baseURI() function from ERC721A
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice overrides supportsInterface function
    /// @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    /// @return boolean saying if this contract supports the interface or not
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, EIP2981AllToken) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || EIP2981AllToken.supportsInterface(interfaceId);
    }
}