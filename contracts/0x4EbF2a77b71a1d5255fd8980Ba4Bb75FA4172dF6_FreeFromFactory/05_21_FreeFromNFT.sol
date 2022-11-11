// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract FreeFromNFT is ERC721URIStorage{
    string public baseURI;
    address public factory;
    uint256 public totalSupply;

    constructor(
        address factory_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        factory = factory_;
        setBaseURI(baseURI_);
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "require factory");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyFactory {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _cid) internal {
        _setTokenURI(_tokenId, _cid);
    }
    
    function mint(address _to, string memory _cid) public onlyFactory returns (uint256){
        _mint(_to, ++totalSupply);
        setTokenURI(totalSupply, _cid);
        return totalSupply;
    }

    function burn(uint256 _tokenId) public onlyFactory {
        _burn(_tokenId);
    }

}