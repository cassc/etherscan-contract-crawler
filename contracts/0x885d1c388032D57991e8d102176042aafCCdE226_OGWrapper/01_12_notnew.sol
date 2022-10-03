// SPDX-License-Identifier: MIT
/*                                                       
      ___           ___           ___           ___                       ___                       ___           ___     
     /\  \         /\__\         /\  \         /\__\          ___        /\  \          ___        /\  \         /\__\    
    /::\  \       /::|  |       /::\  \       /:/  /         /\  \      /::\  \        /\  \      /::\  \       /::|  |   
   /:/\:\  \     /:|:|  |      /:/\ \  \     /:/  /          \:\  \    /:/\ \  \       \:\  \    /:/\:\  \     /:|:|  |   
  /::\~\:\  \   /:/|:|  |__   _\:\~\ \  \   /:/__/  ___      /::\__\  _\:\~\ \  \      /::\__\  /:/  \:\  \   /:/|:|  |__ 
 /:/\:\ \:\__\ /:/ |:| /\__\ /\ \:\ \ \__\  |:|  | /\__\  __/:/\/__/ /\ \:\ \ \__\  __/:/\/__/ /:/__/ \:\__\ /:/ |:| /\__\
 \:\~\:\ \/__/ \/__|:|/:/  / \:\ \:\ \/__/  |:|  |/:/  / /\/:/  /    \:\ \:\ \/__/ /\/:/  /    \:\  \ /:/  / \/__|:|/:/  /
  \:\ \:\__\       |:/:/  /   \:\ \:\__\    |:|__/:/  /  \::/__/      \:\ \:\__\   \::/__/      \:\  /:/  /      |:/:/  / 
   \:\ \/__/       |::/  /     \:\/:/  /     \::::/__/    \:\__\       \:\/:/  /    \:\__\       \:\/:/  /       |::/  /  
    \:\__\         /:/  /       \::/  /       ~~~~         \/__/        \::/  /      \/__/        \::/  /        /:/  /   
     \/__/         \/__/         \/__/                                   \/__/                     \/__/         \/__/    
      ___                    ___                   ___           ___           ___           ___           ___     
     |\__\                  /\__\      ___        /\__\         /\  \         /\  \         /\  \         /\  \    
     |:|  |                /:/  /     /\  \      /::|  |       /::\  \       /::\  \       /::\  \       /::\  \   
     |:|  |               /:/  /      \:\  \    /:|:|  |      /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \  
     |:|__|__            /:/  /       /::\__\  /:/|:|  |__   /::\~\:\  \   /:/  \:\  \   /::\~\:\  \   /::\~\:\  \ 
 ____/::::\__\          /:/__/     __/:/\/__/ /:/ |:| /\__\ /:/\:\ \:\__\ /:/__/_\:\__\ /:/\:\ \:\__\ /:/\:\ \:\__\
 \::::/~~/~             \:\  \    /\/:/  /    \/__|:|/:/  / \/__\:\/:/  / \:\  /\ \/__/ \:\~\:\ \/__/ \:\~\:\ \/__/
  ~~|:|~~|               \:\  \   \::/__/         |:/:/  /       \::/  /   \:\ \:\__\    \:\ \:\__\    \:\ \:\__\  
    |:|  |                \:\  \   \:\__\         |::/  /        /:/  /     \:\/:/  /     \:\ \/__/     \:\ \/__/  
    |:|  |                 \:\__\   \/__/         /:/  /        /:/  /       \::/  /       \:\__\        \:\__\    
     \|__|                  \/__/                 \/__/         \/__/         \/__/         \/__/         \/__/*/

///////////////// Credits /////////////////////////////////////////////////////////////////////////////////////////////////
// @_linagee   - 2015 Name contract Author
// @optimizoor - ERC721A
// @cygar_dev  - ERC721A
// @m_keresty  - re-discovery
// @lcfr_eth   - this hackjob
//
// https://ens.vision
                                                                                                                                                                                     
pragma solidity ^0.8.2;

import "ERC721AA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OGWrapper is ERC721A, Ownable {

    // Base URI
    string private baseURI;
    // Linagee OG Name Wrapper OGW
    constructor() ERC721A("OG Name Wrapper", "OGW")
    {
        // lol degens
        // lol degens
        // lol degens
        // lol degens
    }

    // wrap an existing token in two steps.
    // first wrap the names on this contract.
    // second - initiate transfer on the LNS contract to transfer the names to this contract. - now your names are wrapped into ERC721
    function wrap(string[] calldata _names) external {
        _wrap(_names);
    }

    // unwrap token and set the caller to the owner on LNS contract.
    function unwrap(string[] calldata _names) external {
        _unwrap(_names);
    }

    // mint wrapped erc721 Linagee Names tied to the token.
    function LNSWrappedMint(string[] calldata _names) external payable {
        _mintNames(_msgSender(), _names);
    }

    // return the corresponding tokenId => tokenHash
    function getTokenHash(uint256 tokenId) external view returns (bytes32) {
        return _getTokenHash(tokenId);
    }

    // return the corresponding name tokenid => Name
    function getTokenNameId(uint256 tokenId) external view returns (string memory) {
        require(_getTokenHash(tokenId) == stringToBytes32(_getTokenName(tokenId)), "invalid tokenId");
        return _getTokenName(tokenId);
    }

    // return the corresponding Name => tokenid
    function getTokenIdName(string calldata _name) external view returns (uint256) {
        require(strlen(_name) > 0, "no name");
        return _getNameTokenId(_name);
    }

    // return the owner of the ERC721 & OG token wrapped versions
    function getOwnerWrapper(string calldata _name) external view returns(address) {
        require(strlen(_name) > 0, "no name");
        return _getOwnerWrapper(_name);
    }

    // return the name owner from the Linagee OG contract
    // this should be this contract address for wrapped names.
    function getOwnerLNS(string calldata _name) external view returns(address) {
        require(strlen(_name) > 0, "no name");
        return address(uint160(uint256(oldNames.owner(stringToBytes32(_name)))));
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    // returns bool true if name is available to be registered/wrapped.
    function available(string calldata _name) external view returns(bool) {
        if (oldNames.owner(stringToBytes32(_name)) == bytes32(0)) {
            return bool(true);
        } else {
            return bool(false);
        }
    }

    function _mintNames(address to, string[] calldata _names) internal {
        uint256 quantity = _names.length;

        for (uint256 i = 0; i < quantity;) {
            bytes32 name = stringToBytes32(_names[i]);
            require(oldNames.owner(name) == bytes32(0), "name not available");
            oldNames.reserve(name);
            unchecked {i++;}
        }
        _safeMint(to, _names);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // mistakes happein
    function adminWithdraw() external onlyOwner {
        (bool sent,) = address(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}