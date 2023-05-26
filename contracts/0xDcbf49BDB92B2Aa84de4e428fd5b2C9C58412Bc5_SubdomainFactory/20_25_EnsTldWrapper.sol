// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IENSToken.sol";
import "./interfaces/IManager.sol";

pragma solidity ^0.8.13;

contract EnsTldWrapper is ERC721, Ownable {
    address constant ENS_TOKEN_ADDRESS = 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;
    IENSToken public EnsToken = IENSToken(ENS_TOKEN_ADDRESS);
    IManager public DomainManager;
    string public BaseUri = 'https://esf.tools/api/wrapped-ens-metadata/';
    uint256 public totalSupply;

    constructor(IManager _manager) ERC721("Wrapped ENS", "WENS"){
        DomainManager = _manager;
    }

    function mint(address _addr, uint256 _tokenId) public isDomainManager {
        _safeMint(_addr, _tokenId);
        unchecked { ++totalSupply; }
    }

    function burn(uint256 _tokenId) public isDomainManager {
        _burn(_tokenId);
        unchecked { --totalSupply; } //this is only used for display generally.
    }

    function exists(uint256 _tokenId) public view returns(bool) {
        return _exists(_tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from != address(0) && to != address(0)){
            //the token could expire and then this token would not be bound to it and could be sold independently.
            //this should stop that from happening. 
          require(EnsToken.ownerOf(tokenId) == address(DomainManager) 
                    && EnsToken.nameExpires(tokenId) > block.timestamp
          , "cannot transfer if expired or not in contract"); 
          
            DomainManager.transferDomainOwnership(tokenId, to); 
        
        }
    }

    function setBaseUri(string calldata _uri) public onlyOwner {
        BaseUri = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BaseUri;
    }

   modifier isDomainManager() {
        require(address(DomainManager) == msg.sender, "is not domain manager");
      _;
   }

}