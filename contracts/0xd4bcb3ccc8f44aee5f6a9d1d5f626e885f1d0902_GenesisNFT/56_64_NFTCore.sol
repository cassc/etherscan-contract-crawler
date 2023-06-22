// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '../interfaces/IERC721Core.sol';
import './SafeOwnableInterface.sol';

abstract contract NFTCore is ERC721, IERC721Core, SafeOwnableInterface {

    uint public immutable MAX_SUPPLY;
    string internal baseURI;
    uint public override totalSupply;

    constructor(string memory _name, string memory _symbol, string memory _uri, uint _maxSupply) ERC721(_name, _symbol) {
        baseURI = _uri;
        MAX_SUPPLY = _maxSupply;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function mintInternal(address _to, uint _num) internal {
        uint mTotalSupply = totalSupply;
        require(_num > 0 && mTotalSupply + _num <= MAX_SUPPLY, "already full");
        unchecked {
            for (uint i = 0; i < _num; i ++) {
                _mint(_to, mTotalSupply + 1 + i); 
            }
            totalSupply += _num;
        }
    }

    function burnInternal(address _user, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _user, "illegal owner");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "caller is not owner nor approved");
        _burn(_tokenId);
    }

}