// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Ownable.sol";

contract DualXNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address public dualXContract;
    string public baseURI_;

    constructor(address _owner_, address _dualXContract) 
        ERC721("DualXNFT", "DUX")
        Ownable(_owner_)
    {
        dualXContract = _dualXContract;
    }

    function safeMint(address to) public {
        require(
            msg.sender == dualXContract, 
            "DualXNFT: only dualXContract can mint token"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(msg.sender == dualXContract, "DualXNFT: only dualXContract can burn tokens");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return baseURI_;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI_ = _uri;
    }
}