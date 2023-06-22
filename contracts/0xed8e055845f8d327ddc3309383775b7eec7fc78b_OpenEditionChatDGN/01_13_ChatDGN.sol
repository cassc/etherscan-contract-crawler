// SPDX-License-Identifier: MIT

/*
  __   ___  _             _       ___    ___      __ __  
 / /  / __\| |__    __ _ | |_    /   \  / _ \  /\ \ \\ \ 
/ /  / /   | '_ \  / _` || __|  / /\ / / /_\/ /  \/ / \ \
\ \ / /___ | | | || (_| || |_  / /_// / /_\\ / /\  /  / /
 \_\\____/ |_| |_| \__,_| \__|/___,'  \____/ \_\ \/  /_/

by OG-STUDIO

 */


pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract OpenEditionChatDGN is ERC721, Ownable {

    uint64 public _tokenIds = 0;    
    bool open = true;
    
    string public uri;
    
    constructor() ERC721("<ChatDGN> Open Edition","DGNO") {
    }

    function drain() public onlyOwner {
	    payable(owner()).transfer(address(this).balance);
    }

    //fallback, you never knows if someone wants to tip you ;)
    receive() external payable {
    }

    function setURI(string memory _uri) public onlyOwner {
        uri = _uri;
    }
    
    function close() public onlyOwner {
        open = false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        return uri;

    }

    function mint() public {
        require(open, "too late");

        // index starts at 1 (NOT zero based!!!!)
        unchecked {_tokenIds++;} 
        _safeMint(msg.sender, _tokenIds);
        
    }

}